// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract CryptoLibrary {
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
        string fname;
        string lname;
        MemberStatus status; // 0-Good, 1-Suspended (requires min 2 sigs), 3-Removed (requires min 2 sigs)
        uint[] checkedOutBookIds; // Array to track checked-out book IDs
    }

    // Variables
    Book[] public books;
    Member[] public members;
    address public libraryOwner;
    uint public bookIdCounter;
    uint public memberIdCounter;

    // Mappings
    mapping(uint => Book) public bookById;
    mapping(address => Member) public memberByAddress;

    constructor() {
        libraryOwner = msg.sender;
    }

    // Add a new book
    function addBook(
        string memory _isbn,
        string memory _title,
        string memory _author
    ) public {
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

    // Join library as a new member
    function addMember(
        string memory _fname,
        string memory _lname,
        uint256[] memory _checkedOutBookIds
    ) public {
        memberIdCounter++;
        members.push(
            Member({
                id: memberIdCounter,
                memberAddr: msg.sender,
                fname: _fname,
                lname: _lname,
                status: MemberStatus.Good,
                checkedOutBookIds: _checkedOutBookIds // Initialize with an empty array
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
