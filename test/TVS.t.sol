// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import "forge-std/Test.sol";
import "../src/interfaces/ITVS.sol";
import "../src/interfaces/ITVSSweepBeneficiary.sol";
import "../src/interfaces/ITVSSweepBeneficiary.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract MockBeneficiaryContract is ITVSSweepBeneficiary {
    function receiveETHFromTVS() external payable override { }
}

abstract contract PectraAddress {
    address public constant WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;
    address public constant CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;
}

// Base test contract for common TVS functionality
abstract contract BaseTVSTest is Test, PectraAddress {
    ITVS tvs;
    address beneficiary;
    address owner;

    event Swept(address indexed beneficiary, uint256 indexed amount);
    event BeneficiaryUpdated(address indexed newBeneficiary);
    event UnsentExcessFee(address indexed excessFeeRecipient, uint256 indexed excessFee);
    event WithdrawalRequested(bytes pubkey, uint64 indexed amount, uint256 indexed fee);
    event ConsolidationRequested(bytes srcPubkey, bytes targetPubkey, uint256 indexed fee);

    /**
     * @notice Sets up the test environment.
     */
    function setUp() public virtual {
        owner = makeAddr("owner");
        beneficiary = makeAddr("beneficiary");
        tvs = deployTVS();
    }

    /**
     * @notice Abstract function to be implemented by derived test contracts.
     * @return The deployed TVS contract.
     */
    function deployTVS() internal virtual returns (ITVS);

    /**
     * @notice Common tests that work for both implementations.
     */
    function testSweepToCustomBeneficiaryFailsIfNotOwner() public {
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);

        address customBeneficiary = vm.addr(5);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        tvs.sweep(customBeneficiary, 0);
    }

    /**
     * @notice Tests that the sweep function reverts when the caller is not the owner.
     */
    function testSweepAllWhenZeroBalance() public {
        tvs.sweep(address(0), 0);
        assertEq(beneficiary.balance, 0 ether, "Beneficiary balance should be zero after sweep");
    }

    /**
     * @notice Tests that a non-owner can sweep to the default beneficiary.
     */
    function testNonOwnerCanSweepToDefaultBeneficiary() public {
        uint256 amount = 1 ether;
        vm.deal(address(tvs), amount);

        vm.expectEmit(true, true, true, true);
        emit Swept(beneficiary, amount);

        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);
        tvs.sweep(address(0), 0);

        assertEq(beneficiary.balance, amount, "Beneficiary balance should be equal to the amount swept");
        assertEq(address(tvs).balance, 0, "Contract balance should be zero after sweep");
    }

    /**
     * @notice Tests that the sweep function reverts when the balance is insufficient.
     */
    function testSweepWithFailsWhenBalanceInsufficient() public {
        uint256 balance = 1 ether;
        uint256 amount = balance + 1;
        vm.deal(address(tvs), balance);

        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance(uint256,uint256)", balance, amount));
        vm.prank(owner);
        tvs.sweep(address(0), amount);
    }

    /**
     * @notice Tests that the sweep function reverts when the beneficiary contract does not implement the
     * `sweepToBeneficiaryContract` function.
     */
    function testSweepToContractWithNoSweepToContractInterface() public {
        uint256 amount = 1 ether;
        vm.deal(address(tvs), amount);

        vm.expectRevert();
        tvs.sweepToBeneficiaryContract(address(0), 0);
    }

    /**
     * @notice Tests that the sweep function works when the beneficiary contract implements the
     * `sweepToBeneficiaryContract` function.
     */
    function testSweepToContractWithSweepToContractInterfaceWorks() public {
        uint256 amount = 1 ether;
        vm.deal(address(tvs), 2 ether);

        MockBeneficiaryContract beneficiaryContract = new MockBeneficiaryContract();
        address beneficiaryContractAddress = address(beneficiaryContract);

        vm.expectEmit(true, true, true, true);
        emit Swept(beneficiaryContractAddress, amount);

        vm.prank(owner);
        tvs.sweepToBeneficiaryContract(beneficiaryContractAddress, amount);

        assertEq(
            address(beneficiaryContract).balance, amount, "SweepToContract balance should be equal to the amount swept"
        );
        assertEq(address(tvs).balance, amount, "Contract balance should be zero after sweep");

        // test the default beneficiary contract can receive funds
        vm.prank(owner);
        tvs.setBeneficiary(beneficiaryContractAddress);

        vm.expectEmit(true, true, true, true);
        emit Swept(beneficiaryContractAddress, amount);

        vm.prank(owner);
        tvs.sweepToBeneficiaryContract(address(0), 0);

        assertEq(
            address(beneficiaryContract).balance,
            amount + amount,
            "SweepToContract balance should be equal to the cumulative amount swept"
        );
        assertEq(address(tvs).balance, 0, "Contract balance should be zero after sweep");
    }

    /**
     * @notice Tests that the setBeneficiary function works when the beneficiary address is valid.
     */
    function testSetBeneficiaryWithValidAddress() public {
        address newBeneficiary = makeAddr("newBeneficiary");

        vm.expectEmit(true, true, true, true);
        emit BeneficiaryUpdated(newBeneficiary);

        vm.prank(owner);
        tvs.setBeneficiary(newBeneficiary);

        assertEq(newBeneficiary, tvs.getBeneficiary(), "Beneficiary address not updated");
    }

    /**
     * @notice Tests that the setBeneficiary function reverts when the beneficiary address is invalid.
     */
    function testSetBeneficiaryWithInvalidAddress() public {
        address newBeneficiary = address(0);

        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));

        vm.prank(owner);
        tvs.setBeneficiary(newBeneficiary);
    }

    /**
     * @notice Tests that the setBeneficiary function reverts when the caller is not the owner.
     */
    function testSetBeneficiaryAsUnauthorized() public {
        address nonOwner = makeAddr("nonOwner");
        address newBeneficiary = makeAddr("newBeneficiary");
        vm.prank(nonOwner);

        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));

        tvs.setBeneficiary(newBeneficiary);
    }

    /**
     * @notice Tests that the consolidate function reverts when no value is sent.
     */
    function testConsolidateFailsIfNoValueSent() public {
        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        bytes memory targetPubkey =
            hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte
        // example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        // Mock the call to revert
        vm.mockCallRevert(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), abi.encodePacked(""));

        vm.prank(owner);

        // Expect the transaction to revert due to the call to CONSOLIDATION_CONTRACT_ADDRESS reverting
        uint256 maxFeePerConsolidation = 0.1 ether; // Example max fee
        vm.expectRevert(abi.encodeWithSignature("FeeReadFailed()"));
        tvs.consolidate(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the consolidate function refunds the sender any excess funds after actual fee deduction.
     */
    function testConsolidateRefundsSenderAnyExcessFund() public {
        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcdef1234567890abcd12345678ef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcdef1234567890abcdef123412345678567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 1.5 ether; // Example max fee
        vm.deal(owner, maxFeePerConsolidation);

        // Mock static call response with a higher fee than maxFeePerConsolidation
        uint256 fee = maxFeePerConsolidation - 1;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        vm.prank(owner);

        uint256 ownerBalBefore = owner.balance;
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
        uint256 ownerBalAfter = owner.balance;
        assertEq(
            ownerBalAfter, ownerBalBefore - fee, "Owner should be refunded any excess funds after actual fee deduction."
        );
    }

    /**
     * @notice Tests that the consolidate function emits an event when excess refunds fail.
     */
    function testConsolidateEmitsEventWhenExcessRefundsFail() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 1.5 ether; // Example max fee
        vm.deal(owner, maxFeePerConsolidation);

        // Mock static call response with a higher fee than maxFeePerConsolidation
        uint256 fee = maxFeePerConsolidation - 1;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        // Deploy a contract that cannot receive ETH
        address excessFeeRecipient = address(new MockBeneficiaryContract());

        // Expect the transaction to revert due to fee exceeding maxFeePerConsolidation
        uint256 ownerBalBefore = owner.balance;
        uint256 excessFee = ownerBalBefore - fee;

        vm.expectEmit(true, true, true, true);
        emit UnsentExcessFee(excessFeeRecipient, excessFee);

        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, excessFeeRecipient);
    }

    /**
     * @notice Tests that the consolidate function reverts when the fee exceeds the max fee.
     */
    function testConsolidateFailsIfFeeExceedsMax() public {
        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether; // Example max fee
        uint256 value = maxFeePerConsolidation + 1;
        vm.deal(owner, value);

        // Mock static call response with a higher fee than maxFeePerConsolidation
        uint256 fee = maxFeePerConsolidation + 1;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        vm.prank(owner);

        // Expect the transaction to revert due to fee exceeding maxFeePerConsolidation
        vm.expectRevert(abi.encodeWithSignature("FeeTooHigh(uint256,uint256)", fee, maxFeePerConsolidation));
        tvs.consolidate{ value: value }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the consolidate function reverts when the fee exceeds the value.
     */
    function testConsolidateFailsIfFeeExceedsValue() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerConsolidation);

        // leave surplus funds in contract. so although enough funds exist
        // in contract we still expect revert because fees should only come from
        // sufficient msg.value
        vm.deal(address(tvs), 10 ether);

        bytes memory mockFeeData = abi.encodePacked(maxFeePerConsolidation);

        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        vm.prank(owner);

        // Expect the transaction to revert due to fee exceeding maxFeePerConsolidation
        uint256 value = maxFeePerConsolidation - 1;
        vm.expectRevert(
            abi.encodeWithSignature("InsufficientValueForFee(uint256,uint256)", value, maxFeePerConsolidation)
        );
        tvs.consolidate{ value: value }(requests, maxFeePerConsolidation, owner);
    }

    function testConsolidateFailsIfFeeExceedsValueForMultipleConsolidations() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](4);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        srcPubkeys[1] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        srcPubkeys[2] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        srcPubkeys[3] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys2 = new bytes[](4);
        srcPubkeys2[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        srcPubkeys2[1] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        srcPubkeys2[2] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        srcPubkeys2[3] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        bytes memory targetPubkey2 =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](2);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);
        requests[1] = ITVS.ConsolidationRequest(srcPubkeys2, targetPubkey2);

        uint256 maxFeePerConsolidation = 0.1 ether; // Example max fee
        vm.deal(owner, 1 ether); // Give enough funds for the test

        // leave surplus funds in contract. so although enough funds exist
        // in contract we still expect revert because fees should only come from
        // sufficient msg.value
        vm.deal(address(tvs), 10 ether);

        bytes memory mockFeeData = abi.encodePacked(maxFeePerConsolidation);

        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        vm.prank(owner);

        // Expect the transaction to revert due to insufficient value for total fee
        uint256 totalOperations = 4 * 2; // 4 srcPubkeys per request × 2 requests
        uint256 value = maxFeePerConsolidation * totalOperations - 1;
        uint256 totalFeeRequired = maxFeePerConsolidation * totalOperations;
        vm.expectRevert(abi.encodeWithSignature("InsufficientValueForFee(uint256,uint256)", value, totalFeeRequired));
        tvs.consolidate{ value: value }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the consolidate function reverts when the request fails.
     */
    function testConsolidateFailsIfRequestFails() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerConsolidation);

        // Mock static call response with a valid fee
        bytes memory mockFeeData = abi.encodePacked(maxFeePerConsolidation);

        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        // Mock the call to fail
        vm.mockCallRevert(
            CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(srcPubkeys[0], targetPubkey), abi.encodePacked("")
        );

        vm.prank(owner);

        // Expect the transaction to revert due to the call to CONSOLIDATION_CONTRACT_ADDRESS failing
        vm.expectRevert(abi.encodeWithSignature("RequestFailed()"));
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the consolidate function works if all is fine.
     */
    function testConsolidateWorksIfAllIsFine() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerConsolidation);

        // Mock static call response with a valid fee
        bytes memory mockFeeData = abi.encodePacked(maxFeePerConsolidation);

        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        // Mock the call to succeed
        bytes memory callData = bytes.concat(srcPubkeys[0], targetPubkey);
        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, callData, abi.encodePacked(""));

        vm.prank(owner);

        // Expect the call to the consolidation contract
        vm.expectCall(CONSOLIDATION_CONTRACT_ADDRESS, maxFeePerConsolidation, callData);

        // Expect the consolidation event
        vm.expectEmit(true, true, true, true);
        emit ConsolidationRequested(srcPubkeys[0], targetPubkey, maxFeePerConsolidation);

        // Call the consolidate function
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the consolidate function emits events for multiple consolidations.
     */
    function testConsolidateEmitsEventsForMultipleConsolidations() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for multiple consolidations
        bytes[] memory srcPubkeys1 = new bytes[](1);
        srcPubkeys1[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678";

        bytes[] memory srcPubkeys2 = new bytes[](1);
        srcPubkeys2[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678";

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678";

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](2);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys1, targetPubkey);
        requests[1] = ITVS.ConsolidationRequest(srcPubkeys2, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation * 2);

        // Mock static call response with a valid fee
        bytes memory mockFeeData = abi.encodePacked(maxFeePerConsolidation);
        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        // Mock the calls to succeed
        bytes memory callData1 = bytes.concat(srcPubkeys1[0], targetPubkey);
        bytes memory callData2 = bytes.concat(srcPubkeys2[0], targetPubkey);
        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, callData1, abi.encodePacked(""));
        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, callData2, abi.encodePacked(""));

        vm.prank(owner);

        // Expect the calls to the consolidation contract
        vm.expectCall(CONSOLIDATION_CONTRACT_ADDRESS, maxFeePerConsolidation, callData1);
        vm.expectCall(CONSOLIDATION_CONTRACT_ADDRESS, maxFeePerConsolidation, callData2);

        // Expect the consolidation events
        vm.expectEmit(true, true, true, true);
        emit ConsolidationRequested(srcPubkeys1[0], targetPubkey, maxFeePerConsolidation);

        vm.expectEmit(true, true, true, true);
        emit ConsolidationRequested(srcPubkeys2[0], targetPubkey, maxFeePerConsolidation);

        // Call the consolidate function
        tvs.consolidate{ value: maxFeePerConsolidation * 2 }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the consolidate function reverts when the caller is not the owner.
     */
    function testConsolidateFailsIfNotOwner() public {
        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether; // Example max fee
        address nonOwner = makeAddr("nonOwner");
        vm.deal(nonOwner, maxFeePerConsolidation);

        // Call the consolidate function
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        vm.prank(nonOwner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the withdraw function reverts when the fee read fails.
     */
    function testWithdrawFailsIfFeeReadFails() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock the call to revert
        vm.mockCallRevert(WITHDRAWAL_CONTRACT_ADDRESS, abi.encodePacked(""), abi.encodePacked(""));

        vm.prank(owner);

        // Expect the transaction to revert due to the call to WITHDRAWAL_CONTRACT_ADDRESS reverting
        vm.expectRevert(abi.encodeWithSignature("FeeReadFailed()"));
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that the withdraw function reverts when the fee exceeds the max fee.
     */
    function testWithdrawFailsIfFeeExceedsMax() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock static call response with a higher fee than maxFeePerWithdrawal
        uint256 fee = maxFeePerWithdrawal + 1;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(WITHDRAWAL_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        vm.prank(owner);

        // Expect the transaction to revert due to fee exceeding maxFeePerWithdrawal
        vm.expectRevert(abi.encodeWithSignature("FeeTooHigh(uint256,uint256)", fee, maxFeePerWithdrawal));
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that the withdraw function reverts when the request fails.
     */
    function testWithdrawFailsIfRequestFails() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock static call response with a valid fee
        bytes memory mockFeeData = abi.encodePacked(maxFeePerWithdrawal);

        vm.mockCall(WITHDRAWAL_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        // Mock the call to fail
        vm.mockCallRevert(WITHDRAWAL_CONTRACT_ADDRESS, abi.encodePacked(pubkeys[0], amounts[0]), abi.encodePacked(""));

        vm.prank(owner);

        // Expect the transaction to revert due to the call to WITHDRAWAL_CONTRACT_ADDRESS failing
        vm.expectRevert(abi.encodeWithSignature("RequestFailed()"));
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that the withdraw function refunds the sender any excess funds after actual fee deduction.
     */
    function testWithdrawRefundsSenderAnyExcessFund() public {
        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 2 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock static call response with a valid fee that is less than maxFeePerWithdrawal
        uint256 fee = maxFeePerWithdrawal - 1 ether;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(WITHDRAWAL_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        vm.prank(owner);

        uint256 ownerBalBefore = owner.balance;
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
        uint256 ownerBalAfter = owner.balance;
        assertEq(
            ownerBalAfter, ownerBalBefore - fee, "Owner should be refunded any excess funds after actual fee deduction."
        );
    }

    /**
     * @notice Tests that the withdraw function emits an event when excess refunds fail.
     */
    function testWithdrawEmitsEventWhenExcessRefundsFail() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 2 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock static call response with a valid fee that is less than maxFeePerWithdrawal
        uint256 fee = maxFeePerWithdrawal - 1 ether;
        bytes memory mockFeeData = abi.encodePacked(fee);

        vm.mockCall(WITHDRAWAL_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        // Deploy a contract that cannot receive ETH
        address excessFeeRecipient = address(new MockBeneficiaryContract());

        // Expect the transaction to revert due to fee exceeding maxFeePerWithdrawal
        uint256 ownerBalBefore = owner.balance;
        uint256 excessFee = ownerBalBefore - fee;

        vm.expectEmit(true, true, true, true);
        emit UnsentExcessFee(excessFeeRecipient, excessFee);

        vm.prank(owner);
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, excessFeeRecipient);
    }

    /**
     * @notice Tests that the withdraw function works if all is fine.
     */
    function testWithdrawWorksIfAllIsFine() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Mock static call response with a valid fee
        bytes memory mockFeeData = abi.encodePacked(maxFeePerWithdrawal);

        vm.mockCall(WITHDRAWAL_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        // Mock the call to succeed
        bytes memory callData = abi.encodePacked(pubkeys[0], amounts[0]);
        vm.mockCall(WITHDRAWAL_CONTRACT_ADDRESS, callData, abi.encodePacked(""));

        vm.prank(owner);

        // Expect the call to the withdrawal contract
        vm.expectCall(WITHDRAWAL_CONTRACT_ADDRESS, maxFeePerWithdrawal, callData);

        // Expect the withdrawal event
        vm.expectEmit(true, true, true, true);
        emit WithdrawalRequested(pubkeys[0], amounts[0], maxFeePerWithdrawal);

        // Call the withdraw function
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that the withdraw function emits events for multiple withdrawals.
     */
    function testWithdrawEmitsEventsForMultipleWithdrawals() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for multiple withdrawals
        bytes[] memory pubkeys = new bytes[](2);
        pubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678";
        pubkeys[1] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678";

        uint64[] memory amounts = new uint64[](2);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether;
        vm.deal(owner, maxFeePerWithdrawal * 2);

        // Mock static call response with a valid fee
        bytes memory mockFeeData = abi.encodePacked(maxFeePerWithdrawal);
        vm.mockCall(WITHDRAWAL_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        // Mock the calls to succeed
        bytes memory callData1 = abi.encodePacked(pubkeys[0], amounts[0]);
        bytes memory callData2 = abi.encodePacked(pubkeys[1], amounts[1]);
        vm.mockCall(WITHDRAWAL_CONTRACT_ADDRESS, callData1, abi.encodePacked(""));
        vm.mockCall(WITHDRAWAL_CONTRACT_ADDRESS, callData2, abi.encodePacked(""));

        vm.prank(owner);

        // Expect the calls to the withdrawal contract
        vm.expectCall(WITHDRAWAL_CONTRACT_ADDRESS, maxFeePerWithdrawal, callData1);
        vm.expectCall(WITHDRAWAL_CONTRACT_ADDRESS, maxFeePerWithdrawal, callData2);

        // Expect the withdrawal events
        vm.expectEmit(true, true, true, true);
        emit WithdrawalRequested(pubkeys[0], amounts[0], maxFeePerWithdrawal);

        vm.expectEmit(true, true, true, true);
        emit WithdrawalRequested(pubkeys[1], amounts[1], maxFeePerWithdrawal);

        // Call the withdraw function
        tvs.withdraw{ value: maxFeePerWithdrawal * 2 }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that the withdraw function reverts when the caller is not the owner.
     */
    function testWithdrawFailsIfNotOwner() public {
        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether; // Example max fee
        address nonOwner = makeAddr("nonOwner");
        vm.deal(nonOwner, maxFeePerWithdrawal);

        // Call the withdraw function
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        vm.prank(nonOwner);
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that the withdraw function reverts when a public key is not 48 bytes.
     */
    function testWithdrawFailsIfPubkeyLengthInvalid() public {
        // Prepare mock data for withdrawal with invalid length pubkey
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef123456"; // 47-byte

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether;
        vm.deal(owner, maxFeePerWithdrawal);

        // Call the withdraw function
        vm.expectRevert(abi.encodeWithSignature("InvalidPubkeyLength(uint256)", 47));
        vm.prank(owner);
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that the consolidate function reverts when a source public key is not 48 bytes.
     */
    function testConsolidateFailsIfSrcPubkeyLengthInvalid() public {
        // Prepare mock data for consolidation with invalid length source pubkey
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef123456"; // 47-byte

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        // Call the consolidate function
        vm.expectRevert(abi.encodeWithSignature("InvalidPubkeyLength(uint256)", 47));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the consolidate function reverts when a target public key is not 48 bytes.
     */
    function testConsolidateFailsIfTargetPubkeyLengthInvalid() public {
        // Prepare mock data for consolidation with invalid length target pubkey
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef123456"; // 47-byte

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        // Call the consolidate function
        vm.expectRevert(abi.encodeWithSignature("InvalidPubkeyLength(uint256)", 47));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the withdraw function reverts when the fee exceeds the value.
     */
    function testWithdrawFailsIfFeeExceedsValue() public {
        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether; // Example max fee
        uint256 value = maxFeePerWithdrawal - 1;
        vm.deal(owner, maxFeePerWithdrawal);

        // Call the withdraw function
        vm.expectRevert(abi.encodeWithSignature("InsufficientValueForFee(uint256,uint256)", value, maxFeePerWithdrawal));
        vm.prank(owner);
        tvs.withdraw{ value: value }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that the withdraw function reverts when the input length mismatch.
     */
    function testWithdrawFailsIfInputLengthMismatch() public {
        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
        // example

        uint64[] memory amounts; // length is zero(0)

        uint256 maxFeePerWithdrawal = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Call the withdraw function
        vm.expectRevert(abi.encodeWithSignature("LengthMismatch(uint256,uint256)", pubkeys.length, amounts.length));
        vm.prank(owner);
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that the withdraw function reverts when the pubkeys array is empty.
     */
    function testWithdrawFailsIfPubkeysEmpty() public {
        bytes[] memory pubkeys; // length is zero(0)
        uint64[] memory amounts; // length is zero(0)

        uint256 maxFeePerWithdrawal = 0.1 ether;
        vm.deal(owner, maxFeePerWithdrawal);

        // Call the withdraw function
        vm.expectRevert(abi.encodeWithSignature("InvalidEmptyArray()"));
        vm.prank(owner);
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that the empty pubkeys check takes precedence over the length mismatch check.
     */
    function testWithdrawFailsWithEmptyArrayBeforeLengthMismatch() public {
        bytes[] memory pubkeys; // length is zero(0)

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether;
        vm.deal(owner, maxFeePerWithdrawal);

        // Call the withdraw function
        vm.expectRevert(abi.encodeWithSignature("InvalidEmptyArray()"));
        vm.prank(owner);
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that the consolidate function reverts when the requests array is empty.
     */
    function testConsolidateFailsIfRequestsEmpty() public {
        ITVS.ConsolidationRequest[] memory requests; // length is zero(0)

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        // Call the consolidate function
        vm.expectRevert(abi.encodeWithSignature("InvalidEmptyArray()"));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the consolidate function reverts when a request carries no source public keys.
     */
    function testConsolidateFailsIfSrcPubkeysEmpty() public {
        bytes[] memory srcPubkeys; // length is zero(0)

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        // Call the consolidate function
        vm.expectRevert(abi.encodeWithSignature("InvalidEmptyArray()"));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the consolidate function reverts the whole batch when a single request carries no source
     * public keys, rather than silently skipping that request.
     */
    function testConsolidateFailsIfAnyRequestHasEmptySrcPubkeys() public {
        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        bytes[] memory populatedSrcPubkeys = new bytes[](1);
        populatedSrcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        bytes[] memory emptySrcPubkeys; // length is zero(0)

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](2);
        requests[0] = ITVS.ConsolidationRequest(populatedSrcPubkeys, targetPubkey);
        requests[1] = ITVS.ConsolidationRequest(emptySrcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        // Mock the fee read so the populated request would otherwise be submittable
        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), abi.encodePacked(uint256(1)));

        // Poison the populated request's submission calldata. The whole batch is validated up front, so this call
        // must never happen; if it did, the revert would surface as RequestFailed() instead of InvalidEmptyArray().
        bytes memory firstCallData = bytes.concat(populatedSrcPubkeys[0], targetPubkey);
        vm.mockCallRevert(CONSOLIDATION_CONTRACT_ADDRESS, firstCallData, abi.encodePacked(""));

        // No consolidation request should be submitted for the populated request either
        vm.expectRevert(abi.encodeWithSignature("InvalidEmptyArray()"));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the consolidate function reverts when a request carries an empty target public key.
     */
    function testConsolidateFailsIfTargetPubkeyEmpty() public {
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        bytes memory targetPubkey = ""; // length is zero(0)

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        // Call the consolidate function
        vm.expectRevert(abi.encodeWithSignature("InvalidEmptyArray()"));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the consolidate function reverts the whole batch when a single request carries an empty
     * target public key, rather than silently submitting the other requests.
     */
    function testConsolidateFailsIfAnyRequestHasEmptyTargetPubkey() public {
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        bytes memory populatedTargetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](2);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, populatedTargetPubkey);
        requests[1] = ITVS.ConsolidationRequest(srcPubkeys, ""); // empty target pubkey

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        // Mock the fee read so the populated request would otherwise be submittable
        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), abi.encodePacked(uint256(1)));

        // Poison the populated request's submission calldata. The whole batch is validated up front, so this call
        // must never happen; if it did, the revert would surface as RequestFailed() instead of InvalidEmptyArray().
        bytes memory firstCallData = bytes.concat(srcPubkeys[0], populatedTargetPubkey);
        vm.mockCallRevert(CONSOLIDATION_CONTRACT_ADDRESS, firstCallData, abi.encodePacked(""));

        // No consolidation request should be submitted for the populated request either
        vm.expectRevert(abi.encodeWithSignature("InvalidEmptyArray()"));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that a target public key that is neither empty nor 48 bytes still reverts with
     * {InvalidPubkeyLength}, so the new empty-target guard does not mask the length check.
     */
    function testConsolidateStillFailsWithLengthErrorForShortTargetPubkey() public {
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef123456"; // 47-byte

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        // Call the consolidate function
        vm.expectRevert(abi.encodeWithSignature("InvalidPubkeyLength(uint256)", 47));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the batch-level validation covers every request, not just the first, and that no earlier
     * request in the batch is submitted before a later invalid one is rejected.
     */
    function testConsolidateSubmitsNothingWhenLastOfThreeRequestsHasEmptyTarget() public {
        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        bytes[] memory srcPubkeysA = new bytes[](1);
        srcPubkeysA[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345601"; // 48-byte

        bytes[] memory srcPubkeysB = new bytes[](1);
        srcPubkeysB[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345602"; // 48-byte

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](3);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeysA, targetPubkey);
        requests[1] = ITVS.ConsolidationRequest(srcPubkeysB, targetPubkey);
        requests[2] = ITVS.ConsolidationRequest(srcPubkeysA, ""); // empty target pubkey

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        // Mock the fee read so both populated requests would otherwise be submittable
        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), abi.encodePacked(uint256(1)));

        // Poison both populated requests: neither may be submitted before the invalid third request is rejected
        vm.mockCallRevert(
            CONSOLIDATION_CONTRACT_ADDRESS, bytes.concat(srcPubkeysA[0], targetPubkey), abi.encodePacked("")
        );
        vm.mockCallRevert(
            CONSOLIDATION_CONTRACT_ADDRESS, bytes.concat(srcPubkeysB[0], targetPubkey), abi.encodePacked("")
        );

        vm.expectRevert(abi.encodeWithSignature("InvalidEmptyArray()"));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the batch-level validation also rejects an invalid request in the first position, so the
     * check is not skipped for the leading element.
     */
    function testConsolidateFailsIfFirstRequestHasEmptySrcPubkeys() public {
        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        bytes[] memory emptySrcPubkeys; // length is zero(0)

        bytes[] memory populatedSrcPubkeys = new bytes[](1);
        populatedSrcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](2);
        requests[0] = ITVS.ConsolidationRequest(emptySrcPubkeys, targetPubkey);
        requests[1] = ITVS.ConsolidationRequest(populatedSrcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        vm.expectRevert(abi.encodeWithSignature("InvalidEmptyArray()"));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the batch-level validation also rejects an empty target public key in the first position.
     */
    function testConsolidateFailsIfFirstRequestHasEmptyTargetPubkey() public {
        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](2);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, ""); // empty target pubkey
        requests[1] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        vm.expectRevert(abi.encodeWithSignature("InvalidEmptyArray()"));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that the empty-array check takes precedence over the sufficient-value check, so a malformed batch
     * is rejected with {InvalidEmptyArray} rather than being masked by {InsufficientValueForFee}.
     */
    function testConsolidateFailsWithEmptyArrayBeforeInsufficientValue() public {
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](2);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);
        requests[1] = ITVS.ConsolidationRequest(srcPubkeys, ""); // empty target pubkey

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        // Mock the fee read so that the value sent covers only one of the two operations
        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), abi.encodePacked(maxFeePerConsolidation));

        vm.expectRevert(abi.encodeWithSignature("InvalidEmptyArray()"));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that a zero-length source public key inside a non-empty array is rejected by the length check
     * rather than the empty-array guard, so the two errors stay distinguishable.
     */
    function testConsolidateFailsWithLengthErrorForZeroLengthSrcPubkeyElement() public {
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = ""; // zero-length element inside a non-empty array

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        vm.expectRevert(abi.encodeWithSignature("InvalidPubkeyLength(uint256)", 0));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    /**
     * @notice Tests that a zero-length public key inside a non-empty array is rejected by the length check rather
     * than the empty-array guard, so the two errors stay distinguishable.
     */
    function testWithdrawFailsWithLengthErrorForZeroLengthPubkeyElement() public {
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = ""; // zero-length element inside a non-empty array

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether;
        vm.deal(owner, maxFeePerWithdrawal);

        vm.expectRevert(abi.encodeWithSignature("InvalidPubkeyLength(uint256)", 0));
        vm.prank(owner);
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that a non-empty pubkeys array paired with an empty amounts array reverts with
     * {LengthMismatch}, so the empty-array guard does not swallow the mismatch in the reverse direction.
     */
    function testWithdrawFailsWithLengthMismatchWhenAmountsEmpty() public {
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte

        uint64[] memory amounts; // length is zero(0)

        uint256 maxFeePerWithdrawal = 0.1 ether;
        vm.deal(owner, maxFeePerWithdrawal);

        vm.expectRevert(abi.encodeWithSignature("LengthMismatch(uint256,uint256)", 1, 0));
        vm.prank(owner);
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /**
     * @notice Tests that the transfer function fails if called by a non-owner.
     */
    function testTransferFailsIfNotOwner() public {
        address newBeneficiary = makeAddr("newBeneficiary");
        address newOwner = makeAddr("newOwner");
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        tvs.transfer(newBeneficiary, newOwner);
    }

    /**
     * @notice Tests that the transfer function reverts when the new owner address is zero.
     */
    function testTransferFailsIfNewOwnerIsZeroAddress() public {
        address newBeneficiary = makeAddr("newBeneficiary");

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        tvs.transfer(newBeneficiary, address(0));
    }

    /**
     * @notice Tests that the transfer function reverts when the new beneficiary address is zero.
     */
    function testTransferFailsIfNewBeneficiaryIsZeroAddress() public {
        address newOwner = makeAddr("newOwner");

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        tvs.transfer(address(0), newOwner);
    }

    /**
     * @notice Tests that renounceOwnership reverts with the expected error.
     */
    function testRenounceOwnershipReverts() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("OwnershipCannotBeRenounced()")); // Expect the specific revert error
        Ownable(address(tvs)).renounceOwnership();
    }

    /**
     * @notice Tests that the withdraw function reverts when address(0) is passed as the excessFeeRecipient.
     */
    function testWithdrawRevertsIfExcessFeeRecipientIsZeroAddress() public {
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678";

        uint64[] memory amounts = new uint64[](1);
        amounts[0] = 1 ether;

        uint256 maxFeePerWithdrawal = 0.1 ether;
        vm.deal(owner, maxFeePerWithdrawal);

        bytes memory mockFeeData = abi.encodePacked(maxFeePerWithdrawal);
        vm.mockCall(WITHDRAWAL_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        bytes memory callData = abi.encodePacked(pubkeys[0], amounts[0]);
        vm.mockCall(WITHDRAWAL_CONTRACT_ADDRESS, callData, abi.encodePacked(""));

        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        vm.prank(owner);
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, address(0));
    }

    /**
     * @notice Tests that the consolidate function reverts when address(0) is passed as the excessFeeRecipient.
     */
    function testConsolidateRevertsIfExcessFeeRecipientIsZeroAddress() public {
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] =
        hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678";

        bytes memory targetPubkey =
            hex"1234567890abcdef1234567890abcde67895645f1234567890abcdef1234567890abcdef1234567890abcdef12345678";

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether;
        vm.deal(owner, maxFeePerConsolidation);

        bytes memory mockFeeData = abi.encodePacked(maxFeePerConsolidation);
        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, abi.encodePacked(""), mockFeeData);

        bytes memory callData = bytes.concat(srcPubkeys[0], targetPubkey);
        vm.mockCall(CONSOLIDATION_CONTRACT_ADDRESS, callData, abi.encodePacked(""));

        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        vm.prank(owner);
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, address(0));
    }
}
