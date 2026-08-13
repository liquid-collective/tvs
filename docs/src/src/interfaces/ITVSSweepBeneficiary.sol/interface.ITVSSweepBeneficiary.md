# ITVSSweepBeneficiary
[Git Source](https://github.com/liquid-collective/tvs/blob/73975467b58a06efd3cb21e22cbe8935ab4018be/src/interfaces/ITVSSweepBeneficiary.sol)

**Title:**
Sweep Beneficiary Interface

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

Interface for the TVS beneficiary contract to receive ETH from the TVS.

This interface is used to receive ETH from the TVS contract.

This interface should be implemented by a beneficiary contract if the contract is unable to receive direct ETH
transfers.

The TVS contract is the withdrawal credential of a set of validators in the system.


## Functions
### receiveETHFromTVS

Allows a contract to receive ETH from the TVS via the {sweepToBeneficiaryContract} function.

This function MUST be implemented by the TVS beneficiary contract, in order to use the
{sweepToBeneficiaryContract} function of the TVS.


```solidity
function receiveETHFromTVS() external payable;
```

