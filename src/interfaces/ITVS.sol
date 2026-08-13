// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

/**
 * @title TVS Interface
 * @author Originally authored by Galaxy Blockchain Infrastructure LLC; contributed to The Liquid Foundation
 * @notice Interface for the TVS contract.
 * @dev This interface is used to interact with the TVS contract.
 * @dev The TVS contract is the withdrawal credential of a set of validators in the system.
 */
interface ITVS {
    /**
     * @notice Struct to represent a consolidation request.
     * @param srcPubkeys The public keys of the validators to consolidate from.
     * @param targetPubkey The public key of the validator to consolidate to.
     */
    struct ConsolidationRequest {
        bytes[] srcPubkeys;
        bytes targetPubkey;
    }

    /**
     * @notice Emitted when funds are swept to the beneficiary.
     * @param beneficiary The address to which funds were swept.
     * @param amount The amount of funds swept.
     */
    event Swept(address indexed beneficiary, uint256 indexed amount);

    /**
     * @notice Emitted when the beneficiary address is updated.
     * @param newBeneficiary The new beneficiary address.
     */
    event BeneficiaryUpdated(address indexed newBeneficiary);

    /**
     * @notice Emitted when the excess fee sent as part of a {consolidate} or {withdraw} (partial or full) request
     * could not be refunded to the excess fee recipient.
     * @param excessFeeRecipient The address to which the excess fee should have been sent.
     * @param excessFee The amount of excess fee that could not be refunded.
     */
    event UnsentExcessFee(address indexed excessFeeRecipient, uint256 indexed excessFee);

    /**
     * @notice Emitted when the ownership of the TVS is transferred to a new owner.
     * @param newBeneficiary The address of the new beneficiary.
     * @param newOwner The address of the new owner.
     */
    event Transferred(address indexed newBeneficiary, address indexed newOwner);

    /**
     * @notice Emitted when a withdrawal request is submitted for a validator.
     * @param pubkey The public key of the validator.
     * @param amount The amount to withdraw from the validator.
     * @param fee The fee paid for the withdrawal.
     */
    event WithdrawalRequested(bytes pubkey, uint64 indexed amount, uint256 indexed fee);

    /**
     * @notice Emitted when a consolidation request is submitted.
     * @param srcPubkey The public key of the source validator.
     * @param targetPubkey The public key of the target validator.
     * @param fee The fee paid for the consolidation.
     */
    event ConsolidationRequested(bytes srcPubkey, bytes targetPubkey, uint256 indexed fee);

    /**
     * @notice Error thrown when an invalid address is provided for any reason.
     */
    error InvalidAddress();

    /**
     * @notice Error thrown when an unauthorized access attempt is made.
     * @param caller The address of the caller attempting unauthorized access.
     */
    error Unauthorized(address caller);

    /**
     * @notice Error thrown when an attempt to sweep more funds than available is made.
     * @param available The amount of funds currently available for sweeping.
     * @param required The amount of funds that were requested to be swept.
     */
    error InsufficientBalance(uint256 available, uint256 required);

    /**
     * @notice Error thrown when a fee exceeds the maximum allowed.
     * @dev This error is associated with the {consolidate} and {withdraw} functions.
     * @param currentFee The current fee for the operation.
     * @param maxAllowedFee The maximum allowed fee that can be paid.
     */
    error FeeTooHigh(uint256 currentFee, uint256 maxAllowedFee);

    /**
     * @notice Error thrown when the length of input arrays does not match.
     * @param expected The expected length of the input arrays.
     * @param actual The actual length of the input arrays provided.
     */
    error LengthMismatch(uint256 expected, uint256 actual);

    /**
     * @notice Error thrown when an empty input array is provided.
     * @dev This error is associated with the {consolidate} and {withdraw} functions, which require at least one
     * operation to perform. An empty input would otherwise be a no-op that emits no operation events.
     */
    error InvalidEmptyArray();

    /**
     * @notice Error thrown when reading the fee fails.
     * @dev This error is associated with the {consolidate} and {withdraw} functions, which read the fee from the
     * associated Pectra EL contracts.
     */
    error FeeReadFailed();

    /**
     * @notice Error thrown when adding a consolidation or withdrawal request fails.
     */
    error RequestFailed();

