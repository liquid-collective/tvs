// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.20;

import "./interfaces/ITVS.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

/// @title TVS (v1)
/// @author Alluvial Finance Inc.
/// @notice Abstract base contract for TVS implementations
abstract contract TVS is ITVS {
    using Address for address payable;
    using Address for address;

    address public constant WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;
    address public constant CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

    /// @dev Internal function to assert caller is the owner
    function _assertOwner() internal view {
        if (msg.sender != owner()) {
            revert NotOwner(msg.sender);
        }
    }

    ///@dev Modifier to restrict functions to the contract owner only.
    modifier _onlyOwner() {
        _assertOwner();
        _;
    }

    /// @inheritdoc ITVS
    receive() external payable {}

    function owner() public view virtual returns (address);

    /// @inheritdoc ITVS
    function setBeneficiary(address _beneficiary) virtual external;

    /// @inheritdoc ITVS
    function getBeneficiary() public view virtual override returns (address);

    /// @inheritdoc ITVS
    function sweep(address beneficiary, uint256 _amount) external {
        // Only require owner for custom beneficiary or amount
        if (beneficiary != address(0) || _amount != 0) {
            _assertOwner();
        }
        
        address dest = beneficiary == address(0) ? getBeneficiary() : beneficiary;
        uint256 amountToSweep = _amount == 0 ? address(this).balance : _amount;
        if (amountToSweep > address(this).balance) {
            revert InsufficientBalance(address(this).balance, amountToSweep);
        }
        payable(dest).sendValue(amountToSweep);
        emit Swept(dest, amountToSweep);
    }

    /// @inheritdoc ITVS
    function withdrawFrom(bytes[] memory pubkeys, uint64[] calldata amount, uint256 maxFeePerWithdrawal) external _onlyOwner {
        if (pubkeys.length != amount.length) {
            revert LengthMismatch(pubkeys.length, amount.length);
        }
        
        for (uint256 i = 0; i < pubkeys.length; i++) {
            // Read current fee from the contract
            (bool readOK, bytes memory feeData) = WITHDRAWAL_CONTRACT_ADDRESS.staticcall("");
            if (!readOK) {
                revert FeeReadFailed();
            }
            uint256 fee = uint256(bytes32(feeData));
            
            // Check if fee exceeds maximum allowed
            if (fee > maxFeePerWithdrawal) {
                revert FeeTooHigh(fee, maxFeePerWithdrawal);
            }

            // Add the withdrawal request
            bytes memory callData = abi.encodePacked(pubkeys[i], amount[i]);
            (bool writeOK,) = WITHDRAWAL_CONTRACT_ADDRESS.call{value: fee}(callData);
            if (!writeOK) {
                revert RequestFailed();
            }
        }
    }

    /// @inheritdoc ITVS
    function consolidate(bytes[] memory srcPubkeys, bytes[] memory targetPubkeys, uint256 maxFeePerConsolidation) external _onlyOwner {
        if (srcPubkeys.length != targetPubkeys.length) {
            revert LengthMismatch(srcPubkeys.length, targetPubkeys.length);
        }
        
        for (uint256 i = 0; i < srcPubkeys.length; i++) {
            // Read current fee from the contract
            (bool readOK, bytes memory feeData) = CONSOLIDATION_CONTRACT_ADDRESS.staticcall("");
            if (!readOK) {
                revert FeeReadFailed();
            }
            uint256 fee = uint256(bytes32(feeData));
            
            // Check if fee exceeds maximum allowed
            if (fee > maxFeePerConsolidation) {
                revert FeeTooHigh(fee, maxFeePerConsolidation);
            }

            // Add the consolidation request
            bytes memory callData = bytes.concat(srcPubkeys[i], targetPubkeys[i]);
            (bool writeOK,) = CONSOLIDATION_CONTRACT_ADDRESS.call{value: fee}(callData);
            if (!writeOK) {
                revert RequestFailed();
            }
        }
    }
} 