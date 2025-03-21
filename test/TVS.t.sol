//SPDX-License-Identifier: Proprietary

pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {TVSUpgradeable as TVSV1} from "../src/TVSUpgradeable/TVSUpgradeable.sol";
import {TVSImmutable} from "../src/TVSNonUpgradeable/TVSImmutable.sol";
import "../src/TVSUpgradeable/proxies/TVSBeaconProxy.sol";
import {UpgradeableBeacon} from "lib/solady/src/utils/UpgradeableBeacon.sol";
import {TVS} from "../src/TVS.sol";
import "../src/interfaces/ITVS.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";



contract MockInvalidBeacon {
    address internal implementation; // implementation is internal here, so no implementation() method

    constructor(address _initialImplementation) {
        implementation = _initialImplementation;
    }
}

contract MockInvalidTVSImplementation {}

contract MockExcessFeeRecipient {}

contract TVSUpgradeableInitializationTest is Test {
    address beacon;
    address beneficiary; 
    address owner;
    address tvsImplementation;

    function setUp() public {
        tvsImplementation = address(new TVSV1());
        beneficiary = makeAddr("beneficiary"); 
        owner = makeAddr("owner");
        beacon = address(new UpgradeableBeacon(owner, tvsImplementation));
    }

    /// @notice Tests deployment of `TVSProxy` with valid arguments.
    /// @dev Ensures that:
    /// - The contract deploys and initializes successfully.
    /// - The beacon, owner, and beneficiary are correctly set, as confirmed by getter functions. 
    /// - A custom error `InvalidInitialization(0, 1)` is reverted if `initialize` is called after deployment.
    function testDeployWithValidArguments() public {
        // Deploy the contract with the given valid arguments
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", beneficiary, owner, beacon); 
        TVSV1 tvsProxy = TVSV1(payable(new TVSBeaconProxy(beacon, initData)));

        // Ensure that the contract was deployed and initialized successfully
        assertEq(tvsProxy.beacon(), beacon, "Beacon address not correct");
        assertEq(tvsProxy.getBeneficiary(), beneficiary, "Beneficiary address not correct"); 
        assertEq(tvsProxy.owner(), owner, "Owner address not correct");

        // Ensure that the contract cannot be initialized again
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        tvsProxy.initialize(beneficiary, owner, beacon); 
    }
    /// @notice Tests deployment of `TVSProxy` with a zero address as the beacon.
    /// @dev Expects the deployment to revert with the custom error `InvalidBeacon()` when a zero address is provided as the beacon.

    function testWithZeroAddressBeacon() public {
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", beneficiary, owner, address(0)); 

        vm.expectRevert(abi.encodeWithSignature("InvalidBeacon()"));
        TVSV1(payable(new TVSBeaconProxy(address(0), initData)));
        
    }

    /// @notice Tests deployment of `TVSProxy` with a non-contract address as the beacon.
    /// @dev Expects the deployment to revert with the custom error `InvalidBeacon()` when a non-contract address is provided as the beacon.
    function testWithNonContractBeacon() public {
        address nonContractBeacon = makeAddr("beacon");
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", beneficiary, owner, nonContractBeacon); 

        vm.expectRevert(abi.encodeWithSignature("InvalidBeacon()"));
        TVSV1(payable(new TVSBeaconProxy(nonContractBeacon, initData)));
    }

    /// @notice Tests deployment of `TVSProxy` with a beacon that returns a non-`TVS` contract as implementation.
    /// @dev Expects the deployment to revert with the custom error `InitializationFailed()` when the beacon returns an incompatible implementation.
    function testWithNonTVSImplementation() public {
        // Deploy a non-TVS contract to act as an invalid implementation
        MockInvalidTVSImplementation invalidImplementation = new MockInvalidTVSImplementation();

        // Set the beacon to return this non-TVS implementation
        address _beacon = address(new UpgradeableBeacon(owner, address(invalidImplementation)));
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", beneficiary, owner, beacon); 

        // Expect the transaction to revert with InitializationFailed() error due to non-TVS implementation
        vm.expectRevert(abi.encodeWithSignature("InitializationFailed()"));
        TVSV1(payable(new TVSBeaconProxy(_beacon, initData)));
    }

    /// @notice Tests deployment of `TVSProxy` with a zero address as the owner.
    /// @dev Expects the deployment to revert with the custom error `InitializationFailed()` when a zero address is provided as the owner.
    function testWithZeroAddressOwner() public {
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", beneficiary, address(0), beacon); 

        vm.expectRevert(abi.encodeWithSignature("InitializationFailed()"));
        TVSV1(payable(new TVSBeaconProxy(beacon, initData)));
    }

    /// @notice Tests deployment of `TVSProxy` with a zero address as the beneficiary. 
    /// @dev Expects the deployment to revert with the custom error `InitializationFailed()` when a zero address is provided as the beneficiary. 
    function testWithZeroAddressBeneficiary() public { 
        bytes memory initData =
            abi.encodeWithSignature("initialize(address,address,address)", address(0), owner, beacon); 

        vm.expectRevert(abi.encodeWithSignature("InitializationFailed()"));
        TVSV1(payable(new TVSBeaconProxy(beacon, initData)));
    }
}

