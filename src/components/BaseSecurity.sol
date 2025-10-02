// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardTransientUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 * @title BaseSecurity
 * @author Alluvial Finance Inc.
 * @dev This abstract contract provides a foundational setup for security features,
 *      including ownership management and reentrancy protection. It is designed to
 *      be inherited by both upgradeable and non-upgradeable contracts.
 *
 * @notice This contract uses OpenZeppelin's upgradeable libraries to ensure compatibility
 *         with upgradeable contracts. The use of upgradeable libraries is safe here because
 *         the `_setupSecurity` function is marked as `initializer`, which ensures that it
 *         can only be called once during the initialization phase of an upgradeable contract.
 *         For non-upgradeable contracts, this function can still be used during deployment
 *         without any issues, as it does not rely on proxy-specific behavior.
 *
 * @dev Rational for using upgradeable contracts:
 *      - Upgradeable contracts require initialization instead of constructors due to the
 *        proxy pattern. By using OpenZeppelin's upgradeable libraries, this contract ensures
 *        compatibility with such patterns.
 *      - Non-upgradeable contracts can also inherit this contract without any adverse effects,
 *        as the initializer function behaves like a constructor when called during deployment.
 *      - This design provides flexibility and reusability, allowing the same security setup
 *        to be used across all variants of TVS and thus reduces code duplication
 *        of functions that would otherwise be repeated in each contract simply because of
 *        the different Ownable and ReentrancyGuard implementations.
 *
 * @dev Inheriting contracts should call `_setupSecurity` during their initialization or
 *      deployment phase to properly configure ownership and reentrancy protection.
 */
abstract contract BaseSecurity is Initializable, Ownable2StepUpgradeable, ReentrancyGuardTransientUpgradeable {
    // The following storage location is copied from OpenZeppelin's Ownable2StepUpgradeable contract
    // It is copied here as the upgradeable library does not provide a public getter for the storage location
    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable2Step")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant Ownable2StepStorageLocation =
        0x237e158222e3e6968b72b9db0d8043aacf074ad9f650f0d1606b4d82ee432c00;

    /**
     * @notice Error thrown when ownership cannot be renounced.
     */
    error OwnershipCannotBeRenounced();

    /**
     * @notice Overrides the renounceOwnership function from Ownable2StepUpgradeable to prevent ownership renouncement
     * @dev This function is intentionally left empty to prevent ownership renouncement by mistake
     * @dev Emits an {OwnershipCannotBeRenounced} error
     * @dev Only callable by the contract owner
     */
    function renounceOwnership() public view override onlyOwner {
        revert OwnershipCannotBeRenounced();
    }

    /**
     * @dev Sets up the contract by initializing Ownable and ReentrancyGuard features.
     * @param _owner The address to set as the owner of the contract.
     */
    function _setupSecurity(address _owner) internal initializer {
        __Ownable_init(_owner);
        __Ownable2Step_init();
        __ReentrancyGuardTransient_init();
    }

    /**
     * @notice Internal function to clear the pending owner.
     * @dev This function is used to clear the pending owner.
     */
    function _clearPendingOwner() internal {
        Ownable2StepUpgradeable.Ownable2StepStorage storage $;
        assembly {
            $.slot := Ownable2StepStorageLocation
        }
        delete $._pendingOwner;
    }
}
