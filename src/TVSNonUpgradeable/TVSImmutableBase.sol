// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "../TVS.sol";

/// @title Base for Immutable TVS Contract
/// @author Alluvial Finance Inc.
/// @notice Base contract for TVS Immutable implementations
abstract contract TVSImmutableBase is TVS {
    address internal beneficiary; 

    /**
     * @dev Emitted when the ownership is transferred to a new owner.
     * @param newBeneficiary The address of the new beneficiary.
     * @param newOwner The address of the new owner.
     */
    event Transferred(address indexed newBeneficiary, address indexed newOwner);


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

    /// @notice Transfers the ownership of the TVS.
    /// @dev This function sets a new beneficiary, transfers ownership to a new owner.
    /// @param newBeneficiary The new beneficiary address.
    /// @param newOwner The new owner address.
    function transfer(address newBeneficiary, address newOwner) external _onlyOwner {
        _transferTVSOwnership(newOwner);
        _setBeneficiary(newBeneficiary);
        emit Transferred(newBeneficiary, newOwner);
    }

    function _transferTVSOwnership(address newOwner) internal virtual;
}