// Base test contract for common TVS functionality
abstract contract BaseTVSTest is Test {
    ITVS tvs;
    address beneficiary;
    address owner;

    event Swept(address indexed beneficiary, uint256 indexed amount);
    event BeneficiaryUpdated(address indexed newBeneficiary);
    event UnsentExcessFee(address indexed excessFeeRecipient, uint256 indexed excessFee);

    function setUp() public virtual {
        owner = makeAddr("owner");
        beneficiary = makeAddr("beneficiary");
        tvs = deployTVS();
    }

    // Abstract function to be implemented by derived test contracts
    function deployTVS() internal virtual returns (ITVS);


    // Common tests that work for both implementations
    function testSweepWithZeroBalance() public {
        vm.prank(owner);
        tvs.sweep(address(0), 0);
        assertEq(beneficiary.balance, 0 ether, "Beneficiary balance should be zero after sweep");
    }

    function testSweepWithNonZeroBalance() public {
        uint256 amount = 1 ether;
        vm.deal(address(tvs), amount);

        vm.expectEmit(true, true, true, true);
        emit Swept(beneficiary, amount);

        vm.prank(owner);
        tvs.sweep(address(0), 0);

        assertEq(beneficiary.balance, amount, "Beneficiary balance should be equal to the amount swept");
        assertEq(address(tvs).balance, 0, "Contract balance should be zero after sweep");
    }

    function testSetBeneficiaryWithValidAddress() public {
        address newBeneficiary = makeAddr("newBeneficiary");

        vm.expectEmit(true, true, true, true);
        emit BeneficiaryUpdated(newBeneficiary);

        vm.prank(owner);
        tvs.setBeneficiary(newBeneficiary);

        assertEq(newBeneficiary, tvs.getBeneficiary(), "Beneficiary address not updated");
    }

    function testSetBeneficiaryWithInvalidAddress() public {
        address newBeneficiary = address(0);

        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));

        vm.prank(owner);
        tvs.setBeneficiary(newBeneficiary);
    }

    function testSetBeneficiaryAsUnauthorized() public {

        address randomCaller = makeAddr("randomCaller");
        address newBeneficiary = makeAddr("newBeneficiary");
        vm.prank(randomCaller);

        vm.expectRevert(abi.encodeWithSignature("NotOwner(address)", randomCaller));

        tvs.setBeneficiary(newBeneficiary);
    }

    function testConsolidateFailsIfNoValueSent() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        bytes memory targetPubkey = hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVSBase.ConsolidationRequest(srcPubkeys, targetPubkey);

        // Mock the call to revert
        vm.mockCallRevert(
            CONSOLIDATION_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            abi.encodePacked("")
        );

        vm.prank(owner);

        // Expect the transaction to revert due to the call to CONSOLIDATION_CONTRACT_ADDRESS reverting
        uint256 maxFeePerConsolidation = 0.1 ether; // Example max fee
        vm.expectRevert(abi.encodeWithSignature("FeeReadFailed()"));
        tvs.consolidate(requests, maxFeePerConsolidation, owner);
    }

    function testConsolidateRefundsSenderAnyExcessFund() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        bytes memory targetPubkey = hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVSBase.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 1.5 ether; // Example max fee
        vm.deal(owner, maxFeePerConsolidation);

        // Mock static call response with a higher fee than maxFeePerConsolidation
        uint256 fee = maxFeePerConsolidation - 1;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(
            CONSOLIDATION_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            mockFeeData
        );

        vm.prank(owner);

        uint256 ownerBalBefore = owner.balance;
        tvs.consolidate{value: maxFeePerConsolidation}(requests, maxFeePerConsolidation, owner);
        uint ownerBalAfter = owner.balance;
        assertEq(ownerBalAfter, ownerBalBefore - fee, "Owner should be refunded any excess funds after actual fee deduction.");
    }

    function testConsolidateEmitsEventIfSendToExcessFeeRecipientFails() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        bytes memory targetPubkey = hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVSBase.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 2 ether; // Example max fee
        vm.deal(owner, maxFeePerConsolidation);

        // Mock static call response with a higher fee than maxFeePerConsolidation
        uint256 fee = maxFeePerConsolidation - 1 ether ;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(
            CONSOLIDATION_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            mockFeeData
        );


        address excessFeeRecipient = address(new MockExcessFeeRecipient());

        vm.expectEmit(true, true, true, true);
        emit UnsentExcessFee(excessFeeRecipient, 1 ether);
        
        vm.prank(owner);
        tvs.consolidate{value: maxFeePerConsolidation}(requests, maxFeePerConsolidation, excessFeeRecipient);
    }

    function testConsolidateLeavesExcessFundsInTVSIfSendToExcessFeeRecipientFails() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        bytes memory targetPubkey = hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVSBase.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 2 ether; // Example max fee
        vm.deal(owner, maxFeePerConsolidation);

        // Mock static call response with a higher fee than maxFeePerConsolidation
        uint256 fee = maxFeePerConsolidation - 1 ether;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(
            CONSOLIDATION_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            mockFeeData
        );

        // Mock the call to succeed
        bytes memory callData = bytes.concat(srcPubkeys[0], targetPubkey);
        vm.mockCall( // TODO: ensure mock call reduces contract balance
            CONSOLIDATION_CONTRACT_ADDRESS,
            fee, 
            callData,
            abi.encodePacked("")
        );

        vm.prank(owner);

        // Expect the call to the consolidation contract
        vm.expectCall(
            CONSOLIDATION_CONTRACT_ADDRESS,
            fee, 
            callData
        );
        

        address excessFeeRecipient = address(new MockExcessFeeRecipient());

        uint256 tvsBalanceBefore = address(tvs).balance;
        vm.prank(owner);
        tvs.consolidate{value: maxFeePerConsolidation}(requests, maxFeePerConsolidation, excessFeeRecipient);

        assertEq(address(tvs).balance - tvsBalanceBefore, maxFeePerConsolidation, "TVS should retain any excess funds after failed send to excessFeeRecipient");
    }

    function testConsolidateFailsIfFeeExceedsMax() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        bytes memory targetPubkey = hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVSBase.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether; // Example max fee
        vm.deal(address(tvs), maxFeePerConsolidation);

        // Mock static call response with a higher fee than maxFeePerConsolidation
        uint256 fee = maxFeePerConsolidation + 1;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(
            CONSOLIDATION_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            mockFeeData
        );

        vm.prank(owner);

        // Expect the transaction to revert due to fee exceeding maxFeePerConsolidation
        vm.expectRevert(abi.encodeWithSignature("FeeTooHigh(uint256,uint256)", fee, maxFeePerConsolidation));
        tvs.consolidate(requests, maxFeePerConsolidation, owner);
    }

    function testConsolidateFailsIfRequestFails() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        bytes memory targetPubkey = hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVSBase.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether; // Example max fee
        vm.deal(address(tvs), maxFeePerConsolidation);

        // Mock static call response with a valid fee
        bytes memory mockFeeData = abi.encodePacked(maxFeePerConsolidation);

        vm.mockCall(
            CONSOLIDATION_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            mockFeeData
        );

        // Mock the call to fail
        vm.mockCallRevert(
            CONSOLIDATION_CONTRACT_ADDRESS,
            abi.encodePacked(srcPubkeys[0], targetPubkey),
            abi.encodePacked("")
        );

        vm.prank(owner);

        // Expect the transaction to revert due to the call to CONSOLIDATION_CONTRACT_ADDRESS failing
        vm.expectRevert(abi.encodeWithSignature("RequestFailed()"));        
        tvs.consolidate(requests, maxFeePerConsolidation, owner);
    }
    
    function testConsolidateWorksIfAllIsFine() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        bytes memory targetPubkey = hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVSBase.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether; // Example max fee
        vm.deal(address(tvs), maxFeePerConsolidation);

        // Mock static call response with a valid fee
        bytes memory mockFeeData = abi.encodePacked(maxFeePerConsolidation);

        vm.mockCall(
            CONSOLIDATION_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            mockFeeData
        );

        // Mock the call to succeed
        bytes memory callData = bytes.concat(srcPubkeys[0], targetPubkey);
        vm.mockCall(
            CONSOLIDATION_CONTRACT_ADDRESS,
            callData,
            abi.encodePacked("")
        );

        vm.prank(owner);

        // Expect the call to the consolidation contract
        vm.expectCall(
            CONSOLIDATION_CONTRACT_ADDRESS,
            maxFeePerConsolidation, 
            callData
        );

        // Call the consolidate function
        tvs.consolidate(requests, maxFeePerConsolidation, owner);


    }

    function testwithdrawFailsIfFeeReadFails() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock the call to revert
        vm.mockCallRevert(
            WITHDRAWAL_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            abi.encodePacked("")
        );

        vm.prank(owner);

        // Expect the transaction to revert due to the call to WITHDRAWAL_CONTRACT_ADDRESS reverting
        vm.expectRevert(abi.encodeWithSignature("FeeReadFailed()"));
        tvs.withdraw{value: maxFeePerWithdrawal}(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    function testwithdrawFailsIfFeeExceedsMax() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock static call response with a higher fee than maxFeePerWithdrawal
        uint256 fee = maxFeePerWithdrawal + 1;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(
            WITHDRAWAL_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            mockFeeData
        );

        vm.prank(owner);

        // Expect the transaction to revert due to fee exceeding maxFeePerWithdrawal
        vm.expectRevert(abi.encodeWithSignature("FeeTooHigh(uint256,uint256)", fee, maxFeePerWithdrawal));
        tvs.withdraw{value: maxFeePerWithdrawal}(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    function testwithdrawFailsIfRequestFails() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock static call response with a valid fee
        bytes memory mockFeeData = abi.encodePacked(maxFeePerWithdrawal);

        vm.mockCall(
            WITHDRAWAL_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            mockFeeData
        );

        // Mock the call to fail
        vm.mockCallRevert(
            WITHDRAWAL_CONTRACT_ADDRESS,
            abi.encodePacked(pubkeys[0], amounts[0]),
            abi.encodePacked("")
        );

        vm.prank(owner);

        // Expect the transaction to revert due to the call to WITHDRAWAL_CONTRACT_ADDRESS failing
        vm.expectRevert(abi.encodeWithSignature("RequestFailed()"));
        tvs.withdraw{value: maxFeePerWithdrawal}(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    function testWithdrawRefundsSenderAnyExcessFund() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 2 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock static call response with a valid fee
        uint256 fee = maxFeePerWithdrawal - 1 ether;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(
            WITHDRAWAL_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            mockFeeData
        );

        vm.prank(owner);

        uint256 ownerBalBefore = owner.balance;
        tvs.withdraw{value: maxFeePerWithdrawal}(pubkeys, amounts, maxFeePerWithdrawal, owner);
        uint ownerBalAfter = owner.balance;
        assertEq(ownerBalAfter, ownerBalBefore - fee, "Owner should be refunded any excess funds after actual fee deduction.");
    }

    function testwithdrawEmitsEventIfSendToExcessFeeRecipientFails() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 2 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock static call response with a valid fee
        bytes memory mockFeeData = abi.encodePacked(maxFeePerWithdrawal - 1 ether);

        vm.mockCall(
            WITHDRAWAL_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            mockFeeData
        );

        address excessFeeRecipient = address(new MockExcessFeeRecipient());

        vm.expectEmit(true, true, true, true);
        emit UnsentExcessFee(excessFeeRecipient, 1 ether);
        
        vm.prank(owner);
        tvs.withdraw{value: maxFeePerWithdrawal}(pubkeys, amounts, maxFeePerWithdrawal, excessFeeRecipient);
    }

    function testWithdrawLeavesExcessFundsInTVSIfSendToExcessFeeRecipientFails() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 2 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock static call response with a valid fee
        uint256 fee = maxFeePerWithdrawal - 1 ether;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(
            WITHDRAWAL_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            mockFeeData
        );

        // Mock the call to succeed
        bytes memory callData = abi.encodePacked(pubkeys[0], amounts[0]);
        vm.mockCall(
            WITHDRAWAL_CONTRACT_ADDRESS,
            fee,
            callData,
            abi.encodePacked("")
        );

        vm.prank(owner);
        // Expect the call to the consolidation contract
        vm.expectCall(
            WITHDRAWAL_CONTRACT_ADDRESS,
            fee,
            callData
        );

        address excessFeeRecipient = address(new MockExcessFeeRecipient());

        uint256 tvsBalanceBefore = address(tvs).balance;
        vm.prank(owner);
        tvs.withdraw{value: maxFeePerWithdrawal}(pubkeys, amounts, maxFeePerWithdrawal, excessFeeRecipient);

        assertEq(address(tvs).balance - tvsBalanceBefore, maxFeePerWithdrawal, "TVS should retain any excess funds after failed send to excessFeeRecipient");
    }

    function testwithdrawWorksIfAllIsFine() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock static call response with a valid fee
        bytes memory mockFeeData = abi.encodePacked(maxFeePerWithdrawal);

        vm.mockCall(
            WITHDRAWAL_CONTRACT_ADDRESS,
            abi.encodePacked(""),
            mockFeeData
        );

        // Mock the call to succeed
        bytes memory callData = abi.encodePacked(pubkeys[0], amounts[0]);
        vm.mockCall(
            WITHDRAWAL_CONTRACT_ADDRESS,
            callData,
            abi.encodePacked("")
        );

        vm.prank(owner);
        // Expect the call to the consolidation contract
        vm.expectCall(
            WITHDRAWAL_CONTRACT_ADDRESS,
            maxFeePerWithdrawal,
            callData
        );
        // Call the withdraw function
        tvs.withdraw{value: maxFeePerWithdrawal}(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

}

