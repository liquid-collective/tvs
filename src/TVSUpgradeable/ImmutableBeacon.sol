// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

/// @title Immutable Beacon (v1)
/// @author Alluvial Finance Inc.
/// @notice An immutable beacon that whose implementation can never be altered after deployment
contract ImmutableBeacon {
    address public immutable implementation;

    constructor(address newImplementation) {
        implementation = newImplementation;
    }
}
