// SPDX-License-Identifier: Proprietary
pragma solidity =0.8.28;

// src/TVSUpgradeable/interfaces/IImmutableBeaconFactory.sol

/**
 * @title IImmutableBeaconFactory
 * @notice Interface for the Immutable Beacon Factory
 * @dev This interface is used to deploy new immutable beacon contracts
 */
interface IImmutableBeaconFactory {
    /**
     * @notice Deploys a new immutable beacon contract
     * @param implementation The address of the implementation contract
     * @return beacon The address of the deployed immutable beacon
     */
    function deployBeacon(address implementation) external returns (address beacon);
}

// src/TVSUpgradeable/ImmutableBeacon.sol

/**
 * @title Immutable Beacon (v1)
 * @author Alluvial Finance Inc.
 * @notice An immutable beacon whose implementation can never be altered after deployment
 * @dev This contract is used to store the implementation address of a proxy contract
 * @dev The implementation address is set in the constructor and cannot be changed
 */
contract ImmutableBeacon {
    /**
     * @notice The proxy implementation address stored in the beacon
     * @dev This address is set in the constructor and cannot be changed
     */
    address public immutable implementation;

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

// src/TVSUpgradeable/ImmutableBeaconFactory.sol

/**
 * @title Immutable Beacon Factory
 * @author Alluvial Finance Inc.
 * @notice Factory contract for deploying instances of immutable beacons, guaranteeing that their implementation is
 * frozen after deployment
 */
contract ImmutableBeaconFactory is IImmutableBeaconFactory {
    /// @inheritdoc IImmutableBeaconFactory
    function deployBeacon(address implementation) external returns (address beacon) {
        return address(new ImmutableBeacon(implementation));
    }
}

