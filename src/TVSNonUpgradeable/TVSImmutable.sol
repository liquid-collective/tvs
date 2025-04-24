// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import "./TVSImmutableBase.sol";

/**
 * @title Immutable TVS
 * @author Alluvial Finance Inc.
 * @notice Non-upgradeable implementation of the TVS
 * @dev This contract is a non-upgradeable implementation of the TVS contract.
 */
contract TVSImmutable is TVSImmutableBase {
    /**
     * @notice Constructor for the TVS Immutable contract
     * @dev Initializes the contract with all required parameters
     * @dev The withdrawal and consolidation addresses are pectra EL contract addresses, and are stored as immutable
     * state variables.
     *      They can only be set once here in the constructor.
     * @param beneficiary The default address that will receive all ETH swept from the TVS contract
     * @param owner The address that will have ownership rights over the TVS
     * @param withdrawalContractAddress The address of the withdrawal contract
     * @param consolidationContractAddress The address of the consolidation contract
     */
    constructor(
        address beneficiary,
        address owner,
        address withdrawalContractAddress,
        address consolidationContractAddress
    )
        TVSImmutableBase(withdrawalContractAddress, consolidationContractAddress)
    {
        _setupSecurity(owner);
        _setBeneficiary(beneficiary);
    }
}
