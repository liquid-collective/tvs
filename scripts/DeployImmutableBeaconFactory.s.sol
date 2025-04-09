// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/TVSUpgradeable/ImmutableBeaconFactory.sol";

contract DeployImmutableBeaconFactory is Script {
    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the ImmutableBeaconFactory contract
        new ImmutableBeaconFactory();

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}