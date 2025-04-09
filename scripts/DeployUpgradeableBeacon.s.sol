// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "solady/utils/UpgradeableBeacon.sol";

contract DeployUpgradeableBeacon is Script {
    function run() external {
        // Load constructor parameters from environment variables
        address initialOwner = vm.envAddress("OWNER");
        address initialImplementation = vm.envAddress("TVS_UPGRADEABLE_IMPLEMENTATION");

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the UpgradeableBeacon contract
        new UpgradeableBeacon(initialOwner, initialImplementation);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}