// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.28;

import "./state/proxy/Beacon.sol";
import "./state/tvs/Beneficiary.sol";
import "./interfaces/ITVSUpgradeable.sol";
import "./interfaces/IImmutableBeaconFactory.sol";
import "../interfaces/ISweepToContract.sol";
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

    address public immutable WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;
    address public immutable CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

    /// @notice The address of the immutable beacon contract.
    /// @dev During a TVS transfer, this variable ensures that the current TVS Implementation is frozen,
    /// preventing the oldOwner from modifying the TVS Implementation in the beacon.
    address public immutable immutableBeacon;

    constructor(address withdrawalContractAddress, address consolidationContractAddress, address immutableBeaconFactory) {

        if (withdrawalContractAddress == address(0) || consolidationContractAddress == address(0)) {
            revert InvalidAddress();
        }
        WITHDRAWAL_CONTRACT_ADDRESS = withdrawalContractAddress;
        CONSOLIDATION_CONTRACT_ADDRESS = consolidationContractAddress;
        
        immutableBeacon = IImmutableBeaconFactory(immutableBeaconFactory).deployBeacon(address(this));
    }
    
    receive() external payable {}

    function initialize(address destination, address owner, address newBeacon) external initializer {
        if (destination == address(0) || owner == address(0) || newBeacon == address(0)) revert InvalidAddress();

        __Ownable_init(owner); 
        __ReentrancyGuard_init();
        Beneficiary.set(destination);
        Beacon.set(newBeacon);
    }

    /// @inheritdoc ITVS
    function transfer(address newBeneficiary, address newOwner) external onlyOwner {
        address immutableBeaconImplementation = IBeacon(immutableBeacon).implementation();

        _setBeacon(immutableBeacon, immutableBeaconImplementation);
        _setBeneficiary(newBeneficiary);   
        transferOwnership(newOwner);     
        emit Transferred(newBeneficiary, newOwner);
    }

    /// @inheritdoc ITVS
    function withdrawFrom(bytes[] memory pubkeys, uint64[] calldata amount, uint256 maxFeePerWithdrawal, address excessFeeRecipient) payable external nonReentrant onlyOwner {
        _withdrawFrom(pubkeys, amount, maxFeePerWithdrawal, excessFeeRecipient);
    }

    /// @inheritdoc ITVS
    function consolidate(ConsolidationRequest[] calldata requests, uint256 maxFeePerConsolidation, address excessFeeRecipient) payable external nonReentrant onlyOwner {
        _consolidate(requests, maxFeePerConsolidation, excessFeeRecipient);
    }

    /// @inheritdoc ITVS
    function sweep(address recipient, uint256 amount) external {
        (address dest, uint256 amountToSweep) = _sweep(recipient, amount);
        payable(dest).sendValue(amountToSweep);
    }

    /// @inheritdoc ITVS
    function sweepToContract(address beneficiary, uint256 amount) external nonReentrant {
        (address dest, uint256 amountToSweep) = _sweep(beneficiary, amount);
        ISweepToContract(dest).receiveETHFromTVS{value: amountToSweep}();
    }

    /// @inheritdoc ITVS
    function setBeneficiary(address newBeneficiary) external onlyOwner {
        _setBeneficiary(newBeneficiary);
    }

    /// @inheritdoc ITVSUpgradeable
    function setBeacon(address newBeacon) external onlyOwner {
        address implementation = IBeacon(newBeacon).implementation();
        _setBeacon(newBeacon, implementation);
    }

    function unsafeSetBeacon(address newBeacon) external onlyOwner {
        address oldBeacon = Beacon.get();
        Beacon.set(newBeacon);
        emit BeaconUpdated(oldBeacon, newBeacon);   
    }

    function renounceOwnership() public view override onlyOwner {
        revert OwnershipCannotBeRenounced();
    }

    /// @inheritdoc ITVS
    function getBeneficiary() public view returns (address) {
        return Beneficiary.get();
    }

    /// @inheritdoc ITVSUpgradeable
    function beacon() external view returns (address) {
        return Beacon.get();
    }

    function _setBeacon(address _beacon, address implementation) internal {
        implementation.functionDelegateCall(abi.encodeWithSignature("unsafeSetBeacon(address)", _beacon));
    }

    function _setBeneficiary(address _newBeneficiary) internal {
        if (_newBeneficiary == address(0)) revert InvalidAddress();
        Beneficiary.set(_newBeneficiary);
        emit BeneficiaryUpdated(_newBeneficiary);
    }


    function _withdrawFrom(bytes[] memory _pubkeys, uint64[] calldata _amount, uint256 _maxFeePerWithdrawal, address _excessFeeRecipient)  internal   {
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
            (bool writeOK,) = WITHDRAWAL_CONTRACT_ADDRESS.call{value: fee}(callData);
            if (!writeOK) {
                revert RequestFailed();
            }
            totalFeePaid += fee;
        }

        // Refund any access value back to the excessFeeRecipient
        _refundExcessFee(msg.value, totalFeePaid, _excessFeeRecipient);
    }

    function _consolidate(ConsolidationRequest[] calldata _requests, uint256 _maxFeePerConsolidation, address _excessFeeRecipient)  internal  {

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
                (bool writeOK,) = CONSOLIDATION_CONTRACT_ADDRESS.call{value: fee}(callData);
                if (!writeOK) {
                    revert RequestFailed();
                }

                totalFeePaid += fee;
            }
        }

        // Refund any access value back to the excessFeeRecipient
        _refundExcessFee(msg.value, totalFeePaid, _excessFeeRecipient);
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
            revert OwnableUnauthorizedAccount(msg.sender);
        }
    }

    function _refundExcessFee(uint256 _totalValueReceived, uint256 _totalFeePaid, address _excessFeeRecipient) internal {
        // send excess value  back to _excessFeeRecipient
        if (_totalValueReceived > _totalFeePaid) {
            (bool success, ) = payable(_excessFeeRecipient).call{value: _totalValueReceived - _totalFeePaid}("");
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

    function version() external pure returns (string memory) {
        return "v1.0.0 U";
    }
}