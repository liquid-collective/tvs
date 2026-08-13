// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import "../state/Beneficiary.sol";
import "../interfaces/ITVSSweepBeneficiary.sol";
import "../components/BaseSecurity.sol";
import "../interfaces/ITVS.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

/**
 * @title Transferable Validator Set (TVS - v1)
 * @author Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation
 * @notice Implementation of the TVS
 */
abstract contract TVS is ITVS, BaseSecurity {
    using Address for address payable;
    using Address for address;

    /**
     * @notice The address of the Pectra EL withdrawal contract.
     */
    address public immutable WITHDRAWAL_CONTRACT_ADDRESS;

    /**
     * @notice The address of the Pectra EL consolidation contract.
     */
    address public immutable CONSOLIDATION_CONTRACT_ADDRESS;

    /**
     * @notice Constructor for the TVS contract
     * @dev Initializes the contract with the Pectra withdrawal and consolidation EL contract addresses
     * @dev The withdrawal and consolidation addresses are stored as immutable state variables. They can only be set
     *      once here in the constructor
     * @dev All implementation versions of TVS **MUST** have this constructor, to ensure the correct addresses are set
     * @param withdrawalContractAddress The address of the withdrawal contract
     * @param consolidationContractAddress The address of the consolidation contract
     */
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
    function withdraw(
        bytes[] calldata pubkeys,
        uint64[] calldata amounts,
        uint256 maxFeePerWithdrawal,
        address excessFeeRecipient
    )
        external
        payable
        nonReentrant
        onlyOwner
    {
        if (pubkeys.length == 0) {
            revert InvalidEmptyArray();
        }

        if (pubkeys.length != amounts.length) {
            revert LengthMismatch(pubkeys.length, amounts.length);
        }

        // Check if the value sent is enough to cover the fees
        uint256 maxFeePayable = maxFeePerWithdrawal * pubkeys.length;
        _validateSufficientValueForFee(msg.value, maxFeePayable);

        // Check if fee exceeds maximum allowed, otherwise get fee
        uint256 fee = _validateAndReturnFee(WITHDRAWAL_CONTRACT_ADDRESS, maxFeePerWithdrawal);

        uint256 totalFeePaid = 0;
        for (uint256 i = 0; i < pubkeys.length; i++) {
            _validatePubkeyLength(pubkeys[i]);
            // Add the withdrawal request
            bytes memory callData = abi.encodePacked(pubkeys[i], amounts[i]);
            (bool writeOK,) = WITHDRAWAL_CONTRACT_ADDRESS.call{ value: fee }(callData);
            if (!writeOK) {
                revert RequestFailed();
            }
            totalFeePaid += fee;

            // Emit withdrawal event for each validator
            emit WithdrawalRequested(pubkeys[i], amounts[i], fee);
        }

        // Refund any excess value back to the excessFeeRecipient
        _refundExcessFee(msg.value, totalFeePaid, excessFeeRecipient);
    }

    /// @inheritdoc ITVS
    function consolidate(
        ConsolidationRequest[] calldata requests,
        uint256 maxFeePerConsolidation,
        address excessFeeRecipient
    )
        external
        payable
        nonReentrant
        onlyOwner
    {
        if (requests.length == 0) {
            revert InvalidEmptyArray();
        }

        // Check if fee exceeds maximum allowed, otherwise get fee
        uint256 fee = _validateAndReturnFee(CONSOLIDATION_CONTRACT_ADDRESS, maxFeePerConsolidation);

        // Calculate total number of consolidation operations
        uint256 totalNumOfConsolidationOperations = 0;
        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].srcPubkeys.length == 0) {
                revert InvalidEmptyArray();
            }
            totalNumOfConsolidationOperations += requests[i].srcPubkeys.length;
        }

        // Check if the msg.value is enough to cover the fees
        uint256 totalFeeRequired = fee * totalNumOfConsolidationOperations;
        _validateSufficientValueForFee(msg.value, totalFeeRequired);

        // Perform the consolidation requests
        for (uint256 i = 0; i < requests.length; i++) {
            _validatePubkeyLength(requests[i].targetPubkey);

            for (uint256 j = 0; j < requests[i].srcPubkeys.length; j++) {
                _validatePubkeyLength(requests[i].srcPubkeys[j]);

                // Add the consolidation request
                bytes memory callData = bytes.concat(requests[i].srcPubkeys[j], requests[i].targetPubkey);
                (bool writeOK,) = CONSOLIDATION_CONTRACT_ADDRESS.call{ value: fee }(callData);
                if (!writeOK) {
                    revert RequestFailed();
                }
                // Emit consolidation event for each operation
                emit ConsolidationRequested(requests[i].srcPubkeys[j], requests[i].targetPubkey, fee);
            }
        }

        // Refund any excess value back to the excessFeeRecipient
        _refundExcessFee(msg.value, totalFeeRequired, excessFeeRecipient);
    }

    /// @inheritdoc ITVS
    function sweep(address beneficiary, uint256 amount) external nonReentrant {
        (address dest, uint256 amountToSweep) = _sweep(beneficiary, amount);
        payable(dest).sendValue(amountToSweep);
    }

    /// @inheritdoc ITVS
    function sweepToBeneficiaryContract(address beneficiary, uint256 amount) external nonReentrant {
        (address dest, uint256 amountToSweep) = _sweep(beneficiary, amount);
        ITVSSweepBeneficiary(dest).receiveETHFromTVS{ value: amountToSweep }();
    }

    /// @inheritdoc ITVS
    function setBeneficiary(address newBeneficiary) external onlyOwner {
        _setBeneficiary(newBeneficiary);
    }

    /// @inheritdoc ITVS
    function getBeneficiary() public view returns (address) {
        return Beneficiary.get();
    }

    /**
     * @notice Internal function to transfer the TVS to a new beneficiary and owner.
     * @dev Emits a {Transferred} event.
     * @param _beneficiary The address of the new beneficiary.
     * @param _owner The address of the new owner.
     */
    function _transfer(address _beneficiary, address _owner) internal {
        if (_owner == address(0)) revert InvalidAddress();
        _setBeneficiary(_beneficiary);
        _transferOwnership(_owner);
        emit Transferred(_beneficiary, _owner);
    }

    /**
     * @notice Internal function to set the beneficiary address.
     * @dev Emits a {BeneficiaryUpdated} event.
     * @param _newBeneficiary The address of the new beneficiary.
     */
    function _setBeneficiary(address _newBeneficiary) internal {
        if (_newBeneficiary == address(0)) revert InvalidAddress();
        Beneficiary.set(_newBeneficiary);
        emit BeneficiaryUpdated(_newBeneficiary);
    }

    /**
     * @notice Internal function to refund the excess fee for Pectra-related operations.
     * @dev Emits an {UnsentExcessFee} event if the refund could not be sent.
     * @param _totalValueReceived The total value received.
     * @param _totalFeePaid The total fee paid.
     * @param _excessFeeRecipient The address of the excess fee recipient.
     */
    function _refundExcessFee(
        uint256 _totalValueReceived,
        uint256 _totalFeePaid,
        address _excessFeeRecipient
    )
        internal
    {
        if (_excessFeeRecipient == address(0)) revert InvalidAddress();
        // send excess value back to _excessFeeRecipient
        if (_totalValueReceived > _totalFeePaid) {
            (bool success,) = payable(_excessFeeRecipient).call{ value: _totalValueReceived - _totalFeePaid }("");
            if (!success) {
                emit UnsentExcessFee(_excessFeeRecipient, _totalValueReceived - _totalFeePaid);
            }
        }
    }

    /**
     * @notice Internal function to validate the fee. Used for Pectra-related operations.
     * @dev Reverts if the fee is higher than the maximum allowed fee, or if the fee read fails.
     * @param _feeContract The address of the fee contract.
     * @param _maxAllowedFee The maximum allowed fee.
     * @return _fee The fee.
     */
    function _validateAndReturnFee(address _feeContract, uint256 _maxAllowedFee) internal view returns (uint256 _fee) {
        // Read current fee from the contract
        (bool readOK, bytes memory feeData) = _feeContract.staticcall("");
        if (!readOK) {
            revert FeeReadFailed();
        }
        _fee = uint256(bytes32(feeData));

        if (_fee > _maxAllowedFee) {
            revert FeeTooHigh(_fee, _maxAllowedFee);
        }
    }

    /**
     * @notice Internal function to validate the caller sent sufficient value for the fee. Used for Pectra-related
     *         operations.
     * @param _value The value sent by the caller.
     * @param _totalFee The total fee.
     */
    function _validateSufficientValueForFee(uint256 _value, uint256 _totalFee) internal pure {
        if (_value < _totalFee) {
            revert InsufficientValueForFee(_value, _totalFee);
        }
    }

    /**
     * @notice Internal function to validate that a public key is exactly 48 bytes in length.
     * @param _pubkey The public key to validate.
     */
    function _validatePubkeyLength(bytes memory _pubkey) internal pure {
        if (_pubkey.length != 48) {
            revert InvalidPubkeyLength(_pubkey.length);
        }
    }

    /**
     * @notice Internal function to resolve the destination and amount of a sweep.
     * @dev Only the owner can specify a custom beneficiary for the sweep.
     * @dev Emits a {Swept} event.
     * @param _beneficiary The address of the beneficiary.
     * @param _amount The amount to sweep.
     * @return _dest The address of the destination.
     * @return _amountToSweep The amount to sweep.
     */
    function _sweep(address _beneficiary, uint256 _amount) private returns (address _dest, uint256 _amountToSweep) {
        // Only require owner for custom beneficiary
        if (_beneficiary != address(0)) {
            _checkOwner();
        }

        _dest = _beneficiary == address(0) ? getBeneficiary() : _beneficiary;
        _amountToSweep = _amount == 0 ? address(this).balance : _amount;
        if (_amountToSweep > address(this).balance) {
            revert InsufficientBalance(address(this).balance, _amountToSweep);
        }

        emit Swept(_dest, _amountToSweep);
    }
}
