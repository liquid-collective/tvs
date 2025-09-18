# ITVS
[Git Source](https://github.com/liquid-collective/tvs/blob/94694c515bd11d10170311c3c8bd350b25f11fb2/src/interfaces/ITVS.sol)

**Author:**
Alluvial Finance Inc.

Interface for the TVS contract.

*This interface is used to interact with the TVS contract.*

*The TVS contract is the withdrawal credential of a set of validators in the system.*


## Functions
### receive


```solidity
receive() external payable;
```

### sweep

Sweeps a specific amount, or all ETH on the TVS to the TVS beneficiary or a specified address.

*Only the owner can specify a custom beneficiary for the sweep*

*Emits [Swept](/src/interfaces/ITVS.sol/interface.ITVS.md#swept) event.*


```solidity
function sweep(address beneficiary, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|Address to which funds will be swept, if zero address, sweeps to the  beneficiary address set on the contract|
|`amount`|`uint256`|Amount of funds to sweep, if zero, sweeps all funds on contract|


### sweepToBeneficiaryContract

Sweeps a specific amount, or all ETH on the TVS to the TVS beneficiary contract or a specified
beneficiary contract address.

*Only the owner can specify a custom beneficiary for the sweep*

*Emits a [Swept](/src/interfaces/ITVS.sol/interface.ITVS.md#swept) event.*


```solidity
function sweepToBeneficiaryContract(address beneficiary, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|Address for the contract to which funds will be swept, if zero address, sweeps to the beneficiary address set on the contract|
|`amount`|`uint256`| Amount of funds to sweep, if zero, sweeps all funds on contract.|


### setBeneficiary

Sets a new beneficiary address for fund sweeping.

*Only the owner can call this function.*

*Emits a [BeneficiaryUpdated](/src/interfaces/ITVS.sol/interface.ITVS.md#beneficiaryupdated) event.*


```solidity
function setBeneficiary(address beneficiary) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|New beneficiary address.|


### transfer

Transfers the ownership of the TVS.

*This function sets a new beneficiary, transfers ownership to a new owner.*

*Only the owner can call this function.*

*Emits a [Transferred](/src/interfaces/ITVS.sol/interface.ITVS.md#transferred) event.*


```solidity
function transfer(address newBeneficiary, address newOwner) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBeneficiary`|`address`|The new beneficiary address.|
|`newOwner`|`address`|The new owner address.|


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
    payable;
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

*Both source and target validators (pubKeys) must be from the same TVS (this TVS).*

*The excess fee is the difference between the maximum fee and the actual fee paid.*

*Emits a [UnsentExcessFee](/src/interfaces/ITVS.sol/interface.ITVS.md#unsentexcessfee) event if the excess fee is not sent.*


```solidity
function consolidate(
    ConsolidationRequest[] memory requests,
    uint256 maxFeePerConsolidation,
    address excessFeeRecipient
)
    external
    payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requests`|`ConsolidationRequest[]`|An array of consolidation requests.|
|`maxFeePerConsolidation`|`uint256`|The maximum fee allowed per consolidation request.|
|`excessFeeRecipient`|`address`|The address to which excess fees will be sent.|


### getBeneficiary

Retrieves the current beneficiary address.


```solidity
function getBeneficiary() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the beneficiary.|


### version

Retrieves the version of the contract.


```solidity
function version() external pure returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|Version of the contract|


## Events
### Swept
Emitted when funds are swept to the beneficiary.


```solidity
event Swept(address indexed beneficiary, uint256 indexed amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address to which funds were swept.|
|`amount`|`uint256`|The amount of funds swept.|

### BeneficiaryUpdated
Emitted when the beneficiary address is updated.


```solidity
event BeneficiaryUpdated(address indexed newBeneficiary);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBeneficiary`|`address`|The new beneficiary address.|

### UnsentExcessFee
Emitted when the excess fee sent as part of a {consolidation}, or {withdrawal} - (partial or full)
request could not be refunded to the {excessFeeRecipient} recipient.


```solidity
event UnsentExcessFee(address indexed excessFeeRecipient, uint256 indexed excessFee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`excessFeeRecipient`|`address`|The address to which the excess fee should have been sent.|
|`excessFee`|`uint256`|The amount of excess fee sent.|

### Transferred
Emitted when the ownership of the TVS is transferred to a new owner.


```solidity
event Transferred(address indexed newBeneficiary, address indexed newOwner);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBeneficiary`|`address`|The address of the new beneficiary.|
|`newOwner`|`address`|The address of the new owner.|

### WithdrawalRequested
Emitted when a withdrawal request is submitted for a validator.


```solidity
event WithdrawalRequested(bytes pubkey, uint64 indexed amount, uint256 indexed fee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pubkey`|`bytes`|The public key of the validator.|
|`amount`|`uint64`|The amount to withdraw from the validator.|
|`fee`|`uint256`|The fee paid for the withdrawal.|

### ConsolidationRequested
Emitted when a consolidation request is submitted.


```solidity
event ConsolidationRequested(bytes srcPubkey, bytes targetPubkey, uint256 indexed fee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`srcPubkey`|`bytes`|The public key of the source validator.|
|`targetPubkey`|`bytes`|The public key of the target validator.|
|`fee`|`uint256`|The fee paid for the consolidation.|

## Errors
### InvalidAddress
Error thrown when an invalid address is provided for any reason.


```solidity
error InvalidAddress();
```

### Unauthorized
Error thrown when an unauthorized access attempt is made.


```solidity
error Unauthorized(address caller);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`caller`|`address`|The address of the caller attempting unauthorized access.|

### InsufficientBalance
Error thrown when an attempt to sweep more funds than available is made.


```solidity
error InsufficientBalance(uint256 available, uint256 required);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`available`|`uint256`|The amount of funds currently available for sweeping.|
|`required`|`uint256`|The amount of funds that were requested to be swept.|

### FeeTooHigh
Error thrown when a fee exceeds the maximum allowed.

*This error is associated with the {consolidation} and {withdrawal} functions*


```solidity
error FeeTooHigh(uint256 currentFee, uint256 maxAllowedFee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentFee`|`uint256`|The current fee for the operation.|
|`maxAllowedFee`|`uint256`|The maximum allowed fee that can be paid.|

### LengthMismatch
Error thrown when the length of input arrays does not match.


```solidity
error LengthMismatch(uint256 expected, uint256 actual);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`expected`|`uint256`|The expected length of the input arrays.|
|`actual`|`uint256`|The actual length of the input arrays provided.|

### FeeReadFailed
Error thrown when reading the fee fails.

*This error is associated with the {consolidation} and {withdrawal} functions, which read the fee from the
associated pectra EL contracts.*


```solidity
error FeeReadFailed();
```

### RequestFailed
Error thrown when adding a consolidation or withdraw request fails.


```solidity
error RequestFailed();
```

### InsufficientValueForFee
Error thrown when the value provided is insufficient for the fee.

*This error is associated with the {consolidation} and {withdrawal} functions, which interact with the
associated pectra EL contracts.*


```solidity
error InsufficientValueForFee(uint256 value, uint256 totalFee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`value`|`uint256`|The value provided.|
|`totalFee`|`uint256`|The total fee required.|

### TransferFailed
Error thrown when a TVS transfer couldn't be completed.


```solidity
error TransferFailed();
```

### InvalidPubkeyLength
Error thrown when the length of a pubkey is invalid.


```solidity
error InvalidPubkeyLength(uint256 length);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`length`|`uint256`|The length of the pubkey.|

## Structs
### ConsolidationRequest
Struct to represent a consolidation request.


```solidity
struct ConsolidationRequest {
    bytes[] srcPubkeys;
    bytes targetPubkey;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`srcPubkeys`|`bytes[]`|The public keys of the validators to consolidate from.|
|`targetPubkey`|`bytes`|The public key of the validator to consolidate to.|

