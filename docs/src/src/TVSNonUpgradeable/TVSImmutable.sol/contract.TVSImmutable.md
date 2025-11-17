# TVSImmutable
[Git Source](https://github.com/liquid-collective/tvs/blob/03c48a2bf3813d683a089f40751b05bbe6f7f34c/src/TVSNonUpgradeable/TVSImmutable.sol)

**Inherits:**
[TVSImmutableBase](/Users/praffulsahu/Documents/GitHub/tvs/docs/src/src/TVSNonUpgradeable/TVSImmutableBase.sol/abstract.TVSImmutableBase.md)

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

Non-upgradeable implementation of the TVS

This contract is a non-upgradeable implementation of the TVS contract.


## Functions
### constructor

Constructor for the TVS Immutable contract

Initializes the contract with all required parameters

The withdrawal and consolidation addresses are pectra EL contract addresses, and are stored as immutable
state variables.
They can only be set once here in the constructor.

NOTE: If for any reason the withdrawal, and consolidation addresses changes on a chain where the TVS is
already deployed, consolidation,
and partial withdrawals might not work as expected, except the validators tied to the TVS is exited, and a new
TVS is deployed with
the new addresses due to the immutability of this contract.


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


