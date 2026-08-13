# <h1 align="center"> TVS Reference Implementation </h1>

**A Transferable Validator Set (TVS) is a smart contract used as the withdrawal credential for a set of Ethereum validators, whose ownership can be transferred to a new owner.**

This repository provides multiple implementations of TVS smart contracts covering a range of deployment patterns: immutable, clone (minimal proxy), flexible immutable, and upgradeable (beacon proxy). A permissionless `TVSDeployer` factory contract is included for deploying any variant in a single call.

---

## Audits

These smart contracts have been audited by Certora and Quantstamp. The audit reports can be found in the [audits directory](./audits).

## Core Concepts

Every TVS contract:

- Acts as the **withdrawal credential** for one or more Ethereum validators.
- Has an **owner** who can trigger Pectra EL withdrawal and consolidation requests, sweep ETH, and transfer ownership.
- Has a **beneficiary** address that receives swept ETH.
- Supports **Pectra EL operations**: partial/full withdrawals via the EL withdrawal contract (`0x00000961Ef480Eb55e80D19ad83579A64c007002`) and validator consolidations via the EL consolidation contract (`0x0000BBdDc7CE488642fb579F8B00f3a590007251`).
- Implements `sweep` / `sweepToBeneficiaryContract` to move ETH out of the TVS.
- Implements `transfer` to atomically change both the beneficiary and the owner.
- Prevents accidental ownership renouncement.

---

## Contract Variants

### Non-Upgradeable

| Contract | Description |
|---|---|
| **`TVSImmutable`** | Fully immutable TVS. All parameters (beneficiary, owner, withdrawal/consolidation addresses) are set in the constructor. Cheapest to interact with post-deployment. |
| **`TVSFlexibleImmutable`** | Extends `TVSImmutable` with an `executeCall` / `executeBatch` interface that lets the owner perform arbitrary low-level calls and delegate calls. Provides forward-compatibility with future on-chain features without upgradeability. |
| **`TVSClone`** | An EIP-1167 minimal-proxy-compatible implementation. A single `TVSClone` implementation is deployed once, and cheap clones are created from it. Each clone is initialized with its own beneficiary and owner via `initialize()`. Non-upgradeable despite using the proxy pattern. |

### Upgradeable

| Contract | Description |
|---|---|
| **`TVSUpgradeable`** | Upgradeable TVS implementation using the **beacon proxy** pattern. Each instance is a `TVSBeaconProxy` that delegates to a shared `UpgradeableBeacon`, which in turn points to the `TVSUpgradeable` implementation. The beacon owner can upgrade all proxies at once by changing the beacon's implementation pointer. |
| **`TVSBeaconProxy`** | A lightweight proxy that reads its implementation address from a beacon contract at runtime, using the EIP-1967 beacon slot. Deployed per-TVS instance. |

### Beacon & Factory Contracts

| Contract | Description |
|---|---|
| **`ImmutableBeacon`** | A beacon whose implementation address is set once in the constructor and **can never be changed**. Used during `TVSUpgradeable.transfer()` to freeze the implementation so that the previous owner cannot swap it out mid-transfer. |
| **`ImmutableBeaconFactory`** | A factory that deploys new `ImmutableBeacon` instances. Called by the `TVSUpgradeable` constructor to create the frozen beacon used during transfers. Implements `IImmutableBeaconFactory`. |

### TVSDeployer (Permissionless Factory)

The **`TVSDeployer`** contract is a single entry-point for deploying any TVS variant. It is constructed with references to the `TVSClone` implementation and the `TVSUpgradeable` implementation, and exposes:

| Function | Deploys |
|---|---|
| `deployClone(beneficiary, owner)` | A new EIP-1167 clone of the `TVSClone` implementation, initialized in the same transaction. |
| `deployImmutable(beneficiary, owner)` | A new `TVSImmutable` instance. |
| `deployFlexibleImmutable(beneficiary, owner)` | A new `TVSFlexibleImmutable` instance. |
| `deployUpgradeable(beneficiary, owner, beacon)` | A new `TVSBeaconProxy` pointing to the given beacon. If `beacon` is the zero address, a new `UpgradeableBeacon` is deployed automatically with `msg.sender` as the beacon owner. |

### Shared Components

| Contract / Library | Description |
|---|---|
| **`TVS`** (abstract) | Core TVS logic: withdraw, consolidate, sweep, setBeneficiary, transfer. Inherited by all variants. |
| **`BaseSecurity`** (abstract) | Ownership (OwnableUpgradeable) + reentrancy guard (transient storage). Works for both upgradeable and non-upgradeable variants. |
| **`TVSImmutableBase`** (abstract) | Base for all non-upgradeable variants. Adds `transfer()` and `version()`. |
| **`Beneficiary`** (library) | Manages the beneficiary address in a dedicated storage slot. |
| **`Beacon`** (library) | Manages the beacon address in an EIP-1967-compatible storage slot. |

### Interfaces

| Interface | Purpose |
|---|---|
| `ITVS` | Core TVS interface (sweep, withdraw, consolidate, transfer, setBeneficiary). |
| `ITVSUpgradeable` | Extends `ITVS` with `setBeacon()` and `beacon()`. |
| `ITVSFlexibleImmutable` | Standalone interface declaring `executeCall()` and `executeBatch()` for arbitrary calls. It does not inherit `ITVS` — `TVSFlexibleImmutable` implements both independently. |
| `IImmutableBeaconFactory` | Interface for deploying new `ImmutableBeacon` instances. |
| `ITVSSweepBeneficiary` | Interface a beneficiary contract must implement to receive ETH via `sweepToBeneficiaryContract()`. |

