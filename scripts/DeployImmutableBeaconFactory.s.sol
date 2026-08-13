// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import "forge-std/Script.sol";
import "../src/TVSUpgradeable/ImmutableBeaconFactory.sol";

import { DeployPrepareForAbiInjection } from "scripts/DeployPrepareForAbiInjection.s.sol";

contract DeployImmutableBeaconFactory is DeployPrepareForAbiInjection {
    function run() external {
        address recentDeployment;

        try vm.getDeployment("ImmutableBeaconFactory") returns (address deployment) {
            recentDeployment = deployment;
        } catch {}

        if (recentDeployment != address(0)) {
            console.log("No need to deploy anything, already deployed at: ", recentDeployment);
            return;
        }


        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the ImmutableBeaconFactory contract
        new ImmutableBeaconFactory();

        // Stop broadcasting transactions
        vm.stopBroadcast();

        prepareForAbiInjection();

    }
}