// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

/// @title TVS Interface (v1)
/// @author Alluvial Finance Inc.
/// @notice Interface for the TVS contract.
/// @dev This interface is used to interact with the TVS contract.
/// @dev The TVS contract is the withdrawal credential of a set of validators in the system.
interface ITVS {

    /// @notice Struct to represent a consolidation request.
    struct ConsolidationRequest {
        bytes[] srcPubkeys; 
        bytes targetPubkey; 
    }

    /// --------------------- Events ---------------------

    /// @notice Emitted when funds are swept to the beneficiary.
    /// @param beneficiary The address to which funds were swept.
    /// @param amount The amount of funds swept.
    event Swept(address indexed beneficiary, uint256 indexed amount);

    /// @notice Emitted when the beneficiary address is updated.
    /// @param newBeneficiary The new beneficiary address.
    event BeneficiaryUpdated(address indexed newBeneficiary);

    /// @notice Emitted when an excess fee is sent to a specific address.
    /// @param excessFeeRecipient The address to which the excess fee was sent.
    /// @param excessFee The amount of excess fee sent.
    event UnsentExcessFee(address indexed excessFeeRecipient, uint256 indexed excessFee);

    /// ----------------------- Errors -----------------------

    /// @notice Error thrown when an invalid address is provided for any reason.
    error InvalidAddress();

    /// @notice Error thrown when an unauthorized access attempt is made.
    /// @param caller The address of the caller attempting unauthorized access.
    error Unauthorized(address caller);

    /// @notice Error thrown when an insufficient balance is available for a sweep.
    /// @param available The amount of funds currently available for sweeping.
    /// @param required The amount of funds that were requested to be swept.
    error InsufficientBalance(uint256 available, uint256 required);

    /// @notice Error thrown when a fee exceeds the maximum allowed.
    /// @param currentFee The current fee for the operation.
    /// @param maxAllowedFee The maximum allowed fee that can be paid.
    error FeeTooHigh(uint256 currentFee, uint256 maxAllowedFee);

    /// @notice Error thrown when the length of input arrays does not match.
    /// @param expected The expected length of the input arrays.
    /// @param actual The actual length of the input arrays provided.
    error LengthMismatch(uint256 expected, uint256 actual);

    /// @notice Error thrown when an unauthorized access attempt is made.
    /// @param caller The address of the caller attempting unauthorized access.
    error NotOwner(address caller);

    /// @notice Error thrown when reading the fee fails.
    error FeeReadFailed();

    /// @notice Error thrown when adding a consolidation or withdraw request fails.
    error RequestFailed();

    /// @notice Error thrown when ownership cannot be renounced.
    error OwnershipCannotBeRenounced();

    /// @notice Error thrown when the value provided is insufficient for the fee.
    /// @param value The value provided.
    /// @param totalFee The total fee required.
    error InsufficientvalueForFee(uint256 value, uint256 totalFee);

    /// -------------------------- Core Methods -------------------------

    // Setters

    /// @notice Fallback function to receive funds.
    receive() external payable;

    /// @notice Sweeps a specific amount of funds to a specific address.
    /// @dev Only the owner can specify a custom beneficiary or amount to sweep
    /// @dev Emits {Swept} event.
    /// @param beneficiary Address to which funds will be swept, if zero address, sweeps to the beneficiary address set on the contract
    /// @param amount Amount of funds to sweep, if zero, sweeps all funds on contract
    function sweep(address beneficiary, uint256 amount) external;

    /// @notice Sets a new beneficiary address for fund sweeping.
    /// @dev Only the owner can call this function.
    /// @dev Emits a {BeneficiaryUpdated} event.
    /// @param beneficiary New beneficiary address.
    function setBeneficiary(address beneficiary) external;

    // Getters
    
    /// @notice Retrieves the current beneficiary address.
    /// @return The address of the beneficiary.
    function getBeneficiary() external view returns (address);
    
    /// @notice Retrieves the version of the contract
    /// @return Version of the contract
    function version() external pure returns (string memory);
    
    /// @notice Adds a withdrawal request to CL for a specific TVS.
    /// @dev This is a pectra-compatible function, which allows the owner to withdraw given amount from the specified validator's stake or reward.
    /// @dev Only the owner can call this function.
    /// @dev The excessFeeRecipient can be an EOA or a contract, just ensure it can receive ETH.
    /// @param pubkeys The public keys of the validators to withdraw from.
    /// @param amount The respective amounts to withdraw from each of the validators. Zero amount means full exit
    /// @param maxFeePerWithdrawal The maximum fee allowed per withdrawal.
    function withdraw(bytes[] memory pubkeys, uint64[] calldata amount, uint256 maxFeePerWithdrawal, address excessFeeRecipient) payable external;

    /// @notice Adds a consolidation request to CL for the given source TVS.
    /// @dev This is a pectra-compatible function, which allows the owner to consolidate one or more validators to another.
    /// @dev Only the owner can call this function.
    /// @dev Both source and target validators (pubKeys) must be from the same TVS (this TVS).
    /// @dev The excessFeeRecipient can be an EOA or a contract, just ensure it can receive ETH.
    /// @param requests An array of consolidation requests.
    /// @param maxFeePerConsolidation The maximum fee allowed per consolidation request.
    function consolidate(ConsolidationRequest[] memory requests, uint256 maxFeePerConsolidation, address excessFeeRecipient) payable external;

}