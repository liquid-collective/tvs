// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import "forge-std/Test.sol";

import { TVSClone } from "../src/TVSNonUpgradeable/TVSClone.sol";
import { ITVS } from "../src/interfaces/ITVS.sol";
import { PectraAddress } from "./TVS.t.sol";
import { TVSImmutableBaseTest } from "./TVSImmutableBase.t.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import { Clones } from "lib/openzeppelin-contracts/contracts/proxy/Clones.sol";

contract MockInvalidTVSImplementation { }

contract TVSCloneInitializationTest is Test, PectraAddress {
    address beneficiary;
    address owner;
    address tvsImplementation;
    TVSClone clone;

    /**
     * @notice Sets up the test environment.
     */
    function setUp() public {
        tvsImplementation = address(new TVSClone(WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS));
        clone = TVSClone(payable(Clones.clone(tvsImplementation)));
        beneficiary = makeAddr("beneficiary");
        owner = makeAddr("owner");
    }

    /**
     * @notice Tests that the constructor reverts when the withdrawal contract address is zero.
     * @dev Expects the `InvalidAddress()` error to be reverted.
     */
    function testConstructorWithZeroWithdrawalContract() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSClone(address(0), CONSOLIDATION_CONTRACT_ADDRESS);
    }

    /**
     * @notice Tests that the constructor reverts when the consolidation contract address is zero.
     * @dev Expects the `InvalidAddress()` error to be reverted.
     */
    function testConstructorWithZeroConsolidationContract() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSClone(WITHDRAWAL_CONTRACT_ADDRESS, address(0));
    }

    /**
     * @notice Tests that the constructor reverts when the owner address is zero.
     * @dev Ensures the contract enforces a valid owner address during deployment.
     *      Expects the revert reason "OwnableInvalidOwner(address)" with the zero address.
     */
    function testInitializerWithZeroAddressOwner() public {
        TVSClone clone = TVSClone(payable(Clones.clone(tvsImplementation)));

        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        clone.initialize(beneficiary, address(0));
    }

    /**
     * @notice Tests that the initializer reverts when the beneficiary address is zero.
     * @dev Ensures the contract enforces a valid beneficiary address during deployment.
     *      Expects the revert reason "InvalidAddress()".
     */
    function testInitializerWithZeroAddressBeneficiary() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        clone.initialize(address(0), owner);
    }

    /**
     * @notice Tests deployment of proxy for TVSClone with valid arguments.
     * @dev Ensures that:
     * - The contract deploys and initializes successfully.
     * - The owner, and beneficiary are correctly set, as confirmed by getter functions.
     * - A custom error `InvalidInitialization()` is reverted if `initialize` is called after deployment.
     */
    function testDeployWithValidArguments() public {
        // Deploy the contract with the given valid arguments
        clone.initialize(beneficiary, owner);

        // Ensure that the contract was deployed and initialized successfully
        assertEq(clone.getBeneficiary(), beneficiary, "Beneficiary address not correct");
        assertEq(clone.owner(), owner, "Owner address not correct");

        // Ensure that the contract cannot be initialized again
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        clone.initialize(beneficiary, owner);
    }

    /**
     * @notice Tests deployment of proxy for TVSClone with a non-`TVS` contract as implementation.
     * @dev Expects the deployment to revert without data
     */
    function testWithNonTVSImplementation() public {
        // Deploy a non-TVS contract to act as an invalid implementation
        address invalidImplementation = address(new MockInvalidTVSImplementation());

        // Expect the transaction to revert due to non-TVS implementation
        address clone = Clones.clone(invalidImplementation);
        vm.expectRevert();
        TVSClone(payable(clone)).initialize(beneficiary, owner);
    }

    /**
     * @notice Tests deployment of proxy for TVSClone with a zero address as the owner.
     * @dev Expects the deployment to revert with the custom error `OwnableInvalidOwner(address)` when a zero address is
     * provided as the owner.
     */
    function testWithZeroAddressOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        clone.initialize(beneficiary, address(0));
    }

    /**
     * @notice Tests deployment of proxy for TVSClone with a zero address as the beneficiary.
     * @dev Expects the deployment to revert with the custom error `InvalidAddress()` when a zero address is
     * provided as the beneficiary.
     */
    function testWithZeroAddressBeneficiary() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        clone.initialize(address(0), owner);
    }
}

// Tests specific to TVSClone
contract TVSCloneTest is TVSImmutableBaseTest {
    function deployTVS() internal override returns (ITVS) {
        address tvsImplementation = address(new TVSClone(WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS));
        address payable clone = payable(Clones.clone(tvsImplementation));
        TVSClone(clone).initialize(beneficiary, owner);

        return ITVS(clone);
    }
}
