# TVSUpgradeable
[Git Source](https://github.com/liquid-collective/tvs/blob/03c48a2bf3813d683a089f40751b05bbe6f7f34c/src/TVSUpgradeable/TVSUpgradeable.sol)

**Inherits:**
[ITVSUpgradeable](/Users/praffulsahu/Documents/GitHub/tvs/docs/src/src/TVSUpgradeable/interfaces/ITVSUpgradeable.sol/interface.ITVSUpgradeable.md), [TVS](/Users/praffulsahu/Documents/GitHub/tvs/docs/src/src/components/TVS.sol/abstract.TVS.md)

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

Upgradeable implementation of the TVS

This contract provides an upgradeable version of the TVS using a beacon proxy pattern


## State Variables
### immutableBeacon
The address of the immutable beacon contract

During a TVS transfer, the beacon is temporarily set to this immutable beacon. This variable ensures that
the current TVS Implementation is frozen, preventing the oldOwner from modifying the TVS Implementation in
the beacon


```solidity
address public immutable immutableBeacon
```


## Functions
### constructor

Constructs a new TVSUpgradeable instance

Initializes the contract with Pectra withdrawal and consolidation EL contract addresses, and the immutable
beacon factory address.

The withdrawal and consolidation addresses are stored as immutable state variables. they can only be set
once here in the constructor.


```solidity
constructor(
    address withdrawalContractAddress,
    address consolidationContractAddress,
    address immutableBeaconFactory
)
    TVS(withdrawalContractAddress, consolidationContractAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalContractAddress`|`address`|The address of the withdrawal contract|
|`consolidationContractAddress`|`address`|The address of the consolidation contract|
|`immutableBeaconFactory`|`address`|The address of the immutable beacon factory. This is used once in the constructor to deploy a new immutable beacon contract for the TVS, and this factory address is not persisted on the TVS contract.|


### initialize

Initializes the TVS upgradeable instance

This function can only be called once during the TVS deployment and sets up the initial security, owner,
beneficiary, and beacon address of the TVS


```solidity
function initialize(address beneficiary, address owner, address beaconAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address that will receive all ETH swept from the TVS|
|`owner`|`address`|The address that will have ownership rights over the TVS|
|`beaconAddress`|`address`|The address of the beacon contract|


### transfer

Transfers the ownership of the TVS.

This function sets a new beneficiary, transfers ownership to a new owner.


```solidity
function transfer(address newBeneficiary, address newOwner) external override onlyOwner nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBeneficiary`|`address`|The new beneficiary address.|
|`newOwner`|`address`|The new owner address.|


### setBeaconUnchecked

This function is used by the [setBeacon](//Users/praffulsahu/Documents/GitHub/tvs/docs/src/src/TVSUpgradeable/TVSUpgradeable.sol/contract.TVSUpgradeable.md#setbeacon) function to directly set the beacon address without
additional checks

This function should not be called directly, but only through the [setBeacon](//Users/praffulsahu/Documents/GitHub/tvs/docs/src/src/TVSUpgradeable/TVSUpgradeable.sol/contract.TVSUpgradeable.md#setbeacon) function, it allows the
[setBeacon](//Users/praffulsahu/Documents/GitHub/tvs/docs/src/src/TVSUpgradeable/TVSUpgradeable.sol/contract.TVSUpgradeable.md#setbeacon) perform robust checks before setting the new beacon

Emits a {BeaconUpgraded} event

Only callable by the contract owner


```solidity
function setBeaconUnchecked(address newBeacon) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBeacon`|`address`|The new beacon address|


### setBeacon

Sets a new beacon address for the TVS.

Only the owner can call this function.


```solidity
function setBeacon(address newBeacon) external onlyOwner nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBeacon`|`address`||


### beacon

Retrieves the current beacon address.


```solidity
function beacon() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the beacon.|


### version

Retrieves the version of the contract.


```solidity
function version() external pure returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|Version of the contract|


### _setBeacon

Internal function to set the beacon address

This function is used internally to set the beacon address

This function uses the functionDelegateCall exposed by the OpenZeppelin Address contract to delegate the
call to the implementation contract, and reverts if the call fails


```solidity
function _setBeacon(address _beacon) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_beacon`|`address`|The address of the new beacon contract|


