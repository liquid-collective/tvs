// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./state/tvs/Beneficiary.sol";
import "./state/proxy/Beacon.sol";
import "../TVS.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

/// @title Upgradeable TVS (v1)
/// @author Alluvial Finance Inc.
/// @notice Upgradeable implementation of the TVS
contract TVSUpgradeable is TVS, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address payable;
    using Address for address;

    /// @notice Emitted when the beacon address is updated.
    /// @param oldBeacon The old beacon address.
    /// @param newBeacon The new beacon address.
    event BeaconUpdated(address indexed oldBeacon, address indexed newBeacon);

    /// @notice Emitted when the ownership is transferred to a new owner.
    /// @param newBeneficiary The address of the new beneficiary.
    /// @param newOwner The address of the new owner.
    /// @param newBeacon The address of the new beacon.
    event Transferred(address indexed newBeneficiary, address indexed newOwner, address indexed newBeacon);

    function initialize(address _destination, address _owner, address _beacon) external initializer {
        if (_destination == address(0) || _owner == address(0) || _beacon == address(0)) revert InvalidAddress();

        __Ownable_init(_owner); 
        __ReentrancyGuard_init();
        Beneficiary.set(_destination);
        Beacon.set(_beacon);
    }

    function setBeacon(address _beacon) external _onlyOwner {
        _setBeacon(_beacon);
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

    /// @inheritdoc ITVS
    function getBeneficiary() public view override returns (address) {
        return Beneficiary.get();
    }

    /// @notice Transfers the ownership of the TVS.
    /// @dev This function sets a new beneficiary, transfers ownership to a new owner, and sets a new beacon.
    /// @param newBeneficiary The new beneficiary address.
    /// @param newOwner The new owner address.
    /// @param newBeacon The new beacon address.
    function transfer(address newBeneficiary, address newOwner, address newBeacon) external _onlyOwner {
        _setBeacon(newBeacon);
        _transfer(newBeneficiary, newOwner);
        emit Transferred(newBeneficiary, newOwner, newBeacon);
    }

    /// @inheritdoc ITVS
    function withdraw(bytes[] memory pubkeys, uint64[] calldata amount, uint256 maxFeePerWithdrawal, address excessFeeRecipient) payable external nonReentrant _onlyOwner {
        _withdraw(pubkeys, amount, maxFeePerWithdrawal, excessFeeRecipient);
    }

    /// @inheritdoc ITVS
    function consolidate(ConsolidationRequest[] calldata requests, uint256 maxFeePerConsolidation, address excessFeeRecipient) payable external nonReentrant _onlyOwner {
        _consolidate(requests, maxFeePerConsolidation, excessFeeRecipient);
    }

    function _transferTVSOwnership(address newOwner) internal override {
        _transferOwnership(newOwner);
    }

    function _setBeacon(address _beacon) internal {
        address implementation = IBeacon(_beacon).implementation();
        implementation.functionDelegateCall(abi.encodeWithSignature("unsafeSetBeacon(address)", _beacon));
    }

    function _owner() internal view override returns (address) {
        return OwnableUpgradeable.owner();
    }

    function _setBeneficiary(address _beneficiary) internal override {
        if (_beneficiary == address(0)) revert InvalidAddress();
        Beneficiary.set(_beneficiary);
        emit BeneficiaryUpdated(_beneficiary);
    }

    function version() external pure returns (string memory) {
        return "v1.0.0 U";
    }
}