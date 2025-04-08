//SPDX-License-Identifier: Proprietary

pragma solidity 0.8.28;

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

    function setUp() public virtual {
        owner = makeAddr("owner");
        beneficiary = makeAddr("beneficiary");
        tvs = deployTVS();
    }

    // Abstract function to be implemented by derived test contracts
    function deployTVS() internal virtual returns (ITVS);

    // Common tests that work for both implementations
    function testSweepToCustomBeneficiaryFailsIfNotOwner() public {
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);

        address customBeneficiary = vm.addr(5);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        tvs.sweep(customBeneficiary, 0);
    }

    function testSweepAllWhenZeroBalance() public {
        tvs.sweep(address(0), 0);
        assertEq(beneficiary.balance, 0 ether, "Beneficiary balance should be zero after sweep");
    }

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

    function testSweepWithFailsWhenBalanceInsufficient() public {
        uint256 balance = 1 ether;
        uint256 amount = balance + 1;
        vm.deal(address(tvs), balance);

        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance(uint256,uint256)", balance, amount));
        vm.prank(owner);
        tvs.sweep(address(0), amount);
    }

    function testSweepToContractWithNoSweepToContractInterface() public {
        uint256 amount = 1 ether;
        vm.deal(address(tvs), amount);

        vm.expectRevert();
        tvs.sweepToBeneficiaryContract(address(0), 0);
    }

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

    function testSetBeneficiaryWithValidAddress() public virtual {
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
        address nonOwner = makeAddr("nonOwner");
        address newBeneficiary = makeAddr("newBeneficiary");
        vm.prank(nonOwner);

        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));

        tvs.setBeneficiary(newBeneficiary);
    }

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

    function testConsolidateRefundsSenderAnyExcessFund() public {
        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
            // example

        bytes memory targetPubkey =
            hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte
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

    function testConsolidateEmitsEventWhenExcessRefundsFail() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
            // example

        bytes memory targetPubkey =
            hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte
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

    function testConsolidateFailsIfFeeExceedsMax() public {
        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
            // example

        bytes memory targetPubkey =
            hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte
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

    function testConsolidateFailsIfFeeExceedsValue() public {
        address CONSOLIDATION_CONTRACT_ADDRESS = 0x00431F263cE400f4455c2dCf564e53007Ca4bbBb;

        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
            // example

        bytes memory targetPubkey =
            hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte
            // example

        ITVS.ConsolidationRequest[] memory requests = new ITVS.ConsolidationRequest[](1);
        requests[0] = ITVS.ConsolidationRequest(srcPubkeys, targetPubkey);

        uint256 maxFeePerConsolidation = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerConsolidation);

        // leave suplus funds in contract. so although enough funds exist
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

    function testConsolidateWorksIfAllIsFine() public {
        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
            // example

        bytes memory targetPubkey =
            hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte
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

        // Call the consolidate function
        tvs.consolidate{ value: maxFeePerConsolidation }(requests, maxFeePerConsolidation, owner);
    }

    function testConsolidateFailsIfNotOwner() public {
        // Prepare mock data for consolidation
        bytes[] memory srcPubkeys = new bytes[](1);
        srcPubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
            // example

        bytes memory targetPubkey =
            hex"abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"; // 48-byte
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

    function testWithdrawFailsIfFeeReadFails() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
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

    function testWithdrawFailsIfFeeExceedsMax() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
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

    function testWithdrawFailsIfRequestFails() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
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

    function testWithdrawRefundsSenderAnyExcessFund() public {
        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
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

    function testWithdrawmitsEventWhenExcessRefundsFail() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
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

    function testWithdrawWorksIfAllIsFine() public {
        address WITHDRAWAL_CONTRACT_ADDRESS = 0x0c15F14308530b7CDB8460094BbB9cC28b9AaaAA;

        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
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
        // Expect the call to the consolidation contract
        vm.expectCall(WITHDRAWAL_CONTRACT_ADDRESS, maxFeePerWithdrawal, callData);
        // Call the withdraw function
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    function testWithdrawFailsIfNotOwner() public {
        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
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

    function testWithdrawFailsIfFeeExceedsValue() public {
        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
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

    function testWithdrawFailsIfInputLengthMismatch() public {
        // Prepare mock data for withdrawal
        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678"; // 48-byte
            // example

        uint64[] memory amounts; // length is zero(0)

        uint256 maxFeePerWithdrawal = 0.1 ether; // Example max fee
        vm.deal(owner, maxFeePerWithdrawal);

        // Call the withdraw function
        vm.expectRevert(abi.encodeWithSignature("LengthMismatch(uint256,uint256)", pubkeys.length, amounts.length));
        vm.prank(owner);
        tvs.withdraw{ value: maxFeePerWithdrawal }(pubkeys, amounts, maxFeePerWithdrawal, owner);
    }

    /// @notice Tests that the transfer function fails if called by a non-owner.
    function testTransferFailsIfNotOwner() public {
        address newBeneficiary = makeAddr("newBeneficiary");
        address newOwner = makeAddr("newOwner");
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        tvs.transfer(newBeneficiary, newOwner);
    }

    /// @notice Tests that renounceOwnership reverts with the expected error.
    function testRenounceOwnershipReverts() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("OwnershipCannotBeRenounced()")); // Expect the specific revert error
        Ownable(address(tvs)).renounceOwnership();
    }
}
