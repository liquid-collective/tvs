// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.34;

import "forge-std/Script.sol";
import "../src/TVSNonUpgradeable/TVSImmutable.sol";

import { DeployPrepareForAbiInjection } from "scripts/DeployPrepareForAbiInjection.s.sol";

contract DeployTVSImmutable is DeployPrepareForAbiInjection {
    function run() public {
        // Load constructor parameters from environment variables
        address beneficiary = vm.envAddress("BENEFICIARY");
        address owner = vm.envAddress("OWNER");
        address withdrawalContract = vm.envAddress("WITHDRAWAL_CONTRACT");
        address consolidationContract = vm.envAddress("CONSOLIDATION_CONTRACT");

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the TVSImmutable contract
        new TVSImmutable(
            beneficiary,
            owner,
            withdrawalContract,
            consolidationContract
        );

        // Stop broadcasting transactions
        vm.stopBroadcast();

        prepareForAbiInjection();
    }
}