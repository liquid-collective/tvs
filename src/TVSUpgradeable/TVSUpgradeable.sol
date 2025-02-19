// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.20;

import "./state/tvs/Beneficiary.sol";
import "./state/proxy/Beacon.sol";
import "../TVS.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol";

/// @title Upgradeable TVS (v1)
/// @author Alluvial Finance Inc.
/// @notice Upgradeable implementation of the TVS
contract TVSUpgradeable is TVS, Initializable, OwnableUpgradeable {
    using Address for address payable;
    using Address for address;

    /// @notice Emitted when the beacon address is updated.
    /// @param oldBeacon The old beacon address.
    /// @param newBeacon The new beacon address.
    event BeaconUpdated(address indexed oldBeacon, address indexed newBeacon);

    function initialize(address _destination, address _owner, address _beacon) external initializer {
        if (_destination == address(0) || _owner == address(0) || _beacon == address(0)) revert InvalidAddress();

        __Ownable_init(_owner); 
        Beneficiary.set(_destination);
        Beacon.set(_beacon);
    }

    function setBeacon(address _beacon) external _onlyOwner {
        address implementation = IBeacon(_beacon).implementation();
        implementation.functionDelegateCall(abi.encodeWithSignature("unsafeSetBeacon(address)", _beacon));
    }

    function unsafeSetBeacon(address _beacon) external _onlyOwner {
        address oldBeacon = Beacon.get();
        Beacon.set(_beacon);
        emit BeaconUpdated(oldBeacon, _beacon);
    }

    function beacon() external view returns (address) {
        return Beacon.get();
    }

    function renounceOwnership() public view override _onlyOwner {
        revert OwnershipCannotBeRenounced();
    }

    function setBeneficiary(address _beneficiary) external override _onlyOwner {
        if (_beneficiary == address(0)) revert InvalidAddress();
        Beneficiary.set(_beneficiary);
        emit BeneficiaryUpdated(_beneficiary);
    }

    /// @inheritdoc ITVS
    function getBeneficiary() public view override returns (address) {
        return Beneficiary.get();
    }

    function owner() public view override(OwnableUpgradeable, TVS) returns (address) {
        return OwnableUpgradeable.owner();
    }

    function version() external pure returns (string memory) {
        return "v1.0.0 U";
    }
} 