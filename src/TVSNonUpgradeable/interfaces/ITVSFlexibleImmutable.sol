// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

/**
 * @title ITVSFlexibleImmutable Interface
 * @author Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation
 * @notice Interface for the TVSFlexibleImmutable contract
 * @dev This interface is used to interact with the TVSFlexibleImmutable contract
 * @dev The TVSFlexibleImmutable contract is a flexible immutable implementation of the TVS contract
 */
interface ITVSFlexibleImmutable {
    /**
     * @notice Struct to hold call data for the arbitrary executeCall function
     * @dev The Call struct is used to hold the data required to perform a low-level call or delegatecall.
     * @param to The target address for the call.
     * @param isDelegateCall Boolean flag to indicate whether to perform a delegatecall (true) or a call (false).
     * @param value The amount of ETH (in wei) to transfer. Pass 0 for non-payable calls.
     * @param data The calldata to pass to the target address.
     */
    struct Call {
        address to;
        bool isDelegateCall;
        uint256 value;
        bytes data;
    }

    /**
     * @notice Executes a low-level call or delegatecall to the specified address.
     * @dev Bubbles up revert reasons and handles both ETH transfers and data calls.
     * @param call The Call struct containing the target address, value, data, and call type.
     * @return The return data from the call.
     */
    function executeCall(Call calldata call) external payable returns (bytes memory);

    /**
     * @notice Executes a batch of low-level calls or delegatecalls.
     * NOTE:
     *  - when msg.value is passed, only one delegatecall should be made
     *  - when msg.value is passed, any delegatecall to non-payable functions will fail
     * @dev Reverts on the first call that fails.
     * @param calls An array of Call structs containing the target address, value, data, and call type.
     */
    function executeBatch(Call[] calldata calls) external payable;
}
