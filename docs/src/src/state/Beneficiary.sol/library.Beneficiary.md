# Beneficiary
[Git Source](https://github.com/liquid-collective/tvs/blob/1bf363e8aab5490523d3f7e0ccba11b5e058d641/src/state/Beneficiary.sol)

**Title:**
Beneficiary

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

This library manages the beneficiary address for the TVS proxy contract

The beneficiary address is the address to which all funds are swept when a {sweep} operation is performed

The proxy contract is expected to store the beneficiary address in the `BENEFICIARY_SLOT` slot


## State Variables
### BENEFICIARY_SLOT
Slot for the beneficiary address

This slot is used to store the beneficiary address for the proxy contract


```solidity
bytes32 internal constant BENEFICIARY_SLOT = bytes32(uint256(keccak256("tvs.state.beneficiary")) - 1)
```


## Functions
### set

Set the beneficiary address


```solidity
function set(address newBeneficiary) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBeneficiary`|`address`|The new beneficiary address|


### get

Get the beneficiary address


```solidity
function get() internal view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The beneficiary address|


