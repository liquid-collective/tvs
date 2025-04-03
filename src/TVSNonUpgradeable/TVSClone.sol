// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./TVSImmutableBase.sol";
import "../interfaces/ITVSSweepBeneficiary.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

/// @title TVS Clone Implementation (v1)
/// @author Alluvial Finance Inc.
/// @notice Non-upgradeable implementation of the TVS with initializer
/// @dev The TVSClone contract is designed with the idea of providing an immutable version that is compatible with
/// EIP-1167 clone proxy, offering users a way to minimize gas costs during deployment.
contract TVSClone is TVSImmutableBase, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /// @notice Constructor that sets the withdrawal and consolidation contract addresses
    /// @param withdrawalContractAddress The address of the withdrawal contract
    /// @param consolidationContractAddress The address of the consolidation contract
    constructor(
        address withdrawalContractAddress,
        address consolidationContractAddress
    )
        TVSImmutableBase(withdrawalContractAddress, consolidationContractAddress)
    { }

    /// @notice Initializes the clone with a beneficiary and owner
    /// @dev This function can only be called once per clone
    /// @param beneficiary The address that will receive swept funds
    /// @param owner The address that will have ownership privileges
    function initialize(address beneficiary, address owner) external initializer {
        __Ownable_init(owner);
        _setBeneficiary(beneficiary);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }

    /// @notice Prevents ownership from being renounced
    /// @dev This is a security measure to ensure the contract always has an owner
    /// @custom:reverts OwnershipCannotBeRenounced Always reverts with this error
    function renounceOwnership() public view override(OwnableUpgradeable) onlyOwner {
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
    function setBeneficiary(address beneficiary) external onlyOwner {
        _setBeneficiary(beneficiary);
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
        return OwnableUpgradeable.owner();
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
