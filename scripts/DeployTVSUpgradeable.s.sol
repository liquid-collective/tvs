// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/TVSUpgradeable/proxies/TVSBeaconProxy.sol";

import { DeployPrepareForAbiInjection } from "scripts/DeployPrepareForAbiInjection.s.sol";

contract DeployTVSUpgradeable is DeployPrepareForAbiInjection {
    function run() external {
        // Load constructor parameters from environment variables
        address beacon;
        if (vm.envExists("UPGRADEABLE_BEACON")) {
            beacon = vm.envAddress("UPGRADEABLE_BEACON");
        } else {
            beacon = vm.getDeployment("UpgradeableBeacon");
        }
        address beneficiary = vm.envAddress("BENEFICIARY");
        address owner = vm.envAddress("OWNER");

        // Encode initialization data
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,address)",
            beneficiary,
            owner,
            beacon
        );

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the TVSBeaconProxy contract
        new TVSBeaconProxy(beacon, initData);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        prepareForAbiInjection();

    }
}