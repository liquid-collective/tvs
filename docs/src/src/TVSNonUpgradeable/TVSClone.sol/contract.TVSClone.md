# TVSClone
[Git Source](https://github.com/liquid-collective/tvs/blob/94694c515bd11d10170311c3c8bd350b25f11fb2/src/TVSNonUpgradeable/TVSClone.sol)

**Inherits:**
[TVSImmutableBase](/src/TVSNonUpgradeable/TVSImmutableBase.sol/abstract.TVSImmutableBase.md)

**Author:**
Alluvial Finance Inc.

Non-upgradeable implementation of the TVS with initializer

*The TVSClone contract is designed with the idea of providing an immutable version that is compatible with
EIP-1167 clone proxy, offering users a way to minimize gas costs during deployment.*

*Even though this contract follows the pattern of a proxy implementation contract. It is a non-upgradeable
implementation of the TVS contract, expected to be used only with the clone proxy pattern which is
non-upgradeable.*


## Functions
### constructor


```solidity
constructor(
    address withdrawalContractAddress,
    address consolidationContractAddress
)
    TVSImmutableBase(withdrawalContractAddress, consolidationContractAddress);
```

### initialize

Initializes the TVS clone with beneficiary and owner addresses

*This function can only be called once and sets up the contract security controls and beneficiary.
{_setupSecurity} is called to set the owner and other security controls.*


```solidity
function initialize(address beneficiary, address owner) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The default address that will receive all ETH swept from the TVS contract|
|`owner`|`address`|The address that will have ownership rights over the TVS|


