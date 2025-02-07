// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.20;

import "./TVS.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title Immutable TVS (v1)
/// @author Alluvial Finance Inc.
/// @notice Non-upgradeable implementation of the TVS
contract TVSImmutable is TVS, Ownable {
    address private beneficiary; 

    constructor(address _beneficiary, address _owner) Ownable(_owner) {
        if (_beneficiary == address(0) || _owner == address(0)) revert InvalidAddress();

        beneficiary = _beneficiary;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Ownership cannot be renounced");
    }

    /// @inheritdoc ITVS
    function setBeneficiary(address _beneficiary) override external onlyOwner {
        if (_beneficiary == address(0)) revert InvalidAddress();
        beneficiary = _beneficiary;
        emit BeneficiaryUpdated(_beneficiary);
    }

    /// @inheritdoc ITVS
    function getBeneficiary() public view override returns (address) {
        return beneficiary;
    }

    function owner() public view override(Ownable, TVS) returns (address) {
        return Ownable.owner();
    }

} 