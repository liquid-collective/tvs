// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import "./state/proxy/Beacon.sol";
import "./interfaces/ITVSUpgradeable.sol";
import "./interfaces/IImmutableBeaconFactory.sol";
import "../components/TVS.sol";
import "openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol";

/**
 * @title Upgradeable TVS (v1)
 * @author Alluvial Finance Inc.
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
    address public immutable immutableBeacon;

    /**
     * @notice Constructs a new TVSUpgradeable instance
     * @dev Initializes the contract with Pectra withdrawal and consolidation EL contract addresses, and the immutable
     *      beacon factory address.
     * @dev The withdrawal and consolidation addresses are stored as immutable state variables. they can only be set
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
        immutableBeacon = IImmutableBeaconFactory(immutableBeaconFactory).deployBeacon(address(this));
    }

    /**
     * @notice Initializes the TVS upgradeable instance
     * @dev This function can only be called once during the TVS deployment and sets up the initial security, owner,
     *      beneficiary, and beacon address of the TVS
     * @param beneficiary The address that will receive all ETH swept from the TVS
     * @param owner The address that will have ownership rights over the TVS
     * @param beacon The address of the beacon contract
     */
    function initialize(address beneficiary, address owner, address beacon) external initializer {
        if (beneficiary == address(0) || owner == address(0) || beacon == address(0)) revert InvalidAddress();

        _setupSecurity(owner);
        Beneficiary.set(beneficiary);
        Beacon.set(beacon);
    }

    /// @inheritdoc ITVS
    function transfer(address newBeneficiary, address newOwner) external override onlyOwner {
        _setBeacon(immutableBeacon);
        _transfer(newBeneficiary, newOwner);
    }

    /**
     * @notice This function is used by the {setBeacon} function to directly set the beacon address without
     *         additional checks
     * @dev This function should not be called directly, but only through the {setBeacon} function, it allows the
     *      {setBeacon} perform robust checks before setting the new beacon
     * @dev Emits a {BeaconUpdated} event
     * @dev Only callable by the contract owner
     * @param newBeacon The new beacon address
     */
    function setBeaconUnchecked(address newBeacon) external onlyOwner {
        Beacon.set(newBeacon);
        emit BeaconUpgraded(newBeacon);
    }

    /// @inheritdoc ITVSUpgradeable
    function setBeacon(address newBeacon) external onlyOwner {
        _setBeacon(newBeacon);
    }

    /// @inheritdoc ITVSUpgradeable
    function beacon() external view returns (address) {
        return Beacon.get();
    }

    /// @inheritdoc ITVS
    function version() external pure returns (string memory) {
        return "v1.0.0 U";
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
