// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import "../components/TVS.sol";

/**
 * @title Base for all Immutable TVS Contract
 * @author Alluvial Finance Inc.
 * @notice Base contract for TVS Immutable implementations
 * @dev This contract provides the base functionality for immutable TVS implementations
 */
abstract contract TVSImmutableBase is TVS {
    /**
     * @notice Constructor for the TVS Immutable contract
     * @dev Initializes the contract with Pectra withdrawal and consolidation EL contract addresses.
     * @dev The withdrawal and consolidation addresses are stored as immutable state variables. they can only be set
     * once here in the constructor.
     * @param withdrawalContractAddress The address of the withdrawal contract
     * @param consolidationContractAddress The address of the consolidation contract
     */
    constructor(
        address withdrawalContractAddress,
        address consolidationContractAddress
    )
        TVS(withdrawalContractAddress, consolidationContractAddress)
    { }

    /// @inheritdoc ITVS
    function transfer(address newBeneficiary, address newOwner) external onlyOwner nonReentrant {
        _transfer(newBeneficiary, newOwner);
    }

    /// @inheritdoc ITVS
    function version() external pure returns (string memory) {
        return "1.0.1 I";
    }
}
