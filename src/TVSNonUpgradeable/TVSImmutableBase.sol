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

    constructor(address withdrawalContractAddress, address consolidationContractAddress) {
        if (withdrawalContractAddress == address(0) || consolidationContractAddress == address(0)) {
            revert InvalidAddress();
        }
        WITHDRAWAL_CONTRACT_ADDRESS = withdrawalContractAddress;
        CONSOLIDATION_CONTRACT_ADDRESS = consolidationContractAddress;
    }

    receive() external payable { }

    function sweep(address recipient, uint256 amount) external {
        (address dest, uint256 amountToSweep) = _sweep(recipient, amount);
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

    function _transferTVSOwnership(address _newOwner) internal virtual;

    function _transfer(address _newBeneficiary, address _newOwner) internal {
        _transferTVSOwnership(_newOwner);
        _setBeneficiary(_newBeneficiary);
        emit Transferred(_newBeneficiary, _newOwner);
    }

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

    function _validateFee(uint256 _currentFee, uint256 _maxAllowedFee) internal pure {
        if (_currentFee > _maxAllowedFee) {
            revert FeeTooHigh(_currentFee, _maxAllowedFee);
        }
    }

    function _validateSufficientValueForFee(uint256 _value, uint256 _totalFee) internal pure {
        if (_value < _totalFee) {
            revert InsufficientvalueForFee(_value, _totalFee);
        }
    }

    /// @inheritdoc ITVSImmutable
    function version() external pure returns (string memory) {
        return "v1.0.0 I";
    }
}
