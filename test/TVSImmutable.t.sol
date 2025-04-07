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

    function testConstructorWithZeroAddressOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        new TVSImmutable(beneficiary, address(0), WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS);
    }

    function testConstructorWithZeroAddressBeneficiary() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSImmutable(address(0), owner, WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS);
    }

    function testConstructorWithZeroWithdrawalContract() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSImmutable(beneficiary, owner, address(0), CONSOLIDATION_CONTRACT_ADDRESS);
    }

    function testConstructorWithZeroConsolidationContract() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSImmutable(beneficiary, owner, WITHDRAWAL_CONTRACT_ADDRESS, address(0));
    }
}
