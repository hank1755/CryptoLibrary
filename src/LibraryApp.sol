// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// Create a Library App NFT 1155 per book 
// CRUD capable requ min 2 of 3 sigs

contract LibraryApp {
    
    // Enums
    enum BookStatus {
        New,
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
        address owner; // default owner library contract or borrower
        BookStatus status; // 0-Available, 1-Borrowed, 2-Removed (requires min 2 sigs)
    }

    struct Member {
        uint id;
        address memberAddr;
        string fname;
        string lname;
        MemberStatus status; // 0-Good, 1-Suspended (requires min 2 sigs), 3-Removed (requires min 2 sigs)
    }

    // Variables
    Book[] public books;
    Member[] public members;
    address public libraryOwner; // Library Owner
    address[] public libraryAdmins; // Library Admins (max 3)
    uint public bookIdCounter; // Counter to generate unique book IDs
    uint public memberIdCounter; // Counter to generate unique member IDs
    
    // Mappings
    mapping(uint => Book) public bookById; // Map book ID to Book struct
    mapping(uint => Member) public memberById; // Map member ID to Member struct

    constructor(address[] memory _admins) {
        libraryOwner = msg.sender;
        
        // Loop through the input array and push each admin address individually
        for (uint i = 0; i < _admins.length; i++) {
           libraryAdmins.push(_admins[i]);
        }
    }

    // Create Book Function: javascript-search book api & add to library, mapping
    // Use API from https://openlibrary.org/dev/docs/api/books
    function addBook(
        string memory _isbn, 
        string memory _title, 
        string memory _author, 
        address _owner) 
        public {
            require(libraryOwner == msg.sender);
            
            // Increment the book ID counter
            bookIdCounter++;

            // initialize an empty struct and then update it
            Book memory newBook = Book({
                id: bookIdCounter,
                isbn: _isbn,
                title: _title,
                author: _author,
                owner: _owner,
                status: BookStatus.New
            });
            books.push(newBook);

            // Map the book ID to the Book struct for easy lookup
            bookById[bookIdCounter] = newBook;
        }

    // Update Book Status: 0-Available, 1-Borrowed, 2-Removed (requires min 2 sigs)
    function updateBookStatus(uint _id, BookStatus _status) public {
        Book storage book = books[_id];
        book.status = _status;
    }

    // Add Library Member Function
    function joinLibrary(
    string memory _fname, 
    string memory _lname, 
    MemberStatus _status) 
    public {
        // Increment the book ID counter
        memberIdCounter++;

        // initialize an empty struct and then update it
        Member memory newMember = Member({
            id: memberIdCounter,
            memberAddr: msg.sender,
            fname: _fname,
            lname: _lname,
            status: _status
        });
        members.push(newMember);

        // Map the member ID to the Member struct for easy lookup 
        memberById[memberIdCounter] = newMember;
    }

    // Update Member Status: 0-Good, 1-Suspended (requires min 2 sigs), 3-Removed (requires min 2 sigs)
    function updateMemberStatus(uint _id, MemberStatus _status) public {
        require(libraryOwner == msg.sender);

        Member storage member = members[_id];
        member.status = _status;
    }

    // Remote LibraryApp Admins
    function removeLibraryAdmins(uint _index) public {
        require(libraryOwner == msg.sender);
        require(_index < libraryAdmins.length, "index out of bound");

        for (uint256 i = _index; i < libraryAdmins.length - 1; i++) {
            libraryAdmins[i] = libraryAdmins[i + 1];
        }
        libraryAdmins.pop();
    }
}