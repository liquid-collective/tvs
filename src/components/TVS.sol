// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import "../state/Beneficiary.sol";
import "../interfaces/ITVSSweepBeneficiary.sol";
import "../components/BaseSecurity.sol";
import "../interfaces/ITVS.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

/**
 * @title Transferable Validator Set (TVS - v1)
 * @author Alluvial Finance Inc.
 * @notice implementation of the TVS
 */
abstract contract TVS is ITVS, BaseSecurity {
    using Address for address payable;
    using Address for address;

    /**
     * @notice The address of the pectra EL withdrawal contract.
     */
    address public immutable WITHDRAWAL_CONTRACT_ADDRESS;

    /**
     * @notice The address of the pectra EL consolidation contract.
     */
    address public immutable CONSOLIDATION_CONTRACT_ADDRESS;

    /**
     * @notice Constructor for the TVS contract
     * @dev Initializes the contract with Pectra withdrawal and consolidation EL contract addresses.
     * @dev The withdrawal and consolidation addresses are stored as immutable state variables. they can only be set
     * once here in the constructor.
     * @dev All implementation versions of TVS **MUST** have this constructor, to ensure the correct addresses are set,
     * and available to the proxy
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
        bytes[] memory pubkeys,
        uint64[] calldata amount,
        uint256 maxFeePerWithdrawal,
        address excessFeeRecipient
    )
        external
        payable
        nonReentrant
        onlyOwner
    {
        if (pubkeys.length != amount.length) {
            revert LengthMismatch(pubkeys.length, amount.length);
        }

        // check if the value sent is enough to cover the fees
        uint256 maxFeePayable = maxFeePerWithdrawal * pubkeys.length;
        _validateSufficientValueForFee(msg.value, maxFeePayable);

        // Check if fee exceeds maximum allowed, otherwise get fee
        uint256 fee = _validateAndReturnFee(WITHDRAWAL_CONTRACT_ADDRESS, maxFeePerWithdrawal);

        uint256 totalFeePaid = 0;
        for (uint256 i = 0; i < pubkeys.length; i++) {
            // Add the withdrawal request
            bytes memory callData = abi.encodePacked(pubkeys[i], amount[i]);
            (bool writeOK,) = WITHDRAWAL_CONTRACT_ADDRESS.call{ value: fee }(callData);
            if (!writeOK) {
                revert RequestFailed();
            }
            totalFeePaid += fee;

            // Emit withdrawal event for each validator
            emit WithdrawalRequested(pubkeys[i], amount[i], fee);
        }

        // Refund any access value back to the excessFeeRecipient
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
        // Check if fee exceeds maximum allowed, otherwise get fee
        uint256 fee = _validateAndReturnFee(CONSOLIDATION_CONTRACT_ADDRESS, maxFeePerConsolidation);

        uint256 totalFeePaid = 0;
        for (uint256 i = 0; i < requests.length; i++) {
            for (uint256 j = 0; j < requests[i].srcPubkeys.length; j++) {
                // Add the consolidation request
                bytes memory callData = bytes.concat(requests[i].srcPubkeys[j], requests[i].targetPubkey);
                (bool writeOK,) = CONSOLIDATION_CONTRACT_ADDRESS.call{ value: fee }(callData);
                if (!writeOK) {
                    revert RequestFailed();
                }

                totalFeePaid += fee;

                // Emit consolidation event for each operation
                emit ConsolidationRequested(requests[i].srcPubkeys[j], requests[i].targetPubkey, fee);
            }
        }

        // Ensure only msg.value is used
        _validateSufficientValueForFee(msg.value, totalFeePaid);

        // Refund any access value back to the excessFeeRecipient
        _refundExcessFee(msg.value, totalFeePaid, excessFeeRecipient);
    }

    /// @inheritdoc ITVS
    function sweep(address recipient, uint256 amount) external {
        (address dest, uint256 amountToSweep) = _sweep(recipient, amount);
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
     * @dev This function is used to transfer the TVS to a new beneficiary and owner.
     * @param _beneficiary The address of the new beneficiary.
     * @param _owner The address of the new owner.
     */
    function _transfer(address _beneficiary, address _owner) internal {
        _setBeneficiary(_beneficiary);
        transferOwnership(_owner);
        emit Transferred(_beneficiary, _owner);
    }

    /**
     * @notice Internal function to set the beneficiary address.
     * @param _newBeneficiary The address of the new beneficiary.
     */
    function _setBeneficiary(address _newBeneficiary) internal {
        if (_newBeneficiary == address(0)) revert InvalidAddress();
        Beneficiary.set(_newBeneficiary);
        emit BeneficiaryUpdated(_newBeneficiary);
    }
    /**
     * @dev Internal function to refund the excess fee for pectra related operations.
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
        // send excess value back to _excessFeeRecipient
        if (_totalValueReceived > _totalFeePaid) {
            (bool success,) = payable(_excessFeeRecipient).call{ value: _totalValueReceived - _totalFeePaid }("");
            if (!success) {
                emit UnsentExcessFee(_excessFeeRecipient, _totalValueReceived - _totalFeePaid);
            }
        }
    }

    /**
     * @dev Internal function to validate the fee. Used for pectra related operations.
     * @param _maxAllowedFee The maximum allowed fee.
     * @return _fee The fee.
     * @dev Reverts if the fee is higher than the maximum allowed fee, or if the fee read fails.
     */
    function _validateAndReturnFee(address feeContract, uint256 _maxAllowedFee) internal view returns (uint256 _fee) {
        // Read current fee from the contract
        (bool readOK, bytes memory feeData) = feeContract.staticcall("");
        if (!readOK) {
            revert FeeReadFailed();
        }
        _fee = uint256(bytes32(feeData));

        if (_fee > _maxAllowedFee) {
            revert FeeTooHigh(_fee, _maxAllowedFee);
        }
    }

    /**
     * @dev Internal function to validate the caller sent sufficient value for fee. Used for pectra related operations.
     * @param _value The value.
     * @param _totalFee The total fee.
     */
    function _validateSufficientValueForFee(uint256 _value, uint256 _totalFee) internal pure {
        if (_value < _totalFee) {
            revert InsufficientValueForFee(_value, _totalFee);
        }
    }

    /**
     * @dev Internal function to sweep the TVS.
     * @param _beneficiary The address of the beneficiary.
     * @param _amount The amount to sweep.
     * @return _dest The address of the _destination.
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
