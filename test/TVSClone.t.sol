//SPDX-License-Identifier: Proprietary

pragma solidity 0.8.28;

import "forge-std/Test.sol";

import { TVSClone } from "../src/TVSNonUpgradeable/TVSClone.sol";
import { ITVS } from "../src/interfaces/ITVS.sol";
import { PectraAddress } from "./TVS.t.sol";
import { TVSImmutableBaseTest } from "./TVSImmutableBase.t.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

contract MockProxy {
    using Address for address;

    address public immutable implementation;

    constructor(address _implementation, bytes memory initData) {
        implementation = _implementation;
        implementation.functionDelegateCall(initData);
    }

    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
        if (!success) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
    }
}

contract MockInvalidTVSImplementation { }

contract TVSCloneInitializationTest is Test, PectraAddress {
    address beneficiary;
    address owner;
    address tvsImplementation;

    function setUp() public {
        tvsImplementation = address(new TVSClone(WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS));
        beneficiary = makeAddr("beneficiary");
        owner = makeAddr("owner");
    }

    /**
     * @notice Tests deployment of proxy for TVSClone with a non-`TVS` contract as implementation.
     * @dev Expects the deployment to revert with the custom error `InitializationFailed()`
    function testWithNonTVSImplementation() public {
        // Deploy a non-TVS contract to act as an invalid implementation
        address invalidImplementation = address(new MockInvalidTVSImplementation());

        bytes memory initData = abi.encodeWithSignature("initialize(address,address)", beneficiary, owner);

        // Expect the transaction to revert due to non-TVS implementation
        vm.expectRevert();
        new MockProxy(invalidImplementation, initData);
    }

    /**
     * @notice Tests deployment of proxy for TVSClone with a zero address as the owner.
     * @dev Expects the deployment to revert with the custom error `InitializationFailed()` when a zero address is
     * provided as the owner.
     */
    function testWithZeroAddressOwner() public {
        bytes memory initData = abi.encodeWithSignature("initialize(address,address)", beneficiary, address(0));

        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        new MockProxy(tvsImplementation, initData);
    }

    /**
     * @notice Tests deployment of proxy for TVSClone with a zero address as the beneficiary.
     * @dev Expects the deployment to revert with the custom error `InitializationFailed()` when a zero address is
     * provided as the beneficiary.
     */
    function testWithZeroAddressBeneficiary() public {
        bytes memory initData = abi.encodeWithSignature("initialize(address,address)", address(0), owner);

        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new MockProxy(tvsImplementation, initData);
    }
}

// Tests specific to TVSClone
contract TVSCloneTest is TVSImmutableBaseTest {
    function deployTVS() internal override returns (ITVS) {
        address tvsImplementation = address(new TVSClone(WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS));

        bytes memory initData = abi.encodeWithSignature("initialize(address,address)", beneficiary, owner);

        return ITVS(address(new MockProxy(tvsImplementation, initData)));
    }

    function testSetBeneficiaryWithValidAddress() public override { }

    function testTransfer() public override { }

    function testVersion() public override { }
}