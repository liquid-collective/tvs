# TVSImmutableBase
[Git Source](https://github.com/liquid-collective/tvs/blob/74937b56cfb6ca2a00ba3057606cc7f6aeafe8f6/src/TVSNonUpgradeable/TVSImmutableBase.sol)

**Inherits:**
[TVS](/src/components/TVS.sol/abstract.TVS.md)

**Author:**
Alluvial Finance Inc.

Base contract for TVS Immutable implementations

*This contract provides the base functionality for immutable TVS implementations*


## Functions
### constructor

Constructor for the TVS Immutable contract

*Initializes the contract with Pectra withdrawal and consolidation EL contract addresses.*

*The withdrawal and consolidation addresses are stored as immutable state variables. they can only be set
once here in the constructor.*


```solidity
constructor(
    address withdrawalContractAddress,
    address consolidationContractAddress
)
    TVS(withdrawalContractAddress, consolidationContractAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalContractAddress`|`address`|The address of the withdrawal contract|
|`consolidationContractAddress`|`address`|The address of the consolidation contract|


### transfer

Transfers the ownership of the TVS.

*This function sets a new beneficiary, transfers ownership to a new owner.*


```solidity
function transfer(address newBeneficiary, address newOwner) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBeneficiary`|`address`|The new beneficiary address.|
|`newOwner`|`address`|The new owner address.|


### version

Retrieves the version of the contract.


```solidity
function version() external pure returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|Version of the contract|


