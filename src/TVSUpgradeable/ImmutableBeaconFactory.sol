// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./ImmutableBeacon.sol";
import "./interfaces/IImmutableBeaconFactory.sol";

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
