// SPDX-License-Identifier: Proprietary

pragma solidity 0.8.29;

import "forge-std/Test.sol";

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import { BaseTVSTest } from "./TVS.t.sol";

abstract contract TVSImmutableBaseTest is BaseTVSTest {
    /**
     * @notice Tests the transfer function.
     * @dev Ensures that the state changes took effect and that the owner is the new owner.
     */
    function testTransfer() public {
        address newBeneficiary = makeAddr("newBeneficiary");
        address newOwner = makeAddr("newOwner");

        address oldBeneficiary = tvs.getBeneficiary();
        address oldOwner = Ownable(address(tvs)).owner();

        vm.prank(owner);
        tvs.transfer(newBeneficiary, newOwner);

        assertEq(tvs.getBeneficiary(), oldBeneficiary, "Beneficiary address updated!");
        assertEq(Ownable(address(tvs)).owner(), oldOwner, "Owner address updated!");

        vm.prank(newOwner);
        tvs.acceptTransfer();

        assertEq(tvs.getBeneficiary(), newBeneficiary, "Beneficiary address not updated");
        assertEq(Ownable(address(tvs)).owner(), newOwner, "Owner address not updated");
    }

    /**
     * @notice Tests the version function.
     * @dev Ensures that the version function returns the correct version string.
     */
    function testVersion() public {
        // Call the version function
        string memory returnedVersion = tvs.version();

        // Assert that the returned version matches the expected value
        assertEq(returnedVersion, "1.0.1", "Version string does not match expected value");
    }
}