// Tests specific to TVSImmutable
contract TVSImmutableTest is BaseTVSTest {
    function deployTVS() internal override returns (ITVS) {
        return new TVSImmutable(beneficiary, owner);
    }

    function testConstructorWithZeroAddressOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        new TVSImmutable(beneficiary, address(0));
    }

    function testConstructorWithZeroAddressBeneficiary() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new TVSImmutable(address(0), owner);
    }

    /// @notice Tests the transfer function.
    /// @dev Ensures that the state changes took effect and that the owner is the new owner.
    function testTransfer() public {
        address newBeneficiary = makeAddr("newBeneficiary");
        address newOwner = makeAddr("newOwner");

        vm.prank(owner);
        TVSImmutable(payable(tvs)).transfer(newBeneficiary, newOwner);

        assertEq(tvs.getBeneficiary(), newBeneficiary, "Beneficiary address not updated");
        assertEq(Ownable(address(tvs)).owner(), newOwner, "Owner address not updated");
    }

    /// @notice Tests that the transfer function fails if called by a non-owner.
    function testTransferFailsIfNotOwner() public {
        address newBeneficiary = makeAddr("newBeneficiary");
        address newOwner = makeAddr("newOwner");
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("NotOwner(address)", nonOwner));
        TVSImmutable(payable(tvs)).transfer(newBeneficiary, newOwner);
    }
}

