# ImmutableBeaconFactory
[Git Source](https://github.com/liquid-collective/tvs/blob/74937b56cfb6ca2a00ba3057606cc7f6aeafe8f6/src/TVSUpgradeable/ImmutableBeaconFactory.sol)

**Inherits:**
[IImmutableBeaconFactory](/src/TVSUpgradeable/interfaces/IImmutableBeaconFactory.sol/interface.IImmutableBeaconFactory.md)

**Author:**
Alluvial Finance Inc.

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


