// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TVSImmutableTest} from "./TVSImmutable.t.sol";
import "../src/TVSNonUpgradeable/TVSFlexibleImmutable.sol";

contract MockValidTarget {
    function someFunction() public pure {}
    function anotherFunction(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
    function anotherFunctionPayable(uint256 a, uint256 b) payable public returns (uint256) {
        return a + b;
    }
}

contract MockValidContractWithPayableFunction {
    function someFunction() public payable {}
}

contract TVSFlexibleImmutableTest is TVSImmutableTest {

    TVSFlexibleImmutable tvsFlexible;
    address nonOwner = address(0x2);
    address validTarget = address(new MockValidTarget());
    address invalidTarget = address(0x0);
    bytes validData = abi.encodeWithSignature("someFunction()");
    bytes validDataWithParam = abi.encodeWithSignature("someFunction(uint256,uint256)", 1, 2);
    bytes validDataWithParamPayable = abi.encodeWithSignature("anotherFunctionPayable(uint256,uint256)", 1, 2);
    bytes invalidData = abi.encodeWithSignature("invalidFunction()");
    uint256 validValue = 1 ether;

    function setUp() public override{
        super.setUp();
        vm.deal(owner, 10 ether);
        vm.deal(address(this), 10 ether);
        tvsFlexible = new TVSFlexibleImmutable(beneficiary, owner, WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS);
    }

    function test_RevertWhen_CallerNotOwner() public {
        TVSFlexibleImmutable.Call memory call = TVSFlexibleImmutable.Call({
            to: validTarget,
            value: 0,
            data: validData,
            isDelegateCall: false
        });

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        tvsFlexible.executeCall(call);
    }

    function test_RevertWhen_InvalidTargetAddress() public {
        TVSFlexibleImmutable.Call memory call = TVSFlexibleImmutable.Call({
            to: invalidTarget,
            value: 0,
            data: validData,
            isDelegateCall: false
        });

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("AddressEmptyCode(address)", address(0)));
        tvsFlexible.executeCall(call);
    }

    function test_RevertWhen_InvalidDelegateCallTargetAddress() public {
        TVSFlexibleImmutable.Call memory call = TVSFlexibleImmutable.Call({
            to: invalidTarget,
            value: 0,
            data: validData,
            isDelegateCall: true
        });

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("AddressEmptyCode(address)", address(0)));
        tvsFlexible.executeCall(call);
    }

    function test_RevertWhen_InvalidCallData() public {
        TVSFlexibleImmutable.Call memory call = TVSFlexibleImmutable.Call({
            to: validTarget,
            value: 0,
            data: invalidData,
            isDelegateCall: false
        });

        vm.prank(owner);
        vm.expectRevert(); // Expect revert with the target's revert reason
        tvsFlexible.executeCall(call);
    }

    function test_RevertWhen_InsufficientBalanceForValueTransfer() public {
        TVSFlexibleImmutable.Call memory call = TVSFlexibleImmutable.Call({
            to: validTarget,
            value: validValue,
            data: validData,
            isDelegateCall: false
        });

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance(uint256,uint256)", 0, 1 ether));
        tvsFlexible.executeCall(call);
    }

    function test_ExecuteCall_SuccessfulWithValueTransfer() public {
        TVSFlexibleImmutable.Call memory call = TVSFlexibleImmutable.Call({
            to: validTarget,
            value: validValue,
            data: validDataWithParamPayable,
            isDelegateCall: false
        });

        vm.deal(owner, validValue);
        vm.prank(owner);
        bytes memory resultByte = tvsFlexible.executeCall{value: call.value}(call);
        // convert the result to uint256
        uint256 result = abi.decode(resultByte, (uint256));
        assertEq(result, 3, "Result should be 3");
        // Add assertions to verify the expected state changes or events
    }

    function test_ExecuteCall_SuccessfulWithoutValueTransfer() public {
        TVSFlexibleImmutable.Call memory call = TVSFlexibleImmutable.Call({
            to: validTarget,
            value: 0,
            data: validData,
            isDelegateCall: false
        });

        vm.prank(owner);
        tvsFlexible.executeCall(call);
        // Add assertions to verify the expected state changes or events
    }
}
