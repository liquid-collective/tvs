// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.20;

/// @title TVS Interface (v1)
/// @author Alluvial Finance Inc.
/// @notice Interface for the TVS contract.
/// @dev This interface is used to interact with the TVS contract.
/// @dev The TVS contract is the withdrawal credential of a set of validators in the system.
interface ITVS {
    /// --------------------- Events ---------------------

    /// @notice Emitted when funds are swept to the beneficiary.
    /// @param beneficiary The address to which funds were swept.
    /// @param amount The amount of funds swept.
    event Swept(address indexed beneficiary, uint256 indexed amount);

    /// @notice Emitted when the beneficiary address is updated.
    /// @param newBeneficiary The new beneficiary address.
    event BeneficiaryUpdated(address indexed newBeneficiary);

    /// ----------------------- Errors -----------------------

    /// @notice Error thrown when an invalid address is provided for any reason.
    error InvalidAddress();

    /// @notice Error thrown when an unauthorized access attempt is made.
    /// @param caller The address of the caller attempting unauthorized access.
    error Unauthorized(address caller);

    /// -------------------------- Core Methods -------------------------

    // Setters

    /// @notice Fallback function to receive funds.
    receive() external payable;

    /// @notice Sweeps a specific amount of funds to a specific address.
    /// @dev Only the owner can specify a custom beneficiary or amount to sweep
    /// @dev Emits {Swept} event.
    /// @param beneficiary Address to which funds will be swept, if zero address, sweeps to the beneficiary address set on the contract
    /// @param _amount Amount of funds to sweep, if zero, sweeps all funds on contract
    function sweep(address beneficiary, uint256 _amount) external;

    /// @notice Adds a withdrawal request to CL for a specific TVS.
    /// @dev Only the owner can call this function.
    /// @param pubkeys The public keys of the validators to withdraw from.
    /// @param amount The respective amounts to withdraw from each of the validators. Zero amount means full exit
    function withdrawFrom(bytes[] memory pubkeys, uint64[] calldata amount) external;

    /// @notice Adds a consolidation request to CL for the given source TVS.
    /// @dev Only the owner can call this function.
    /// @dev Both source and target TVS must belong to this TVS.
    /// @param srcPubkeys The public keys of the source validators making the request.
    /// @param targetPubkeys The public keys of the target validators to consolidate to.
    function consolidate(bytes[] memory srcPubkeys, bytes[] memory targetPubkeys) external;

    /// @notice Sets a new beneficiary address for fund sweeping.
    /// @dev Only the owner can call this function.
    /// @dev Emits a {BeneficiaryUpdated} event.
    /// @param beneficiary New beneficiary address.
    function setBeneficiary(address beneficiary) external;

    // Getters

    /// @notice Retrieves the owner of the TVS.
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @notice Retrieves the current beneficiary address.
    /// @return The address of the beneficiary.
    function getBeneficiary() external view returns (address);
}
