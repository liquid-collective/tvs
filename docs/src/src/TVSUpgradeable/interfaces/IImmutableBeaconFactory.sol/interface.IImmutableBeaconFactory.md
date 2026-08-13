# IImmutableBeaconFactory
[Git Source](https://github.com/liquid-collective/tvs/blob/96c19775021894fde7393def044436b34bb7c971/src/TVSUpgradeable/interfaces/IImmutableBeaconFactory.sol)

**Title:**
Immutable Beacon Factory Interface

**Author:**
Originally authored by Galaxy Blockchain Infrastructure LLC; contributed to The Liquid Foundation

Interface for the Immutable Beacon Factory

This interface is used to deploy new immutable beacon contracts


## Functions
### deployBeacon

Deploys a new immutable beacon contract


```solidity
function deployBeacon(address implementation) external returns (address beacon);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`implementation`|`address`|The address of the implementation contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`beacon`|`address`|The address of the deployed immutable beacon|


