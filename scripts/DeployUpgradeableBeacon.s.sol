// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.34;

import "forge-std/Script.sol";

import "solady/utils/UpgradeableBeacon.sol";

import { DeployPrepareForAbiInjection } from "scripts/DeployPrepareForAbiInjection.s.sol";

contract DeployUpgradeableBeacon is DeployPrepareForAbiInjection {
    function run() external {
        
        address recentDeployment;

        try vm.getDeployment("UpgradeableBeacon") returns (address deployment) {
            recentDeployment = deployment;
        } catch {}

        if (recentDeployment != address(0)) {
            console.log("No need to deploy anything, already deployed at: ", recentDeployment);
            return;
        }

        // Load constructor parameters from environment variables
        address initialOwner = vm.envAddress("OWNER");
        address initialImplementation;
        
        if(vm.envExists("TVS_UPGRADEABLE_IMPLEMENTATION")){
            initialImplementation = vm.envAddress("TVS_UPGRADEABLE_IMPLEMENTATION");
        }else{
            initialImplementation = vm.getDeployment("TVSUpgradeable") ;
        }

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the UpgradeableBeacon contract
        new UpgradeableBeacon(initialOwner, initialImplementation);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        prepareForAbiInjection();

    }
}