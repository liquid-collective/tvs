# TVSDeployer
[Git Source](https://github.com/liquid-collective/tvs/blob/1bf363e8aab5490523d3f7e0ccba11b5e058d641/src/TVSDeployer.sol)

**Title:**
TVS Deployer

**Author:**
Originally authored by Alluvial Finance, Inc; contributed to The Liquid Foundation

Permissionless deployer for all TVS variants


## State Variables
### WITHDRAWAL_CONTRACT_ADDRESS
The address of the Pectra EL withdrawal contract


```solidity
address public constant WITHDRAWAL_CONTRACT_ADDRESS = 0x00000961Ef480Eb55e80D19ad83579A64c007002
```


### CONSOLIDATION_CONTRACT_ADDRESS
The address of the Pectra EL consolidation contract


```solidity
address public constant CONSOLIDATION_CONTRACT_ADDRESS = 0x0000BBdDc7CE488642fb579F8B00f3a590007251
```


### CLONE_IMPLEMENTATION
The address of the TVSClone implementation contract


```solidity
address public immutable CLONE_IMPLEMENTATION
```


### UPGRADEABLE_TVS_IMPLEMENTATION
The address of the TVSUpgradeable implementation contract


```solidity
address public immutable UPGRADEABLE_TVS_IMPLEMENTATION
```


## Functions
### constructor

Constructor for the TVSDeployer contract


```solidity
constructor(address _cloneImplementation, address _upgradeableTVSImplementation) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cloneImplementation`|`address`|The address of the TVSClone implementation contract|
|`_upgradeableTVSImplementation`|`address`|The address of the TVSUpgradeable implementation contract|


### deployClone

Deploys a new TVSClone proxy and initializes it

Emits a [TVSCloneDeployed](/src/TVSDeployer.sol/contract.TVSDeployer.md#tvsclonedeployed) event


```solidity
function deployClone(address beneficiary, address owner) external returns (address tvs);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address that will receive all ETH swept from the TVS|
|`owner`|`address`|The address that will have ownership rights over the TVS|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tvs`|`address`|The address of the deployed TVS proxy|


### deployImmutable

Deploys a new TVSImmutable contract

Emits a [TVSImmutableDeployed](/src/TVSDeployer.sol/contract.TVSDeployer.md#tvsimmutabledeployed) event


```solidity
function deployImmutable(address beneficiary, address owner) external returns (address tvs);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address that will receive all ETH swept from the TVS|
|`owner`|`address`|The address that will have ownership rights over the TVS|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tvs`|`address`|The address of the deployed TVS contract|


### deployFlexibleImmutable

Deploys a new TVSFlexibleImmutable contract

Emits a [TVSFlexibleImmutableDeployed](/src/TVSDeployer.sol/contract.TVSDeployer.md#tvsflexibleimmutabledeployed) event


```solidity
function deployFlexibleImmutable(address beneficiary, address owner) external returns (address tvs);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address that will receive all ETH swept from the TVS|
|`owner`|`address`|The address that will have ownership rights over the TVS|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tvs`|`address`|The address of the deployed TVS contract|


### deployUpgradeable

Deploys a new TVSUpgradeable (beacon proxy) and initializes it

Emits a [TVSUpgradeableDeployed](/src/TVSDeployer.sol/contract.TVSDeployer.md#tvsupgradeabledeployed) event

If a new beacon is deployed, it is deployed with the sender as the owner


```solidity
function deployUpgradeable(address beneficiary, address owner, address beacon) external returns (address tvs);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address that will receive all ETH swept from the TVS|
|`owner`|`address`|The address that will have ownership rights over the TVS|
|`beacon`|`address`|The address of the UpgradeableBeacon contract. If zero address, a new beacon will be deployed|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tvs`|`address`|The address of the deployed TVS proxy|


## Events
### TVSCloneDeployed
Emitted when a TVSClone contract is deployed


```solidity
event TVSCloneDeployed(address indexed tvs, address indexed implementation, address indexed owner);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tvs`|`address`|The address of the deployed TVSClone contract|
|`implementation`|`address`|The address of the TVSClone implementation contract|
|`owner`|`address`|The address of the owner of the TVSClone contract|

### TVSImmutableDeployed
Emitted when a TVSImmutable contract is deployed


```solidity
event TVSImmutableDeployed(address indexed tvs, address indexed owner);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tvs`|`address`|The address of the deployed TVSImmutable contract|
|`owner`|`address`|The address of the owner of the TVSImmutable contract|

### TVSFlexibleImmutableDeployed
Emitted when a TVSFlexibleImmutable contract is deployed


```solidity
event TVSFlexibleImmutableDeployed(address indexed tvs, address indexed owner);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tvs`|`address`|The address of the deployed TVSFlexibleImmutable contract|
|`owner`|`address`|The address of the owner of the TVSFlexibleImmutable contract|

### TVSUpgradeableDeployed
Emitted when a TVSUpgradeable contract is deployed


```solidity
event TVSUpgradeableDeployed(address indexed tvs, address indexed beacon, address indexed owner);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tvs`|`address`|The address of the deployed TVSUpgradeable contract|
|`beacon`|`address`|The address of the beacon contract|
|`owner`|`address`|The address of the owner of the TVSUpgradeable contract|

