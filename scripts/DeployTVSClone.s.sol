// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import "forge-std/Script.sol";
import "../src/TVSNonUpgradeable/TVSClone.sol";
import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";

contract DeployTVSClone is Script {
    function run() public {
        // Load constructor parameters from environment variables
        address implementation;
        if (vm.envExists("TVS_CLONE_IMPLEMENTATION")) {
            implementation = vm.envAddress("TVS_CLONE_IMPLEMENTATION");
        } else {
            implementation = vm.getDeployment("TVSClone");
        }
        address beneficiary = vm.envAddress("BENEFICIARY");
        address owner = vm.envAddress("OWNER");

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the TVSClone proxy
        address clone = Clones.clone(implementation);
        TVSClone(payable(clone)).initialize(beneficiary, owner);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
