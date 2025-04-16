# Beacon
[Git Source](https://github.com/liquid-collective/tvs/blob/74937b56cfb6ca2a00ba3057606cc7f6aeafe8f6/src/TVSUpgradeable/state/proxy/Beacon.sol)

**Author:**
Alluvial Finance Inc.

This library manages the beacon address for the proxy contract

*The beacon address is the address of the contract that holds the implementation address*

*The implementation address is the address of the contract that contains the business logic*

*The beacon address is expected to have an `implementation()` function that returns the address of the
implementation*

*The proxy contract is expected to have a `BEACON_SLOT` slot that stores the beacon address*


## State Variables
### BEACON_SLOT
*Slot for the beacon address*

*The slot is defined using the EIP-1967 standard*


```solidity
bytes32 internal constant BEACON_SLOT = bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1);
```


## Functions
### set

Set the beacon address


```solidity
function set(address newBeacon) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBeacon`|`address`|The new beacon address|


### get

Get the beacon address


```solidity
function get() internal view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The beacon address|


