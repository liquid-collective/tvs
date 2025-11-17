// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { TVSImmutableBaseTest } from "./TVSImmutableBase.t.sol";
import { TVSFlexibleImmutable } from "../src/TVSNonUpgradeable/TVSFlexibleImmutable.sol";
import { ITVS } from "../src/interfaces/ITVS.sol";

import { ITVSFlexibleImmutable } from "../src/TVSNonUpgradeable/interfaces/ITVSFlexibleImmutable.sol";

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

contract TVSFlexibleImmutableTest is TVSImmutableBaseTest {
    TVSFlexibleImmutableExt tvsFlexible;
    address nonOwner = address(0x2);
    MockTarget target;

    function setUp() public override {
        target = new MockTarget();
        super.setUp();
    }

    /**
     * @notice Deploys the TVS contract.
     * @return The deployed TVS contract.
     */
    function deployTVS() internal override returns (ITVS) {
        tvsFlexible = new TVSFlexibleImmutableExt(
            beneficiary, owner, WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS
        );
        return tvsFlexible;
    }

    /**
     * @notice Tests that the constructor reverts when the owner address is zero.
     * @dev Ensures the contract enforces a valid owner address during deployment.
     *      Expects the revert reason "OwnableInvalidOwner(address)" with the zero address.
     */
    function testConstructorWithZeroAddressOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        new TVSFlexibleImmutable(beneficiary, address(0), WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS);
    }

    /**
     * @notice Tests that the constructor reverts when the beneficiary address is zero.
     * @dev Ensures the contract enforces a valid beneficiary address during deployment.
     *      Expects the revert reason "InvalidAddress()".
     */
    function testConstructorWithZeroAddressBeneficiary() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSFlexibleImmutable(address(0), owner, WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS);
    }

    /**
     * @notice Tests that the constructor reverts when the withdrawal contract address is zero.
     * @dev Expects the `InvalidAddress()` error to be reverted.
     */
    function testConstructorWithZeroWithdrawalContract() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSFlexibleImmutable(beneficiary, owner, address(0), CONSOLIDATION_CONTRACT_ADDRESS);
    }

    /**
     * @notice Tests that the constructor reverts when the consolidation contract address is zero.
     * @dev Expects the `InvalidAddress()` error to be reverted.
     */
    function testConstructorWithZeroConsolidationContract() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSFlexibleImmutable(beneficiary, owner, WITHDRAWAL_CONTRACT_ADDRESS, address(0));
    }

    /**
     * @notice Generates the call data for the `setState` function.
     * @param _state The state value to be set.
     * @return The call data for the `setState` function.
     */
    function getCallData(uint256 _state) public pure returns (bytes memory) {
        return abi.encodeWithSignature("setState(uint256)", _state);
    }

    /**
     * @notice Generates the calls for the `executeBatch` function.
     * @param n The number of calls to generate.
     * @return The generated calls.
     */
    function generateCalls(uint256 n) public view returns (ITVSFlexibleImmutable.Call[] memory) {
        ITVSFlexibleImmutable.Call[] memory calls = new ITVSFlexibleImmutable.Call[](n);

        for (uint256 i = 0; i < n; i++) {
            calls[i] = ITVSFlexibleImmutable.Call({
                to: address(target),
                value: i % 2 == 0 ? 1 ether : 0, // Alternate between calls with and without value
                data: getCallData(i + 1), // Increment state value for each call
                isDelegateCall: i % 2 == 1 // Alternate between delegate calls and normal calls
            });
        }

        return calls;
    }

    /**
     * @notice Tests that the `executeCall` function reverts when the caller is not the owner.
     */
    function test_RevertWhen_CallerNotOwner() public {
        bytes memory data = getCallData(3);

        // When making a Call
        ITVSFlexibleImmutable.Call memory call =
            ITVSFlexibleImmutable.Call({ to: address(target), value: 0, data: data, isDelegateCall: false });

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        tvsFlexible.executeCall(call);

        // When making a DelegateCall
        ITVSFlexibleImmutable.Call({ to: address(target), value: 0, data: data, isDelegateCall: true });

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        tvsFlexible.executeCall(call);
    }

    /**
     * @notice Tests that the `executeCall` function reverts when the `isDelegateCall` is true.
     */
    function test_ExecuteDelegateCallWhen_IsDelegateCallIsTrue() public {
        bytes memory data = getCallData(3);
        ITVSFlexibleImmutable.Call memory call =
            ITVSFlexibleImmutable.Call({ to: address(target), value: 0, data: data, isDelegateCall: true });

        vm.expectCall(address(target), data);
        vm.prank(owner);
        tvsFlexible.executeCall(call);

        assertEq(tvsFlexible.getState(), 3, "State of tvsFlexible should be updated to 3");
        assertEq(target.getState(), 0, "State of target should not be updated");
    }

    /**
     * @notice Tests that the `executeCall` function reverts when the `isDelegateCall` is false.
     */
    function test_ExecuteCallWhen_IsDelegateCallIsFalse() public {
        // When Called without Value Transfer
        bytes memory data = getCallData(3);
        ITVSFlexibleImmutable.Call memory callWithoutValue =
            ITVSFlexibleImmutable.Call({ to: address(target), value: 0, data: data, isDelegateCall: false });

        vm.expectCall(address(target), data);
        vm.prank(owner);
        tvsFlexible.executeCall(callWithoutValue);
        assertEq(tvsFlexible.getState(), 0, "State of tvsFlexible should not be updated");
        assertEq(target.getState(), 3, "State of target should be updated to 3");

        // When called with Value Transfer
        data = getCallData(7);
        uint256 _value = 1 ether;
        ITVSFlexibleImmutable.Call memory callWithValue =
            ITVSFlexibleImmutable.Call({ to: address(target), value: _value, data: data, isDelegateCall: false });

        vm.expectCall(address(target), _value, data);
        vm.deal(owner, _value);
        vm.prank(owner);
        tvsFlexible.executeCall{ value: _value }(callWithValue);
        assertEq(tvsFlexible.getState(), 0, "State of tvsFlexible should not be updated");
        assertEq(target.getState(), 7, "State of target should be updated to 7");
    }

    /**
     * @notice Tests that the `executeBatch` function reverts when the caller is not the owner.
     */
    function test_ExecuteBatch_ShouldBeAtomic() public {
        // Prepare the batch of calls
        ITVSFlexibleImmutable.Call[] memory calls = new ITVSFlexibleImmutable.Call[](2);

        // First call: Set value in target1
        calls[0] =
            ITVSFlexibleImmutable.Call({ to: address(target), value: 0, data: getCallData(42), isDelegateCall: false });

        // Second call: Invalid call to revert
        calls[1] = ITVSFlexibleImmutable.Call({
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

    /**
     * @notice Tests that the `executeBatch` function reverts when the caller is not the owner.
     */
    function test_ExecuteBatch_RevertWhen_CallerNotOwner() public {
        // Prepare the batch of calls
        ITVSFlexibleImmutable.Call[] memory calls = new ITVSFlexibleImmutable.Call[](1);

        // First call: Set value in target1
        calls[0] =
            ITVSFlexibleImmutable.Call({ to: address(target), value: 0, data: getCallData(84), isDelegateCall: false });

        // Prank as a non-owner
        vm.prank(nonOwner);

        // Expect revert due to unauthorized caller
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        tvsFlexible.executeBatch(calls);
    }

    /**
     * @notice Tests that the `executeBatch` function reverts when the target is called `n` times.
     * @param n The number of calls to generate.
     */
    function test_ExecuteBatch_TargetCalledNTimes(uint256 n) public {
        n = n % 20; // Arbitrary number;

        // Generate the calls
        ITVSFlexibleImmutable.Call[] memory calls = generateCalls(n);

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
