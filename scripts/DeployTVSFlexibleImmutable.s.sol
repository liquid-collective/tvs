// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import "forge-std/Script.sol";
import "../src/TVSNonUpgradeable/TVSFlexibleImmutable.sol";

import { DeployPrepareForAbiInjection } from "scripts/DeployPrepareForAbiInjection.s.sol";

contract DeployTVSFlexibleImmutable is DeployPrepareForAbiInjection {
    function run() public {
        // Load constructor parameters from environment variables
        address beneficiary = vm.envAddress("BENEFICIARY");
        address owner = vm.envAddress("OWNER");
        address withdrawalContract = vm.envAddress("WITHDRAWAL_CONTRACT");
        address consolidationContract = vm.envAddress("CONSOLIDATION_CONTRACT");

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the TVSFlexibleImmutable contract
        new TVSFlexibleImmutable(beneficiary, owner, withdrawalContract, consolidationContract);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        prepareForAbiInjection();
    }
}
