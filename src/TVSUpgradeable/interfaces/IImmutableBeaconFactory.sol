// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

/**
 * @title IImmutableBeaconFactory
 * @author Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation
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
