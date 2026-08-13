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
        } catch { }

        if (recentDeployment != address(0)) {
            console.log("No need to deploy anything, already deployed at: ", recentDeployment);
            prepareForAbiInjection();
            return;
        }

        address cloneImplementation;
        if (vm.envExists("TVS_CLONE_IMPLEMENTATION")) {
            cloneImplementation = vm.envAddress("TVS_CLONE_IMPLEMENTATION");
            if (cloneImplementation == address(0)) {
                cloneImplementation = vm.getDeployment("TVSClone");
            }
        } else {
            cloneImplementation = vm.getDeployment("TVSClone");
        }

        address upgradeableTVSImplementation;
        if (vm.envExists("TVS_UPGRADEABLE_IMPLEMENTATION")) {
            upgradeableTVSImplementation = vm.envAddress("TVS_UPGRADEABLE_IMPLEMENTATION");
            if (upgradeableTVSImplementation == address(0)) {
                upgradeableTVSImplementation = vm.getDeployment("TVSUpgradeable");
            }
        } else {
            upgradeableTVSImplementation = vm.getDeployment("TVSUpgradeable");
        }

        if (cloneImplementation == address(0)) {
            revert(
                "DeployTVSDeployer: TVSClone implementation is zero; set TVS_CLONE_IMPLEMENTATION or record TVSClone deployment"
            );
        }
        if (upgradeableTVSImplementation == address(0)) {
            revert(
                "DeployTVSDeployer: TVSUpgradeable implementation is zero; set TVS_UPGRADEABLE_IMPLEMENTATION or record TVSUpgradeable deployment"
            );
        }

        vm.startBroadcast();

        new TVSDeployer(cloneImplementation, upgradeableTVSImplementation);

        vm.stopBroadcast();

        prepareForAbiInjection();
    }
}
