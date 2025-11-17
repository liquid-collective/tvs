# ITVSUpgradeable
[Git Source](https://github.com/liquid-collective/tvs/blob/03c48a2bf3813d683a089f40751b05bbe6f7f34c/src/TVSUpgradeable/interfaces/ITVSUpgradeable.sol)

**Inherits:**
[ITVS](/Users/praffulsahu/Documents/GitHub/tvs/docs/src/src/interfaces/ITVS.sol/interface.ITVS.md)

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

Interface for the TVS contract.

This interface is used to interact with the TVS contract.

The TVSUpgradeable contract is an upgradeable implementation of the TVS contract


## Functions
### setBeacon

Sets a new beacon address for the TVS.

Only the owner can call this function.

Emits a [BeaconUpgraded](//Users/praffulsahu/Documents/GitHub/tvs/docs/src/src/TVSUpgradeable/interfaces/ITVSUpgradeable.sol/interface.ITVSUpgradeable.md#beaconupgraded) event.


```solidity
function setBeacon(address beacon) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beacon`|`address`|The new beacon address.|


### beacon

Retrieves the current beacon address.


```solidity
function beacon() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the beacon.|


## Events
### BeaconUpgraded
Emitted when the beacon address is updated.


```solidity
event BeaconUpgraded(address indexed beacon);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beacon`|`address`|The new beacon address.|

## Errors
### InvalidBeacon
Error thrown when the beacon address is invalid.


```solidity
error InvalidBeacon();
```

