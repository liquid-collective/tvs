// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./ImmutableBeacon.sol";
import "./interfaces/IImmutableBeaconFactory.sol";

/// @title Immutable Beacon Factory (v1)
/// @author Alluvial Finance Inc.
/// @notice Factory contract for deploying instances of UpgradeableBeacon that have no owners
/// @notice Thus guaranteeing that their implementation is frozen 
contract ImmutableBeaconFactory is IImmutableBeaconFactory {

    /// @inheritdoc IImmutableBeaconFactory
    function deployBeacon(address implementation) external returns (address beacon) {
        return address(new ImmutableBeacon(implementation));
    }
}