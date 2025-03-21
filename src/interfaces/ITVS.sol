// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./ITVSBase.sol";

/// @title TVS Interface (v1)
/// @author Alluvial Finance Inc.
/// @notice Interface for the TVS contract.
/// @dev This interface is used to interact with the TVS contract.
/// @dev The TVS contract is the withdrawal credential of a set of validators in the system.
interface ITVS is ITVSBase {
    
    /// @notice Adds a withdrawal request to CL for a specific TVS.
    /// @dev Only the owner can call this function.
    /// @dev The excessFeeRecipient can be an EOA or a contract, just ensure it can receive ETH.
    /// @param pubkeys The public keys of the validators to withdraw from.
    /// @param amount The respective amounts to withdraw from each of the validators. Zero amount means full exit
    /// @param maxFeePerWithdrawal The maximum fee allowed per withdrawal.
    function withdrawFrom(bytes[] memory pubkeys, uint64[] calldata amount, uint256 maxFeePerWithdrawal, address excessFeeRecipient) payable external;

    /// @notice Adds a consolidation request to CL for the given source TVS.
    /// @dev Only the owner can call this function.
    /// @dev Both source and target validators (pubKeys) must be from the same TVS (this TVS).
    /// @dev The excessFeeRecipient can be an EOA or a contract, just ensure it can receive ETH.
    /// @param requests An array of consolidation requests.
    /// @param maxFeePerConsolidation The maximum fee allowed per consolidation request.
    function consolidate(ConsolidationRequest[] memory requests, uint256 maxFeePerConsolidation, address excessFeeRecipient) payable external;

}