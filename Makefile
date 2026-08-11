# Load environment variables from .env file
-include .env
export

# Conditionally set the etherscan-api-key flag
ifdef ETHERSCAN_API_KEY
    ETHERSCAN_API_KEY_FLAG = --etherscan-api-key $(ETHERSCAN_API_KEY)
endif

# Conditionally set the verifier-url flag
ifdef ETHERSCAN_API
    VERIFIER_URL_FLAG = --verifier-url $(ETHERSCAN_API)
endif

# Conditionally set the verify flag if both ETHERSCAN_API_KEY and ETHERSCAN_API are set
ifneq (,$(and $(ETHERSCAN_API_KEY),$(ETHERSCAN_API)))
    VERIFY_FLAG = --verify
endif

# Common deployment flags
DEPLOY_FLAGS = --rpc-url $(RPC_URL) \
               $(VERIFY_FLAG) \
               $(VERIFIER_URL_FLAG) \
               $(ETHERSCAN_API_KEY_FLAG) \
               --broadcast \
               --private-key $(PRIVATE_KEY)

deploy-ImmutableBeaconFactory:
	forge script scripts/DeployImmutableBeaconFactory.s.sol:DeployImmutableBeaconFactory $(DEPLOY_FLAGS) && \
	DEPLOYMENT_PATH=ImmutableBeaconFactory CONTRACT_NAME=ImmutableBeaconFactory make abi

clone-TVS:
	forge script scripts/DeployTVSClone.s.sol:DeployTVSClone $(DEPLOY_FLAGS)

deploy-TVSCloneImplementation:
	forge script scripts/DeployTVSCloneImplementation.s.sol:DeployTVSCloneImplementation $(DEPLOY_FLAGS) && \
	DEPLOYMENT_PATH=TVSCloneImplementation CONTRACT_NAME=TVSClone make abi

deploy-TVSFlexibleImmutable:
	forge script scripts/DeployTVSFlexibleImmutable.s.sol:DeployTVSFlexibleImmutable $(DEPLOY_FLAGS) && \
	DEPLOYMENT_PATH=TVSFlexibleImmutable CONTRACT_NAME=TVSFlexibleImmutable make abi

deploy-TVSImmutable:
	forge script scripts/DeployTVSImmutable.s.sol:DeployTVSImmutable $(DEPLOY_FLAGS) && \
	DEPLOYMENT_PATH=TVSImmutable CONTRACT_NAME=TVSImmutable make abi

deploy-TVSUpgradeable:
	forge script scripts/DeployTVSUpgradeable.s.sol:DeployTVSUpgradeable $(DEPLOY_FLAGS) && \
	DEPLOYMENT_PATH=TVSUpgradeable CONTRACT_NAME=TVSBeaconProxy make abi

deploy-TVSUpgradeableImplementation:
	forge script scripts/DeployTVSUpgradeableImplementation.s.sol:DeployTVSUpgradeableImplementation $(DEPLOY_FLAGS) && \
	DEPLOYMENT_PATH=TVSUpgradeableImplementation CONTRACT_NAME=TVSUpgradeable make abi

deploy-UpgradeableBeacon:
	forge script scripts/DeployUpgradeableBeacon.s.sol:DeployUpgradeableBeacon $(DEPLOY_FLAGS) --ffi && \
	DEPLOYMENT_PATH=UpgradeableBeacon CONTRACT_NAME=UpgradeableBeacon make abi

deploy-TVSDeployer:
	forge script scripts/DeployTVSDeployer.s.sol:DeployTVSDeployer $(DEPLOY_FLAGS) && \
	DEPLOYMENT_PATH=TVSDeployer CONTRACT_NAME=TVSDeployer make abi

ABI_SOURCE := out/$(CONTRACT_NAME).sol/$(CONTRACT_NAME).json
TEMP_JSON := broadcast/temp.json

abi:
	@echo "📄 Injecting ABI into broadcast files..." && \
	if [ ! -f "$(TEMP_JSON)" ]; then \
		echo "ℹ️  Skipping ABI injection since no new deployment"; \
		exit 0; \
	fi && \
	if [ ! -f "$(ABI_SOURCE)" ]; then \
		echo "❌ Error: Contract ABI not found at $(ABI_SOURCE)"; \
		exit 1; \
	fi && \
	CHAINID=$$(jq -r '.chainID' $(TEMP_JSON)) && \
	ABI=$$(jq '.abi' "$(ABI_SOURCE)") && \
	BASE_PATH=./broadcast/Deploy$(DEPLOYMENT_PATH).s.sol/$$CHAINID && \
	FILE=$$BASE_PATH/run-latest.json && \
	if [ ! -f "$$FILE" ]; then \
		echo "❌ Error: Broadcast file not found: $$FILE"; \
		exit 1; \
	fi; \
	echo "✍️  Injecting ABI into $$FILE..."; \
	jq --argjson abi "$$ABI" '. + {abi: $$abi}' "$$FILE" > "$$FILE.tmp" && \
	mv "$$FILE.tmp" "$$FILE"; \
	echo "✅ ABI injected into $$FILE"; \
	echo "🧹 Cleaning up $(TEMP_JSON)..." && \
	rm -f $(TEMP_JSON) && \
	echo "✅ Temp file removed"

# Documentation commands
docs:
	forge doc --build

# Coverage commands
coverage:
	forge coverage --no-match-coverage "test|scripts" --report lcov

check-submodules:
	bash check-submodule-versions.sh

# Declared phony so they are never shadowed by same-named files or directories (e.g. the `docs/` directory)
.PHONY: abi docs coverage check-submodules clone-TVS \
        deploy-ImmutableBeaconFactory \
        deploy-TVSCloneImplementation \
        deploy-TVSDeployer \
        deploy-TVSFlexibleImmutable \
        deploy-TVSImmutable \
        deploy-TVSUpgradeable \
        deploy-TVSUpgradeableImplementation \
        deploy-UpgradeableBeacon