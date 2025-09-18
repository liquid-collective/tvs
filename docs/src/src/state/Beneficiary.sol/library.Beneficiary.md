# Beneficiary
[Git Source](https://github.com/liquid-collective/tvs/blob/94694c515bd11d10170311c3c8bd350b25f11fb2/src/state/Beneficiary.sol)

**Author:**
Alluvial Finance Inc.

This library manages the beneficiary address for the TVS proxy contract

*The beneficiary address is the address to which all funds are swept to when a {sweep} operation is performed*

*The proxy contract is expected to have a `BENEFICIARY_SLOT` slot that stores the beneficiary address*


## State Variables
### BENEFICIARY_SLOT
Slot for the beneficiary address

*This slot is used to store the beneficiary address for the proxy contract*


```solidity
bytes32 internal constant BENEFICIARY_SLOT = bytes32(uint256(keccak256("tvs.state.beneficiary")) - 1);
```


## Functions
### set

Set the beneficiary address


```solidity
function set(address _newBeneficiary) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_newBeneficiary`|`address`|The new beneficiary address|


### get

Get the beneficiary address


```solidity
function get() internal view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The beneficiary address|


