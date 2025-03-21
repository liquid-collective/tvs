// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./TVSImmutableBase.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title Immutable TVS (v1)
/// @author Alluvial Finance Inc.
/// @notice Non-upgradeable implementation of the TVS
contract TVSImmutable is TVSImmutableBase, Ownable {
    constructor(address _beneficiary, address _owner) Ownable(_owner) {
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

}