// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import "./state/proxy/Beacon.sol";
import "./interfaces/ITVSUpgradeable.sol";
import "./interfaces/IImmutableBeaconFactory.sol";
import "../components/TVS.sol";
import "openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol";

/**
 * @title Upgradeable TVS (v1)
 * @author Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation
 * @notice Upgradeable implementation of the TVS
 * @dev This contract provides an upgradeable version of the TVS using a beacon proxy pattern
 */
contract TVSUpgradeable is ITVSUpgradeable, TVS {
    using Address for address;

    /**
     * @notice The address of the immutable beacon contract
     * @dev During a TVS transfer, the beacon is temporarily set to this immutable beacon. This variable ensures that
     *      the current TVS Implementation is frozen, preventing the oldOwner from modifying the TVS Implementation in
     *      the beacon
     */
    address public immutable IMMUTABLE_BEACON;

    /**
     * @notice Constructs a new TVSUpgradeable instance
     * @dev Initializes the contract with Pectra withdrawal and consolidation EL contract addresses, and the immutable
     *      beacon factory address.
     * @dev The withdrawal and consolidation addresses are stored as immutable state variables. They can only be set
     *      once here in the constructor.
     * @param withdrawalContractAddress The address of the withdrawal contract
     * @param consolidationContractAddress The address of the consolidation contract
     * @param immutableBeaconFactory The address of the immutable beacon factory. This is used once in the constructor
     *        to deploy a new immutable beacon contract for the TVS, and this factory address is not persisted on the
     *        TVS contract.
     */
    constructor(
        address withdrawalContractAddress,
        address consolidationContractAddress,
        address immutableBeaconFactory
    )
        TVS(withdrawalContractAddress, consolidationContractAddress)
    {
        IMMUTABLE_BEACON = IImmutableBeaconFactory(immutableBeaconFactory).deployBeacon(address(this));
        _disableInitializers();
    }

    /**
     * @notice Initializes the TVS upgradeable instance
     * @dev This function can only be called once during the TVS deployment and sets up the initial security, owner,
     *      beneficiary, and beacon address of the TVS
     * @dev No {BeneficiaryUpdated} event is emitted during initialization
     * @param beneficiary The address that will receive all ETH swept from the TVS
     * @param owner The address that will have ownership rights over the TVS
     * @param beaconAddress The address of the beacon contract
     */
    function initialize(address beneficiary, address owner, address beaconAddress) external {
        if (beneficiary == address(0) || owner == address(0) || beaconAddress == address(0)) revert InvalidAddress();

        _setupSecurity(owner);
        Beneficiary.set(beneficiary);
        Beacon.set(beaconAddress);
    }

    /// @inheritdoc ITVS
    function transfer(address newBeneficiary, address newOwner) external override onlyOwner nonReentrant {
        _setBeacon(IMMUTABLE_BEACON);
        _transfer(newBeneficiary, newOwner);
    }

    /**
     * @notice This function is used by the {setBeacon} function to directly set the beacon address without
     *         additional checks
     * @dev WARNING: This function should only be invoked via delegatecall from {_setBeacon}. Direct calls bypass
     *      validation. It allows the {setBeacon} function to perform robust checks before setting the new beacon.
     * @dev Emits a {BeaconUpgraded} event
     * @dev Only callable by the contract owner
     * @param newBeacon The new beacon address
     */
    function setBeaconUnchecked(address newBeacon) external onlyOwner {
        Beacon.set(newBeacon);
        emit BeaconUpgraded(newBeacon);
    }

    /// @inheritdoc ITVSUpgradeable
    function setBeacon(address newBeacon) external onlyOwner nonReentrant {
        _setBeacon(newBeacon);
    }

    /// @inheritdoc ITVSUpgradeable
    function beacon() external view returns (address) {
        return Beacon.get();
    }

    /// @inheritdoc ITVS
    function version() external pure returns (string memory) {
        return "1.0.3";
    }

    /**
     * @notice Internal function to set the beacon address
     * @dev This function is used internally to set the beacon address
     * @dev This function uses the functionDelegateCall exposed by the OpenZeppelin Address contract to delegate the
     *      call to the implementation contract, and reverts if the call fails
     * @param _beacon The address of the new beacon contract
     */
    function _setBeacon(address _beacon) internal {
        address implementation = IBeacon(_beacon).implementation();
        implementation.functionDelegateCall(abi.encodeWithSignature("setBeaconUnchecked(address)", _beacon));
    }
}
