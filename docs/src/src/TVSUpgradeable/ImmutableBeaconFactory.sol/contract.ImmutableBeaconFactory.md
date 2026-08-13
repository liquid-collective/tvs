# ImmutableBeaconFactory
[Git Source](https://github.com/liquid-collective/tvs/blob/0a7c19c25bddf9711a5173f5e1fef30c118f1dd9/src/TVSUpgradeable/ImmutableBeaconFactory.sol)

**Inherits:**
[IImmutableBeaconFactory](/src/TVSUpgradeable/interfaces/IImmutableBeaconFactory.sol/interface.IImmutableBeaconFactory.md)

**Title:**
Immutable Beacon Factory

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

Factory contract for deploying instances of immutable beacons, guaranteeing that their implementation is
frozen after deployment


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


