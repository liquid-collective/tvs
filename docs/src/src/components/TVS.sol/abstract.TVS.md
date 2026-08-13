# TVS
[Git Source](https://github.com/liquid-collective/tvs/blob/3c7308137aaf51079c5881c944f3f47ae5a7cb85/src/components/TVS.sol)

**Inherits:**
[ITVS](/src/interfaces/ITVS.sol/interface.ITVS.md), [BaseSecurity](/src/components/BaseSecurity.sol/abstract.BaseSecurity.md)

**Title:**
Transferable Validator Set (TVS - v1)

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

Implementation of the TVS


## Constants
### WITHDRAWAL_CONTRACT_ADDRESS
The address of the Pectra EL withdrawal contract.


```solidity
address public immutable WITHDRAWAL_CONTRACT_ADDRESS
```


### CONSOLIDATION_CONTRACT_ADDRESS
The address of the Pectra EL consolidation contract.


```solidity
address public immutable CONSOLIDATION_CONTRACT_ADDRESS
```


## Functions
### constructor

Constructor for the TVS contract

Initializes the contract with the Pectra withdrawal and consolidation EL contract addresses

The withdrawal and consolidation addresses are stored as immutable state variables. They can only be set
once here in the constructor

All implementation versions of TVS **MUST** have this constructor, to ensure the correct addresses are set


```solidity
constructor(address withdrawalContractAddress, address consolidationContractAddress) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalContractAddress`|`address`|The address of the withdrawal contract|
|`consolidationContractAddress`|`address`|The address of the consolidation contract|


### receive

Receive function to accept ETH transfers.


```solidity
receive() external payable;
```

### withdraw

Adds a withdrawal request to the Pectra EL withdrawal contract for the specified validators.

Only the owner can call this function.


```solidity
function withdraw(
    bytes[] calldata pubkeys,
    uint64[] calldata amounts,
    uint256 maxFeePerWithdrawal,
    address excessFeeRecipient
)
    external
    payable
    nonReentrant
    onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pubkeys`|`bytes[]`|The public keys of the validators to withdraw from.|
|`amounts`|`uint64[]`|The amount in gwei to withdraw from each validator, in the same order as `pubkeys`. Zero indicates a full withdrawal (validator exit).|
|`maxFeePerWithdrawal`|`uint256`|The maximum fee allowed per withdrawal.|
|`excessFeeRecipient`|`address`|The address to which excess fees will be sent.|


### consolidate

Adds a consolidation request to the Pectra EL consolidation contract for the given source validators.

Only the owner can call this function.


```solidity
function consolidate(
    ConsolidationRequest[] calldata requests,
    uint256 maxFeePerConsolidation,
    address excessFeeRecipient
)
    external
    payable
    nonReentrant
    onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requests`|`ConsolidationRequest[]`|An array of consolidation requests.|
|`maxFeePerConsolidation`|`uint256`|The maximum fee allowed per consolidation request.|
|`excessFeeRecipient`|`address`|The address to which excess fees will be sent.|


### sweep

Sweeps a specific amount, or all ETH on the TVS to the TVS beneficiary or a specified address.

Only the owner can specify a custom beneficiary for the sweep.


```solidity
function sweep(address beneficiary, uint256 amount) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|Address to which funds will be swept. If zero address, sweeps to the beneficiary address set on the contract.|
|`amount`|`uint256`|Amount of funds to sweep. If zero, sweeps all funds on the contract.|


### sweepToBeneficiaryContract

Sweeps a specific amount, or all ETH on the TVS to the TVS beneficiary contract or a specified
beneficiary contract address.

Only the owner can specify a custom beneficiary for the sweep.


```solidity
function sweepToBeneficiaryContract(address beneficiary, uint256 amount) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|Address of the contract to which funds will be swept. If zero address, sweeps to the beneficiary address set on the contract.|
|`amount`|`uint256`|Amount of funds to sweep. If zero, sweeps all funds on the contract.|


### setBeneficiary

Sets a new beneficiary address for fund sweeping.

Only the owner can call this function.


```solidity
function setBeneficiary(address newBeneficiary) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBeneficiary`|`address`||


### getBeneficiary

Retrieves the current beneficiary address.


```solidity
function getBeneficiary() public view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the beneficiary.|


### _transfer

Internal function to transfer the TVS to a new beneficiary and owner.

Emits a {Transferred} event.


```solidity
function _transfer(address _beneficiary, address _owner) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_beneficiary`|`address`|The address of the new beneficiary.|
|`_owner`|`address`|The address of the new owner.|


### _setBeneficiary

Internal function to set the beneficiary address.

Emits a {BeneficiaryUpdated} event.


```solidity
function _setBeneficiary(address _newBeneficiary) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_newBeneficiary`|`address`|The address of the new beneficiary.|


### _refundExcessFee

Internal function to refund the excess fee for Pectra-related operations.

Emits an {UnsentExcessFee} event if the refund could not be sent.


```solidity
function _refundExcessFee(
    uint256 _totalValueReceived,
    uint256 _totalFeePaid,
    address _excessFeeRecipient
)
    internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_totalValueReceived`|`uint256`|The total value received.|
|`_totalFeePaid`|`uint256`|The total fee paid.|
|`_excessFeeRecipient`|`address`|The address of the excess fee recipient.|


### _validateAndReturnFee

Internal function to validate the fee. Used for Pectra-related operations.

Reverts if the fee is higher than the maximum allowed fee, or if the fee read fails.


```solidity
function _validateAndReturnFee(address _feeContract, uint256 _maxAllowedFee) internal view returns (uint256 _fee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_feeContract`|`address`|The address of the fee contract.|
|`_maxAllowedFee`|`uint256`|The maximum allowed fee.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_fee`|`uint256`|The fee.|


### _validateSufficientValueForFee

Internal function to validate the caller sent sufficient value for the fee. Used for Pectra-related
operations.


```solidity
function _validateSufficientValueForFee(uint256 _value, uint256 _totalFee) internal pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_value`|`uint256`|The value sent by the caller.|
|`_totalFee`|`uint256`|The total fee.|


### _validatePubkeyLength

Internal function to validate that a public key is exactly 48 bytes in length.


```solidity
function _validatePubkeyLength(bytes memory _pubkey) internal pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_pubkey`|`bytes`|The public key to validate.|


### _sweep

Internal function to resolve the destination and amount of a sweep.

Only the owner can specify a custom beneficiary for the sweep.

Emits a {Swept} event.


```solidity
function _sweep(address _beneficiary, uint256 _amount) private returns (address _dest, uint256 _amountToSweep);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_beneficiary`|`address`|The address of the beneficiary.|
|`_amount`|`uint256`|The amount to sweep.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_dest`|`address`|The address of the destination.|
|`_amountToSweep`|`uint256`|The amount to sweep.|


