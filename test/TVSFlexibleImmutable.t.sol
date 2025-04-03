// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { TVSImmutableTest } from "./TVSImmutable.t.sol";
import "../src/TVSNonUpgradeable/TVSFlexibleImmutable.sol";
import { ITVS } from "../src/interfaces/ITVS.sol";

contract MockTarget {
    bytes32 private constant STATE_SLOT = bytes32(uint256(keccak256("mock.state.slot")));

    function setState(uint256 _state) public payable {
        bytes32 stateSlot = STATE_SLOT;
        assembly {
            sstore(stateSlot, _state)
        }
    }

    function getState() public view returns (uint256 data) {
        // solhint-disable-next-line no-inline-assembly
        bytes32 stateSlot = STATE_SLOT;
        assembly {
            data := sload(stateSlot)
        }
    }
}

contract TVSFlexibleImmutableExt is TVSFlexibleImmutable, MockTarget {
    constructor(
        address beneficiary,
        address owner,
        address withdrawalContractAddress,
        address consolidationContractAddress
    )
        TVSFlexibleImmutable(beneficiary, owner, withdrawalContractAddress, consolidationContractAddress)
    { }
}

contract TVSFlexibleImmutableTest is TVSImmutableTest {
    TVSFlexibleImmutableExt tvsFlexible;
    address nonOwner = address(0x2);
    MockTarget target;

    function setUp() public override {
        target = new MockTarget();
        super.setUp();
    }

    function deployTVS() internal override returns (ITVS) {
        tvsFlexible =
            new TVSFlexibleImmutableExt(beneficiary, owner, WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS);
        return tvsFlexible;
    }

    function getCallData(uint256 _state) public pure returns (bytes memory) {
        return abi.encodeWithSignature("setState(uint256)", _state);
    }

    function generateCalls(uint256 n) public view returns (TVSFlexibleImmutable.Call[] memory) {
        TVSFlexibleImmutable.Call[] memory calls = new TVSFlexibleImmutable.Call[](n);

        for (uint256 i = 0; i < n; i++) {
            calls[i] = TVSFlexibleImmutable.Call({
                to: address(target),
                value: i % 2 == 0 ? 1 ether : 0, // Alternate between calls with and without value
                data: getCallData(i + 1), // Increment state value for each call
                isDelegateCall: i % 2 == 1 // Alternate between delegate calls and normal calls
             });
        }

        return calls;
    }

    function test_RevertWhen_CallerNotOwner() public {
        bytes memory data = getCallData(3);

        // When making a Call
        TVSFlexibleImmutable.Call memory call =
            TVSFlexibleImmutable.Call({ to: address(target), value: 0, data: data, isDelegateCall: false });

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        tvsFlexible.executeCall(call);

        // When making a DelegateCall
        TVSFlexibleImmutable.Call({ to: address(target), value: 0, data: data, isDelegateCall: true });

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        tvsFlexible.executeCall(call);
    }

    function test_ExecuteDelegateCallWhen_IsDelegateCallIsTrue() public {
        bytes memory data = getCallData(3);
        TVSFlexibleImmutable.Call memory call =
            TVSFlexibleImmutable.Call({ to: address(target), value: 0, data: data, isDelegateCall: true });

        vm.expectCall(address(target), data);
        vm.prank(owner);
        tvsFlexible.executeCall(call);

        assertEq(tvsFlexible.getState(), 3, "State of tvsFlexible should be updated to 3");
        assertEq(target.getState(), 0, "State of target should not be updated");
    }

    function test_ExecuteCallWhen_IsDelegateCallIsFalse() public {
        // When Called without Value Transfer
        bytes memory data = getCallData(3);
        TVSFlexibleImmutable.Call memory callWithoutValue =
            TVSFlexibleImmutable.Call({ to: address(target), value: 0, data: data, isDelegateCall: false });

        vm.expectCall(address(target), data);
        vm.prank(owner);
        tvsFlexible.executeCall(callWithoutValue);
        assertEq(tvsFlexible.getState(), 0, "State of tvsFlexible should not be updated");
        assertEq(target.getState(), 3, "State of target should be updated to 3");

        // When called with Value Transfer
        data = getCallData(7);
        uint256 _value = 1 ether;
        TVSFlexibleImmutable.Call memory callWithValue =
            TVSFlexibleImmutable.Call({ to: address(target), value: _value, data: data, isDelegateCall: false });

        vm.expectCall(address(target), _value, data);
        vm.deal(owner, _value);
        vm.prank(owner);
        tvsFlexible.executeCall{ value: _value }(callWithValue);
        assertEq(tvsFlexible.getState(), 0, "State of tvsFlexible should not be updated");
        assertEq(target.getState(), 7, "State of target should be updated to 7");
    }

    function test_ExecuteBatch_ShouldBeAtomic() public {
        // Prepare the batch of calls
        TVSFlexibleImmutable.Call[] memory calls = new TVSFlexibleImmutable.Call[](2);

        // First call: Set value in target1
        calls[0] =
            TVSFlexibleImmutable.Call({ to: address(target), value: 0, data: getCallData(42), isDelegateCall: false });

        // Second call: Invalid call to revert
        calls[1] = TVSFlexibleImmutable.Call({
            to: address(0xdead), // Invalid address
            value: 0,
            data: getCallData(84),
            isDelegateCall: false
        });

        // Prank as the owner
        vm.prank(owner);

        // Expect revert on the second call
        vm.expectRevert(); // Not concerned with the exact reason, we care only that one bad call should fail the whole
            // batch
        tvsFlexible.executeBatch(calls);
    }

    function test_ExecuteBatch_RevertWhen_CallerNotOwner() public {
        // Prepare the batch of calls
        TVSFlexibleImmutable.Call[] memory calls = new TVSFlexibleImmutable.Call[](1);

        // First call: Set value in target1
        calls[0] =
            TVSFlexibleImmutable.Call({ to: address(target), value: 0, data: getCallData(84), isDelegateCall: false });

        // Prank as a non-owner
        vm.prank(nonOwner);

        // Expect revert due to unauthorized caller
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        tvsFlexible.executeBatch(calls);
    }

    function test_ExecuteBatch_TargetCalledNTimes(uint256 n) public {
        n = n % 20; // Arbitrary number;

        // Generate the calls
        TVSFlexibleImmutable.Call[] memory calls = generateCalls(n);

        // Prank as the owner
        vm.prank(owner);

        // Expect the target to be called `n` times
        for (uint256 i = 0; i < n; i++) {
            if (calls[i].isDelegateCall) {
                vm.expectCall(address(target), calls[i].data);
            } else {
                vm.expectCall(address(target), calls[i].value, calls[i].data);
            }
        }

        // Fund the owner for calls with value
        uint256 _value = n * 1 ether;
        vm.deal(owner, _value);

        // Execute the batch
        tvsFlexible.executeBatch{ value: _value }(calls);
    }
}
