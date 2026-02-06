// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.29;

import "forge-std/Test.sol";
import "../src/TVSDeployer.sol";
import "../src/TVSNonUpgradeable/TVSClone.sol";
import "../src/TVSNonUpgradeable/TVSImmutable.sol";
import "../src/TVSNonUpgradeable/TVSFlexibleImmutable.sol";
import "../src/TVSUpgradeable/TVSUpgradeable.sol";
import "../src/TVSUpgradeable/interfaces/IImmutableBeaconFactory.sol";
import "../src/interfaces/ITVS.sol";
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

    // ============ Constructor Tests ============

    function testDeployerConstructor() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidImplementation()"));
        new TVSDeployer(address(0), address(0));
        vm.expectRevert(abi.encodeWithSignature("InvalidImplementation()"));
        new TVSDeployer(address(0x01), address(0));
        TVSClone cloneImplementation = new TVSClone(withdrawalContract, consolidationContract);
        vm.expectRevert(abi.encodeWithSignature("InvalidImplementation()"));
        new TVSDeployer(address(cloneImplementation), address(0));
    }

    function testDeployerConstructorRevertsWithZeroCloneImplementation() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidImplementation()"));
        new TVSDeployer(address(0), makeAddr("upgradeable"));
    }

    function testDeployerConstructorRevertsWithZeroUpgradeableImplementation() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidImplementation()"));
        new TVSDeployer(makeAddr("clone"), address(0));
    }

    function testDeployerConstructorSetsImplementations() public view {
        assertTrue(deployer.CLONE_IMPLEMENTATION() != address(0), "Clone implementation should be set");
        assertTrue(deployer.UPGRADEABLE_TVS_IMPLEMENTATION() != address(0), "Upgradeable implementation should be set");
    }

    function testDeployerConstantsAreCorrect() public view {
        // Verify Pectra addresses are set correctly
        assertEq(
            deployer.WITHDRAWAL_CONTRACT_ADDRESS(),
            0x00000961Ef480Eb55e80D19ad83579A64c007002,
            "Withdrawal contract address mismatch"
        );
        assertEq(
            deployer.CONSOLIDATION_CONTRACT_ADDRESS(),
            0x0000BBdDc7CE488642fb579F8B00f3a590007251,
            "Consolidation contract address mismatch"
        );
    }

    // ============ Deploy Clone Tests ============

    function testDeployClone() public {
        // Deploy implementations
        TVSClone cloneImplementation = new TVSClone(withdrawalContract, consolidationContract);
        TVSUpgradeable upgradeableImplementation =
            new TVSUpgradeable(withdrawalContract, consolidationContract, immutableBeaconFactory);

        // Re-deploy deployer with implementations
        deployer = new TVSDeployer(address(cloneImplementation), address(upgradeableImplementation));

        vm.expectEmit(false, true, true, true);
        emit TVSDeployer.TVSCloneDeployed(address(0), address(cloneImplementation), owner);
        // Deploy clone
        address clone = deployer.deployClone(beneficiary, owner);

        // Verify
        assertTrue(clone != address(0));
        assertEq(TVSClone(payable(clone)).owner(), owner);
        // Check beneficiary if possible, or other initialized state
        assertEq(TVSClone(payable(clone)).getBeneficiary(), beneficiary);
    }

    function testDeployCloneRevertsWithZeroBeneficiary() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        deployer.deployClone(address(0), owner);
    }

    function testDeployCloneRevertsWithZeroOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        deployer.deployClone(beneficiary, address(0));
    }

    function testDeployMultipleClones() public {
        address clone1 = deployer.deployClone(beneficiary, owner);
        address clone2 = deployer.deployClone(makeAddr("beneficiary2"), makeAddr("owner2"));

        // Verify they are different addresses
        assertTrue(clone1 != clone2, "Clones should have different addresses");

        // Verify each has correct state
        assertEq(TVSClone(payable(clone1)).owner(), owner);
        assertEq(TVSClone(payable(clone2)).owner(), makeAddr("owner2"));
        assertEq(TVSClone(payable(clone1)).getBeneficiary(), beneficiary);
        assertEq(TVSClone(payable(clone2)).getBeneficiary(), makeAddr("beneficiary2"));
    }

    function testDeployCloneFuzz(address _beneficiary, address _owner) public {
        vm.assume(_beneficiary != address(0));
        vm.assume(_owner != address(0));

        address clone = deployer.deployClone(_beneficiary, _owner);

        assertTrue(clone != address(0));
        assertEq(TVSClone(payable(clone)).owner(), _owner);
        assertEq(TVSClone(payable(clone)).getBeneficiary(), _beneficiary);
    }

    // ============ Deploy Immutable Tests ============

    function testDeployImmutable() public {
        vm.expectEmit(false, true, true, true);
        emit TVSDeployer.TVSImmutableDeployed(address(0), owner);
        address tvs = deployer.deployImmutable(beneficiary, owner);

        assertTrue(tvs != address(0));
        assertEq(TVSImmutable(payable(tvs)).owner(), owner);
        assertEq(TVSImmutable(payable(tvs)).WITHDRAWAL_CONTRACT_ADDRESS(), deployer.WITHDRAWAL_CONTRACT_ADDRESS());
        assertEq(TVSImmutable(payable(tvs)).CONSOLIDATION_CONTRACT_ADDRESS(), deployer.CONSOLIDATION_CONTRACT_ADDRESS());
        assertEq(TVSImmutable(payable(tvs)).getBeneficiary(), beneficiary);
    }

    function testDeployImmutableRevertsWithZeroBeneficiary() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        deployer.deployImmutable(address(0), owner);
    }

    function testDeployImmutableRevertsWithZeroOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        deployer.deployImmutable(beneficiary, address(0));
    }

    function testDeployMultipleImmutables() public {
        address tvs1 = deployer.deployImmutable(beneficiary, owner);
        address tvs2 = deployer.deployImmutable(makeAddr("beneficiary2"), makeAddr("owner2"));

        assertTrue(tvs1 != tvs2, "Immutables should have different addresses");
        assertEq(TVSImmutable(payable(tvs1)).owner(), owner);
        assertEq(TVSImmutable(payable(tvs2)).owner(), makeAddr("owner2"));
    }

    function testDeployImmutableFuzz(address _beneficiary, address _owner) public {
        vm.assume(_beneficiary != address(0));
        vm.assume(_owner != address(0));

        address tvs = deployer.deployImmutable(_beneficiary, _owner);

        assertTrue(tvs != address(0));
        assertEq(TVSImmutable(payable(tvs)).owner(), _owner);
        assertEq(TVSImmutable(payable(tvs)).getBeneficiary(), _beneficiary);
    }

    // ============ Deploy Flexible Immutable Tests ============

    function testDeployFlexibleImmutable() public {
        vm.expectEmit(false, true, true, true);
        emit TVSDeployer.TVSFlexibleImmutableDeployed(address(0), owner);
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
        assertEq(TVSImmutable(payable(tvs)).getBeneficiary(), beneficiary);
    }

    function testDeployFlexibleImmutableRevertsWithZeroBeneficiary() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        deployer.deployFlexibleImmutable(address(0), owner);
    }

    function testDeployFlexibleImmutableRevertsWithZeroOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        deployer.deployFlexibleImmutable(beneficiary, address(0));
    }

    function testDeployFlexibleImmutableFuzz(address _beneficiary, address _owner) public {
        vm.assume(_beneficiary != address(0));
        vm.assume(_owner != address(0));

        address tvs = deployer.deployFlexibleImmutable(_beneficiary, _owner);

        assertTrue(tvs != address(0));
        assertEq(TVSFlexibleImmutable(payable(tvs)).owner(), _owner);
        assertEq(TVSFlexibleImmutable(payable(tvs)).getBeneficiary(), _beneficiary);
    }

    // ============ Deploy Upgradeable Tests ============

    function testDeployUpgradeable() public {
        // Deploy beacon using the upgradeable implementation from deployer
        UpgradeableBeacon beacon = new UpgradeableBeacon(owner, deployer.UPGRADEABLE_TVS_IMPLEMENTATION());
        vm.expectEmit(false, true, true, true);
        emit TVSDeployer.TVSUpgradeableDeployed(address(0), address(beacon), owner);
        // Deploy proxy
        address proxy = deployer.deployUpgradeable(beneficiary, owner, address(beacon));

        assertTrue(proxy != address(0));
        assertEq(TVSUpgradeable(payable(proxy)).owner(), owner);
        assertEq(TVSUpgradeable(payable(proxy)).beacon(), address(beacon));
        assertEq(TVSImmutable(payable(proxy)).getBeneficiary(), beneficiary);
    }

    function testDeployUpgradeableWithZeroBeacon() public {
        address deployerAddress = address(this);

        vm.expectEmit(false, false, true, true);
        emit TVSDeployer.TVSUpgradeableDeployed(address(0), address(0), owner);
        // Deploy proxy with zero beacon - should deploy new beacon automatically
        address proxy = deployer.deployUpgradeable(beneficiary, owner, address(0));

        assertTrue(proxy != address(0));
        assertEq(TVSUpgradeable(payable(proxy)).owner(), owner);
        assertEq(TVSImmutable(payable(proxy)).getBeneficiary(), beneficiary);
        // Get the beacon address from the proxy
        address deployedBeacon = TVSUpgradeable(payable(proxy)).beacon();
        assertTrue(deployedBeacon != address(0));

        // Verify the beacon was deployed with correct owner (msg.sender, which is this test contract)
        UpgradeableBeacon beacon = UpgradeableBeacon(payable(deployedBeacon));
        assertEq(beacon.owner(), deployerAddress);

        // Verify the beacon has the correct implementation
        assertEq(beacon.implementation(), deployer.UPGRADEABLE_TVS_IMPLEMENTATION());
    }

    function testDeployUpgradeableRevertsWithZeroBeneficiary() public {
        UpgradeableBeacon beacon = new UpgradeableBeacon(owner, deployer.UPGRADEABLE_TVS_IMPLEMENTATION());

        vm.expectRevert(); // InitializationFailed from TVSBeaconProxy
        deployer.deployUpgradeable(address(0), owner, address(beacon));
    }

    function testDeployUpgradeableRevertsWithZeroOwner() public {
        UpgradeableBeacon beacon = new UpgradeableBeacon(owner, deployer.UPGRADEABLE_TVS_IMPLEMENTATION());

        vm.expectRevert(); // InitializationFailed from TVSBeaconProxy
        deployer.deployUpgradeable(beneficiary, address(0), address(beacon));
    }

    function testDeployUpgradeableRevertsWithInvalidBeacon() public {
        // Non-contract address as beacon
        address invalidBeacon = makeAddr("notAContract");

        vm.expectRevert(); // InvalidBeacon from TVSBeaconProxy
        deployer.deployUpgradeable(beneficiary, owner, invalidBeacon);
    }

    function testDeployMultipleUpgradeablesWithSameBeacon() public {
        UpgradeableBeacon beacon = new UpgradeableBeacon(owner, deployer.UPGRADEABLE_TVS_IMPLEMENTATION());

        address proxy1 = deployer.deployUpgradeable(beneficiary, owner, address(beacon));
        address proxy2 = deployer.deployUpgradeable(makeAddr("beneficiary2"), makeAddr("owner2"), address(beacon));

        assertTrue(proxy1 != proxy2, "Proxies should have different addresses");
        assertEq(TVSUpgradeable(payable(proxy1)).beacon(), address(beacon));
        assertEq(TVSUpgradeable(payable(proxy2)).beacon(), address(beacon));
        assertEq(TVSUpgradeable(payable(proxy1)).owner(), owner);
        assertEq(TVSUpgradeable(payable(proxy2)).owner(), makeAddr("owner2"));
    }

    function testDeployMultipleUpgradeablesWithAutoBeacon() public {
        address proxy1 = deployer.deployUpgradeable(beneficiary, owner, address(0));
        address proxy2 = deployer.deployUpgradeable(makeAddr("beneficiary2"), makeAddr("owner2"), address(0));

        assertTrue(proxy1 != proxy2, "Proxies should have different addresses");

        // Each should have its own beacon since we passed address(0)
        address beacon1 = TVSUpgradeable(payable(proxy1)).beacon();
        address beacon2 = TVSUpgradeable(payable(proxy2)).beacon();
        assertTrue(beacon1 != beacon2, "Auto-deployed beacons should be different");
    }

    function testDeployUpgradeableFuzz(address _beneficiary, address _owner) public {
        vm.assume(_beneficiary != address(0));
        vm.assume(_owner != address(0));

        UpgradeableBeacon beacon = new UpgradeableBeacon(_owner, deployer.UPGRADEABLE_TVS_IMPLEMENTATION());
        address proxy = deployer.deployUpgradeable(_beneficiary, _owner, address(beacon));

        assertTrue(proxy != address(0));
        assertEq(TVSUpgradeable(payable(proxy)).owner(), _owner);
        assertEq(TVSUpgradeable(payable(proxy)).getBeneficiary(), _beneficiary);
    }

    // ============ Functional Tests (Deployed TVS Works) ============

    function testDeployedCloneCanReceiveAndSweep() public {
        address payable clone = payable(deployer.deployClone(beneficiary, owner));

        // Send ETH to the clone
        uint256 amount = 1 ether;
        vm.deal(address(this), amount);
        (bool sent,) = clone.call{ value: amount }("");
        assertTrue(sent, "Failed to send ETH to clone");
        assertEq(clone.balance, amount);

        // Anyone can sweep to default beneficiary
        ITVS(clone).sweep(address(0), 0);
        assertEq(beneficiary.balance, amount, "Beneficiary should receive swept funds");
        assertEq(clone.balance, 0, "Clone balance should be zero after sweep");
    }

    function testDeployedImmutableCanReceiveAndSweep() public {
        address payable tvs = payable(deployer.deployImmutable(beneficiary, owner));

        // Send ETH to the TVS
        uint256 amount = 1 ether;
        vm.deal(address(this), amount);
        (bool sent,) = tvs.call{ value: amount }("");
        assertTrue(sent, "Failed to send ETH to TVS");
        assertEq(tvs.balance, amount);

        // Anyone can sweep to default beneficiary
        ITVS(tvs).sweep(address(0), 0);
        assertEq(beneficiary.balance, amount, "Beneficiary should receive swept funds");
    }

    function testDeployedUpgradeableCanReceiveAndSweep() public {
        UpgradeableBeacon beacon = new UpgradeableBeacon(owner, deployer.UPGRADEABLE_TVS_IMPLEMENTATION());
        address payable proxy = payable(deployer.deployUpgradeable(beneficiary, owner, address(beacon)));

        // Send ETH to the proxy
        uint256 amount = 1 ether;
        vm.deal(address(this), amount);
        (bool sent,) = proxy.call{ value: amount }("");
        assertTrue(sent, "Failed to send ETH to proxy");
        assertEq(proxy.balance, amount);

        // Anyone can sweep to default beneficiary
        ITVS(proxy).sweep(address(0), 0);
        assertEq(beneficiary.balance, amount, "Beneficiary should receive swept funds");
    }

    function testDeployedTVSOwnerCanSetBeneficiary() public {
        address payable tvs = payable(deployer.deployImmutable(beneficiary, owner));
        address newBeneficiary = makeAddr("newBeneficiary");

        vm.prank(owner);
        ITVS(tvs).setBeneficiary(newBeneficiary);

        assertEq(ITVS(tvs).getBeneficiary(), newBeneficiary);
    }

    function testDeployedTVSNonOwnerCannotSetBeneficiary() public {
        address payable tvs = payable(deployer.deployImmutable(beneficiary, owner));
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        ITVS(tvs).setBeneficiary(makeAddr("newBeneficiary"));
    }

    // ============ Version Test ============

    function testDeployedTVSVersionsMatch() public {
        address payable clone = payable(deployer.deployClone(beneficiary, owner));
        address payable immutableTvs = payable(deployer.deployImmutable(beneficiary, owner));
        address payable flexibleTvs = payable(deployer.deployFlexibleImmutable(beneficiary, owner));
        UpgradeableBeacon beacon = new UpgradeableBeacon(owner, deployer.UPGRADEABLE_TVS_IMPLEMENTATION());
        address payable upgradeableTvs = payable(deployer.deployUpgradeable(beneficiary, owner, address(beacon)));

        string memory expectedVersion = "1.0.2";
        assertEq(ITVS(clone).version(), expectedVersion);
        assertEq(ITVS(immutableTvs).version(), expectedVersion);
        assertEq(ITVS(flexibleTvs).version(), expectedVersion);
        assertEq(ITVS(upgradeableTvs).version(), expectedVersion);
    }
    
    function testDeployUpgradeableWithInvalidBeacon() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidImplementation()"));
        deployer.deployUpgradeable(beneficiary, owner, address(0x01));
    }
}
