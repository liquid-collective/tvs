# ITVS
[Git Source](https://github.com/liquid-collective/tvs/blob/3c7308137aaf51079c5881c944f3f47ae5a7cb85/src/interfaces/ITVS.sol)

**Title:**
TVS Interface

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

Interface for the TVS contract.

This interface is used to interact with the TVS contract.

The TVS contract is the withdrawal credential of a set of validators in the system.


## Functions
### receive

Receive function to accept ETH transfers.


```solidity
receive() external payable;
```

### sweep

Sweeps a specific amount, or all ETH on the TVS to the TVS beneficiary or a specified address.

Only the owner can specify a custom beneficiary for the sweep.

Emits a [Swept](/src/interfaces/ITVS.sol/interface.ITVS.md#swept) event.


```solidity
function sweep(address beneficiary, uint256 amount) external;
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

Emits a [Swept](/src/interfaces/ITVS.sol/interface.ITVS.md#swept) event.


```solidity
function sweepToBeneficiaryContract(address beneficiary, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|Address of the contract to which funds will be swept. If zero address, sweeps to the beneficiary address set on the contract.|
|`amount`|`uint256`|Amount of funds to sweep. If zero, sweeps all funds on the contract.|


### setBeneficiary

Sets a new beneficiary address for fund sweeping.

Only the owner can call this function.

Emits a [BeneficiaryUpdated](/src/interfaces/ITVS.sol/interface.ITVS.md#beneficiaryupdated) event.


```solidity
function setBeneficiary(address beneficiary) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|New beneficiary address.|


### transfer

Transfers the ownership of the TVS.

This function sets a new beneficiary, transfers ownership to a new owner.

Only the owner can call this function.

Emits a [Transferred](/src/interfaces/ITVS.sol/interface.ITVS.md#transferred) event.


```solidity
function transfer(address newBeneficiary, address newOwner) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBeneficiary`|`address`|The new beneficiary address.|
|`newOwner`|`address`|The new owner address.|


### withdraw

Adds a withdrawal request to the Pectra EL withdrawal contract for the specified validators.

Only the owner can call this function.

Emits an [UnsentExcessFee](/src/interfaces/ITVS.sol/interface.ITVS.md#unsentexcessfee) event if the excess fee is not sent.


```solidity
function withdraw(
    bytes[] calldata pubkeys,
    uint64[] calldata amounts,
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
|`amounts`|`uint64[]`|The amount in gwei to withdraw from each validator, in the same order as `pubkeys`. Zero indicates a full withdrawal (validator exit).|
|`maxFeePerWithdrawal`|`uint256`|The maximum fee allowed per withdrawal.|
|`excessFeeRecipient`|`address`|The address to which excess fees will be sent.|


### consolidate

Adds a consolidation request to the Pectra EL consolidation contract for the given source validators.

Only the owner can call this function.

Both source and target validators (pubkeys) must be from the same TVS (this TVS).

The excess fee is the difference between the maximum fee and the actual fee paid.

Emits an [UnsentExcessFee](/src/interfaces/ITVS.sol/interface.ITVS.md#unsentexcessfee) event if the excess fee is not sent.


```solidity
function consolidate(
    ConsolidationRequest[] calldata requests,
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
|`<none>`|`string`|The version of the contract.|


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
Emitted when the excess fee sent as part of a [consolidate](/src/interfaces/ITVS.sol/interface.ITVS.md#consolidate) or [withdraw](/src/interfaces/ITVS.sol/interface.ITVS.md#withdraw) (partial or full) request
could not be refunded to the excess fee recipient.


```solidity
event UnsentExcessFee(address indexed excessFeeRecipient, uint256 indexed excessFee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`excessFeeRecipient`|`address`|The address to which the excess fee should have been sent.|
|`excessFee`|`uint256`|The amount of excess fee that could not be refunded.|

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

This error is associated with the [consolidate](/src/interfaces/ITVS.sol/interface.ITVS.md#consolidate) and [withdraw](/src/interfaces/ITVS.sol/interface.ITVS.md#withdraw) functions.


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

This error is associated with the [consolidate](/src/interfaces/ITVS.sol/interface.ITVS.md#consolidate) and [withdraw](/src/interfaces/ITVS.sol/interface.ITVS.md#withdraw) functions, which read the fee from the
associated Pectra EL contracts.


```solidity
error FeeReadFailed();
```

### RequestFailed
Error thrown when adding a consolidation or withdrawal request fails.


```solidity
error RequestFailed();
```

### InsufficientValueForFee
Error thrown when the value provided is insufficient for the fee.

This error is associated with the [consolidate](/src/interfaces/ITVS.sol/interface.ITVS.md#consolidate) and [withdraw](/src/interfaces/ITVS.sol/interface.ITVS.md#withdraw) functions, which interact with the
associated Pectra EL contracts.


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

