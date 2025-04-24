# ImmutableBeacon
[Git Source](https://github.com/liquid-collective/tvs/blob/74937b56cfb6ca2a00ba3057606cc7f6aeafe8f6/src/TVSUpgradeable/ImmutableBeacon.sol)

**Author:**
Alluvial Finance Inc.

An immutable beacon whose implementation can never be altered after deployment

*This contract is used to store the implementation address of a proxy contract*

*The implementation address is set in the constructor and cannot be changed*


## State Variables
### implementation
The proxy implementation address stored in the beacon

*This address is set in the constructor and cannot be changed*


```solidity
address public immutable implementation;
```


## Functions
### constructor

Constructor for the ImmutableBeacon contract

*Sets the proxy implementation address on the beacon*


```solidity
constructor(address theImplementation);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`theImplementation`|`address`|The address of the implementation contract|


## Errors
### InvalidImplementation
Emitted when the implementation address is invalid


```solidity
error InvalidImplementation();
```