// Tests specific to TVSUpgradeable
contract TVSUpgradeableTest is BaseTVSTest {
    // Keep the inherited TVS tvs for base functionality
    TVSV1 public tvsV1;  // Add separate TVSV1 reference for upgradeable-specific functions
    address beacon;
    address tvsImplementation;

    event BeaconUpdated(address indexed oldBeacon, address indexed newBeacon);


    function setUp() public override {
        owner = makeAddr("owner");
        beneficiary = makeAddr("beneficiary");
        tvsImplementation = address(new TVSV1());
        beacon = address(new UpgradeableBeacon(owner, tvsImplementation));
        tvs = deployTVS();
        tvsV1 = TVSV1(payable(tvs)); // Cast the TVS address to TVSV1
    }

    function deployTVS() internal override returns (ITVS) {
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,address)",
            beneficiary,
            owner,
            beacon
        );
        return ITVS(payable(new TVSBeaconProxy(beacon, initData)));
    }

    /// @notice Tests setting a new beacon address by the owner using the `setBeacon` function.
    /// @dev Expects the beacon address to be updated successfully when set by the owner.
    function testUpdateUsingSetBeaconFunction() public {
        address newBeacon = address(new UpgradeableBeacon(owner, tvsImplementation));

        vm.expectEmit(true, true, true, true);
        emit BeaconUpdated(tvsV1.beacon(), newBeacon);

        vm.prank(owner);
        tvsV1.setBeacon(newBeacon);

        assertEq(newBeacon, tvsV1.beacon());
    }

    /// @notice Tests setting a new valid beacon address by the owner using the `unsafeSetBeacon` function.
    /// @dev Expects the beacon address to be updated successfully when set by the owner using `unsafeSetBeacon`.
    function testUpdateUsingUnsafeSetBeaconFunction() public {
        address newBeacon = address(new UpgradeableBeacon(owner, tvsImplementation));

        vm.expectEmit(true, true, true, true);
        emit BeaconUpdated(tvsV1.beacon(), newBeacon);

        vm.prank(owner);
        tvsV1.unsafeSetBeacon(newBeacon);

        assertEq(newBeacon, tvsV1.beacon());
    }

    /// @notice Tests setting a zero address as the new beacon address.
    /// @dev Expects the transaction to revert when attempting to set a zero address as the beacon.
    function testUpdateWithInValidAddress() public {
        address newBeacon = address(0);

        vm.expectRevert();

        vm.prank(owner);
        tvsV1.setBeacon(newBeacon);
    }

    /// @notice Tests setting a new beacon address that does not implement the required `implementation()` function.
    /// @dev Expects the transaction to revert when a beacon without `implementation()` is set.
    function testUpdateUsingBeaconWithoutImplementationFunction() public {
        address newBeacon = address(new MockInvalidBeacon(tvsImplementation));

        vm.expectRevert();

        vm.prank(owner);
        tvsV1.setBeacon(newBeacon);
    }

    /// @notice Tests setting a new beacon address that points to an implementation contract without `unsafeSetBeacon(address)`.
    /// @dev Expects the transaction to revert when the beacon's implementation lacks the `unsafeSetBeacon(address)` function.
    function testUpdateUsingBeaconWithImplementationWithoutUnsafeSetBeaconFunction() public {
        address invalidTVSImplementation = address(new MockInvalidTVSImplementation());
        address newBeacon = address(new UpgradeableBeacon(owner, invalidTVSImplementation));

        vm.expectRevert();

        vm.prank(owner);
        tvsV1.setBeacon(newBeacon);
    }

    /// @notice Tests that a non-owner cannot set a new beacon address using both `setBeacon` and `unsafeSetBeacon` functions.
    /// @dev Expects the transaction to revert with the custom error `Unauthorized(msg.sender)` when a non-owner attempts to set the beacon.
    function testUpdateAsUnauthorized() public {
        address randomCaller = makeAddr("randomCaller");
        vm.prank(randomCaller);

        vm.expectRevert(abi.encodeWithSignature("NotOwner(address)", randomCaller));

        address newBeacon = makeAddr("newBeacon");
        tvsV1.setBeacon(newBeacon);
    }

    /// @notice Tests the transfer function.
    /// @dev Ensures that the state changes took effect and that the owner is the new owner.
    function testTransfer() public {
        address newBeneficiary = makeAddr("newBeneficiary");
        address newOwner = makeAddr("newOwner");
        address newBeacon = address(new UpgradeableBeacon(owner, tvsImplementation));

        vm.prank(owner);
        tvsV1.transfer(newBeneficiary, newOwner, newBeacon);

        assertEq(tvsV1.getBeneficiary(), newBeneficiary, "Beneficiary address not updated");
        assertEq(tvsV1.beacon(), newBeacon, "Beacon address not updated");
        assertEq(tvsV1.owner(), newOwner, "Owner address not updated");
    }

    /// @notice Tests that the transfer function fails if called by a non-owner.
    function testTransferFailsIfNotOwner() public {
        address newBeneficiary = makeAddr("newBeneficiary");
        address newBeacon = address(new UpgradeableBeacon(owner, tvsImplementation));
        address newOwner = makeAddr("newOwner");
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("NotOwner(address)", nonOwner));
        tvsV1.transfer(newBeneficiary, newOwner, newBeacon);
    }

    /// @notice Tests that the transfer function fails if an invalid beacon is provided.
    function testTransferFailsWithInvalidBeacon() public {
        address newBeneficiary = makeAddr("newBeneficiary");
        address newOwner = makeAddr("newOwner");
        address invalidBeacon = address(new MockInvalidBeacon(tvsImplementation));

        vm.prank(owner);
        vm.expectRevert();
        tvsV1.transfer(newBeneficiary, newOwner, invalidBeacon);
    }

}