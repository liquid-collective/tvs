// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import "openzeppelin-contracts/contracts/utils/StorageSlot.sol";

/**
 * @title PendingBeneficiary
 * @author Alluvial Finance Inc.
 * @notice This library manages the pending beneficiary address for the TVS proxy contract
 * @dev The pending beneficiary address is the address to which all funds are swept to when a {sweep} operation is
 * performed
 * @dev The proxy contract is expected to have a `PENDING_BENEFICIARY_SLOT` slot that stores the pending beneficiary
 * address
 */
library PendingBeneficiary {
    /**
     * @notice Slot for the pending beneficiary address
     * @dev This slot is used to store the pending beneficiary address for the proxy contract
     */
    bytes32 internal constant PENDING_BENEFICIARY_SLOT =
        bytes32(uint256(keccak256("tvs.state.pendingBeneficiary")) - 1);

    /**
     * @notice Set the pending beneficiary address
     * @param _newPendingBeneficiary The new pending beneficiary address
     */
    function set(address _newPendingBeneficiary) internal {
        StorageSlot.getAddressSlot(PENDING_BENEFICIARY_SLOT).value = _newPendingBeneficiary;
    }

    /**
     * @notice Get the pending beneficiary address
     * @return The pending beneficiary address
     */
    function get() internal view returns (address) {
        return StorageSlot.getAddressSlot(PENDING_BENEFICIARY_SLOT).value;
    }
}
