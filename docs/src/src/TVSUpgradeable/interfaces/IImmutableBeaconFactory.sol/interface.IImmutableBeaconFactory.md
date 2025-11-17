# IImmutableBeaconFactory
[Git Source](https://github.com/liquid-collective/tvs/blob/03c48a2bf3813d683a089f40751b05bbe6f7f34c/src/TVSUpgradeable/interfaces/IImmutableBeaconFactory.sol)

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


