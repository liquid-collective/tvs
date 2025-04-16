# ITVSUpgradeable
[Git Source](https://github.com/liquid-collective/tvs/blob/74937b56cfb6ca2a00ba3057606cc7f6aeafe8f6/src/TVSUpgradeable/interfaces/ITVSUpgradeable.sol)

**Inherits:**
[ITVS](/src/interfaces/ITVS.sol/interface.ITVS.md)

**Author:**
Alluvial Finance Inc.

Interface for the TVS contract.

*This interface is used to interact with the TVS contract.*

*The TVSUpgradeable contract is an upgradeable implementation of the TVS contract*


## Functions
### setBeacon

Sets a new beacon address for the TVS.

*Only the owner can call this function.*

*Emits a [BeaconUpdated](/src/TVSUpgradeable/interfaces/ITVSUpgradeable.sol/interface.ITVSUpgradeable.md#beaconupdated) event.*


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
### BeaconUpdated
Emitted when the beacon address is updated.


```solidity
event BeaconUpdated(address indexed oldBeacon, address indexed newBeacon);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`oldBeacon`|`address`|The old beacon address.|
|`newBeacon`|`address`|The new beacon address.|

## Errors
### InvalidBeacon
Error thrown when the beacon address is invalid.


```solidity
error InvalidBeacon();
```

