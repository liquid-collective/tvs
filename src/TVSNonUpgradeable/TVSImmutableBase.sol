// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "../interfaces/ITVS.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

/// @title Base for Immutable TVS Contract
/// @author Alluvial Finance Inc.
/// @notice Base contract for TVS Immutable implementations
abstract contract TVSImmutableBase is ITVS {
    address internal beneficiary;

    using Address for address payable;
    using Address for address;

    address public immutable WITHDRAWAL_CONTRACT_ADDRESS;
    address public immutable CONSOLIDATION_CONTRACT_ADDRESS;

    /// @notice Constructs a new TVSImmutableBase contract
    /// @dev Initializes the contract with withdrawal and consolidation contract addresses
    /// @param withdrawalContractAddress The address of the withdrawal contract
    /// @param consolidationContractAddress The address of the consolidation contract
    /// @custom:reverts InvalidAddress If either address is zero
    constructor(address withdrawalContractAddress, address consolidationContractAddress) {
        if (withdrawalContractAddress == address(0) || consolidationContractAddress == address(0)) {
            revert InvalidAddress();
        }
        WITHDRAWAL_CONTRACT_ADDRESS = withdrawalContractAddress;
        CONSOLIDATION_CONTRACT_ADDRESS = consolidationContractAddress;
    }

    /// @inheritdoc ITVS
    receive() external payable { }

    /// @inheritdoc ITVS
    function sweep(address recipient, uint256 amount) external {
        (address dest, uint256 amountToSweep) = _sweep(recipient, amount);
        payable(dest).sendValue(amountToSweep);
    }

    /// @inheritdoc ITVS
    function getBeneficiary() public view returns (address) {
        return beneficiary;
    }

    /// @notice Returns the current owner of the contract
    /// @return The address of the current owner
    function _owner() internal view virtual returns (address);

    /// @notice Sets a new beneficiary address
    /// @dev Reverts if the new beneficiary address is zero
    /// @param _beneficiary The address of the new beneficiary
    /// @custom:reverts InvalidAddress If the new beneficiary address is zero
    function _setBeneficiary(address _beneficiary) internal {
        if (_beneficiary == address(0)) revert InvalidAddress();
        beneficiary = _beneficiary;
        emit BeneficiaryUpdated(_beneficiary);
    }

    /// @notice Transfers ownership of the TVS contract to a new owner
    /// @dev Reverts if the new owner address is zero
    /// @param _newOwner The address of the new owner
    /// @custom:reverts InvalidAddress If the new owner address is zero
    function _transferTVSOwnership(address _newOwner) internal virtual;

    /// @notice Transfers both beneficiary and ownership to new addresses
    /// @dev Reverts if either new address is zero
    /// @param _newBeneficiary The address of the new beneficiary
    /// @param _newOwner The address of the new owner
    /// @custom:reverts InvalidAddress If either new address is zero
    function _transfer(address _newBeneficiary, address _newOwner) internal {
        _transferTVSOwnership(_newOwner);
        _setBeneficiary(_newBeneficiary);
        emit Transferred(_newBeneficiary, _newOwner);
    }

    /// @notice Processes withdrawal requests for multiple validators
    /// @dev Reverts if pubkeys and amounts arrays have different lengths or if fees are insufficient
    /// @param _pubkeys Array of validator public keys
    /// @param _amount Array of withdrawal amounts
    /// @param _maxFeePerWithdrawal Maximum fee allowed per withdrawal
    /// @param _excessFeeRecipient Address to receive any excess fees
    /// @custom:reverts LengthMismatch If pubkeys and amounts arrays have different lengths
    /// @custom:reverts InsufficientValueForFee If sent value is less than required fees
    /// @custom:reverts FeeTooHigh If any fee exceeds maximum allowed
    /// @custom:reverts FeeReadFailed If fee reading fails
    /// @custom:reverts RequestFailed If withdrawal request fails
    function _withdraw(
        bytes[] memory _pubkeys,
        uint64[] calldata _amount,
        uint256 _maxFeePerWithdrawal,
        address _excessFeeRecipient
    )
        internal
    {
        if (_pubkeys.length != _amount.length) {
            revert LengthMismatch(_pubkeys.length, _amount.length);
        }

        // check if the value sent is enough to cover the fees
        uint256 maxFeePayable = _maxFeePerWithdrawal * _pubkeys.length;
        _validateSufficientValueForFee(msg.value, maxFeePayable);

        uint256 totalFeePaid = 0;
        for (uint256 i = 0; i < _pubkeys.length; i++) {
            // Read current fee from the contract
            (bool readOK, bytes memory feeData) = WITHDRAWAL_CONTRACT_ADDRESS.staticcall("");
            if (!readOK) {
                revert FeeReadFailed();
            }
            uint256 fee = uint256(bytes32(feeData));

            // Check if fee exceeds maximum allowed
            _validateFee(fee, _maxFeePerWithdrawal);

            // Add the withdrawal request
            bytes memory callData = abi.encodePacked(_pubkeys[i], _amount[i]);
            (bool writeOK,) = WITHDRAWAL_CONTRACT_ADDRESS.call{ value: fee }(callData);
            if (!writeOK) {
                revert RequestFailed();
            }
            totalFeePaid += fee;
        }

        // Refund any access value back to the excessFeeRecipient
        _refundExcessFee(msg.value, totalFeePaid, _excessFeeRecipient);
    }

    /// @notice Processes consolidation requests for multiple validators
    /// @dev Reverts if fees are insufficient or if any request fails
    /// @param _requests Array of consolidation requests
    /// @param _maxFeePerConsolidation Maximum fee allowed per consolidation
    /// @param _excessFeeRecipient Address to receive any excess fees
    /// @custom:reverts InsufficientValueForFee If sent value is less than required fees
    /// @custom:reverts FeeTooHigh If any fee exceeds maximum allowed
    /// @custom:reverts FeeReadFailed If fee reading fails
    /// @custom:reverts RequestFailed If consolidation request fails
    function _consolidate(
        ConsolidationRequest[] calldata _requests,
        uint256 _maxFeePerConsolidation,
        address _excessFeeRecipient
    )
        internal
    {
        uint256 totalFeePaid = 0;
        for (uint256 i = 0; i < _requests.length; i++) {
            for (uint256 j = 0; j < _requests[i].srcPubkeys.length; j++) {
                // Read current fee from the contract
                (bool readOK, bytes memory feeData) = CONSOLIDATION_CONTRACT_ADDRESS.staticcall("");
                if (!readOK) {
                    revert FeeReadFailed();
                }
                uint256 fee = uint256(bytes32(feeData));

                // Check if fee exceeds maximum allowed
                _validateFee(fee, _maxFeePerConsolidation);

                // Add the consolidation request
                bytes memory callData = bytes.concat(_requests[i].srcPubkeys[j], _requests[i].targetPubkey);
                (bool writeOK,) = CONSOLIDATION_CONTRACT_ADDRESS.call{ value: fee }(callData);
                if (!writeOK) {
                    revert RequestFailed();
                }

                totalFeePaid += fee;
            }
        }

        // Refund any access value back to the excessFeeRecipient
        _refundExcessFee(msg.value, totalFeePaid, _excessFeeRecipient);
    }

    /// @notice Sweeps funds to a specified beneficiary
    /// @dev If beneficiary is zero address, uses default beneficiary. Requires owner for custom beneficiary
    /// @param _beneficiary Address to receive swept funds (zero for default)
    /// @param _amount Amount to sweep (zero for full balance)
    /// @return dest The address that will receive the funds
    /// @return amountToSweep The amount that will be swept
    /// @custom:reverts InsufficientBalance If requested amount exceeds contract balance
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

    /// @notice Asserts that the caller is the current owner of the contract
    /// @dev Reverts if the caller is not the owner
    /// @custom:reverts OwnableUnauthorizedAccount If the caller is not the owner
    function _assertOwner() internal virtual;

    /// @notice Refunds any excess fees to the specified recipient
    /// @dev Emits UnsentExcessFee event if refund fails
    /// @param _totalValueReceived Total value received in the transaction
    /// @param _totalFeePaid Total fees paid for operations
    /// @param _excessFeeRecipient Address to receive excess fees
    function _refundExcessFee(
        uint256 _totalValueReceived,
        uint256 _totalFeePaid,
        address _excessFeeRecipient
    )
        internal
    {
        // send excess value  back to _excessFeeRecipient
        if (_totalValueReceived > _totalFeePaid) {
            (bool success,) = payable(_excessFeeRecipient).call{ value: _totalValueReceived - _totalFeePaid }("");
            if (!success) {
                emit UnsentExcessFee(_excessFeeRecipient, _totalValueReceived - _totalFeePaid);
            }
        }
    }

    /// @notice Validates that a fee does not exceed the maximum allowed
    /// @dev Reverts if the current fee exceeds the maximum allowed
    /// @param _currentFee The current fee to validate
    /// @param _maxAllowedFee The maximum allowed fee
    /// @custom:reverts FeeTooHigh If current fee exceeds maximum allowed
    function _validateFee(uint256 _currentFee, uint256 _maxAllowedFee) internal pure {
        if (_currentFee > _maxAllowedFee) {
            revert FeeTooHigh(_currentFee, _maxAllowedFee);
        }
    }

    /// @notice Validates that the sent value is sufficient to cover the total fee
    /// @dev Reverts if the sent value is less than the total fee
    /// @param _value The value sent in the transaction
    /// @param _totalFee The total fee required
    /// @custom:reverts InsufficientValueForFee If sent value is less than total fee
    function _validateSufficientValueForFee(uint256 _value, uint256 _totalFee) internal pure {
        if (_value < _totalFee) {
            revert InsufficientValueForFee(_value, _totalFee);
        }
    }

    /// @inheritdoc ITVS
    function version() external pure returns (string memory) {
        return "v1.0.0 I";
    }
}
