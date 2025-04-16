# ITVSFlexibleImmutable
[Git Source](https://github.com/liquid-collective/tvs/blob/74937b56cfb6ca2a00ba3057606cc7f6aeafe8f6/src/TVSNonUpgradeable/interfaces/ITVSFlexibleImmutable.sol)

**Author:**
Alluvial Finance Inc.

Interface for the TVSFlexibleImmutable contract

*This interface is used to interact with the TVSFlexibleImmutable contract*

*The TVSFlexibleImmutable contract is a flexible immutable implementation of the TVS contract*


## Functions
### executeCall

Executes a low-level call or delegatecall to the specified address.

*Bubbles up revert reasons and handles both ETH transfers and data calls.*


```solidity
function executeCall(Call calldata call) external payable returns (bytes memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`call`|`Call`|The Call struct containing the target address, value, data, and call type.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|The return data from the call.|


### executeBatch

Executes a batch of low-level calls or delegatecalls.

*revert on the first call that fails.*


```solidity
function executeBatch(Call[] calldata calls) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`calls`|`Call[]`|An array of Call structs containing the target address, value, data, and call type.|


## Structs
### Call
Struct to hold call data for the arbitrary executeCall function

*The Call struct is used to hold the data required to perform a low-level call or delegatecall.*


```solidity
struct Call {
    address to;
    uint256 value;
    bytes data;
    bool isDelegateCall;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The target address for the call.|
|`value`|`uint256`|The amount of ETH (in wei) to transfer. Pass 0 for non-payable calls.|
|`data`|`bytes`|The calldata to pass to the target address.|
|`isDelegateCall`|`bool`|Boolean flag to indicate whether to perform a delegatecall (true) or a call (false).|

