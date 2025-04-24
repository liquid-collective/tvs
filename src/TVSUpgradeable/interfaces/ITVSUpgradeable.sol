// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import "../../interfaces/ITVS.sol";

/**
 * @title TVS Interface (Upgradeable)
 * @author Alluvial Finance Inc.
 * @notice Interface for the TVS contract.
 * @dev This interface is used to interact with the TVS contract.
 * @dev The TVSUpgradeable contract is an upgradeable implementation of the TVS contract
 */
interface ITVSUpgradeable is ITVS {
    /**
     * @notice Emitted when the beacon address is updated.
     * @param oldBeacon The old beacon address.
     * @param newBeacon The new beacon address.
     */
    event BeaconUpdated(address indexed oldBeacon, address indexed newBeacon);

    /**
     * @notice Error thrown when the beacon address is invalid.
     */
    error InvalidBeacon();

    /**
     * @notice Sets a new beacon address for the TVS.
     * @dev Only the owner can call this function.
     * @dev Emits a {BeaconUpdated} event.
     * @param beacon The new beacon address.
     */
    function setBeacon(address beacon) external;

    /**
     * @notice Retrieves the current beacon address.
     * @return The address of the beacon.
     */
    function beacon() external view returns (address);
}