---

## Project Structure

```
src/
  components/
    TVS.sol                          # Core TVS logic (abstract)
    BaseSecurity.sol                 # Ownership + reentrancy guard (abstract)
  interfaces/
    ITVS.sol                         # Core TVS interface
    ITVSSweepBeneficiary.sol         # Beneficiary contract interface
  state/
    Beneficiary.sol                  # Beneficiary storage library
  TVSNonUpgradeable/
    TVSImmutableBase.sol             # Base for non-upgradeable variants
    TVSImmutable.sol                 # Immutable TVS
    TVSFlexibleImmutable.sol         # Immutable TVS + arbitrary calls
    TVSClone.sol                     # EIP-1167 clone implementation
    interfaces/
      ITVSFlexibleImmutable.sol
  TVSUpgradeable/
    TVSUpgradeable.sol               # Upgradeable TVS (beacon proxy pattern)
    ImmutableBeacon.sol              # Frozen beacon (used during transfer)
    ImmutableBeaconFactory.sol       # Factory for ImmutableBeacon
    proxies/
      TVSBeaconProxy.sol             # Lightweight beacon proxy
    state/proxy/
      Beacon.sol                     # Beacon address storage library
    interfaces/
      ITVSUpgradeable.sol
      IImmutableBeaconFactory.sol
  TVSDeployer.sol                    # Permissionless deployer for all variants
scripts/                             # Foundry deployment scripts
test/                                # Foundry test suite
audits/                              # Certora & Quantstamp audit reports
```

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- An RPC URL for the target network

### Installation

```bash
git clone --recurse-submodules https://github.com/liquid-collective/tvs.git
cd tvs
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Coverage

```bash
make coverage
```

### Documentation

```bash
make docs
```

---

## Deployment

### Environment Variables

Create a `.env` file (see the Makefile for full usage):

| Variable | Required | Description |
|---|---|---|
| `RPC_URL` | Yes | RPC endpoint for the target chain |
| `PRIVATE_KEY` | Yes | Deployer private key |
| `BENEFICIARY` | Yes | Default beneficiary address |
| `OWNER` | Yes | Contract owner address |
| `WITHDRAWAL_CONTRACT` | Yes | Pectra EL withdrawal contract address |
| `CONSOLIDATION_CONTRACT` | Yes | Pectra EL consolidation contract address |
| `ETHERSCAN_API_KEY` | No | For contract verification |
| `ETHERSCAN_API` | No | Custom verifier URL |
| `IMMUTABLE_BEACON_FACTORY` | No | Pre-deployed factory address (overrides broadcast lookup) |
| `TVS_CLONE_IMPLEMENTATION` | No | Pre-deployed clone implementation address |
| `TVS_UPGRADEABLE_IMPLEMENTATION` | No | Pre-deployed upgradeable implementation address |
| `UPGRADEABLE_BEACON` | No | Pre-deployed beacon address |

### Deployment Steps

Contracts should be deployed in the following order. Each step depends on the one before it (where noted).

#### 1. Deploy ImmutableBeaconFactory

```bash
make deploy-ImmutableBeaconFactory
```
No dependencies. Deploys the `ImmutableBeaconFactory`, required by `TVSUpgradeable`.

#### 2. Deploy TVSClone Implementation

```bash
make deploy-TVSCloneImplementation
```
No dependencies. Deploys the `TVSClone` implementation used by clone proxies.

#### 3. Deploy TVSUpgradeable Implementation

```bash
make deploy-TVSUpgradeableImplementation
```
Depends on: `ImmutableBeaconFactory` (or set `IMMUTABLE_BEACON_FACTORY` env var).

#### 4. Deploy UpgradeableBeacon

```bash
make deploy-UpgradeableBeacon
```
Depends on: `TVSUpgradeableImplementation` (or set `TVS_UPGRADEABLE_IMPLEMENTATION` env var).

#### 5. Deploy TVSDeployer (optional)

```bash
make deploy-TVSDeployer
```
Depends on: `TVSCloneImplementation` and `TVSUpgradeableImplementation` (or set `TVS_CLONE_IMPLEMENTATION` and
`TVS_UPGRADEABLE_IMPLEMENTATION` env vars). Only needed if you want the permissionless factory on-chain; the
per-variant deployments below do not require it.

#### 6. Deploy a TVS Instance

Pick the variant you need:

```bash
# Upgradeable (beacon proxy)
make deploy-TVSUpgradeable

# Clone (EIP-1167 minimal proxy)
make clone-TVS

# Immutable
make deploy-TVSImmutable

# Flexible Immutable
make deploy-TVSFlexibleImmutable
```

- `deploy-TVSUpgradeable` depends on `UpgradeableBeacon` (or set `UPGRADEABLE_BEACON` env var).
- `clone-TVS` depends on `TVSCloneImplementation` (or set `TVS_CLONE_IMPLEMENTATION` env var).
- The immutable variants have no deployment dependencies.

---

## Dependencies

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [OpenZeppelin Contracts Upgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable)
- [Solady](https://github.com/Vectorized/solady) (UpgradeableBeacon)
- [Forge Std](https://github.com/foundry-rs/forge-std)

## Security

If you're interested in learning more about Liquid Collective security processes, including security audits and the protocol's vulnerability disclosure policy, see: [Liquid Collective Security](https://github.com/liquid-collective/security).

## Contributing

For guidance on setting up a development environment and how to make a contribution to Liquid Collective, see the [contributing guidelines](https://github.com/liquid-collective/liquid-collective-protocol/blob/main/CONTRIBUTING.md).

## License

See the [LICENSE](./LICENSE) file for details.
