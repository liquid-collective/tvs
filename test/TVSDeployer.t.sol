// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import "forge-std/Test.sol";
import "../src/TVSDeployer.sol";
import "../src/TVSNonUpgradeable/TVSClone.sol";
import "../src/TVSNonUpgradeable/TVSImmutable.sol";
import "../src/TVSNonUpgradeable/TVSFlexibleImmutable.sol";
import "../src/TVSUpgradeable/TVSUpgradeable.sol";
import "../src/TVSUpgradeable/interfaces/IImmutableBeaconFactory.sol";
import "lib/solady/src/utils/UpgradeableBeacon.sol";

contract TVSDeployerTest is Test {
    TVSDeployer public deployer;
    address public beneficiary;
    address public owner;
    address public withdrawalContract;
    address public consolidationContract;
    address public immutableBeaconFactory;

    function setUp() public {
        // Deploy dummy implementations for setup
        TVSClone cloneImplementation = new TVSClone(makeAddr("withdrawal"), makeAddr("consolidation"));

        beneficiary = makeAddr("beneficiary");
        owner = makeAddr("owner");
        withdrawalContract = makeAddr("withdrawal");
        consolidationContract = makeAddr("consolidation");
        immutableBeaconFactory = makeAddr("immutableBeaconFactory");

        // Mock the immutable beacon factory response
        vm.mockCall(
            immutableBeaconFactory,
            abi.encodeWithSelector(IImmutableBeaconFactory.deployBeacon.selector),
            abi.encode(makeAddr("immutableBeacon"))
        );

        // Deploy upgradeable implementation
        TVSUpgradeable upgradeableImplementation =
            new TVSUpgradeable(withdrawalContract, consolidationContract, immutableBeaconFactory);

        // Deploy deployer with both implementations
        deployer = new TVSDeployer(address(cloneImplementation), address(upgradeableImplementation));
    }

    function testDeployerConstructor() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidImplementation()"));
        new TVSDeployer(address(0), address(0));
        vm.expectRevert(abi.encodeWithSignature("InvalidImplementation()"));
        new TVSDeployer(address(0x01), address(0));
    }

    function testDeployClone() public {
        // Deploy implementations
        TVSClone cloneImplementation = new TVSClone(withdrawalContract, consolidationContract);
        TVSUpgradeable upgradeableImplementation =
            new TVSUpgradeable(withdrawalContract, consolidationContract, immutableBeaconFactory);

        // Re-deploy deployer with implementations
        deployer = new TVSDeployer(address(cloneImplementation), address(upgradeableImplementation));

        // Deploy clone
        address clone = deployer.deployClone(beneficiary, owner);

        // Verify
        assertTrue(clone != address(0));
        assertEq(TVSClone(payable(clone)).owner(), owner);
        // Check beneficiary if possible, or other initialized state
    }

    function testDeployImmutable() public {
        address tvs = deployer.deployImmutable(beneficiary, owner);

        assertTrue(tvs != address(0));
        assertEq(TVSImmutable(payable(tvs)).owner(), owner);
        assertEq(TVSImmutable(payable(tvs)).WITHDRAWAL_CONTRACT_ADDRESS(), deployer.WITHDRAWAL_CONTRACT_ADDRESS());
        assertEq(TVSImmutable(payable(tvs)).CONSOLIDATION_CONTRACT_ADDRESS(), deployer.CONSOLIDATION_CONTRACT_ADDRESS());
    }

    function testDeployFlexibleImmutable() public {
        address tvs = deployer.deployFlexibleImmutable(beneficiary, owner);

        assertTrue(tvs != address(0));
        assertEq(TVSFlexibleImmutable(payable(tvs)).owner(), owner);
        assertEq(
            TVSFlexibleImmutable(payable(tvs)).WITHDRAWAL_CONTRACT_ADDRESS(), deployer.WITHDRAWAL_CONTRACT_ADDRESS()
        );
        assertEq(
            TVSFlexibleImmutable(payable(tvs)).CONSOLIDATION_CONTRACT_ADDRESS(),
            deployer.CONSOLIDATION_CONTRACT_ADDRESS()
        );
    }

    function testDeployUpgradeable() public {
        // Deploy beacon using the upgradeable implementation from deployer
        UpgradeableBeacon beacon = new UpgradeableBeacon(owner, deployer.upgradeableTVSImplementation());

        // Deploy proxy
        address proxy = deployer.deployUpgradeable(beneficiary, owner, address(beacon));

        assertTrue(proxy != address(0));
        assertEq(TVSUpgradeable(payable(proxy)).owner(), owner);
        assertEq(TVSUpgradeable(payable(proxy)).beacon(), address(beacon));
    }

    function testDeployUpgradeableWithZeroBeacon() public {
        address deployerAddress = address(this);

        // Deploy proxy with zero beacon - should deploy new beacon automatically
        address proxy = deployer.deployUpgradeable(beneficiary, owner, address(0));

        assertTrue(proxy != address(0));
        assertEq(TVSUpgradeable(payable(proxy)).owner(), owner);

        // Get the beacon address from the proxy
        address deployedBeacon = TVSUpgradeable(payable(proxy)).beacon();
        assertTrue(deployedBeacon != address(0));

        // Verify the beacon was deployed with correct owner (msg.sender, which is this test contract)
        UpgradeableBeacon beacon = UpgradeableBeacon(payable(deployedBeacon));
        assertEq(beacon.owner(), deployerAddress);

        // Verify the beacon has the correct implementation
        assertEq(beacon.implementation(), deployer.upgradeableTVSImplementation());
    }
}
