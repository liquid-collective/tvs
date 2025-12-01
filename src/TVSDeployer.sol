// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import { TVSClone } from "./TVSNonUpgradeable/TVSClone.sol";
import { TVSImmutable } from "./TVSNonUpgradeable/TVSImmutable.sol";
import { TVSFlexibleImmutable } from "./TVSNonUpgradeable/TVSFlexibleImmutable.sol";
import { TVSBeaconProxy } from "./TVSUpgradeable/proxies/TVSBeaconProxy.sol";

/**
 * @title TVS Deployer
 * @notice Permissionless deployer for all TVS variants
 */
contract TVSDeployer {
    event TVSCloneDeployed(address indexed tvs, address indexed implementation, address indexed owner);
    event TVSImmutableDeployed(address indexed tvs, address indexed owner);
    event TVSFlexibleImmutableDeployed(address indexed tvs, address indexed owner);
    event TVSUpgradeableDeployed(address indexed tvs, address indexed beacon, address indexed owner);

    /**
     * @notice The address of the TVSClone implementation contract
     */
    address public immutable cloneImplementation;

    /**
     * @notice Constructor for the TVSDeployer contract
     * @param _cloneImplementation The address of the TVSClone implementation contract
     */
    constructor(address _cloneImplementation) {
        if (_cloneImplementation == address(0)) revert("Invalid implementation");
        cloneImplementation = _cloneImplementation;
    }

    /**
     * @notice Deploys a new TVSClone proxy and initializes it
     * @param beneficiary The address that will receive all ETH swept from the TVS
     * @param owner The address that will have ownership rights over the TVS
     * @return tvs The address of the deployed TVS proxy
     */
    function deployClone(
        address beneficiary,
        address owner
    ) external returns (address tvs) {
        tvs = Clones.clone(cloneImplementation);
        TVSClone(payable(tvs)).initialize(beneficiary, owner);
        emit TVSCloneDeployed(tvs, cloneImplementation, owner);
    }

    /**
     * @notice Deploys a new TVSImmutable contract
     * @param beneficiary The address that will receive all ETH swept from the TVS
     * @param owner The address that will have ownership rights over the TVS
     * @param withdrawalContractAddress The address of the withdrawal contract
     * @param consolidationContractAddress The address of the consolidation contract
     * @return tvs The address of the deployed TVS contract
     */
    function deployImmutable(
        address beneficiary,
        address owner,
        address withdrawalContractAddress,
        address consolidationContractAddress
    ) external returns (address tvs) {
        tvs = address(new TVSImmutable(
            beneficiary,
            owner,
            withdrawalContractAddress,
            consolidationContractAddress
        ));
        emit TVSImmutableDeployed(tvs, owner);
    }

    /**
     * @notice Deploys a new TVSFlexibleImmutable contract
     * @param beneficiary The address that will receive all ETH swept from the TVS
     * @param owner The address that will have ownership rights over the TVS
     * @param withdrawalContractAddress The address of the withdrawal contract
     * @param consolidationContractAddress The address of the consolidation contract
     * @return tvs The address of the deployed TVS contract
     */
    function deployFlexibleImmutable(
        address beneficiary,
        address owner,
        address withdrawalContractAddress,
        address consolidationContractAddress
    ) external returns (address tvs) {
        tvs = address(new TVSFlexibleImmutable(
            beneficiary,
            owner,
            withdrawalContractAddress,
            consolidationContractAddress
        ));
        emit TVSFlexibleImmutableDeployed(tvs, owner);
    }

    /**
     * @notice Deploys a new TVSUpgradeable (Beacon Proxy) and initializes it
     * @param beacon The address of the UpgradeableBeacon contract
     * @param beneficiary The address that will receive all ETH swept from the TVS
     * @param owner The address that will have ownership rights over the TVS
     * @return tvs The address of the deployed TVS proxy
     */
    function deployUpgradeable(
        address beacon,
        address beneficiary,
        address owner
    ) external returns (address tvs) {
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,address)",
            beneficiary,
            owner,
            beacon
        );
        tvs = address(new TVSBeaconProxy(beacon, initData));
        emit TVSUpgradeableDeployed(tvs, beacon, owner);
    }
}
