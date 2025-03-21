// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import "forge-std/Test.sol";


contract TestTVS is Test {

    function testTVS() public {
        assertEq(uint256(1), uint256(1), "ok");
    }

}