# TVSClone
[Git Source](https://github.com/liquid-collective/tvs/blob/73975467b58a06efd3cb21e22cbe8935ab4018be/src/TVSNonUpgradeable/TVSClone.sol)

**Inherits:**
[TVSImmutableBase](/src/TVSNonUpgradeable/TVSImmutableBase.sol/abstract.TVSImmutableBase.md)

**Title:**
TVS Clone Implementation (v1)

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

Non-upgradeable implementation of the TVS with initializer

The TVSClone contract is designed with the idea of providing an immutable version that is compatible with
EIP-1167 clone proxy, offering users a way to minimize gas costs during deployment.

Even though this contract follows the pattern of a proxy implementation contract, it is a non-upgradeable
implementation of the TVS contract, expected to be used only with the clone proxy pattern which is
non-upgradeable.


## Functions
### constructor

Constructor that disables initializers to prevent direct use of the implementation contract


```solidity
constructor(
    address withdrawalContractAddress,
    address consolidationContractAddress
)
    TVSImmutableBase(withdrawalContractAddress, consolidationContractAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalContractAddress`|`address`|The address of the withdrawal contract|
|`consolidationContractAddress`|`address`|The address of the consolidation contract|


### initialize

Initializes the TVS clone with beneficiary and owner addresses

This function can only be called once and sets up the contract security controls and beneficiary.
{_setupSecurity} is called to set the owner and other security controls.


```solidity
function initialize(address beneficiary, address owner) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The default address that will receive all ETH swept from the TVS contract|
|`owner`|`address`|The address that will have ownership rights over the TVS|


