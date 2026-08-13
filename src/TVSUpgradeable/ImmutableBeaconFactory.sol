// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import "./ImmutableBeacon.sol";
import "./interfaces/IImmutableBeaconFactory.sol";

/**
 * @title Immutable Beacon Factory
 * @author Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation
 * @notice Factory contract for deploying instances of immutable beacons, guaranteeing that their implementation is
 * frozen after deployment
 */
contract ImmutableBeaconFactory is IImmutableBeaconFactory {
    /// @inheritdoc IImmutableBeaconFactory
    function deployBeacon(address implementation) external returns (address beacon) {
        beacon = address(new ImmutableBeacon(implementation));
    }
}
