// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import "forge-std/Test.sol";
import "../src/TVSDeployer.sol";
import "../src/TVSNonUpgradeable/TVSClone.sol";
import "../src/TVSNonUpgradeable/TVSImmutable.sol";
import "../src/TVSNonUpgradeable/TVSFlexibleImmutable.sol";
import "../src/TVSUpgradeable/TVSUpgradeable.sol";
import "openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract TVSDeployerTest is Test {
    TVSDeployer public deployer;
    address public beneficiary;
    address public owner;
    address public withdrawalContract;
    address public consolidationContract;
    address public immutableBeaconFactory;

    function setUp() public {
        // Deploy a dummy implementation for setup
        TVSClone implementation = new TVSClone(makeAddr("withdrawal"), makeAddr("consolidation"));
        deployer = new TVSDeployer(address(implementation));
        
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
    }

    function testDeployClone() public {
        // Deploy implementation
        TVSClone implementation = new TVSClone(withdrawalContract, consolidationContract);
        
        // Re-deploy deployer with implementation
        deployer = new TVSDeployer(address(implementation));

        // Deploy clone
        address clone = deployer.deployClone(beneficiary, owner);

        // Verify
        assertTrue(clone != address(0));
        assertEq(TVSClone(payable(clone)).owner(), owner);
        // Check beneficiary if possible, or other initialized state
    }

    function testDeployImmutable() public {
        address tvs = deployer.deployImmutable(
            beneficiary,
            owner,
            withdrawalContract,
            consolidationContract
        );

        assertTrue(tvs != address(0));
        assertEq(TVSImmutable(payable(tvs)).owner(), owner);
        assertEq(TVSImmutable(payable(tvs)).WITHDRAWAL_CONTRACT_ADDRESS(), withdrawalContract);
        assertEq(TVSImmutable(payable(tvs)).CONSOLIDATION_CONTRACT_ADDRESS(), consolidationContract);
    }

    function testDeployFlexibleImmutable() public {
        address tvs = deployer.deployFlexibleImmutable(
            beneficiary,
            owner,
            withdrawalContract,
            consolidationContract
        );

        assertTrue(tvs != address(0));
        assertEq(TVSFlexibleImmutable(payable(tvs)).owner(), owner);
        assertEq(TVSFlexibleImmutable(payable(tvs)).WITHDRAWAL_CONTRACT_ADDRESS(), withdrawalContract);
        assertEq(TVSFlexibleImmutable(payable(tvs)).CONSOLIDATION_CONTRACT_ADDRESS(), consolidationContract);
    }

    function testDeployUpgradeable() public {
        // Deploy implementation
        TVSUpgradeable implementation = new TVSUpgradeable(
            withdrawalContract,
            consolidationContract,
            immutableBeaconFactory
        );

        // Deploy beacon
        UpgradeableBeacon beacon = new UpgradeableBeacon(address(implementation), owner);

        // Deploy proxy
        address proxy = deployer.deployUpgradeable(address(beacon), beneficiary, owner);

        assertTrue(proxy != address(0));
        assertEq(TVSUpgradeable(payable(proxy)).owner(), owner);
        assertEq(TVSUpgradeable(payable(proxy)).beacon(), address(beacon));
    }
}
