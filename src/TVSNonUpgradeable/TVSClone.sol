// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./TVSImmutableBase.sol";
import "./interfaces/ITVSImmutable.sol";
import "../shared/interfaces/ISweepToContract.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

/// @title TVS Clone Implementation (v1)
/// @author Alluvial Finance Inc.
/// @notice Non-upgradeable implementation of the TVS with initializer
/// @dev The TVSClone contract is designed with the idea of providing an immutable version that is compatible with EIP-1167 clone proxy, offering users a way to minimize gas costs during deployment.
contract TVSClone is ITVSImmutable, TVSImmutableBase, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    constructor(address _withdrawalContractAddress, address _consolidationContractAddress)  TVSImmutableBase(_withdrawalContractAddress, _consolidationContractAddress) {}
    
    function initialize(address _beneficiary, address _owner) external initializer {
        __Ownable_init(_owner); 
        _setBeneficiary(_beneficiary);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }
    
    function renounceOwnership() public view override(OwnableUpgradeable) onlyOwner() {
        revert OwnershipCannotBeRenounced();
    }

    /// @inheritdoc ITVSImmutable
    function sweepToContract(address _beneficiary, uint256 _amount) external override nonReentrant {
        (address dest, uint256 amountToSweep) = _sweep(_beneficiary, _amount);
        ISweepToContract(dest).receiveETHFromTVS{value: amountToSweep}();
    }

    /// @inheritdoc ITVSImmutable
    function transfer(address newBeneficiary, address newOwner) external onlyOwner() {
        _transfer(newBeneficiary, newOwner);
    }

    /// @inheritdoc ITVSImmutable
    function setBeneficiary(address _beneficiary) external onlyOwner() {
        _setBeneficiary(_beneficiary);
    }

    /// @inheritdoc ITVSImmutable
    function withdrawFrom(bytes[] memory pubkeys, uint64[] calldata amount, uint256 maxFeePerWithdrawal, address excessFeeRecipient) payable external nonReentrant onlyOwner {
        _withdrawFrom(pubkeys, amount, maxFeePerWithdrawal, excessFeeRecipient);
    }

    /// @inheritdoc ITVSImmutable
    function consolidate(ConsolidationRequest[] calldata requests, uint256 maxFeePerConsolidation, address excessFeeRecipient) payable external nonReentrant onlyOwner {
        _consolidate(requests, maxFeePerConsolidation, excessFeeRecipient);
    }

    function _owner() internal view override returns (address) {
        return OwnableUpgradeable.owner();
    }

    function _transferTVSOwnership(address newOwner) internal override {
        _transferOwnership(newOwner);
    }

    /// @dev Internal function to assert caller is the owner
    function _assertOwner() internal override view {
        if (msg.sender != _owner()) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
    }
}