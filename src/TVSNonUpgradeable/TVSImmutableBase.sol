// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "../TVS.sol";

/// @title Base for Immutable TVS Contract
/// @author Alluvial Finance Inc.
/// @notice Base contract for TVS Immutable implementations
abstract contract TVSImmutableBase is TVS {
    address internal beneficiary; 

    function getBeneficiary() public override view returns (address) {
        return beneficiary;
    }

    function _setBeneficiary(address _beneficiary) internal override {
        if (_beneficiary == address(0)) revert InvalidAddress();
        beneficiary = _beneficiary;
        emit BeneficiaryUpdated(_beneficiary);
    }

    function version() external pure returns (string memory) {
        return "v1.0.0 I";
    }
}