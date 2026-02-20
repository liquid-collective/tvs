// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.34;

import "forge-std/Script.sol";
import "../src/TVSUpgradeable/TVSUpgradeable.sol";

import { DeployPrepareForAbiInjection } from "scripts/DeployPrepareForAbiInjection.s.sol";

contract DeployTVSUpgradeableImplementation is DeployPrepareForAbiInjection {
    function run() public {
        address recentDeployment;

        try vm.getDeployment("TVSUpgradeable") returns (address deployment) {
            recentDeployment = deployment;
        } catch {}

        if (recentDeployment != address(0)) {
            console.log("No need to deploy anything, already deployed at: ", recentDeployment);
            return;
        }

        // Load constructor parameters from environment variables
        address withdrawalContract = vm.envAddress("WITHDRAWAL_CONTRACT");
        address consolidationContract = vm.envAddress("CONSOLIDATION_CONTRACT");
        address immutableBeaconFactory;

            if (vm.envExists("IMMUTABLE_BEACON_FACTORY")) {
                immutableBeaconFactory = vm.envAddress("IMMUTABLE_BEACON_FACTORY");
            } else {
                immutableBeaconFactory = vm.getDeployment("ImmutableBeaconFactory");
            }

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

        prepareForAbiInjection();
    }
}