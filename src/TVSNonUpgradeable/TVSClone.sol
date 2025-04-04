// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./TVSImmutableBase.sol";

/**
 * @title TVS Clone Implementation (v1)
 * @author Alluvial Finance Inc.
 * @notice Non-upgradeable implementation of the TVS with initializer
 * @dev The TVSClone contract is designed with the idea of providing an immutable version that is compatible with
 *      EIP-1167 clone proxy, offering users a way to minimize gas costs during deployment.
 * @dev Even though this contract follows the pattern of a proxy implementation contract. It is a non-upgradeable
 * implementation of the TVS contract,
 *      expected to be used only with the clone proxy pattern which is non-upgradeable.
 */
contract TVSClone is TVSImmutableBase {
    // @inheritdoc TVSImmutableBase
    constructor(
        address withdrawalContractAddress,
        address consolidationContractAddress
    )
        TVSImmutableBase(withdrawalContractAddress, consolidationContractAddress)
    { }

    /**
     * @notice Initializes the TVS clone with beneficiary and owner addresses
     * @dev This function can only be called once and sets up the contract security controls and beneficiary.
     * {_setupSecurity} is called to set the owner and other security controls.
     * @param beneficiary The default address that will receive all ETH swept from the TVS contract
     * @param owner The address that will have ownership rights over the TVS
     */
    function initialize(address beneficiary, address owner) external initializer {
        _setupSecurity(owner);
        _setBeneficiary(beneficiary);
    }
}
