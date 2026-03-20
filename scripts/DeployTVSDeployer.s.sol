// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.34;

import "forge-std/Script.sol";
import "../src/TVSDeployer.sol";

import { DeployPrepareForAbiInjection } from "scripts/DeployPrepareForAbiInjection.s.sol";

contract DeployTVSDeployer is DeployPrepareForAbiInjection {
    function run() public {
        address recentDeployment;

        try vm.getDeployment("TVSDeployer") returns (address deployment) {
            recentDeployment = deployment;
        } catch {}

        if (recentDeployment != address(0)) {
            console.log("No need to deploy anything, already deployed at: ", recentDeployment);
            return;
        }

        address cloneImplementation;
        if (vm.envExists("TVS_CLONE_IMPLEMENTATION")) {
            cloneImplementation = vm.envAddress("TVS_CLONE_IMPLEMENTATION");
        } else {
            cloneImplementation = vm.getDeployment("TVSClone");
        }

        address upgradeableTVSImplementation;
        if (vm.envExists("TVS_UPGRADEABLE_IMPLEMENTATION")) {
            upgradeableTVSImplementation = vm.envAddress("TVS_UPGRADEABLE_IMPLEMENTATION");
        } else {
            upgradeableTVSImplementation = vm.getDeployment("TVSUpgradeable");
        }

        vm.startBroadcast();

        new TVSDeployer(cloneImplementation, upgradeableTVSImplementation);

        vm.stopBroadcast();

        prepareForAbiInjection();
    }
}
