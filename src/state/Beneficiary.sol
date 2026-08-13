// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.34;

import "openzeppelin-contracts/contracts/utils/StorageSlot.sol";

/**
 * @title Beneficiary
 * @author Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation
 * @notice This library manages the beneficiary address for the TVS proxy contract
 * `@dev` The beneficiary address is the address to which all funds are swept when a {sweep} operation is performed
 * `@dev` TVS variants store the beneficiary address in the `BENEFICIARY_SLOT` slot
 */
library Beneficiary {
    /**
     * @notice Slot for the beneficiary address
     * @dev This slot is used to store the beneficiary address for the proxy contract
     */
    bytes32 internal constant BENEFICIARY_SLOT = bytes32(uint256(keccak256("tvs.state.beneficiary")) - 1);

    /**
     * @notice Set the beneficiary address
     * @param newBeneficiary The new beneficiary address
     */
    function set(address newBeneficiary) internal {
        StorageSlot.getAddressSlot(BENEFICIARY_SLOT).value = newBeneficiary;
    }

    /**
     * @notice Get the beneficiary address
     * @return The beneficiary address
     */
    function get() internal view returns (address) {
        return StorageSlot.getAddressSlot(BENEFICIARY_SLOT).value;
    }
}
