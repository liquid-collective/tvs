// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.34;

/**
 * @title Sweep Beneficiary Interface
 * @author Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation
 * @notice Interface for the TVS beneficiary contract to receive ETH from the TVS.
 * @dev This interface is used to receive ETH from the TVS contract.
 * @dev This interface should be implemented by a beneficiary contract if the contract is unable to receive direct ETH
 * transfers
 * @dev The TVS contract is the withdrawal credential of a set of validators in the system.
 */
interface ITVSSweepBeneficiary {
    /**
     * @notice Allows a contract to receive ETH from TVS via the `sweepToContract` function.
     * @dev This function MUST be implemented by the TVS beneficiary contract, in order to use the `sweepToContract`
     * function of the TVS.
     */
    function receiveETHFromTVS() external payable;
}
