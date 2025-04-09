//SPDX-License-Identifier: Proprietary

pragma solidity 0.8.28;

import "forge-std/Test.sol";

import { TVSUpgradeable as TVSV1 } from "../src/TVSUpgradeable/TVSUpgradeable.sol";
import { ImmutableBeacon } from "../src/TVSUpgradeable/ImmutableBeacon.sol";

import "../src/TVSUpgradeable/proxies/TVSBeaconProxy.sol";
import { UpgradeableBeacon } from "lib/solady/src/utils/UpgradeableBeacon.sol";
import { ITVS } from "../src/interfaces/ITVS.sol";
import { BaseTVSTest, PectraAddress } from "./TVS.t.sol";
import { ImmutableBeaconFactory } from "../src/TVSUpgradeable/ImmutableBeaconFactory.sol";

contract MockInvalidTVSImplementation { }

contract MockInvalidBeacon {
    address internal implementation; // implementation is internal here, so no implementation() method

    constructor(address _initialImplementation) {
        implementation = _initialImplementation;
    }
}

contract MockInvalidImmutableBeaconFactory {
    function deployBeacon(address implementation) external returns (address beacon) {
        return address(new MockInvalidBeacon(implementation));
    }
}

contract TVSUpgradeableInitializationTest is Test, PectraAddress {
    address beacon;
    address beneficiary;
    address owner;
    address tvsImplementation;
    address immutableBeaconFactory = address(new ImmutableBeaconFactory());

    function setUp() public {
        tvsImplementation =
            address(new TVSV1(WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS, immutableBeaconFactory));
        beneficiary = makeAddr("beneficiary");
        owner = makeAddr("owner");
        beacon = address(new UpgradeableBeacon(owner, tvsImplementation));
    }

    /**
     * @notice Tests that the constructor reverts when the withdrawal contract address is zero.
     * @dev Expects the `InvalidAddress()` error to be reverted.
     */
    function testConstructorWithZeroWithdrawalContract() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSV1(address(0), CONSOLIDATION_CONTRACT_ADDRESS, immutableBeaconFactory);
    }

    /**
     * @notice Tests that the constructor reverts when the consolidation contract address is zero.
     * @dev Expects revert without data `InvalidAddress()` error to be reverted.
     */
    function testConstructorWithZeroConsolidationContract() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSV1(WITHDRAWAL_CONTRACT_ADDRESS, address(0), immutableBeaconFactory);
    }

    /**
     * @notice Tests that the constructor reverts when the immutableBeaconFactory is zero.
     * @dev Expects to be reverted without data.
     */
    function testConstructorWithZeroImmutableBeaconFactory() public {
        vm.expectRevert();
        new TVSV1(WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS, address(0));
    }

    /**
     * @notice Tests deployment of `TVSBeaconProxy` with valid arguments.
     * @dev Ensures that:
     * - The contract deploys and initializes successfully.
     * - The beacon, owner, and beneficiary are correctly set, as confirmed by getter functions.
     * - A custom error `InvalidInitialization()` is reverted if `initialize` is called after deployment.
     */
    function testDeployWithValidArguments() public {
        // Deploy the contract with the given valid arguments
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", beneficiary, owner, beacon);
        TVSV1 tvsProxy = TVSV1(address(new TVSBeaconProxy(beacon, initData)));

        // Ensure that the contract was deployed and initialized successfully
        assertEq(tvsProxy.beacon(), beacon, "Beacon address not correct");
        assertEq(tvsProxy.getBeneficiary(), beneficiary, "Beneficiary address not correct");
        assertEq(tvsProxy.owner(), owner, "Owner address not correct");

        // This check is to ensure that the implementation code is not empty because it was set while the implementation
        // was being deployed
        assertNotEq(
            ImmutableBeacon(TVSV1(address(tvsImplementation)).immutableBeacon()).implementation().code.length,
            0,
            "immutableBeacon implementation code not correct"
        );

        // Ensure that the contract cannot be initialized again
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        tvsProxy.initialize(beneficiary, owner, beacon);
    }

    /**
     * @notice Tests deployment of `TVSBeaconProxy` with a zero address as the beacon.
     * @dev Expects the deployment to revert with the custom error `InvalidBeacon()` when a zero address is provided as
     * the beacon.
     */
    function testWithZeroAddressBeacon() public {
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", beneficiary, owner, address(0));

        vm.expectRevert(abi.encodeWithSignature("InvalidBeacon()"));
        new TVSBeaconProxy(address(0), initData);
    }

    /**
     * @notice Tests deployment of `TVSBeaconProxy` with a non-contract address as the beacon.
     * @dev Expects the deployment to revert with the custom error `InvalidBeacon()` when a non-contract address is
     * provided as the beacon.
     */
    function testWithNonContractBeacon() public {
        address nonContractBeacon = makeAddr("beacon");
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", beneficiary, owner, nonContractBeacon);

        vm.expectRevert(abi.encodeWithSignature("InvalidBeacon()"));
        new TVSBeaconProxy(nonContractBeacon, initData);
    }

    /**
     * @notice Tests deployment of `TVSBeaconProxy` with a beacon that returns a non-`TVS` contract as implementation.
     * @dev Expects the deployment to revert with the custom error `InitializationFailed()` when the beacon returns an
     * incompatible implementation.
     */
    function testWithNonTVSImplementation() public {
        // Deploy a non-TVS contract to act as an invalid implementation
        MockInvalidTVSImplementation invalidImplementation = new MockInvalidTVSImplementation();

        // Set the beacon to return this non-TVS implementation
        address _beacon = address(new UpgradeableBeacon(owner, address(invalidImplementation)));
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", beneficiary, owner, beacon);

        // Expect the transaction to revert with InitializationFailed() error due to non-TVS implementation
        vm.expectRevert(abi.encodeWithSignature("InitializationFailed()"));
        new TVSBeaconProxy(_beacon, initData);
    }

    /**
     * @notice Tests deployment of `TVSBeaconProxy` with a zero address as the owner.
     * @dev Expects the deployment to revert with the custom error `InitializationFailed()` when a zero address is
     * provided as the owner.
     */
    function testWithZeroAddressOwner() public {
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", beneficiary, address(0), beacon);

        vm.expectRevert(abi.encodeWithSignature("InitializationFailed()"));
        new TVSBeaconProxy(beacon, initData);
    }

    /**
     * @notice Tests deployment of `TVSBeaconProxy` with a zero address as the beneficiary.
     * @dev Expects the deployment to revert with the custom error `InitializationFailed()` when a zero address is
     * provided as the beneficiary.
     */
    function testWithZeroAddressBeneficiary() public {
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", address(0), owner, beacon);

        vm.expectRevert(abi.encodeWithSignature("InitializationFailed()"));
        new TVSBeaconProxy(beacon, initData);
    }
}

