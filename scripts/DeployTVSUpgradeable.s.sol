// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/TVSUpgradeable/proxies/TVSBeaconProxy.sol";

contract DeployTVSUpgradeable is Script {
    function run() external {
        // Load constructor parameters from environment variables
        address beacon = vm.envAddress("UPGRADEABLE_BEACON");
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
    }
}