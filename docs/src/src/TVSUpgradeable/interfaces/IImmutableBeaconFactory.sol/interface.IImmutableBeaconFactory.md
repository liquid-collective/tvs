# IImmutableBeaconFactory
[Git Source](https://github.com/liquid-collective/tvs/blob/94694c515bd11d10170311c3c8bd350b25f11fb2/src/TVSUpgradeable/interfaces/IImmutableBeaconFactory.sol)

Interface for the Immutable Beacon Factory

*This interface is used to deploy new immutable beacon contracts*


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


