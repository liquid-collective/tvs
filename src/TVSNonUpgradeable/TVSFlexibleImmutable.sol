// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./TVSImmutable.sol";
import "./interfaces/ITVSFlexibleImmutable.sol";

/**
 * @title Flexible Immutable TVS (v1)
 * @author Alluvial Finance Inc.
 * @notice Non-upgradeable implementation of the TVS with arbitrary executeCall function
 * @dev This contract implements all the functionality of the TVSImmutable contract and adds an additional executeCall
 * function
 *      that allows for arbitrary calls to be made to, and from the contract by the owner only. This provides the
 * flexibility to
 *      capture, and interact with future functionalities that cannot be added to the TVSImmutable contract.
 */
contract TVSFlexibleImmutable is ITVSFlexibleImmutable, TVSImmutable {
    /**
     * @notice Constructor for the TVSFlexibleImmutable contract
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
        TVSImmutable(beneficiary, owner, withdrawalContractAddress, consolidationContractAddress)
    { }

    /// @inheritdoc ITVSFlexibleImmutable
    function executeCall(Call calldata call) external payable onlyOwner returns (bytes memory) {
        return _executeCall(call);
    }

    /// @inheritdoc ITVSFlexibleImmutable
    function executeBatch(Call[] calldata calls) external payable virtual onlyOwner {
        uint256 callsLength = calls.length;
        for (uint256 i = 0; i < callsLength; i++) {
            Call calldata call = calls[i];
            _executeCall(call);
        }
    }

    /**
     * @notice Internal function to execute an arbitrary call
     * @dev This function is used to execute an arbitrary call from the TVS contract by the owner only.
     * @dev The call is executed using the functionDelegateCall or functionCallWithValue function depending on the
     * isDelegateCall flag.
     * @param call The call to execute
     * @return returnData The return data from the call
     */
    function _executeCall(Call calldata call) internal returns (bytes memory returnData) {
        if (call.isDelegateCall) {
            return Address.functionDelegateCall(call.to, call.data);
        } else {
            return Address.functionCallWithValue(call.to, call.data, call.value);
        }
    }
}
