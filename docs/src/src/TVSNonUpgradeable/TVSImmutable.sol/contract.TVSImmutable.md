# TVSImmutable
[Git Source](https://github.com/liquid-collective/tvs/blob/73975467b58a06efd3cb21e22cbe8935ab4018be/src/TVSNonUpgradeable/TVSImmutable.sol)

**Inherits:**
[TVSImmutableBase](/src/TVSNonUpgradeable/TVSImmutableBase.sol/abstract.TVSImmutableBase.md)

**Title:**
Immutable TVS

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

Non-upgradeable implementation of the TVS

This contract is a non-upgradeable implementation of the TVS contract.


## Functions
### constructor

Constructor for the TVS Immutable contract

Initializes the contract with all required parameters

The withdrawal and consolidation addresses are Pectra EL contract addresses, and are stored as immutable
state variables. They can only be set once here in the constructor

NOTE: Because this contract is immutable, if the withdrawal or consolidation addresses ever change on a
chain where the TVS is already deployed, consolidations and partial withdrawals will no longer work. In
that case the validators tied to the TVS must be exited and a new TVS deployed with the new addresses


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


