// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.20;

import "./TVSImmutableBase.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

/// @title SudoMutable TVS (v1)
/// @author Alluvial Finance Inc.
/// @notice Non-upgradeable implementation of the TVS with initializer
/// @dev The TVSSudoMutable contract is designed with the idea of providing an Immutable version that is compatible with EIP-1167 proxy, offering users a way to minimize gas costs during deployment.
contract TVSSudoMutable is TVSImmutableBase, Initializable, OwnableUpgradeable {

    function initialize(address _beneficiary, address _owner) external initializer {
        __Ownable_init(_owner); 
        _setBeneficiary(_beneficiary);
    }

    function owner() public view override(OwnableUpgradeable, TVS) returns (address) {
        return OwnableUpgradeable.owner();
    }

    function renounceOwnership() public view override(OwnableUpgradeable) _onlyOwner {
        revert OwnershipCannotBeRenounced();
    }
} 