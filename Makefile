# Load environment variables from .env file
include .env
export

# Common deployment flags
DEPLOY_FLAGS = --rpc-url $(RPC_URL) \
               --private-key $(PRIVATE_KEY) \
               --verify \
               --etherscan-api-key $(ETHERSCAN_API_KEY) \
               --verifier-url $(ETHERSCAN_API) \
               --broadcast

deploy-ImmutableBeaconFactory:
	forge script scripts/DeployImmutableBeaconFactory.s.sol:DeployImmutableBeaconFactory $(DEPLOY_FLAGS)

clone-TVS:
	forge script scripts/DeployTVSClone.s.sol:DeployTVSClone $(DEPLOY_FLAGS)

deploy-TVSCloneImplementation:
	forge script scripts/DeployTVSCloneImplementation.s.sol:DeployTVSCloneImplementation $(DEPLOY_FLAGS)

deploy-TVSFlexibleImmutable:
	forge script scripts/DeployTVSFlexibleImmutable.s.sol:DeployTVSFlexibleImmutable $(DEPLOY_FLAGS)

deploy-TVSImmutable:
	forge script scripts/DeployTVSImmutable.s.sol:DeployTVSImmutable $(DEPLOY_FLAGS)

deploy-TVSUpgradeable:
	forge script scripts/DeployTVSUpgradeable.s.sol:DeployTVSUpgradeable $(DEPLOY_FLAGS)

deploy-TVSUpgradeableImplementation:
	forge script scripts/DeployTVSUpgradeableImplementation.s.sol:DeployTVSUpgradeableImplementation $(DEPLOY_FLAGS)

deploy-UpgradableBeacon:
	forge script scripts/DeployUpgradableBeacon.s.sol:DeployUpgradableBeacon $(DEPLOY_FLAGS)
