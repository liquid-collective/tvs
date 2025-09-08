# TVS
[Git Source](https://github.com/liquid-collective/tvs/blob/f5c73298c5c83b0c84fd88c0b4e9e6669cf53875/src/components/TVS.sol)

**Inherits:**
[ITVS](/src/interfaces/ITVS.sol/interface.ITVS.md), [BaseSecurity](/src/components/BaseSecurity.sol/abstract.BaseSecurity.md)

**Author:**
Alluvial Finance Inc.

implementation of the TVS


## State Variables
### WITHDRAWAL_CONTRACT_ADDRESS
The address of the pectra EL withdrawal contract.


```solidity
address public immutable WITHDRAWAL_CONTRACT_ADDRESS;
```


### CONSOLIDATION_CONTRACT_ADDRESS
The address of the pectra EL consolidation contract.


```solidity
address public immutable CONSOLIDATION_CONTRACT_ADDRESS;
```


## Functions
### constructor

Constructor for the TVS contract

*Initializes the contract with Pectra withdrawal and consolidation EL contract addresses.*

*The withdrawal and consolidation addresses are stored as immutable state variables. they can only be set
once here in the constructor.*

*All implementation versions of TVS **MUST** have this constructor, to ensure the correct addresses are set,
and available to the proxy*


```solidity
constructor(address withdrawalContractAddress, address consolidationContractAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalContractAddress`|`address`|The address of the withdrawal contract|
|`consolidationContractAddress`|`address`|The address of the consolidation contract|


### receive


```solidity
receive() external payable;
```

### withdraw

Adds a withdrawal request to the pectra EL withdrawal contract for a specified validator.

*Only the owner can call this function.*


```solidity
function withdraw(
    bytes[] memory pubkeys,
    uint64[] calldata amount,
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
|`amount`|`uint64[]`|The amount in gwei to withdraw from each validator. Zero indicates a full withdrawal (validator exit).|
|`maxFeePerWithdrawal`|`uint256`|The maximum fee allowed per withdrawal.|
|`excessFeeRecipient`|`address`|The address to which excess fees will be sent.|


### consolidate

Adds a consolidation request to the pectra EL consolidation contract for the given source validators.

*Only the owner can call this function.*


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

*Only the owner can specify a custom beneficiary for the sweep*


```solidity
function sweep(address recipient, uint256 amount) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`||
|`amount`|`uint256`|Amount of funds to sweep, if zero, sweeps all funds on contract|


### sweepToBeneficiaryContract

Sweeps a specific amount, or all ETH on the TVS to the TVS beneficiary contract or a specified
beneficiary contract address.

*Only the owner can specify a custom beneficiary for the sweep*


```solidity
function sweepToBeneficiaryContract(address beneficiary, uint256 amount) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|Address for the contract to which funds will be swept, if zero address, sweeps to the beneficiary address set on the contract|
|`amount`|`uint256`| Amount of funds to sweep, if zero, sweeps all funds on contract.|


### setBeneficiary

Sets a new beneficiary address for fund sweeping.

*Only the owner can call this function.*


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

*This function is used to transfer the TVS to a new beneficiary and owner.*


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


```solidity
function _setBeneficiary(address _newBeneficiary) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_newBeneficiary`|`address`|The address of the new beneficiary.|


### _refundExcessFee

*Internal function to refund the excess fee for pectra related operations.*


```solidity
function _refundExcessFee(uint256 _totalValueReceived, uint256 _totalFeePaid, address _excessFeeRecipient) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_totalValueReceived`|`uint256`|The total value received.|
|`_totalFeePaid`|`uint256`|The total fee paid.|
|`_excessFeeRecipient`|`address`|The address of the excess fee recipient.|


### _validateAndReturnFee

*Internal function to validate the fee. Used for pectra related operations.*

*Reverts if the fee is higher than the maximum allowed fee, or if the fee read fails.*


```solidity
function _validateAndReturnFee(address feeContract, uint256 _maxAllowedFee) internal view returns (uint256 _fee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeContract`|`address`|The address of the fee contract.|
|`_maxAllowedFee`|`uint256`|The maximum allowed fee.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_fee`|`uint256`|The fee.|


### _validateSufficientValueForFee

*Internal function to validate the caller sent sufficient value for fee. Used for pectra related operations.*


```solidity
function _validateSufficientValueForFee(uint256 _value, uint256 _totalFee) internal pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_value`|`uint256`|The value.|
|`_totalFee`|`uint256`|The total fee.|


### _validatePubkeyLength

*Internal function to validate that a public key is exactly 48 bytes in length*


```solidity
function _validatePubkeyLength(bytes memory pubkey) internal pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pubkey`|`bytes`|The public key to validate|


### _sweep

*Internal function to sweep the TVS.*


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
|`_dest`|`address`|The address of the _destination.|
|`_amountToSweep`|`uint256`|The amount to sweep.|


