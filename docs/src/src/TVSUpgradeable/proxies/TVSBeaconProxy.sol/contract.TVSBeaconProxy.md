# TVSBeaconProxy
[Git Source](https://github.com/liquid-collective/tvs/blob/94694c515bd11d10170311c3c8bd350b25f11fb2/src/TVSUpgradeable/proxies/TVSBeaconProxy.sol)

**Author:**
Alluvial Finance Inc.

This is an EIP-1167 minimal proxy that interacts with an upgradable beacon contract

*It uses the beacon contract to fetch the implementation address and delegate the call.*

*The beacon contract is expected to have an `implementation()` function that returns the address of the
implementation.*


## Functions
### constructor

Constructs a new TVSBeaconProxy instance

*The constructor will get the implementation address from the beacon, and delegate the initialization call
to the implementation.*

*This function will revert if the implementation on the beacon is not a contract, or the input data to
initialize has invalid addresses.*


```solidity
constructor(address beacon, bytes memory initData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beacon`|`address`|The address of the beacon contract|
|`initData`|`bytes`|The initialization data to be passed to the implementation contract|


### fallback

Fallback function that delegates all calls to the implementation address returned by the beacon

*This function uses inline assembly to first fetch the implementation address from the beacon*

*and then delegates the call to it.*


```solidity
fallback() external payable;
```

### _getImplementation

Internal function to fetch the implementation address from the beacon

*This function uses inline assembly to fetch the implementation address from the beacon*


```solidity
function _getImplementation(address _beacon) internal view returns (address _implementation);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_beacon`|`address`|The address of the beacon contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_implementation`|`address`|The address of the implementation contract|


## Errors
### InitializationFailed

```solidity
error InitializationFailed();
```

### InvalidBeacon

```solidity
error InvalidBeacon();
```

