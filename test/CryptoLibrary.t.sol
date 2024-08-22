// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/forge-std/src/Test.sol";
import {CryptoLibrary} from "../src/CryptoLibrary.sol";

contract DeployCryptoLibraryTest is Test {
    CryptoLibrary public cryptolibrary;
    address private libraryOwner =
        address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address[3] private libraryAdmins = [
        address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
        address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC),
        address(0x90F79bf6EB2c4f870365E785982E1f101E93b906)
    ];
    string[3] private nickNames = ["bob", "jon", "luci"];

    function setUp() public {
        // Deploy the CryptoLibrary contract with owner and admin addresses
        vm.startPrank(libraryOwner); // Impersonate the owner
        cryptolibrary = new CryptoLibrary(libraryAdmins, nickNames);
        vm.stopPrank();
    }

    // Test for successful contract deployment
    function testContractDeployment() public view {
        assert(address(cryptolibrary) != address(0)); // Ensure contract address is not zero
    }

    // Test that roles match constructor parameters
    function testConstructorRoles() public view {
        // Test that libraryOwner has the LIBRARY_OWNER role
        assertTrue(
            cryptolibrary.hasRole(cryptolibrary.LIBRARY_OWNER(), libraryOwner)
        );

        // Test that each libraryAdmin has the LIBRARY_ADMIN role
        for (uint i = 0; i < libraryAdmins.length; i++) {
            assertTrue(
                cryptolibrary.hasRole(
                    cryptolibrary.LIBRARY_ADMIN(),
                    libraryAdmins[i]
                )
            );
        }
    }

    // Test the addMember function
    function testAddMember() public {
        address newMember = address(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
        string memory nickname = "newbie";

        // Add new member as an admin
        vm.startPrank(libraryOwner);
        cryptolibrary.addMember(
            newMember,
            nickname,
            CryptoLibrary.MemberRole.Member
        );
        vm.stopPrank();

        // Check if the member was added correctly
        (
            uint memberId,
            address memberAddr,
            string memory memberNickName,
            CryptoLibrary.MemberRole role,
            CryptoLibrary.MemberStatus status //uint[] memory checkedOutBookIds
        ) = cryptolibrary.memberByAddress(newMember);

        // Perform the assertions on the retrieved values
        assertEq(memberNickName, nickname, "Nickname mismatch");
        assertEq(memberAddr, newMember, "Address mismatch");
        assertEq(
            uint(role),
            uint(CryptoLibrary.MemberRole.Member),
            "Role mismatch"
        );
    }

    // Test the joinLibrary function
    function testJoinLibrary() public {
        address newMember = address(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
        string memory nickname = "guest";

        // New member joins the library
        vm.startPrank(newMember);
        cryptolibrary.joinLibrary(nickname);
        vm.stopPrank();

        // Check if the member was added correctly
        (
            uint memberId,
            address memberAddr,
            string memory memberNickName,
            CryptoLibrary.MemberRole role,
            CryptoLibrary.MemberStatus status //uint[] memory checkedOutBookIds
        ) = cryptolibrary.memberByAddress(newMember);
        assertEq(memberNickName, nickname, "Nickname mismatch");
        assertEq(memberAddr, newMember, "Address mismatch");
        assertEq(
            uint(role),
            uint(CryptoLibrary.MemberRole.Member),
            "Role mismatch"
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

    // Test the checkoutBook function
    function testCheckoutBook() public {
        string memory isbn = "978-0735200661";
        string memory title = "Technical Analysis of the Financial Markets";
        string memory author = "John J. Murphy";
        address member = address(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);

        // Add book
        vm.startPrank(libraryAdmins[0]);
        cryptolibrary.addBook(isbn, title, author);
        vm.stopPrank();

        // Join library as a member
        vm.startPrank(member);
        cryptolibrary.joinLibrary("guest");
        vm.stopPrank();

        // Checkout book as member
        vm.startPrank(member);
        cryptolibrary.checkoutBook(1);
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
        assertEq(bookOwner, member, "Book ownership mismatch");
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
        address member = address(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);

        // Add book
        vm.startPrank(libraryAdmins[0]);
        cryptolibrary.addBook(isbn, title, author);
        vm.stopPrank();

        // Join library as a member
        vm.startPrank(member);
        cryptolibrary.joinLibrary("guest");
        vm.stopPrank();

        // Checkout book as member
        vm.startPrank(member);
        cryptolibrary.checkoutBook(1);
        vm.stopPrank();

        // Checkin book as member
        vm.startPrank(member);
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
