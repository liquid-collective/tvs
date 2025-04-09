// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/TVSNonUpgradeable/TVSClone.sol";

contract DeployTVSCloneImplementation is Script {
    function run() public {
        // Load constructor parameters from environment variables
        address withdrawalContract = vm.envAddress("WITHDRAWAL_CONTRACT");
        address consolidationContract = vm.envAddress("CONSOLIDATION_CONTRACT");

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the TVSClone contract
        new TVSClone(
            withdrawalContract,
            consolidationContract
        );

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}