# TVS Repository - Agent Context

> This document provides context for AI agents (Claude, Cursor, Copilot, etc.) and human developers working with the Transferable Validator Set (TVS) repository.

---

## Agent Instructions

When working with this codebase, follow these guidelines:

### Do
- Run `forge test` before suggesting changes are complete
- Run `forge fmt` before committing Solidity changes
- Use `address payable` when casting TVS contract addresses for ITVS interface calls
- Validate all tests pass after modifications: `forge test --summary`
- Check for compiler warnings: `forge build`

### Don't
- Modify Pectra contract addresses without understanding chain-specific implications
- Change Solidity version from `0.8.29`
- Modify audited contracts without explicit approval (see `/audits`)
- Use `renounceOwnership()` - it's intentionally disabled
- Suggest upgrades to immutable TVS variants

### Code Style
- Follow existing patterns in the codebase
- Use NatSpec comments (`@notice`, `@dev`, `@param`, `@return`)
- Constants should be `UPPER_SNAKE_CASE`
- Internal functions prefixed with `_`
- Use custom errors, not `require` strings

---

## Overview

**Transferable Validator Set (TVS)** is a smart contract system that serves as the withdrawal credential for Ethereum validators. The key innovation is that ownership of validator sets can be transferred to new owners, enabling validator set trading and management.

- **Solidity Version**: 0.8.29
- **Framework**: Foundry
- **License**: Proprietary
- **Audited By**: Certora, Quantstamp (reports in `/audits`)

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                        TVS Variants                              │
├─────────────────┬─────────────────┬─────────────────────────────┤
│   Upgradeable   │   Immutable     │   Clone (EIP-1167)          │
│   (Beacon Proxy)│   (Direct)      │   (Minimal Proxy)           │
├─────────────────┴─────────────────┴─────────────────────────────┤
│                     Core TVS Logic                               │
│            src/components/TVS.sol (abstract)                     │
├─────────────────────────────────────────────────────────────────┤
│                    BaseSecurity                                  │
│   (Ownable + ReentrancyGuard via OZ Upgradeable libs)           │
└─────────────────────────────────────────────────────────────────┘
```

## Core Contracts

### Main Implementation

| File | Description |
|------|-------------|
| `src/components/TVS.sol` | **Abstract base** implementing core TVS logic: sweep, withdraw, consolidate, transfer |
| `src/components/BaseSecurity.sol` | Security base with Ownable + ReentrancyGuard, prevents ownership renouncement |
| `src/interfaces/ITVS.sol` | Main interface defining all TVS operations |

### TVS Variants

| Variant | File | Use Case |
|---------|------|----------|
| **TVSUpgradeable** | `src/TVSUpgradeable/TVSUpgradeable.sol` | Beacon proxy pattern, upgradeable via beacon |
| **TVSImmutable** | `src/TVSNonUpgradeable/TVSImmutable.sol` | Fully immutable, set at deployment |
| **TVSFlexibleImmutable** | `src/TVSNonUpgradeable/TVSFlexibleImmutable.sol` | Immutable + arbitrary call execution (`executeCall`, `executeBatch`) |
| **TVSClone** | `src/TVSNonUpgradeable/TVSClone.sol` | EIP-1167 minimal proxy for gas-efficient deployment |

### Proxy Infrastructure (Upgradeable Only)

| File | Description |
|------|-------------|
| `src/TVSUpgradeable/proxies/TVSBeaconProxy.sol` | Custom beacon proxy with inline assembly for delegation |
| `src/TVSUpgradeable/ImmutableBeacon.sol` | Beacon with frozen implementation (used during transfers) |
| `src/TVSUpgradeable/ImmutableBeaconFactory.sol` | Factory to deploy immutable beacons |
| `src/TVSUpgradeable/state/proxy/Beacon.sol` | Storage slot management for beacon address |

### State Management

| File | Description |
|------|-------------|
| `src/state/Beneficiary.sol` | Library for beneficiary address storage slot |
| `src/TVSUpgradeable/state/proxy/Beacon.sol` | Library for beacon address storage slot |

## Key Functionality

### Core Operations (all variants)

1. **`sweep(address beneficiary, uint256 amount)`** - Transfer ETH to beneficiary
   - Non-owner can sweep to default beneficiary
   - Owner can specify custom beneficiary
   
2. **`sweepToBeneficiaryContract(address, uint256)`** - Sweep to contract implementing `ITVSSweepBeneficiary`

3. **`withdraw(bytes[] pubkeys, uint64[] amounts, uint256 maxFee, address feeRecipient)`** - Pectra EL withdrawal requests
   - Interacts with `WITHDRAWAL_CONTRACT_ADDRESS` (passed at deployment)
   - Validates 48-byte pubkeys
   - Refunds excess fees

4. **`consolidate(ConsolidationRequest[], uint256 maxFee, address feeRecipient)`** - Pectra EL consolidation
   - Interacts with `CONSOLIDATION_CONTRACT_ADDRESS` (passed at deployment)
   - Merges validators

5. **`transfer(address newBeneficiary, address newOwner)`** - Transfer TVS ownership
   - Upgradeable: Also freezes beacon to immutable version
   - Updates beneficiary and owner atomically

6. **`setBeneficiary(address)`** - Update beneficiary (owner only)

### Upgradeable-Specific

- **`setBeacon(address)`** - Update beacon with validation (checks implementation has `setBeaconUnchecked`)
- **`setBeaconUnchecked(address)`** - Direct beacon update (no validation)
- **`beacon()`** - Get current beacon address

### FlexibleImmutable-Specific

- **`executeCall(Call)`** - Execute arbitrary call/delegatecall
- **`executeBatch(Call[])`** - Execute multiple calls atomically

## Inheritance Hierarchy

```
BaseSecurity (Initializable, OwnableUpgradeable, ReentrancyGuardTransientUpgradeable)
    └── TVS (abstract) - Core logic
        ├── TVSUpgradeable - Beacon proxy pattern
        └── TVSImmutableBase (abstract)
            ├── TVSImmutable - Direct deployment
            │   └── TVSFlexibleImmutable - With executeCall
            └── TVSClone - For EIP-1167 cloning
