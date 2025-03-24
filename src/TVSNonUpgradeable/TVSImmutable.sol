// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./TVSImmutableBase.sol";
import "./interfaces/ITVSImmutable.sol";
import "../shared/interfaces/ISweepToContract.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/// @title Immutable TVS (v1)
/// @author Alluvial Finance Inc.
/// @notice Non-upgradeable implementation of the TVS
contract TVSImmutable is ITVSImmutable, TVSImmutableBase, Ownable, ReentrancyGuard {

    constructor(address _beneficiary, address _owner) Ownable(_owner) ReentrancyGuard() {
        _setBeneficiary(_beneficiary);
    }

    function renounceOwnership() public view override(Ownable) _onlyOwner {
        revert OwnershipCannotBeRenounced();
    }

    /// @inheritdoc ITVSImmutable
    function sweepToContract(address _beneficiary, uint256 _amount) external override nonReentrant {
        (address dest, uint256 amountToSweep) = _sweep(_beneficiary, _amount);
        ISweepToContract(dest).receiveETHFromTVS{value: amountToSweep}();
    }

    /// @inheritdoc ITVSImmutable
    function withdrawFrom(bytes[] memory pubkeys, uint64[] calldata amount, uint256 maxFeePerWithdrawal, address excessFeeRecipient) payable external nonReentrant _onlyOwner {
        _withdrawFrom(pubkeys, amount, maxFeePerWithdrawal, excessFeeRecipient);
    }

    /// @inheritdoc ITVSImmutable
    function consolidate(ConsolidationRequest[] calldata requests, uint256 maxFeePerConsolidation, address excessFeeRecipient) payable external nonReentrant _onlyOwner {
        _consolidate(requests, maxFeePerConsolidation, excessFeeRecipient);
    }

    function _owner() internal view override returns (address) {
        return Ownable.owner();
    }

    function _transferTVSOwnership(address newOwner) internal override {
        _transferOwnership(newOwner);
    }
}