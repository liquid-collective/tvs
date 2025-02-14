//SPDX-License-Identifier: Proprietary
pragma solidity 0.8.20;

interface IProtocolVersion {
    /// @notice Retrieves the version of the contract
    /// @return Version of the contract
    function version() external pure returns (string memory);
}
