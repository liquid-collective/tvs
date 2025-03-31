// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./TVSImmutableBase.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/// @title Immutable TVS (v1)
/// @author Alluvial Finance Inc.
/// @notice Non-upgradeable implementation of the TVS
contract TVSImmutable is TVSImmutableBase, Ownable, ReentrancyGuard {
    constructor(address _beneficiary, address _owner) Ownable(_owner) ReentrancyGuard() {
        _setBeneficiary(_beneficiary);
    }

    function _owner() internal view override returns (address) {
        return Ownable.owner();
    }

    function renounceOwnership() public view override(Ownable) _onlyOwner {
        revert OwnershipCannotBeRenounced();
    }

    function _transferTVSOwnership(address newOwner) internal override {
        _transferOwnership(newOwner);
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
        _onlyOwner
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
        _onlyOwner
    {
        _consolidate(requests, maxFeePerConsolidation, excessFeeRecipient);
    }
}
