// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/TVSUpgradeable/TVSUpgradeable.sol";

contract DeployTVSUpgradeableImplementation is Script {
    function run() public {
        // Load constructor parameters from environment variables
        address withdrawalContract = vm.envAddress("WITHDRAWAL_CONTRACT");
        address consolidationContract = vm.envAddress("CONSOLIDATION_CONTRACT");
        address immutableBeaconFactory = vm.envAddress("IMMUTABLE_BEACON_FACTORY");

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the TVSUpgradeable contract
        new TVSUpgradeable(
            withdrawalContract,
            consolidationContract,
            immutableBeaconFactory
        );

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}