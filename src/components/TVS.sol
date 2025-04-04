// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "../state/Beneficiary.sol";
import "../interfaces/ITVSSweepBeneficiary.sol";
import "../components/BaseSecurity.sol";
import "../interfaces/ITVS.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol";

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

    /**
     * @notice Internal function to transfer the TVS to a new beneficiary and owner.
     * @dev This function is used to transfer the TVS to a new beneficiary and owner.
     * @param newBeneficiary The address of the new beneficiary.
     * @param newOwner The address of the new owner.
     */
    function _transfer(address newBeneficiary, address newOwner) internal {
        _setBeneficiary(newBeneficiary);
        transferOwnership(newOwner);
        emit Transferred(newBeneficiary, newOwner);
    }

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
            (bool writeOK,) = WITHDRAWAL_CONTRACT_ADDRESS.call{ value: fee }(callData);
            if (!writeOK) {
                revert RequestFailed();
            }
            totalFeePaid += fee;
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
                (bool writeOK,) = CONSOLIDATION_CONTRACT_ADDRESS.call{ value: fee }(callData);
                if (!writeOK) {
                    revert RequestFailed();
                }

                totalFeePaid += fee;
            }
        }

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
     * @dev Internal function to set the beneficiary.
     * @param _newBeneficiary The address of the new beneficiary.
     */
    function _setBeneficiary(address _newBeneficiary) internal {
        if (_newBeneficiary == address(0)) revert InvalidAddress();
        Beneficiary.set(_newBeneficiary);
        emit BeneficiaryUpdated(_newBeneficiary);
    }

    /**
     * @dev Internal function to sweep the TVS.
     * @param _beneficiary The address of the beneficiary.
     * @param _amount The amount to sweep.
     * @return dest The address of the destination.
     * @return amountToSweep The amount to sweep.
     */
    function _sweep(address _beneficiary, uint256 _amount) private returns (address dest, uint256 amountToSweep) {
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

    /**
     * @dev Modifier to assert caller is the owner of the contract
     */
    function _assertOwner() internal view {
        if (msg.sender != owner()) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
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
        // send excess value  back to _excessFeeRecipient
        if (_totalValueReceived > _totalFeePaid) {
            (bool success,) = payable(_excessFeeRecipient).call{ value: _totalValueReceived - _totalFeePaid }("");
            if (!success) {
                emit UnsentExcessFee(_excessFeeRecipient, _totalValueReceived - _totalFeePaid);
            }
        }
    }

    /**
     * @dev Internal function to validate the fee for pectra related operations.
     * @param _currentFee The current fee.
     * @param _maxAllowedFee The maximum allowed fee.
     */
    function _validateFee(uint256 _currentFee, uint256 _maxAllowedFee) internal pure {
        if (_currentFee > _maxAllowedFee) {
            revert FeeTooHigh(_currentFee, _maxAllowedFee);
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
}
