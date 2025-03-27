// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./TVSImmutable.sol";

/// @title Flexible Immutable TVS (v1)
/// @author Alluvial Finance Inc.
/// @notice Non-upgradeable implementation of the TVS with arbitrary executeCall function
contract TVSFlexibleImmutable is TVSImmutable {

    /// @notice Struct to hold call data for executeCall function
    /// @dev The Call struct is used to hold the data required to perform a low-level call or delegatecall.
    /// @param to The target address for the operation.
    /// @param data The calldata to pass to the target contract.
    /// @param value The amount of ETH (in wei) to transfer. Pass 0 for non-payable calls.
    /// @param isDelegateCall Boolean flag to indicate whether to perform a delegatecall (true) or a call (false).
    struct Call {
        address to;
        uint256 value;
        bytes data;
        bool isDelegateCall;
    }

    constructor(address newBeneficiary, address newOwner, address withdrawalContractAddress, address consolidationContractAddress) 
    TVSImmutable(newBeneficiary, newOwner, withdrawalContractAddress, consolidationContractAddress) {
        _setBeneficiary(newBeneficiary);
    }


    /// @notice Executes a low-level call or delegatecall to the specified address.
    /// @dev Bubbles up revert reasons and handles both ETH transfers and data calls.
    /// @param call The Call struct containing the target address, value, data, and call type.
    function executeCall(
        Call calldata call
    ) payable external onlyOwner returns (bytes memory) {
        return _executeCall(call);
    }

    /// @notice Executes a batch of low-level calls or delegatecalls.
    /// @dev revert on the first call that fails.
    /// @param calls An array of Call structs containing the target address, value, data, and call type.
    function executeBatch(Call[] calldata calls) virtual external payable onlyOwner{
        uint256 callsLength = calls.length;
        for (uint256 i = 0; i < callsLength; i++) {
            Call calldata call = calls[i];
            _executeCall(call);
        }
    }

    function _executeCall(Call calldata call) internal returns (bytes memory returnData) {
        if (call.isDelegateCall) {
            return Address.functionDelegateCall(call.to, call.data);
        } else {
            return Address.functionCallWithValue(call.to, call.data, call.value);
        }
    }
}