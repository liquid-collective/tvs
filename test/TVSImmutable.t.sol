//SPDX-License-Identifier: Proprietary

pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {TVSUpgradeable as TVSV1} from "../src/TVSUpgradeable/TVSUpgradeable.sol";
import {TVSImmutable} from "../src/TVSNonUpgradeable/TVSImmutable.sol";
import {ITVS} from "../src/interfaces/ITVS.sol";
import {UpgradeableBeacon} from "lib/solady/src/utils/UpgradeableBeacon.sol";
import "../src/interfaces/ISweepToContract.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {BaseTVSTest} from "./TVS.t.sol";



// Tests specific to TVSImmutable
contract TVSImmutableTest is BaseTVSTest {

    function setUp() public override virtual {
        super.setUp();
    }

    function deployTVS() internal virtual override returns (ITVS) {
        return new TVSImmutable(beneficiary, owner, WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS);
    }

    function testConstructorWithZeroAddressOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        new TVSImmutable(beneficiary, address(0), WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS);
    }

    function testConstructorWithZeroAddressBeneficiary() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSImmutable(address(0), owner, WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS);
    }

    /// @notice Tests the transfer function.
    /// @dev Ensures that the state changes took effect and that the owner is the new owner.
    function testTransfer() public {
        address newBeneficiary = makeAddr("newBeneficiary");
        address newOwner = makeAddr("newOwner");

        vm.prank(owner);
        tvs.transfer(newBeneficiary, newOwner);

        assertEq(tvs.getBeneficiary(), newBeneficiary, "Beneficiary address not updated");
        assertEq(Ownable(address(tvs)).owner(), newOwner, "Owner address not updated");
    }

    /// @notice Tests that the transfer function fails if called by a non-owner.
    function testTransferFailsIfNotOwner() public {
        address newBeneficiary = makeAddr("newBeneficiary");
        address newOwner = makeAddr("newOwner");
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        tvs.transfer(newBeneficiary, newOwner);
    }
}