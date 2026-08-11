// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.34;

import "forge-std/Script.sol";

contract DeployPrepareForAbiInjection is Script {
    /// @dev Writes the chain ID to a temporary file consumed by the `abi` Makefile target, which injects the
    ///      deployed contract's ABI into the matching broadcast file.
    function prepareForAbiInjection() internal {
        string memory tempFile = string.concat(vm.projectRoot(), "/broadcast", "/temp.json");

        // Format the chain ID into a JSON string
        string memory jsonData = string.concat('{"chainID": "', vm.toString(block.chainid), '"}');

        vm.writeJson(jsonData, tempFile);
    }
}
