# ITVSUpgradeable
[Git Source](https://github.com/liquid-collective/tvs/blob/0a7c19c25bddf9711a5173f5e1fef30c118f1dd9/src/TVSUpgradeable/interfaces/ITVSUpgradeable.sol)

**Inherits:**
[ITVS](/src/interfaces/ITVS.sol/interface.ITVS.md)

**Title:**
TVS Interface (Upgradeable)

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

Interface for the TVSUpgradeable contract.

This interface is used to interact with the TVSUpgradeable contract.

The TVSUpgradeable contract is an upgradeable implementation of the TVS contract.


## Functions
### setBeacon

Sets a new beacon address for the TVS.

Only the owner can call this function.

Emits a [BeaconUpgraded](/src/TVSUpgradeable/interfaces/ITVSUpgradeable.sol/interface.ITVSUpgradeable.md#beaconupgraded) event.


```solidity
function setBeacon(address newBeacon) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBeacon`|`address`|The new beacon address.|


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

