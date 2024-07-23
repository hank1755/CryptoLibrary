// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// Create a Library App NFT 1155 per book 
// CRUD capable requ min 2 of 3 sigs
// Use API from https://openlibrary.org/dev/docs/api/books

contract LibraryApp {
    
    // Enums
    enum BookStatus {
        Available,
        Borrowed,
        Unavailable,
        Purged
    }

    enum MemberStatus {
        Good,
        Suspended,
        Purged
    }

    // Structs
    struct Book {
        string isbn;
        string title;
        string author;
        address owner; // default owner library contract or borrower
        BookStatus status; // 0-Available, 1-Borrowed, 2-Unavailable, 3-Purged
    }

    struct Member {
        address memberAddr;
        string fname;
        string lname;
        MemberStatus status; // 0-Good, 1-Suspended, 3-Purged
    }

    // Variables
    Book[] public books;
    Member[] public members;
    address public libraryOwner; // Library Owner
    address[] public libraryAdmins; // Library Admins
    uint private bookIdCounter; // Counter to generate unique book IDs
    
    // Mappings
    mapping(uint => Book) public bookById; // Map book ID to Book struct

    constructor(address[] memory _libraryAdmins) {
        libraryOwner = msg.sender;
        
        // Loop through the input array and push each admin address individually
        for (uint i = 0; i < _libraryAdmins.length; i++) {
            libraryAdmins.push(_libraryAdmins[i]);
        }
    }

    // Helper function to generate a unique ISBN string
    function generateUniqueIsbn(uint _isbn, uint _counter) private pure returns (string memory) {
        return string(abi.encodePacked(_isbn, "-", uintToString(_counter)));
    }

    // Helper function to convert uint to string
    function uintToString(uint _value) private pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint temp = _value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    // Create Book Function: javascript-search book api & add to library, mapping
    function addBook(
        string memory _isbn, 
        string memory _title, 
        string memory _author, 
        address _owner, 
        BookStatus _status) 
        private {
            // Increment the book ID counter
            bookIdCounter++;

            // Generate a unique ISBN string
            string memory uniqueIsbn = string(abi.encodePacked(_isbn, "-", uintToString(bookIdCounter)));

            // initialize an empty struct and then update it
            Book memory newBook = Book({
            isbn : uniqueIsbn,
            title : _title,
            author : _author,
            owner : _owner,
            status : _status
            });
            books.push(newBook);

            // Map the book ID to the book struct for easy lookup
            bookById[bookIdCounter] = newBook;
        }

    // Search for books by isbn
    function searchBookIsbn(uint _isbn) public view returns (
        string memory,
        string memory, 
        string memory, 
        address, 
        BookStatus) {
            Book storage book = books[_isbn];
            return (
                book.isbn,
                book.title,
                book.author,
                book.owner,
                book.status);
        }

    // Update Book Function: check-in, check-out, purge from library
    //function updateBookStatus(uint _id, BookStatus _status) private {
    //    Book storage book = books[_isbn];
    //}

    // Delete Book Function: maintenance admin function, 2 of 3 sigs required

    // Create Library Member Function: generate random guid or use chainlink random
    // Read Library Member Function
    // Update Library Member Function
    // Delete Library Member Function
}