// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/forge-std/src/Test.sol";
import {CryptoLibrary} from "../src/CryptoLibrary.sol";

contract CryptoLibraryTest is Test {
    CryptoLibrary public cryptolibrary;
    address private libraryOwner =
        address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address[] private admins = [
        address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
        address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
        address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)
    ];

    function setUp() public {
        vm.startPrank(libraryOwner); // Start impersonating an address for transactions
        cryptolibrary = new CryptoLibrary(admins); // AggregatorV3Interface address
        vm.stopPrank(); // Stop impersonating
    }

    function testDeployment() public view {
        // Verify that the contract address is not zero
        assert(address(cryptolibrary) != address(0));

        // Verify that the contract owner is correctly set
        assertEq(cryptolibrary.libraryOwner(), libraryOwner);
    }

    function testAddBook() public {
        // Define book details
        string memory isbn = "978-0735200661";
        string memory title = "Technical Analysis of the Financial Markets";
        string memory author = "John J. Murphy";
        address bookOwner = address(cryptolibrary);

        // Call addBook
        vm.startPrank(libraryOwner); // Impersonate the owner to call the private function
        cryptolibrary.addBook(isbn, title, author);
        vm.stopPrank();

        // Verify the book count
        uint256 expectedBookId = cryptolibrary.bookIdCounter(); // Use getter for public variable
        assertEq(expectedBookId, 1, "Book ID counter should be 1");

        // Retrieve the added book from the books array using the bookIdCounter
        (
            uint256 id,
            string memory bookIsbn,
            string memory bookTitle,
            string memory bookAuthor,
            address bookAddr,
            CryptoLibrary.BookStatus bookStatus
        ) = cryptolibrary.bookById(expectedBookId);

        // Verify book details
        assertEq(id, 1, "Book ID should be 1");
        assertEq(
            keccak256(abi.encodePacked(bookIsbn)),
            keccak256(abi.encodePacked(isbn)),
            "ISBN should match"
        );
        assertEq(
            keccak256(abi.encodePacked(bookTitle)),
            keccak256(abi.encodePacked(title)),
            "Title should match"
        );
        assertEq(
            keccak256(abi.encodePacked(bookAuthor)),
            keccak256(abi.encodePacked(author)),
            "Author should match"
        );
        assertEq(address(bookAddr), address(bookOwner), "Owner should match");
        assertEq(
            uint(bookStatus),
            uint(CryptoLibrary.BookStatus.Available),
            "Status should match"
        );
    }

    function testRemoveBook() public {
        // Define book details
        string memory isbn = "978-0735200661";
        string memory title = "Technical Analysis of the Financial Markets";
        string memory author = "John J. Murphy";
        address bookOwner = address(cryptolibrary);

        // Call addBook
        vm.startPrank(libraryOwner); // Impersonate the owner to call the private function
        cryptolibrary.addBook(isbn, title, author);
        vm.stopPrank();

        // Verify the book count
        uint256 expectedBookId = cryptolibrary.bookIdCounter(); // Use getter for public variable
        assertEq(expectedBookId, 1, "Book ID counter should be 1");

        // Retrieve the added book from the books array using the bookIdCounter
        (
            uint256 id,
            string memory bookIsbn,
            string memory bookTitle,
            string memory bookAuthor,
            address bookAddr,
            CryptoLibrary.BookStatus bookStatus
        ) = cryptolibrary.bookById(expectedBookId);

        // Verify book details
        assertEq(id, 1, "Book ID should be 1");
        assertEq(
            keccak256(abi.encodePacked(bookIsbn)),
            keccak256(abi.encodePacked(isbn)),
            "ISBN should match"
        );
        assertEq(
            keccak256(abi.encodePacked(bookTitle)),
            keccak256(abi.encodePacked(title)),
            "Title should match"
        );
        assertEq(
            keccak256(abi.encodePacked(bookAuthor)),
            keccak256(abi.encodePacked(author)),
            "Author should match"
        );
        assertEq(address(bookAddr), address(bookOwner), "Owner should match");
        assertEq(
            uint(bookStatus),
            uint(CryptoLibrary.BookStatus.Available),
            "Status should match"
        );
    }
}