// Tests specific to TVSUpgradeable
contract TVSUpgradeableTest is BaseTVSTest {
    // Keep the inherited TVS tvs for base functionality
    TVSV1 public tvsV1; // Add separate TVSV1 reference for upgradeable-specific functions
    address beacon;
    address tvsImplementation;
    address immutableBeaconFactory = address(new ImmutableBeaconFactory());

    event BeaconUpdated(address indexed oldBeacon, address indexed newBeacon);

    function setUp() public override {
        tvsImplementation =
            address(new TVSV1(WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS, immutableBeaconFactory));
        owner = makeAddr("owner");
        beacon = address(new UpgradeableBeacon(owner, tvsImplementation));

        super.setUp();
        tvsV1 = TVSV1(address(tvs)); // Cast the TVS address to TVSV1
    }

    function deployTVS() internal override returns (ITVS) {
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", beneficiary, owner, beacon);

        return ITVS(address(new TVSBeaconProxy(beacon, initData)));
    }

    /**
     * @notice Tests setting a new beacon address by the owner using the `setBeacon` function.
     * @dev Expects the beacon address to be updated successfully when set by the owner.
     */
    function testUpdateUsingSetBeaconFunction() public {
        address newBeacon = address(new UpgradeableBeacon(owner, tvsImplementation));

        vm.expectEmit(true, true, true, true);
        emit BeaconUpdated(tvsV1.beacon(), newBeacon);

        vm.prank(owner);
        tvsV1.setBeacon(newBeacon);

        assertEq(newBeacon, tvsV1.beacon());
    }

    /**
     * @notice Tests setting a new valid beacon address by the owner using the `setBeaconUnchecked` function.
     * @dev Expects the beacon address to be updated successfully when set by the owner using `unsafeSetBeacon`.
     */
    function testUpdateUsingSetBeaconUncheckedFunction() public {
        address newBeacon = address(new UpgradeableBeacon(owner, tvsImplementation));

        vm.expectEmit(true, true, true, true);
        emit BeaconUpdated(tvsV1.beacon(), newBeacon);

        vm.prank(owner);
        tvsV1.setBeaconUnchecked(newBeacon);

        assertEq(newBeacon, tvsV1.beacon());
    }

    /**
     * @notice Tests setting a zero address as the new beacon address.
     * @dev Expects the transaction to revert when attempting to set a zero address as the beacon.
     */
    function testUpdateBeaconWithInValidAddress() public {
        address newBeacon = address(0);

        vm.expectRevert();

        vm.prank(owner);
        tvsV1.setBeacon(newBeacon);
    }

    /**
     * @notice Tests setting a new beacon address that does not implement the required `implementation()` function.
     * @dev Expects the transaction to revert when a beacon without `implementation()` is set.
     */
    function testUpdateUsingBeaconWithoutImplementationFunction() public {
        address newBeacon = address(new MockInvalidBeacon(tvsImplementation));

        vm.expectRevert();

        vm.prank(owner);
        tvsV1.setBeacon(newBeacon);
    }

    /**
     * @notice Tests setting a new beacon address that points to an implementation contract without
     * `setBeaconUnchecked(address)`.
     * @dev Expects the transaction to revert when the beacon's implementation lacks the `setBeaconUnchecked(address)`
     * function.
     */
    function testUpdateUsingBeaconWithImplementationWithoutUnsafeSetBeaconFunction() public {
        address invalidTVSImplementation = address(new MockInvalidTVSImplementation());
        address newBeacon = address(new UpgradeableBeacon(owner, invalidTVSImplementation));

        vm.expectRevert();

        vm.prank(owner);
        tvsV1.setBeacon(newBeacon);
    }

    /**
     * @notice Tests that a non-owner cannot set a new beacon address using both `setBeacon` and `unsafeSetBeacon`
     * functions.
     * @dev Expects the transaction to revert with the custom error `Unauthorized(msg.sender)` when a non-owner
     * attempts to set the beacon.
     */
    function testUpdateBeaconAsUnauthorized() public {
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);

        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));

        address newBeacon = makeAddr("newBeacon");
        tvsV1.setBeacon(newBeacon);
    }

    /**
     * @notice Tests the transfer function.
     * @dev Ensures that the state changes took effect and that the owner is the new owner.
     */
    function testTransfer() public {
        address newBeneficiary = makeAddr("newBeneficiary");
        address newOwner = makeAddr("newOwner");

        address oldBeacon = tvsV1.beacon();

        vm.prank(owner);
        tvsV1.transfer(newBeneficiary, newOwner);

        assertEq(tvsV1.getBeneficiary(), newBeneficiary, "Beneficiary address not updated");
        assertNotEq(tvsV1.beacon(), oldBeacon, "Beacon did not change after transfer");
        assertEq(
            tvsV1.beacon(),
            TVSV1(address(tvsImplementation)).immutableBeacon(),
            "Beacon address not updated to the immutableBeacon"
        );
        assertEq(tvsV1.owner(), newOwner, "Owner address not updated");
    }

    /**
     * @notice Tests that the transfer function fails if an invalid beacon is provided.
     */
    function testTransferFailsWithInvalidBeacon() public {
        address newBeneficiary = makeAddr("newBeneficiary");
        address newOwner = makeAddr("newOwner");

        address invalidImmutableBeaconFactory = address(new MockInvalidImmutableBeaconFactory());

        tvsImplementation = address(
            new TVSV1(WITHDRAWAL_CONTRACT_ADDRESS, CONSOLIDATION_CONTRACT_ADDRESS, invalidImmutableBeaconFactory)
        );
        beacon = address(new UpgradeableBeacon(owner, tvsImplementation));

        ITVS tvs = deployTVS();
        vm.prank(owner);
        vm.expectRevert();
        tvs.transfer(newBeneficiary, newOwner);
    }

    /**
     * @notice Tests the version function.
     * @dev Ensures that the version function returns the correct version string.
     */
    function testVersion() public view {
        // Call the version function
        string memory returnedVersion = tvs.version();

        // Assert that the returned version matches the expected value
        assertEq(returnedVersion, "v1.0.0 U", "Version string does not match expected value");
    }

    /**
     * @notice Tests that the immutable beacon deployment fails when the implementation is zero.
     * @dev Expects the transaction to revert with the custom error `InvalidImplementation()`.
     */
    function testImmutableBeaconDeploymentFailsWhenImplementationIsZero() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidImplementation()"));
        new ImmutableBeacon(address(0));
    }
}
