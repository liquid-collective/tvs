// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

/**
 * @title Immutable Beacon (v1)
 * @author Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation
 * @notice An immutable beacon whose implementation can never be altered after deployment
 * @dev This contract is used to store the implementation address of a proxy contract
 * @dev The implementation address is set in the constructor and cannot be changed
 */
contract ImmutableBeacon {
    /**
     * @notice The proxy implementation address stored in the beacon
     * @dev This address is set in the constructor and cannot be changed
     */
    address public immutable implementation; // solhint-disable-line

    /**
     * @notice Emitted when the implementation address is invalid
     */
    error InvalidImplementation();

    /**
     * @notice Constructor for the ImmutableBeacon contract
     * @dev Sets the proxy implementation address on the beacon
     * @param theImplementation The address of the implementation contract
     */
    constructor(address theImplementation) {
        if (theImplementation == address(0)) revert InvalidImplementation();
        implementation = theImplementation;
    }
}
