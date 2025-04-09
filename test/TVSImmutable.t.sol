//SPDX-License-Identifier: Proprietary

pragma solidity 0.8.28;

import "forge-std/Test.sol";
import { TVSImmutable } from "../src/TVSNonUpgradeable/TVSImmutable.sol";
import { ITVS } from "../src/interfaces/ITVS.sol";
import { TVSImmutableBaseTest } from "./TVSImmutableBase.t.sol";

// Tests specific to TVSImmutable
contract TVSImmutableTest is TVSImmutableBaseTest {
    function deployTVS() internal virtual override returns (ITVS) {
        return new TVSImmutable(beneficiary, owner, WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS);
    }

    /**
     * @notice Tests that the constructor reverts when the owner address is zero.
     * @dev Ensures the contract enforces a valid owner address during deployment.
     *      Expects the revert reason "OwnableInvalidOwner(address)" with the zero address.
     */
    function testConstructorWithZeroAddressOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        new TVSImmutable(beneficiary, address(0), WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS);
    }

    /**
     * @notice Tests that the constructor reverts when the beneficiary address is zero.
     * @dev Ensures the contract enforces a valid beneficiary address during deployment.
     *      Expects the revert reason "InvalidAddress()".
     */
    function testConstructorWithZeroAddressBeneficiary() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSImmutable(address(0), owner, WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS);
    }

    /**
     * @notice Tests that the constructor reverts when the withdrawal contract address is zero.
     * @dev Expects the `InvalidAddress()` error to be reverted.
     */
    function testConstructorWithZeroWithdrawalContract() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSImmutable(beneficiary, owner, address(0), CONSOLIDATION_CONTRACT_ADDRESS);
    }

    /**
     * @notice Tests that the constructor reverts when the consolidation contract address is zero.
     * @dev Expects the `InvalidAddress()` error to be reverted.
     */
    function testConstructorWithZeroConsolidationContract() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSImmutable(beneficiary, owner, WITHDRAWAL_CONTRACT_ADDRESS, address(0));
    }
}
