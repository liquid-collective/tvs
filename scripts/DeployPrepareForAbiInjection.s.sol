// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

contract DeployPrepareForAbiInjection is Script{

    function prepareForAbiInjection() internal {
        
        string memory tempFile = string.concat(
            vm.projectRoot(),
            "/broadcast",
            "/temp.json"
        );

        uint timestamp = block.timestamp;//(vm.unixTime() + 500) / 1000;
        console.log(timestamp);

        // Format them into a JSON string
        string memory jsonData = string.concat(
            '{"chainID": "',
            vm.toString(block.chainid),
            '"}'
        );  

        vm.writeJson(jsonData, tempFile);

    }
}