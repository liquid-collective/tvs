// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./TVSImmutableBase.sol";
import "../interfaces/ITVS.sol";
import "../interfaces/ITVSSweepBeneficiary.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/// @title Immutable TVS (v1)
/// @author Alluvial Finance Inc.
/// @notice Non-upgradeable implementation of the TVS
contract TVSImmutable is TVSImmutableBase, Ownable, ReentrancyGuard {
    /// @notice Constructs a new TVSImmutable contract
    /// @dev Initializes the contract with beneficiary, owner, and contract addresses
    /// @param theBeneficiary The address that will receive swept funds
    /// @param theOwner The address that will have ownership privileges
    /// @param withdrawalContractAddress The address of the withdrawal contract
    /// @param consolidationContractAddress The address of the consolidation contract
    constructor(
        address theBeneficiary,
        address theOwner,
        address withdrawalContractAddress,
        address consolidationContractAddress
    )
        Ownable(theOwner)
        TVSImmutableBase(withdrawalContractAddress, consolidationContractAddress)
        ReentrancyGuard()
    {
        _setBeneficiary(theBeneficiary);
    }

    /// @notice Prevents ownership from being renounced
    /// @dev This is a security measure to ensure the contract always has an owner
    /// @custom:reverts OwnershipCannotBeRenounced Always reverts with this error
    function renounceOwnership() public view override(Ownable) onlyOwner {
        revert OwnershipCannotBeRenounced();
    }

    /// @inheritdoc ITVS
    function sweepToBeneficiaryContract(address beneficiary, uint256 amount) external override nonReentrant {
        (address dest, uint256 amountToSweep) = _sweep(beneficiary, amount);
        ITVSSweepBeneficiary(dest).receiveETHFromTVS{ value: amountToSweep }();
    }

    /// @inheritdoc ITVS
    function transfer(address newBeneficiary, address newOwner) external onlyOwner {
        _transfer(newBeneficiary, newOwner);
    }

    /// @inheritdoc ITVS
    function setBeneficiary(address newBeneficiary) external onlyOwner {
        _setBeneficiary(newBeneficiary);
    }

    /// @inheritdoc ITVS
    function withdraw(
        bytes[] memory pubkeys,
        uint64[] calldata amount,
        uint256 maxFeePerWithdrawal,
        address excessFeeRecipient
    )
        external
        payable
        nonReentrant
        onlyOwner
    {
        _withdraw(pubkeys, amount, maxFeePerWithdrawal, excessFeeRecipient);
    }

    /// @inheritdoc ITVS
    function consolidate(
        ConsolidationRequest[] calldata requests,
        uint256 maxFeePerConsolidation,
        address excessFeeRecipient
    )
        external
        payable
        nonReentrant
        onlyOwner
    {
        _consolidate(requests, maxFeePerConsolidation, excessFeeRecipient);
    }

    /// @notice Returns the current owner of the contract
    /// @return The address of the current owner
    function _owner() internal view override returns (address) {
        return Ownable.owner();
    }

    /// @notice Transfers ownership of the TVS contract to a new owner
    /// @dev Reverts if the new owner address is zero
    /// @param _newOwner The address of the new owner
    /// @custom:reverts InvalidAddress If the new owner address is zero
    function _transferTVSOwnership(address _newOwner) internal override {
        if (_newOwner == address(0)) revert InvalidAddress();
        _transferOwnership(_newOwner);
    }

    /// @notice Asserts that the caller is the current owner of the contract
    /// @dev Reverts if the caller is not the owner
    /// @custom:reverts OwnableUnauthorizedAccount If the caller is not the owner
    function _assertOwner() internal view override {
        if (msg.sender != _owner()) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
    }
}
