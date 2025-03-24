// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./interfaces/ITVSImmutable.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

/// @title Base for Immutable TVS Contract
/// @author Alluvial Finance Inc.
/// @notice Base contract for TVS Immutable implementations
abstract contract TVSImmutableBase is ITVSImmutable {
    address internal beneficiary; 
    
    using Address for address payable;
    using Address for address;
    address public immutable WITHDRAWAL_CONTRACT_ADDRESS;
    address public immutable CONSOLIDATION_CONTRACT_ADDRESS;

    constructor(address _withdrawalContractAddress, address _consolidationContractAddress) {
        if (_withdrawalContractAddress == address(0) || _consolidationContractAddress == address(0)) {
            revert InvalidAddress();
        }
        WITHDRAWAL_CONTRACT_ADDRESS = _withdrawalContractAddress;
        CONSOLIDATION_CONTRACT_ADDRESS = _consolidationContractAddress;
    }

    receive() external payable {}

    function sweep(address _beneficiary, uint256 _amount) external {
        (address dest, uint256 amountToSweep) = _sweep(_beneficiary, _amount);
        payable(dest).sendValue(amountToSweep);
    }

    function getBeneficiary() public view returns (address) {
        return beneficiary;
    }

    function _owner() internal view virtual returns (address);

    function _setBeneficiary(address _beneficiary) internal {
        if (_beneficiary == address(0)) revert InvalidAddress();
        beneficiary = _beneficiary;
        emit BeneficiaryUpdated(_beneficiary);
    }

    function _transferTVSOwnership(address newOwner) internal virtual;

    function _transfer(address newBeneficiary, address newOwner) internal {
        _transferTVSOwnership(newOwner);
        _setBeneficiary(newBeneficiary);
        emit Transferred(newBeneficiary, newOwner);
    }

    function _withdrawFrom(bytes[] memory pubkeys, uint64[] calldata amount, uint256 maxFeePerWithdrawal, address excessFeeRecipient)  internal   {
        if (pubkeys.length != amount.length) {
            revert LengthMismatch(pubkeys.length, amount.length);
        }

        // check if the value sent is enough to cover the fees
        uint256 maxFeePayable = maxFeePerWithdrawal * pubkeys.length;
        _validateSufficientValueForFee(msg.value, maxFeePayable);
        
        uint256 totalFeePaid = 0;
        for (uint256 i = 0; i < pubkeys.length; i++) {
            // Read current fee from the contract
            (bool readOK, bytes memory feeData) = WITHDRAWAL_CONTRACT_ADDRESS.staticcall("");
            if (!readOK) {
                revert FeeReadFailed();
            }
            uint256 fee = uint256(bytes32(feeData));
            
            // Check if fee exceeds maximum allowed
            _validateFee(fee, maxFeePerWithdrawal);

            // Add the withdrawal request
            bytes memory callData = abi.encodePacked(pubkeys[i], amount[i]);
            (bool writeOK,) = WITHDRAWAL_CONTRACT_ADDRESS.call{value: fee}(callData);
            if (!writeOK) {
                revert RequestFailed();
            }
            totalFeePaid += fee;
        }

        // Refund any access value back to the excessFeeRecipient
        _refundExcessFee(msg.value, totalFeePaid, excessFeeRecipient);
    }

    function _consolidate(ConsolidationRequest[] calldata requests, uint256 maxFeePerConsolidation, address excessFeeRecipient)  internal  {

        uint256 totalFeePaid = 0;
        for (uint256 i = 0; i < requests.length; i++) {
            for (uint256 j = 0; j < requests[i].srcPubkeys.length; j++) {
                
                // Read current fee from the contract
                (bool readOK, bytes memory feeData) = CONSOLIDATION_CONTRACT_ADDRESS.staticcall("");
                if (!readOK) {
                    revert FeeReadFailed();
                }
                uint256 fee = uint256(bytes32(feeData));   

                // Check if fee exceeds maximum allowed
                _validateFee(fee, maxFeePerConsolidation);

                // Add the consolidation request
                bytes memory callData = bytes.concat(requests[i].srcPubkeys[j], requests[i].targetPubkey);
                (bool writeOK,) = CONSOLIDATION_CONTRACT_ADDRESS.call{value: fee}(callData);
                if (!writeOK) {
                    revert RequestFailed();
                }

                totalFeePaid += fee;
            }
        }

        // Refund any access value back to the excessFeeRecipient
        _refundExcessFee(msg.value, totalFeePaid, excessFeeRecipient);
    }

    function _sweep(address _beneficiary, uint256 _amount) internal returns (address dest, uint256 amountToSweep) {

        // Only require owner for custom beneficiary
        if (_beneficiary != address(0)) {
            _assertOwner();
        }
        
        dest = _beneficiary == address(0) ? getBeneficiary() : _beneficiary;
        amountToSweep = _amount == 0 ? address(this).balance : _amount;
        if (amountToSweep > address(this).balance) {
            revert InsufficientBalance(address(this).balance, amountToSweep);
        }

        emit Swept(dest, amountToSweep);
    }

    /// @dev Internal function to assert caller is the owner
    function _assertOwner() internal virtual;

    function _refundExcessFee(uint256 totalValueReceived, uint256 totalFeePaid, address excessFeeRecipient) internal {
        // send excess value  back to excessFeeRecipient
        if (totalValueReceived > totalFeePaid) {
            (bool success, ) = payable(excessFeeRecipient).call{value: totalValueReceived - totalFeePaid}("");
            if (!success) {
                emit UnsentExcessFee(excessFeeRecipient, totalValueReceived - totalFeePaid);
            }
        }
    }

    function _validateFee(uint256 currentFee, uint256 maxAllowedFee) internal pure {
        if (currentFee > maxAllowedFee) {
            revert FeeTooHigh(currentFee, maxAllowedFee);
        }
    }

    function _validateSufficientValueForFee(uint256 value, uint256 totalFee) internal pure {
        if (value < totalFee) {
            revert InsufficientvalueForFee(value, totalFee);
        }
    }


    /// @inheritdoc ITVSImmutable
    function version() external pure returns (string memory) {
        return "v1.0.0 I";
    }

}