// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import "openzeppelin-contracts/contracts/utils/StorageSlot.sol";

/**
 * @title Beacon
 * @author Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation
 * @notice This library manages the beacon address for the proxy contract
 * @dev The beacon address is the address of the contract that holds the implementation address
 * @dev The implementation address is the address of the contract that contains the business logic
 * @dev The beacon address is expected to have an `implementation()` function that returns the address of the
 *      implementation
 * @dev The proxy contract is expected to store the beacon address in the `BEACON_SLOT` slot
 */
library Beacon {
    /**
     * @notice Slot for the beacon address
     * @dev The slot is defined using the EIP-1967 standard
     */
    bytes32 internal constant BEACON_SLOT = bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1);

    /**
     * @notice Set the beacon address
     * @param newBeacon The new beacon address
     */
    function set(address newBeacon) internal {
        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;
    }

    /**
     * @notice Get the beacon address
     * @return The beacon address
     */
    function get() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }
}