    /**
     * @notice Error thrown when the value provided is insufficient for the fee.
     * @dev This error is associated with the {consolidate} and {withdraw} functions, which interact with the
     * associated Pectra EL contracts.
     * @param value The value provided.
     * @param totalFee The total fee required.
     */
    error InsufficientValueForFee(uint256 value, uint256 totalFee);

    /**
     * @notice Error thrown when a TVS transfer couldn't be completed.
     */
    error TransferFailed();

    /**
     * @notice Error thrown when the length of a pubkey is invalid.
     * @param length The length of the pubkey.
     */
    error InvalidPubkeyLength(uint256 length);

    /**
     * @notice Receive function to accept ETH transfers.
     */
    receive() external payable;

    /**
     * @notice Sweeps a specific amount, or all ETH on the TVS to the TVS beneficiary or a specified address.
     * @dev Only the owner can specify a custom beneficiary for the sweep.
     * @dev Emits a {Swept} event.
     * @param beneficiary Address to which funds will be swept. If zero address, sweeps to the beneficiary address set
     * on the contract.
     * @param amount Amount of funds to sweep. If zero, sweeps all funds on the contract.
     */
    function sweep(address beneficiary, uint256 amount) external;

    /**
     * @notice Sweeps a specific amount, or all ETH on the TVS to the TVS beneficiary contract or a specified
     * beneficiary contract address.
     * @dev Only the owner can specify a custom beneficiary for the sweep.
     * @dev Emits a {Swept} event.
     * @param beneficiary Address of the contract to which funds will be swept. If zero address, sweeps to the
     * beneficiary address set on the contract.
     * @param amount Amount of funds to sweep. If zero, sweeps all funds on the contract.
     */
    function sweepToBeneficiaryContract(address beneficiary, uint256 amount) external;

    /**
     * @notice Sets a new beneficiary address for fund sweeping.
     * @dev Only the owner can call this function.
     * @dev Emits a {BeneficiaryUpdated} event.
     * @param beneficiary New beneficiary address.
     */
    function setBeneficiary(address beneficiary) external;

    /**
     * @notice Transfers the ownership of the TVS.
     * @dev This function sets a new beneficiary, transfers ownership to a new owner.
     * @dev Only the owner can call this function.
     * @dev Emits a {Transferred} event.
     * @param newBeneficiary The new beneficiary address.
     * @param newOwner The new owner address.
     */
    function transfer(address newBeneficiary, address newOwner) external;

    /**
     * @notice Adds a withdrawal request to the Pectra EL withdrawal contract for the specified validators.
     * @dev Only the owner can call this function.
     * @dev Reverts with {InvalidEmptyArray} if `pubkeys` is empty.
     * @dev Emits an {UnsentExcessFee} event if the excess fee is not sent.
     * @param pubkeys The public keys of the validators to withdraw from.
     * @param amounts The amount in gwei to withdraw from each validator, in the same order as `pubkeys`. Zero
     * indicates a full withdrawal (validator exit).
     * @param maxFeePerWithdrawal The maximum fee allowed per withdrawal.
     * @param excessFeeRecipient The address to which excess fees will be sent.
     */
    function withdraw(
        bytes[] calldata pubkeys,
        uint64[] calldata amounts,
        uint256 maxFeePerWithdrawal,
        address excessFeeRecipient
    )
        external
        payable;

    /**
     * @notice Adds a consolidation request to the Pectra EL consolidation contract for the given source validators.
     * @dev Only the owner can call this function.
     * @dev Both source and target validators (pubkeys) must be from the same TVS (this TVS).
     * @dev Reverts with {InvalidEmptyArray} if `requests` is empty, or if any request has no source pubkeys or an
     * empty target pubkey.
     * @dev The excess fee is the difference between the maximum fee and the actual fee paid.
     * @dev Emits an {UnsentExcessFee} event if the excess fee is not sent.
     * @param requests An array of consolidation requests.
     * @param maxFeePerConsolidation The maximum fee allowed per consolidation request.
     * @param excessFeeRecipient The address to which excess fees will be sent.
     */
    function consolidate(
        ConsolidationRequest[] calldata requests,
        uint256 maxFeePerConsolidation,
        address excessFeeRecipient
    )
        external
        payable;

    // Getters

    /**
     * @notice Retrieves the current beneficiary address.
     * @return The address of the beneficiary.
     */
    function getBeneficiary() external view returns (address);

    /**
     * @notice Retrieves the version of the contract.
     * @return The version of the contract.
     */
    function version() external pure returns (string memory);
}
