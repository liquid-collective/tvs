# BaseSecurity
[Git Source](https://github.com/liquid-collective/tvs/blob/83e38ad02ffffb0bac3de9ed3b5bc74e76e66343/src/components/BaseSecurity.sol)

**Inherits:**
Initializable, OwnableUpgradeable, ReentrancyGuardTransient

**Title:**
BaseSecurity

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

This contract uses OpenZeppelin's upgradeable libraries to ensure compatibility
with upgradeable contracts. The use of upgradeable libraries is safe here because
the `_setupSecurity` function is marked as `initializer`, which ensures that it
can only be called once during the initialization phase of an upgradeable contract.
For non-upgradeable contracts, this function can still be used during deployment
without any issues, as it does not rely on proxy-specific behavior.

This abstract contract provides a foundational setup for security features,
including ownership management and reentrancy protection. It is designed to
be inherited by both upgradeable and non-upgradeable contracts.

Rationale for using upgradeable contracts:
- Upgradeable contracts require initialization instead of constructors due to the
proxy pattern. By using OpenZeppelin's upgradeable libraries, this contract ensures
compatibility with such patterns.
- Non-upgradeable contracts can also inherit this contract without any adverse effects,
as the initializer function behaves like a constructor when called during deployment.
- This design provides flexibility and reusability, allowing the same security setup
to be used across all variants of TVS and thus reduces code duplication
of functions that would otherwise be repeated in each contract simply because of
the different Ownable and ReentrancyGuard implementations.

Inheriting contracts should call `_setupSecurity` during their initialization or
deployment phase to properly configure ownership and reentrancy protection.


## Functions
### renounceOwnership

Overrides the renounceOwnership function from OwnableUpgradeable to prevent ownership renouncement

This function reverts unconditionally to prevent ownership renouncement by mistake

Reverts with [OwnershipCannotBeRenounced](/src/components/BaseSecurity.sol/abstract.BaseSecurity.md#ownershipcannotberenounced)

Only callable by the contract owner


```solidity
function renounceOwnership() public view override onlyOwner;
```

### transferOwnership

Overrides transferOwnership to prevent direct ownership transfers that bypass protocol invariants.

Direct calls to transferOwnership skip the beneficiary update, and Transferred event
enforced by the transfer() function. All ownership transfers must go through transfer().

Reverts with [UseTransferFunction](/src/components/BaseSecurity.sol/abstract.BaseSecurity.md#usetransferfunction)


```solidity
function transferOwnership(address) public view override onlyOwner;
```

### _setupSecurity

Sets up the contract by initializing Ownable and ReentrancyGuard features.


```solidity
function _setupSecurity(address _owner) internal initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|The address to set as the owner of the contract.|


## Errors
### OwnershipCannotBeRenounced
Error thrown when ownership cannot be renounced.


```solidity
error OwnershipCannotBeRenounced();
```

### UseTransferFunction
Error thrown when transferOwnership is called directly.

Ownership transfers must go through the secure transfer() function, which enforces
all protocol invariants (updating the beneficiary, freezing the beacon, emitting
the Transferred event). Calling transferOwnership directly bypasses these invariants.


```solidity
error UseTransferFunction();
```

