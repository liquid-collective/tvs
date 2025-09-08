# TVSImmutable
[Git Source](https://github.com/liquid-collective/tvs/blob/f5c73298c5c83b0c84fd88c0b4e9e6669cf53875/src/TVSNonUpgradeable/TVSImmutable.sol)

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

*NOTE: If for any reason the withdrawal, and consolidation addresses changes on a chain where the TVS is
already deployed, consolidation,
and partial withdrawals might not work as expected, except the validators tied to the TVS is exited, and a new
TVS is deployed with
the new addresses due to the immutability of this contract.*


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