```

## Test Files

| Test File | Coverage |
|-----------|----------|
| `test/TVS.t.sol` | **Base test contract** - `BaseTVSTest` with common tests for sweep, withdraw, consolidate, etc. |
| `test/TVSUpgradeable.t.sol` | Upgradeable-specific: beacon updates, transfer with beacon freeze |
| `test/TVSImmutable.t.sol` | Constructor validation, inherits `TVSImmutableBaseTest` |
| `test/TVSImmutableBase.t.sol` | Common immutable tests: transfer, version |
| `test/TVSClone.t.sol` | Clone initialization, EIP-1167 proxy tests |
| `test/TVSFlexibleImmutable.t.sol` | `executeCall`/`executeBatch` tests, delegate call behavior |

### Test Architecture

Tests use inheritance to avoid duplication:
- `BaseTVSTest` - Abstract base with `deployTVS()` hook
- `TVSImmutableBaseTest` extends `BaseTVSTest` - Adds immutable-specific tests
- Concrete test contracts implement `deployTVS()` for each variant

### Running Tests

```bash
forge test                    # Run all tests
forge test -vvv               # Verbose output
forge test --match-test testSweep  # Run specific test
forge test --match-contract TVSUpgradeableTest  # Run specific contract tests
forge test --summary          # Show test summary table
```

## Deployment

### Scripts (in `/scripts`)

| Script | Purpose |
|--------|---------|
| `DeployImmutableBeaconFactory.s.sol` | Deploy beacon factory (first for upgradeable) |
| `DeployTVSUpgradeableImplementation.s.sol` | Deploy TVSUpgradeable implementation |
| `DeployUpgradeableBeacon.s.sol` | Deploy upgradeable beacon pointing to implementation |
| `DeployTVSUpgradeable.s.sol` | Deploy TVSBeaconProxy |
| `DeployTVSCloneImplementation.s.sol` | Deploy TVSClone implementation |
| `DeployTVSClone.s.sol` | Clone the TVSClone implementation |
| `DeployTVSImmutable.s.sol` | Deploy TVSImmutable |
| `DeployTVSFlexibleImmutable.s.sol` | Deploy TVSFlexibleImmutable |

### Deployment Order (Upgradeable)

1. `ImmutableBeaconFactory` (no dependencies)
2. `TVSUpgradeableImplementation` (needs factory)
3. `UpgradeableBeacon` (needs implementation)
4. `TVSUpgradeable` proxy (needs beacon)

### Environment Variables

```bash
BENEFICIARY=0x...           # Required: Address for swept funds
OWNER=0x...                 # Required: Contract owner
RPC_URL=...                 # Required: Network RPC
PRIVATE_KEY=...             # Required: Deployer key

