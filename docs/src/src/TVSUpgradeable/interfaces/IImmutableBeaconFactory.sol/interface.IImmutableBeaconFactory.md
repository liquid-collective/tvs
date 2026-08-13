# IImmutableBeaconFactory
[Git Source](https://github.com/liquid-collective/tvs/blob/73975467b58a06efd3cb21e22cbe8935ab4018be/src/TVSUpgradeable/interfaces/IImmutableBeaconFactory.sol)

**Title:**
Immutable Beacon Factory Interface

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

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


