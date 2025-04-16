# ITVSSweepBeneficiary
[Git Source](https://github.com/liquid-collective/tvs/blob/74937b56cfb6ca2a00ba3057606cc7f6aeafe8f6/src/interfaces/ITVSSweepBeneficiary.sol)

Interface for the TVS beneficiary contract to receive ETH from the TVS.

*This interface is used to receive ETH from the TVS contract.*

*This interface should be implemented by a beneficiary contract if the contract is unable to receive direct ETH
transfers*

*The TVS contract is the withdrawal credential of a set of validators in the system.*


## Functions
### receiveETHFromTVS

Allows a contract to receive ETH from TVS via the `sweepToContract` function.

*This function MUST be implemented by the TVS beneficiary contract, in order to use the `sweepToContract`
function of the TVS.*


```solidity
function receiveETHFromTVS() external payable;
```

