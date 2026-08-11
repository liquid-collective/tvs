// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.34;

import "forge-std/Script.sol";
import "../src/TVSNonUpgradeable/TVSClone.sol";

import { DeployPrepareForAbiInjection } from "scripts/DeployPrepareForAbiInjection.s.sol";

contract DeployTVSCloneImplementation is DeployPrepareForAbiInjection {
    function run() public {
        address recentDeployment;

        try vm.getDeployment("TVSClone") returns (address deployment) {
            recentDeployment = deployment;
        } catch { }

        if (recentDeployment != address(0)) {
            console.log("No need to deploy anything, already deployed at: ", recentDeployment);
            return;
        }

        // Load constructor parameters from environment variables
        address withdrawalContract = vm.envAddress("WITHDRAWAL_CONTRACT");
        address consolidationContract = vm.envAddress("CONSOLIDATION_CONTRACT");

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the TVSClone contract
        new TVSClone(withdrawalContract, consolidationContract);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        prepareForAbiInjection();
    }
}
