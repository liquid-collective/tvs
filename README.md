# <h1 align="center"> TVS Reference Implementation </h1>

**A transferable validator set (TVS) is a set of `n` validators sharing the same smart contract for their withdrawal credentials, whose ownership can be transferred to a new owner.**

This repository provides a reference implementation for deploying and managing a transferable validator set using smart contracts.

---

## Audits 

These smart contracts have been audited by Certora and Quantstamp. The audit reports can be found in the [audits directory](./audits).

## Features

- **Immutable Beacon Factory**: Deploys and manages immutable beacon proxies.
- **Upgradeable Contracts**: Supports upgradeable implementations for flexibility.
- **Deployment Scripts**: Automates deployment and ensures reusability across different networks.
- **Integration with Foundry**: Uses Foundry for testing, deployment, and cheat codes.

---

## Getting Started

### Prerequisites

- Install [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- Ensure you have a local Ethereum node or RPC URL for deployment and testing.

### Installation

To install dependencies:
```bash
git clone https://github.com/your-repo/tvs-reference-implementation.git
cd tvs-reference-implementation
forge install
yarn install
```

### Run Tests
```bash 
forge test
```

### Deployment

1. Configure Environment Variables: Update the .env file with the necessary details:

- BENEFICIARY: Address to receive validator rewards.
- OWNER: Address of the contract owner.
- RPC_URL: RPC URL for the blockchain network.
- PRIVATE_KEY: Private key for deployment.

    Optionally, specify addresses for pre-deployed contracts:

- IMMUTABLE_BEACON_FACTORY
- TVS_CLONE_IMPLEMENTATION
- TVS_UPGRADEABLE_IMPLEMENTATION
- UPGRADEABLE_BEACON

    If these are not specified, the deployment script will use the last deployment address from the broadcast folder.


### Deployment Order and Dependencies

1. Deploy Immutable Beacon Factory:
```bash
make deploy-ImmutableBeaconFactory
```

- Dependency: None.
- Purpose: Deploys the `ImmutableBeaconFactory` contract, which is required for deploying other contracts like `TVSUpgradeable`.

2. Deploy TVS Upgradeable Implementation:

```bash
make deploy-TVSUpgradeableImplementation
```
- Dependency: `ImmutableBeaconFactory` must be deployed first or env `IMMUTABLE_BEACON_FACTORY` should be set.
- Purpose: Deploys the `TVSUpgradeable` implementation contract, which is used by the `UpgradeableBeacon`

3. Deploy Upgradeable Beacon:

```bash
make deploy-UpgradeableBeacon
```

- Dependency: `TVSUpgradeableImplementation` must be deployed first or env `TVS_UPGRADEABLE_IMPLEMENTATION` should be set.
- Purpose: Deploys the `UpgradeableBeacon` implementation contract, which points to the `TVSUpgradeable` implementation

4. Deploy TVS Upgradeable:

```bash
make deploy-TVSUpgradeable
```

- Dependency: `UpgradeableBeacon` must be deployed first or env `UPGRADEABLE_BEACON` should be set.
- Deploys the `TVSBeaconProxy` contract, which uses the `UpgradeableBeacon` for upgradeable functionality.

5. Deploy TVS Clone Implementation:

```bash
make deploy-TVSCloneImplementation
```

- Dependency: None.
- Purpose: Deploys the `TVSClone` implementation contract, which is used for creating clone proxies.


6. Deploy Immutable Beacon Factory:
```bash
make clone-TVS
```

- Dependency: `TVSCloneImplementation` must be deployed first or env for `TVS_CLONE_IMPLEMENTATION` set.
- Purpose: Deploys a clone proxy of the `TVSClone` implementation using the minimal proxy pattern.


7. Deploy TVS Flexible Immutable:

```bash
make deploy-TVSFlexibleImmutable
```

- Dependency: None.
- Purpose: Deploys a flexible immutable contract.

### Deployment Notes
- ImmutableBeaconFactory: This contract is a foundational component and must be deployed first if TVSUpgradeable or other contracts depend on it.
- UpgradeableBeacon: Acts as a pointer to the TVSUpgradeableImplementation and must be deployed before deploying the TVSBeaconProxy.
- TVSClone: Uses the minimal proxy pattern and requires the TVSCloneImplementation to be deployed first.
- Environment Variables: Ensure all required variables are set in the .env file before running the deployment scripts.

## Folder Structure
- src/: Contains the core smart contracts
- script/: Deployment scripts for automating contract deployment.
- test/: Unit tests for the smart contracts.
- broadcast/: Stores deployment artifacts and addresses for reuse.

## Contributing
Contributions are welcome! Please fork the repository and submit a pull request with your changes.

## License
See the LICENSE file for details.
