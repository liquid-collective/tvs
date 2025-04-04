//SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "openzeppelin-contracts/contracts/utils/StorageSlot.sol";

/// @title Beacon
/// @author Alluvial Finance Inc.
/// @notice This library manages the beacon address for the proxy contract
/// @dev The beacon address is the address of the contract that holds the implementation address
/// @dev The implementation address is the address of the contract that contains the business logic
/// @dev The beacon address is expected to have an `implementation()` function that returns the address of the
///      implementation
/// @dev The proxy contract is expected to have a `BEACON_SLOT` slot that stores the beacon address
library Beacon {
    /// @dev Slot for the beacon address
    bytes32 internal constant BEACON_SLOT = bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1); // from the
        // EIP-1967 standard

    /// @notice Get the beacon address
    /// @return The beacon address
    function get() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /// @notice Set the beacon address
    /// @param newValue The new beacon address
    function set(address newValue) internal {
        StorageSlot.getAddressSlot(BEACON_SLOT).value = newValue;
    }
}
