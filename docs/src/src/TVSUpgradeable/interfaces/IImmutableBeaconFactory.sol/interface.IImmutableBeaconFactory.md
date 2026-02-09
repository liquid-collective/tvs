# IImmutableBeaconFactory
[Git Source](https://github.com/liquid-collective/tvs/blob/4ac2b74c6a3425c037c24fec5693ed6e51456b86/src/TVSUpgradeable/interfaces/IImmutableBeaconFactory.sol)

**Title:**
IImmutableBeaconFactory

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


