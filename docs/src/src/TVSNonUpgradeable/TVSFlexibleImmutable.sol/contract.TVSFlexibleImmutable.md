# TVSFlexibleImmutable
[Git Source](https://github.com/liquid-collective/tvs/blob/f546bad8c547a073ff1d0af0687e478a4dedbebc/src/TVSNonUpgradeable/TVSFlexibleImmutable.sol)

**Inherits:**
[ITVSFlexibleImmutable](/src/TVSNonUpgradeable/interfaces/ITVSFlexibleImmutable.sol/interface.ITVSFlexibleImmutable.md), [TVSImmutable](/src/TVSNonUpgradeable/TVSImmutable.sol/contract.TVSImmutable.md)

**Title:**
Flexible Immutable TVS (v1)

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

Non-upgradeable implementation of the TVS with arbitrary executeCall function

This contract implements all the functionality of the TVSImmutable contract and adds an additional executeCall
function that allows for arbitrary calls to be made to, and from the contract by the owner only. This provides
the flexibility to capture, and interact with future functionalities that cannot be added to the TVSImmutable
contract.


## Functions
### constructor

Constructor for the TVSFlexibleImmutable contract

Initializes the contract with all required parameters

The withdrawal and consolidation addresses are Pectra EL contract addresses, and are stored as immutable
state variables. They can only be set once here in the constructor


```solidity
constructor(
    address beneficiary,
    address owner,
    address withdrawalContractAddress,
    address consolidationContractAddress
)
    TVSImmutable(beneficiary, owner, withdrawalContractAddress, consolidationContractAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The default address that will receive all ETH swept from the TVS contract|
|`owner`|`address`|The address that will have ownership rights over the TVS|
|`withdrawalContractAddress`|`address`|The address of the withdrawal contract|
|`consolidationContractAddress`|`address`|The address of the consolidation contract|


### executeCall

Executes a low-level call or delegatecall to the specified address.

Bubbles up revert reasons and handles both ETH transfers and data calls.


```solidity
function executeCall(Call calldata call) external payable onlyOwner nonReentrant returns (bytes memory);
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

NOTE:
- when msg.value is passed, only one delegatecall should be made;
- when msg.value is passed, any delegatecall to non-payable functions will fail.


```solidity
function executeBatch(Call[] calldata calls) external payable virtual onlyOwner nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`calls`|`Call[]`|An array of Call structs containing the target address, value, data, and call type.|


### _executeCall

Internal function to execute an arbitrary call

This function is used to execute an arbitrary call from the TVS contract by the owner only.

The call is executed using the functionDelegateCall or functionCallWithValue function depending on the
isDelegateCall flag.


```solidity
function _executeCall(Call calldata _call) internal returns (bytes memory _returnData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_call`|`Call`|The call to execute|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_returnData`|`bytes`|The return data from the call|


