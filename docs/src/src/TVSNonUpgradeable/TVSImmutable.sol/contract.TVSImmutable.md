# TVSImmutable
[Git Source](https://github.com/liquid-collective/tvs/blob/74937b56cfb6ca2a00ba3057606cc7f6aeafe8f6/src/TVSNonUpgradeable/TVSImmutable.sol)

**Inherits:**
[TVSImmutableBase](/src/TVSNonUpgradeable/TVSImmutableBase.sol/abstract.TVSImmutableBase.md)

**Author:**
Alluvial Finance Inc.

Non-upgradeable implementation of the TVS

*This contract is a non-upgradeable implementation of the TVS contract.*


## Functions
### constructor

Constructor for the TVS Immutable contract

*Initializes the contract with all required parameters*

*The withdrawal and consolidation addresses are pectra EL contract addresses, and are stored as immutable
state variables.
They can only be set once here in the constructor.*


```solidity
constructor(
    address beneficiary,
    address owner,
    address withdrawalContractAddress,
    address consolidationContractAddress
)
    TVSImmutableBase(withdrawalContractAddress, consolidationContractAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The default address that will receive all ETH swept from the TVS contract|
|`owner`|`address`|The address that will have ownership rights over the TVS|
|`withdrawalContractAddress`|`address`|The address of the withdrawal contract|
|`consolidationContractAddress`|`address`|The address of the consolidation contract|


