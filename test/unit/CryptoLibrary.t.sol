// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/forge-std/src/Test.sol";
import {CryptoLibrary} from "../../src/CryptoLibrary.sol";

contract DeployCryptoLibraryTest is Test {
    CryptoLibrary public cryptolibrary;
    address private libraryOwner =
        address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address[3] private libraryAdmins = [
        address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
        address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC),
        address(0x90F79bf6EB2c4f870365E785982E1f101E93b906)
    ];
    string[3] private nickNames = ["admin1", "admin2", "admin3"];

    function setUp() public {
        // Deploy the CryptoLibrary contract with owner and admin addresses
        vm.startPrank(libraryOwner); // Impersonate the owner

        // Get price feed address
        address _priceFeedAddr = vm.envAddress("PRICE_FEED_ETHUSD_SEPOLIA");

        cryptolibrary = new CryptoLibrary(
            _priceFeedAddr,
            libraryAdmins,
            nickNames
        );
        vm.stopPrank();
    }

    // Test for successful contract deployment
    function testContractDeployment() public view {
        assert(address(cryptolibrary) != address(0)); // Ensure contract address is not zero

        // Log the deployed contract's address
        console.log(
            "Deployed CryptoLibrary contract at address:",
            address(cryptolibrary)
        );
    }

    // Test that roles match constructor parameters
    function testConstructorRoles() public view {
        // Test that libraryOwner has the LIBRARY_OWNER role
        assertTrue(
            cryptolibrary.hasRole(cryptolibrary.LIBRARY_OWNER(), libraryOwner)
        );

        // Log the assigned roles via constructor
        console.log("LIBRARY_OWNER Role address:", libraryOwner);

        // Test that each libraryAdmin has the LIBRARY_ADMIN role
        for (uint i = 0; i < libraryAdmins.length; i++) {
            assertTrue(
                cryptolibrary.hasRole(
                    cryptolibrary.LIBRARY_ADMIN(),
                    libraryAdmins[i]
                )
            );

            console.log(
                "LIBRARY_ADMIN role address index",
                i,
                ":",
                libraryAdmins[i]
            );
        }
    }

    // Test the addMember function
    function testAddMember() public {
        // Define the new member details
        address newMember = address(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
        string memory nickname = "newMember";
        CryptoLibrary.MemberRole expectedRole = CryptoLibrary.MemberRole.Member;
        CryptoLibrary.MemberStatus expectedStatus = CryptoLibrary
            .MemberStatus
            .Good;

        // Add new member
        vm.startPrank(libraryOwner);
        cryptolibrary.addMember(newMember, nickname, expectedRole);
        vm.stopPrank();

        // Access the Member struct stored in the mapping
        (
            uint memberId,
            address memberAddr,
            string memory memberNickName,
            CryptoLibrary.MemberRole memberRole,
            CryptoLibrary.MemberStatus memberStatus,
            uint[] memory memberBooksCheckedOut
        ) = cryptolibrary.getMemberProfile(newMember);

        // Log the MemberId
        console.log("MemberId", memberId);

        // Check if the address matches
        assertEq(memberAddr, newMember, "Address mismatch");

        // Check if the nickname matches
        assertEq(memberNickName, nickname, "Nickname mismatch");

        // Check if the role matches the expected role
        assertEq(uint(memberRole), uint(expectedRole), "Role mismatch");

        // Check if the status matches the expected status
        assertEq(uint(memberStatus), uint(expectedStatus), "Status mismatch");

        // Check if the checkedOutBookIds array is empty (as expected for a new member)
        assertEq(
            memberBooksCheckedOut.length,
            0,
            "Checked-out book IDs should be empty"
        );
    }

    // Test the joinLibrary function
    function testJoinLibrary() public {
        address newMemberAddr = address(
            0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc
        );
        string memory nickname = "newMember";

        // New member joins the library
        vm.startPrank(newMemberAddr);
        cryptolibrary.joinLibrary(nickname);
        vm.stopPrank();

        // Access the Member struct stored in the mapping
        (
            uint memberId,
            address memberAddr,
            string memory memberNickName,
            CryptoLibrary.MemberRole memberRole,
            CryptoLibrary.MemberStatus memberStatus,
            uint[] memory memberBooksCheckedOut
        ) = cryptolibrary.getMemberProfile(newMemberAddr);

        // Log the MemberId
        console.log("MemberId", memberId);

        assertEq(memberNickName, nickname, "Nickname mismatch");
        assertEq(memberAddr, newMemberAddr, "Address mismatch");
        assertEq(
            uint(memberRole),
            uint(CryptoLibrary.MemberRole.Member),
            "Role must be: Member"
        );
        assertEq(
            uint(memberStatus),
            uint(CryptoLibrary.MemberStatus.Good),
            "Status must be: Good"
        );

        // Check if the checkedOutBookIds array is empty (as expected for a new member)
        assertEq(
            memberBooksCheckedOut.length,
            0,
            "Checked-out book IDs should be empty"
        );
    }

    // Test the addBook function
    function testAddBook() public {
        string memory isbn = "978-0735200661";
        string memory title = "Technical Analysis of the Financial Markets";
        string memory author = "John J. Murphy";

        // Add book as an admin
        vm.startPrank(libraryAdmins[0]);
        cryptolibrary.addBook(isbn, title, author);
        vm.stopPrank();

        // Check if the book was added correctly
        uint expectedBookId = cryptolibrary.bookIdCounter();
        (
            uint id,
            string memory bookIsbn,
            string memory bookTitle,
            string memory bookAuthor,
            address bookOwner,
            CryptoLibrary.BookStatus bookStatus
        ) = cryptolibrary.bookById(expectedBookId);

        assertEq(id, expectedBookId, "Book ID mismatch");
        assertEq(
            keccak256(abi.encodePacked(bookIsbn)),
            keccak256(abi.encodePacked(isbn)),
            "ISBN mismatch"
        );
        assertEq(
            keccak256(abi.encodePacked(bookTitle)),
            keccak256(abi.encodePacked(title)),
            "Title mismatch"
        );
        assertEq(
            keccak256(abi.encodePacked(bookAuthor)),
            keccak256(abi.encodePacked(author)),
            "Author mismatch"
        );
        assertEq(bookOwner, address(cryptolibrary), "Owner mismatch");
        assertEq(
            uint(bookStatus),
            uint(CryptoLibrary.BookStatus.Available),
            "Book status mismatch"
        );
    }

    // Test the checkoutBookFunding function
    function testCheckoutBookFunding() public {
        string memory isbn = "978-0735200661";
        string memory title = "Technical Analysis of the Financial Markets";
        string memory author = "John J. Murphy";
        address newMemberAddr = address(
            0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc
        );

        // Fund the test addresses with some ETH (e.g., 1 ETH)
        vm.deal(newMemberAddr, 1 ether);
        console.log("newMemberAddr Balance", newMemberAddr.balance);
        vm.deal(libraryAdmins[0], 1 ether);
        console.log("libraryAdmin1 Balance", libraryAdmins[0].balance);

        // Add book
        vm.startPrank(libraryAdmins[0]);
        cryptolibrary.addBook(isbn, title, author);
        vm.stopPrank();

        // Join library as a member
        vm.startPrank(newMemberAddr);
        cryptolibrary.joinLibrary("newMember");
        vm.stopPrank();

        // Get initial contract balance
        uint initialContractBalance = address(cryptolibrary).balance;

        // Get initial member balance
        uint initialMemberBalance = newMemberAddr.balance;

        // Define the checkout fee (0.1 ETH)
        uint checkoutFee = 0.1 ether;

        // Checkout book as member
        vm.startPrank(newMemberAddr);
        cryptolibrary.checkoutBook{value: checkoutFee}(1);
        vm.stopPrank();

        // Ensure the contract balance increased by the correct amount
        uint expectedContractBalance = initialContractBalance + checkoutFee;
        assertEq(
            address(cryptolibrary).balance,
            expectedContractBalance,
            "Contract balance mismatch after book checkout"
        );

        // Ensure the member's balance decreased by the correct amount (taking gas fees into account)
        uint expectedMemberBalance = initialMemberBalance - checkoutFee;
        assertApproxEqRel(
            newMemberAddr.balance,
            expectedMemberBalance,
            0.01 ether, // Approximate within 0.01 ETH to account for gas fees
            "Member balance mismatch after book checkout"
        );
    }

    // Test the checkoutBook function
    function testCheckoutBook() public {
        string memory isbn = "978-0735200661";
        string memory title = "Technical Analysis of the Financial Markets";
        string memory author = "John J. Murphy";
        address newMemberAddr = address(
            0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc
        );

        // Fund the test addresses with some ETH (e.g., 1 ETH)
        vm.deal(newMemberAddr, 1 ether);
        console.log("newMemberAddr Balance", newMemberAddr.balance);
        vm.deal(libraryAdmins[0], 1 ether);
        console.log("libraryAdmin1 Balance", libraryAdmins[0].balance);

        // Add book
        vm.startPrank(libraryAdmins[0]);
        cryptolibrary.addBook(isbn, title, author);
        vm.stopPrank();

        // Join library as a member
        vm.startPrank(newMemberAddr);
        cryptolibrary.joinLibrary("newMember");
        vm.stopPrank();

        // Define the checkout fee (0.1 ETH)
        uint checkoutFee = 0.1 ether;

        // Checkout book as member
        vm.startPrank(newMemberAddr);
        cryptolibrary.checkoutBook{value: checkoutFee}(1);
        vm.stopPrank();

        // Check if the book was checked out correctly
        (
            uint bookId,
            string memory bookIsbn,
            string memory bookTitle,
            string memory bookAuthor,
            address bookOwner,
            CryptoLibrary.BookStatus bookStatus
        ) = cryptolibrary.bookById(1);

        // Log the MemberId
        console.log("BookId", bookId);

        assertEq(
            keccak256(abi.encodePacked(bookIsbn)),
            keccak256(abi.encodePacked(isbn)),
            "ISBN mismatch"
        );
        assertEq(
            keccak256(abi.encodePacked(bookTitle)),
            keccak256(abi.encodePacked(title)),
            "Title mismatch"
        );
        assertEq(
            keccak256(abi.encodePacked(bookAuthor)),
            keccak256(abi.encodePacked(author)),
            "Author mismatch"
        );
        assertEq(bookOwner, newMemberAddr, "Book ownership mismatch");
        assertEq(
            uint(bookStatus),
            uint(CryptoLibrary.BookStatus.Borrowed),
            "Book status mismatch"
        );
    }

    // Test the checkinBook function
    function testCheckinBook() public {
        string memory isbn = "978-0735200661";
        string memory title = "Technical Analysis of the Financial Markets";
        string memory author = "John J. Murphy";
        address newMemberAddr = address(
            0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc
        );

        // Fund the test addresses with some ETH (e.g., 1 ETH)
        vm.deal(newMemberAddr, 1 ether);
        console.log("newMemberAddr Balance", newMemberAddr.balance);
        vm.deal(libraryAdmins[0], 1 ether);
        console.log("libraryAdmin1 Balance", libraryAdmins[0].balance);

        // Add book
        vm.startPrank(libraryAdmins[0]);
        cryptolibrary.addBook(isbn, title, author);
        vm.stopPrank();

        // Join library as a member
        vm.startPrank(newMemberAddr);
        cryptolibrary.joinLibrary("newMember");
        vm.stopPrank();

        // Define the checkout fee (0.1 ETH)
        uint checkoutFee = 0.1 ether;

        // Checkout book as member
        vm.startPrank(newMemberAddr);
        cryptolibrary.checkoutBook{value: checkoutFee}(1);
        vm.stopPrank();

        // Checkin book as member
        vm.startPrank(newMemberAddr);
        cryptolibrary.checkinBook(1);
        vm.stopPrank();

        // Check if the book was checked in correctly
        (
            uint bookId,
            string memory bookIsbn,
            string memory bookTitle,
            string memory bookAuthor,
            address bookOwner,
            CryptoLibrary.BookStatus bookStatus
        ) = cryptolibrary.bookById(1);

        // Log the MemberId
        console.log("BookId", bookId);

        assertEq(
            keccak256(abi.encodePacked(bookIsbn)),
            keccak256(abi.encodePacked(isbn)),
            "ISBN mismatch"
        );
        assertEq(
            keccak256(abi.encodePacked(bookTitle)),
            keccak256(abi.encodePacked(title)),
            "Title mismatch"
        );
        assertEq(
            keccak256(abi.encodePacked(bookAuthor)),
            keccak256(abi.encodePacked(author)),
            "Author mismatch"
        );
        assertEq(
            bookOwner,
            address(cryptolibrary),
            "Book ownership mismatch after checkin"
        );
        assertEq(
            uint(bookStatus),
            uint(CryptoLibrary.BookStatus.Available),
            "Book status mismatch after checkin"
        );
    }
}
