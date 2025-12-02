// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import { TVSClone } from "./TVSNonUpgradeable/TVSClone.sol";
import { TVSImmutable } from "./TVSNonUpgradeable/TVSImmutable.sol";
import { TVSFlexibleImmutable } from "./TVSNonUpgradeable/TVSFlexibleImmutable.sol";
import { TVSBeaconProxy } from "./TVSUpgradeable/proxies/TVSBeaconProxy.sol";
import { UpgradeableBeacon } from "solady/utils/UpgradeableBeacon.sol";

/**
 * @title TVS Deployer
 * @notice Permissionless deployer for all TVS variants
 */
contract TVSDeployer {
    /**
     * @notice Error thrown when an invalid implementation is provided
     */
    error InvalidImplementation();
    /**
     * @notice Emitted when a TVSClone contract is deployed
     * @param tvs The address of the deployed TVSClone contract
     * @param implementation The address of the TVSClone implementation contract
     * @param owner The address of the owner of the TVSClone contract
     */
    event TVSCloneDeployed(address indexed tvs, address indexed implementation, address indexed owner);

    /**
     * @notice Emitted when a TVSImmutable contract is deployed
     * @param tvs The address of the deployed TVSImmutable contract
     * @param owner The address of the owner of the TVSImmutable contract
     */
    event TVSImmutableDeployed(address indexed tvs, address indexed owner);

    /**
     * @notice Emitted when a TVSFlexibleImmutable contract is deployed
     * @param tvs The address of the deployed TVSFlexibleImmutable contract
     * @param owner The address of the owner of the TVSFlexibleImmutable contract
     */
    event TVSFlexibleImmutableDeployed(address indexed tvs, address indexed owner);

    /**
     * @notice Emitted when a TVSUpgradeable contract is deployed
     * @param tvs The address of the deployed TVSUpgradeable contract
     * @param beacon The address of the beacon contract
     * @param owner The address of the owner of the TVSUpgradeable contract
     */
    event TVSUpgradeableDeployed(address indexed tvs, address indexed beacon, address indexed owner);

    /**
     * @notice The address of the pectra EL withdrawal contract
     */
    address public constant WITHDRAWAL_CONTRACT_ADDRESS = 0x00000961Ef480Eb55e80D19ad83579A64c007002;

    /**
     * @notice The address of the pectra EL consolidation contract
     */
    address public constant CONSOLIDATION_CONTRACT_ADDRESS = 0x0000BBdDc7CE488642fb579F8B00f3a590007251;

    /**
     * @notice The address of the TVSClone implementation contract
     */
    address public immutable cloneImplementation;

    /**
     * @notice The address of the TVSUpgradeable implementation contract
     */
    address public immutable upgradeableTVSImplementation;

    /**
     * @notice Constructor for the TVSDeployer contract
     * @param _cloneImplementation The address of the TVSClone implementation contract
     * @param _upgradeableTVSImplementation The address of the TVSUpgradeable implementation contract
     */
    constructor(address _cloneImplementation, address _upgradeableTVSImplementation) {
        if (_cloneImplementation == address(0)) revert InvalidImplementation();
        if (_upgradeableTVSImplementation == address(0)) revert InvalidImplementation();
        cloneImplementation = _cloneImplementation;
        upgradeableTVSImplementation = _upgradeableTVSImplementation;
    }

    /**
     * @notice Deploys a new TVSClone proxy and initializes it
     * @param beneficiary The address that will receive all ETH swept from the TVS
     * @param owner The address that will have ownership rights over the TVS
     * @return tvs The address of the deployed TVS proxy
     */
    function deployClone(address beneficiary, address owner) external returns (address tvs) {
        tvs = Clones.clone(cloneImplementation);
        TVSClone(payable(tvs)).initialize(beneficiary, owner);
        emit TVSCloneDeployed(tvs, cloneImplementation, owner);
    }

    /**
     * @notice Deploys a new TVSImmutable contract
     * @param beneficiary The address that will receive all ETH swept from the TVS
     * @param owner The address that will have ownership rights over the TVS
     * @return tvs The address of the deployed TVS contract
     */
    function deployImmutable(address beneficiary, address owner) external returns (address tvs) {
        tvs = address(new TVSImmutable(beneficiary, owner, WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS));
        emit TVSImmutableDeployed(tvs, owner);
    }

    /**
     * @notice Deploys a new TVSFlexibleImmutable contract
     * @param beneficiary The address that will receive all ETH swept from the TVS
     * @param owner The address that will have ownership rights over the TVS
     * @return tvs The address of the deployed TVS contract
     */
    function deployFlexibleImmutable(address beneficiary, address owner) external returns (address tvs) {
        tvs = address(
            new TVSFlexibleImmutable(beneficiary, owner, WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS)
        );
        emit TVSFlexibleImmutableDeployed(tvs, owner);
    }

    /**
     * @notice Deploys a new TVSUpgradeable (Beacon Proxy) and initializes it
     * @param beneficiary The address that will receive all ETH swept from the TVS
     * @param owner The address that will have ownership rights over the TVS
     * @param beacon The address of the UpgradeableBeacon contract. If zero address, a new beacon will be deployed.
     * @return tvs The address of the deployed TVS proxy
     */
    function deployUpgradeable(address beneficiary, address owner, address beacon) external returns (address tvs) {
        // If beacon is zero address, deploy a new UpgradeableBeacon
        if (beacon == address(0)) {
            beacon = address(new UpgradeableBeacon(msg.sender, upgradeableTVSImplementation));
        }

        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", beneficiary, owner, beacon);
        tvs = address(new TVSBeaconProxy(beacon, initData));
        emit TVSUpgradeableDeployed(tvs, beacon, owner);
    }
}
