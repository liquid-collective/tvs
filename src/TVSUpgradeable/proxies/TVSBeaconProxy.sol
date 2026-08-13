// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import "../state/proxy/Beacon.sol";

/**
 * @title TVSBeaconProxy
 * @author Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation
 * @notice This is an EIP-1167 minimal proxy that interacts with an upgradeable beacon contract
 * @dev It uses the beacon contract to fetch the implementation address and delegate the call.
 * @dev The beacon contract is expected to have an `implementation()` function that returns the address of the
 *      implementation.
 */
contract TVSBeaconProxy {
    /**
     * @notice Error thrown when the proxy initialization fails
     */
    error InitializationFailed();

    /**
     * @notice Error thrown when the beacon address is invalid
     */
    error InvalidBeacon();

    /**
     * @notice Constructs a new TVSBeaconProxy instance
     * @dev The constructor will get the implementation address from the beacon, and delegate the initialization call
     *      to the implementation.
     * @dev This function will revert if the implementation on the beacon is not a contract, or the input data to
     *      initialize has invalid addresses.
     * @param beacon The address of the beacon contract
     * @param initData The initialization data to be passed to the implementation contract
     */
    constructor(address beacon, bytes memory initData) {
        address implementation = _getImplementation(beacon);
        if (implementation.code.length == 0) revert InvalidBeacon();
        (bool success,) = implementation.delegatecall(initData);
        if (!success) {
            revert InitializationFailed();
        }
    }

    /**
     * @notice Fallback function that delegates all calls to the implementation address returned by the beacon
     * @dev This function uses inline assembly to first fetch the implementation address from the beacon
     * @dev and then delegates the call to it.
     */
    fallback() external payable {
        address implementation = _getImplementation(Beacon.get());
        assembly ("memory-safe") {
            // Copy the call data to memory
            calldatacopy(0, 0, calldatasize())

            // Perform the delegate call to the implementation address
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data from the delegate call
            returndatacopy(0, 0, returndatasize())

            // If the delegate call failed, revert with returned data
            if iszero(result) { revert(0, returndatasize()) }

            // Return the data from the delegate call
            return(0, returndatasize())
        }
    }

    /**
     * @notice Internal function to fetch the implementation address from the beacon
     * @dev This function uses inline assembly to fetch the implementation address from the beacon
     * @param _beacon The address of the beacon contract
     * @return _implementation The address of the implementation contract
     */
    function _getImplementation(address _beacon) internal view returns (address _implementation) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)

            // Store the function selector for `implementation()` (keccak256("implementation()") = 0x5c60da1b)
            mstore(ptr, 0x5c60da1b00000000000000000000000000000000000000000000000000000000)

            // Perform the staticcall to the BEACON_ADDRESS
            let success :=
                staticcall(
                    gas(), // forward all remaining gas
                    _beacon, // address of the beacon
                    ptr, // input starts at ptr
                    0x04, // size of the function selector (4 bytes)
                    ptr, // store output at ptr (reuse memory)
                    0x20 // size of the output (32 bytes, address size)
                )

            // Check if the staticcall was successful
            if iszero(success) { revert(0, 0) } // revert if the call failed

            // Load the returned address from memory (stored at ptr)
            _implementation := mload(ptr)
        }
    }
}
