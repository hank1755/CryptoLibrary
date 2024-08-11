// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

contract CryptoLibrary {
    error CryptoLibrary__NotOwner();

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

    enum MemberRole {
        Member,
        Admin,
        Owner
    }

    // Structs
    struct Book {
        uint id;
        string isbn;
        string title;
        string author;
        address owner; // Default owner library contract or borrower
        BookStatus status; // 0-Available, 1-Borrowed, 2-Removed (requires min 2 sigs)
    }

    struct Member {
        uint id;
        address memberAddr;
        string nickName;
        MemberRole role; // 0-Member, 1-Admin, 2-Owner
        MemberStatus status; // 0-Good, 1-Suspended (requires min 2 sigs), 3-Removed (requires min 2 sigs)
        uint[] checkedOutBookIds; // Array to track checked-out book IDs
    }

    // State Variables
    Book[] public books;
    Member[] public members;
    address public libraryOwner;
    uint public bookIdCounter;
    uint public memberIdCounter;

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == libraryOwner);
        if (msg.sender != libraryOwner) revert CryptoLibrary__NotOwner();
        _;
    }

    // Mappings
    mapping(uint => Book) public bookById;
    mapping(address => Member) public memberByAddress;

    constructor(address[3] memory _adminAddr, string[3] memory _nickName) {
        libraryOwner = msg.sender;

        for (uint i = 0; i < _adminAddr.length; i++) {
            addMember(_adminAddr[i], _nickName[i], MemberRole.Admin); // 0-Member, 1-Admin, 2-Owner
        }
    }

    // Add a new book
    function addBook(
        string memory _isbn,
        string memory _title,
        string memory _author
    ) public onlyOwner {
        bookIdCounter++;
        books.push(
            Book({
                id: bookIdCounter,
                isbn: _isbn,
                title: _title,
                author: _author,
                owner: address(this), // Initially owned by the library
                status: BookStatus.Available
            })
        );
        bookById[bookIdCounter] = books[bookIdCounter - 1];
    }

    // Self Service: Join Library
    function joinLibrary(string memory _nickName) public {
        memberIdCounter++;
        members.push(
            Member({
                id: memberIdCounter,
                memberAddr: msg.sender,
                nickName: _nickName,
                status: MemberStatus.Good,
                role: MemberRole.Member,
                checkedOutBookIds: new uint[](0)
            })
        );
        memberByAddress[msg.sender] = members[memberIdCounter - 1];
    }

    // Add Member
    function addMember(
        address _memberAddr,
        string memory _nickName,
        MemberRole _role
    ) public onlyOwner {
        memberIdCounter++;
        members.push(
            Member({
                id: memberIdCounter,
                memberAddr: _memberAddr,
                nickName: _nickName,
                status: MemberStatus.Good,
                role: _role, // 0-Member, 1-Admin, 2-Owner
                checkedOutBookIds: new uint[](0)
            })
        );
        memberByAddress[msg.sender] = members[memberIdCounter - 1];
    }

    // Check out a book
    function checkoutBook(uint _bookId) public {
        require(_bookId > 0 && _bookId <= bookIdCounter, "Invalid book ID");
        Book storage book = bookById[_bookId];
        Member storage member = memberByAddress[msg.sender];

        require(book.status == BookStatus.Available, "Book is not available");
        require(
            member.status == MemberStatus.Good,
            "Member is not in good standing"
        );

        // Update book status and ownership
        book.status = BookStatus.Borrowed;
        book.owner = msg.sender;

        // Update member's checked-out books
        member.checkedOutBookIds.push(_bookId);
    }

    // Return a book
    function returnBook(uint _bookId) public {
        require(_bookId > 0 && _bookId <= bookIdCounter, "Invalid book ID");
        Book storage book = bookById[_bookId];
        Member storage member = memberByAddress[msg.sender];

        require(book.owner == msg.sender, "You don't own this book");
        require(book.status == BookStatus.Borrowed, "Book is not borrowed");

        // Update book status and ownership
        book.status = BookStatus.Available;
        book.owner = address(this);

        // Remove the book ID from the member's checked-out list
        _removeBookId(member, _bookId);
    }

    // Internal function to remove a book ID from the member's list
    function _removeBookId(Member storage member, uint _bookId) internal {
        uint length = member.checkedOutBookIds.length;
        for (uint i = 0; i < length; i++) {
            if (member.checkedOutBookIds[i] == _bookId) {
                // Move the last element to the deleted spot
                member.checkedOutBookIds[i] = member.checkedOutBookIds[
                    length - 1
                ];
                member.checkedOutBookIds.pop(); // Remove the last element
                break;
            }
        }
    }

    // Get books checked out by a member
    function getCheckedOutBooks(
        address _memberAddr
    ) public view returns (Book[] memory) {
        Member storage member = memberByAddress[_memberAddr];
        uint[] memory bookIds = member.checkedOutBookIds;
        Book[] memory checkedOutBooks = new Book[](bookIds.length);

        for (uint i = 0; i < bookIds.length; i++) {
            checkedOutBooks[i] = bookById[bookIds[i]];
        }

        return checkedOutBooks;
    }
}
