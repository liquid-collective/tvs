# TVSBeaconProxy
[Git Source](https://github.com/liquid-collective/tvs/blob/ec61e0de7686fd76f32b89e56f6a3ecf6bf520ed/src/TVSUpgradeable/proxies/TVSBeaconProxy.sol)

**Title:**
TVSBeaconProxy

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

This is a lightweight beacon proxy that resolves its implementation from an upgradeable beacon contract

It uses the beacon contract to fetch the implementation address and delegate the call

The beacon address is read from the EIP-1967 beacon slot managed by the {Beacon} library

The beacon contract is expected to have an `implementation()` function that returns the address of the
implementation


## Functions
### constructor

Constructs a new TVSBeaconProxy instance

The constructor will get the implementation address from the beacon, and delegate the initialization call
to the implementation

This will revert if the implementation on the beacon is not a contract, or if the input data to
initialize has invalid addresses


```solidity
constructor(address beacon, bytes memory initData) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beacon`|`address`|The address of the beacon contract|
|`initData`|`bytes`|The initialization data to be passed to the implementation contract|


### fallback

Fallback function that delegates all calls to the implementation address returned by the beacon

This function first fetches the implementation address from the beacon and then uses inline assembly to
delegate the call to it


```solidity
fallback() external payable;
```

### _getImplementation

Internal function to fetch the implementation address from the beacon

This function uses inline assembly to fetch the implementation address from the beacon


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
Error thrown when the proxy initialization fails


```solidity
error InitializationFailed();
```

### InvalidBeacon
Error thrown when the beacon address is invalid


```solidity
error InvalidBeacon();
```

