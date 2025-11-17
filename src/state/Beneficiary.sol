//SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import "openzeppelin-contracts/contracts/utils/StorageSlot.sol";

/**
 * @title Beneficiary
 * @author Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation
 * @notice This library manages the beneficiary address for the TVS proxy contract
 * @dev The beneficiary address is the address to which all funds are swept to when a {sweep} operation is performed
 * @dev The proxy contract is expected to have a `BENEFICIARY_SLOT` slot that stores the beneficiary address
 */
library Beneficiary {
    /**
     * @notice Slot for the beneficiary address
     * @dev This slot is used to store the beneficiary address for the proxy contract
     */
    bytes32 internal constant BENEFICIARY_SLOT = bytes32(uint256(keccak256("tvs.state.beneficiary")) - 1);

    /**
     * @notice Set the beneficiary address
     * @param _newBeneficiary The new beneficiary address
     */
    function set(address _newBeneficiary) internal {
        StorageSlot.getAddressSlot(BENEFICIARY_SLOT).value = _newBeneficiary;
    }

    /**
     * @notice Get the beneficiary address
     * @return The beneficiary address
     */
    function get() internal view returns (address) {
        return StorageSlot.getAddressSlot(BENEFICIARY_SLOT).value;
    }
}