# Optional (uses broadcast folder if not set):
IMMUTABLE_BEACON_FACTORY=0x...
TVS_CLONE_IMPLEMENTATION=0x...
TVS_UPGRADEABLE_IMPLEMENTATION=0x...
UPGRADEABLE_BEACON=0x...
```

### Make Targets

```bash
make deploy-ImmutableBeaconFactory
make deploy-TVSUpgradeableImplementation
make deploy-UpgradeableBeacon
make deploy-TVSUpgradeable
make deploy-TVSCloneImplementation
make clone-TVS
make deploy-TVSFlexibleImmutable
```

## Important Constants

```solidity
// Pectra EL Contract Addresses (used in tests)
// Note: These are passed as constructor parameters, not hardcoded
WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA   // test value
CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb // test value

// Pubkey length for validators
PUBKEY_LENGTH = 48 bytes

// Current version
VERSION = "1.0.2"
```

## Storage Slots

```solidity
// Beneficiary storage slot
bytes32 BENEFICIARY_SLOT = bytes32(uint256(keccak256("tvs.state.beneficiary")) - 1);

// Beacon storage slot (upgradeable only)
bytes32 BEACON_SLOT = bytes32(uint256(keccak256("tvs.state.beacon")) - 1);
```

## Security Considerations

1. **Ownership cannot be renounced** - `renounceOwnership()` reverts with `OwnershipCannotBeRenounced()`
2. **ReentrancyGuard** - All state-changing functions protected
3. **Transfer freezes beacon** - Upgradeable TVS freezes to immutable beacon during transfer to prevent implementation swaps
4. **Pubkey validation** - All pubkeys must be exactly 48 bytes
5. **Fee protection** - `maxFee` parameters prevent excessive gas costs

## Common Errors

| Error | Cause |
|-------|-------|
| `InvalidAddress()` | Zero address provided |
| `Unauthorized(address)` | Non-owner calling owner-only function |
| `InsufficientBalance(uint256, uint256)` | Sweep amount exceeds balance |
| `FeeTooHigh(uint256, uint256)` | Pectra fee exceeds maxFee |
| `FeeReadFailed()` | Failed to read fee from Pectra contract |
| `RequestFailed()` | Pectra withdraw/consolidate call failed |
| `InvalidPubkeyLength(uint256)` | Pubkey not 48 bytes |
| `OwnershipCannotBeRenounced()` | Attempted to renounce ownership |
| `InvalidBeacon()` | Invalid beacon address |
| `InvalidImplementation()` | Zero implementation address |

## File Quick Reference

```
src/
├── components/
│   ├── BaseSecurity.sol        # Ownable + ReentrancyGuard base
│   └── TVS.sol                 # Core TVS logic (abstract)
├── interfaces/
│   ├── ITVS.sol                # Main TVS interface
│   └── ITVSSweepBeneficiary.sol # Interface for sweep recipient contracts
├── state/
│   └── Beneficiary.sol         # Beneficiary storage slot
├── TVSNonUpgradeable/
│   ├── interfaces/
│   │   └── ITVSFlexibleImmutable.sol
│   ├── TVSClone.sol            # EIP-1167 compatible
│   ├── TVSFlexibleImmutable.sol # With executeCall
│   ├── TVSImmutable.sol        # Basic immutable
│   └── TVSImmutableBase.sol    # Base for immutable variants
└── TVSUpgradeable/
    ├── interfaces/
    │   ├── IImmutableBeaconFactory.sol
    │   └── ITVSUpgradeable.sol
    ├── proxies/
    │   └── TVSBeaconProxy.sol  # Beacon proxy implementation
    ├── state/proxy/
    │   └── Beacon.sol          # Beacon storage slot
    ├── ImmutableBeacon.sol     # Frozen beacon for transfers
    ├── ImmutableBeaconFactory.sol
    └── TVSUpgradeable.sol      # Upgradeable TVS implementation
```

## Dependencies

- **OpenZeppelin Contracts** - `openzeppelin-contracts/`
- **OpenZeppelin Contracts Upgradeable** - `openzeppelin-contracts-upgradeable/`
- **Solady** - `lib/solady/` (UpgradeableBeacon)
- **Forge Std** - `forge-std/` (testing)
