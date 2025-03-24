// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./state/proxy/Beacon.sol";
import "./state/tvs/Beneficiary.sol";
import "./interfaces/ITVSUpgradeable.sol";
import "../shared/interfaces/ISweepToContract.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";


/// @title Upgradeable TVS (v1)
/// @author Alluvial Finance Inc.
/// @notice Upgradeable implementation of the TVS
contract TVSUpgradeable is ITVSUpgradeable, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address payable;
    using Address for address;

    address public constant WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;
    address public constant CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

    receive() external payable {}

    function initialize(address _destination, address _owner, address _beacon) external initializer {
        if (_destination == address(0) || _owner == address(0) || _beacon == address(0)) revert InvalidAddress();

        __Ownable_init(_owner); 
        __ReentrancyGuard_init();
        Beneficiary.set(_destination);
        Beacon.set(_beacon);
    }

    /// @inheritdoc ITVSUpgradeable
    function transfer(address newBeneficiary, address newOwner, address newBeacon) external onlyOwner {
        _setBeacon(newBeacon);
        _transfer(newBeneficiary, newOwner);
        emit Transferred(newBeneficiary, newOwner, newBeacon);
    }

    /// @inheritdoc ITVSUpgradeable
    function withdrawFrom(bytes[] memory pubkeys, uint64[] calldata amount, uint256 maxFeePerWithdrawal, address excessFeeRecipient) payable external nonReentrant onlyOwner {
        _withdrawFrom(pubkeys, amount, maxFeePerWithdrawal, excessFeeRecipient);
    }

    /// @inheritdoc ITVSUpgradeable
    function consolidate(ConsolidationRequest[] calldata requests, uint256 maxFeePerConsolidation, address excessFeeRecipient) payable external nonReentrant onlyOwner {
        _consolidate(requests, maxFeePerConsolidation, excessFeeRecipient);
    }

    function sweep(address _beneficiary, uint256 _amount) external {
        (address dest, uint256 amountToSweep) = _sweep(_beneficiary, _amount);
        payable(dest).sendValue(amountToSweep);
    }

    // TODO: Add reentrancy guard
    function sweepToContract(address _beneficiary, uint256 _amount) external {
        (address dest, uint256 amountToSweep) = _sweep(_beneficiary, _amount);
        ISweepToContract(dest).receiveETHFromTVS{value: amountToSweep}();
    }

    function setBeneficiary(address _beneficiary) external onlyOwner {
        _setBeneficiary(_beneficiary);
    }

    /// @inheritdoc ITVSUpgradeable
    function setBeacon(address _beacon) external onlyOwner {
        _setBeacon(_beacon);
    }

    function unsafeSetBeacon(address _beacon) external onlyOwner {
        address oldBeacon = Beacon.get();
        Beacon.set(_beacon);
        emit BeaconUpdated(oldBeacon, _beacon);   
    }

    function renounceOwnership() public view override onlyOwner {
        revert OwnershipCannotBeRenounced();
    }

    /// @inheritdoc ITVSUpgradeable
    function getBeneficiary() public view returns (address) {
        return Beneficiary.get();
    }

    /// @inheritdoc ITVSUpgradeable
    function beacon() external view returns (address) {
        return Beacon.get();
    }

    function _setBeacon(address _beacon) internal {
        address implementation = IBeacon(_beacon).implementation();
        implementation.functionDelegateCall(abi.encodeWithSignature("unsafeSetBeacon(address)", _beacon));
    }

    function _setBeneficiary(address _beneficiary) internal {
        if (_beneficiary == address(0)) revert InvalidAddress();
        Beneficiary.set(_beneficiary);
        emit BeneficiaryUpdated(_beneficiary);
    }


    function _transfer(address newBeneficiary, address newOwner) internal {
        transferOwnership(newOwner);
        _setBeneficiary(newBeneficiary);
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

    /// @dev Internal function to assert caller is the owner
    function _assertOwner() internal view {
        if (msg.sender != owner()) {
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

    function version() external pure returns (string memory) {
        return "v1.0.0 U";
    }
}