// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

/// @title IImmutableBeaconFactory
/// @notice Interface for the Immutable Beacon Factory
interface IImmutableBeaconFactory {
    
    /// @notice Deploys a new UpgradeableBeacon contract
    /// @param implementation The address of the initial implementation contract
    /// @return beacon The address of the deployed UpgradeableBeacon
    function deployBeacon(address implementation) external returns (address beacon);
}