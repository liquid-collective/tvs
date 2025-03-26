// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "openzeppelin-contracts/contracts/utils/Address.sol";
import "./interfaces/ITVS.sol";

import "./interfaces/ISweepBeneficiary.sol";

/// @title TVS (v1)
/// @author Alluvial Finance Inc.
/// @notice Abstract base contract for TVS implementations
abstract contract TVS is ITVS  {
    using Address for address payable;
    using Address for address;

    address public constant WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;
    address public constant CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

    ///@dev Modifier to restrict functions to the contract owner only.
    modifier _onlyOwner() {
        _assertOwner();
        _;
    }

    /// @inheritdoc ITVS
    receive() external payable {}

    function _owner() internal view virtual returns (address);

    /// @inheritdoc ITVS
    function setBeneficiary(address _beneficiary) external _onlyOwner {
        _setBeneficiary(_beneficiary);
    }

    /// @inheritdoc ITVS
    function getBeneficiary() public view virtual override returns (address);

    /// @inheritdoc ITVS
    function sweep(address _beneficiary, uint256 _amount) external {
        (address dest, uint256 amountToSweep) = _sweep(_beneficiary, _amount);
        payable(dest).sendValue(amountToSweep);
    }

    /// @inheritdoc ITVS
    // TODO: Add reentrancy guard
    function sweepToContract(address _beneficiary, uint256 _amount) external {
        (address dest, uint256 amountToSweep) = _sweep(_beneficiary, _amount);
        ISweepBeneficiary(dest).receiveETHFromTVS{value: amountToSweep}();
    }

    /**
     * @dev Prepares sweep details by determining the destination and amount to sweep
     * Emits a {Swept} event with the destination and amount to sweep
     * Requirements:
     * - If a custom beneficiary is provided, the caller must be the owner
     * - The beneficiary must not be the zero address
     * - The amount to sweep must not exceed the contract balance
     * @param _beneficiary  The address to sweep to. If zero address, the contract beneficiary is used
     * @param _amount The amount to sweep. If zero, the entire balance is swept
     * @return dest The destination address
     * @return amountToSweep The amount to sweep
     */
    function _prepareSweep(address _beneficiary, uint256 _amount) private returns (address dest, uint256 amountToSweep) {

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

    function _transfer(address newBeneficiary, address newOwner) internal {
        _transferTVSOwnership(newOwner);
        _setBeneficiary(newBeneficiary);
    }

    function _withdraw(bytes[] memory pubkeys, uint64[] calldata amount, uint256 maxFeePerWithdrawal, address excessFeeRecipient)  internal   {
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

    function _transferTVSOwnership(address newOwner) internal virtual;

    function _setBeneficiary(address _beneficiary) internal virtual;

    /// @dev Internal function to assert caller is the owner
    function _assertOwner() internal view {
        if (msg.sender != _owner()) {
            revert NotOwner(msg.sender);
        }
    }

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

} 