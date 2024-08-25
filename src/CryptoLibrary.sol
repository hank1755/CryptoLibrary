// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CryptoLibrary is AccessControlEnumerable, ReentrancyGuard {
    error CryptoLibrary__NotAdminOrOwner();
    error CryptoLibrary__NotOwner();
    error CryptoLibrary__NotAdmin();

    // Type Declarations
    using PriceConverter for uint256;

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
    address public owner;
    Book[] public books;
    Member[] public members;
    uint public bookIdCounter;
    uint public memberIdCounter;
    uint256 public constant LibraryFee = 0.1 ether; // 1 ether = 10^18 wei
    AggregatorV3Interface private s_priceFeed;

    // Events
    event MemberJoined(address indexed member, string nickname, uint memberId);
    event MemberAdded(address indexed member, string nickname, uint memberId);
    event BookAdded(
        uint indexed bookId,
        string isbn,
        string title,
        string author
    );
    event BookCheckedOut(uint indexed bookId, address indexed member);
    event BookCheckedIn(uint indexed bookId, address indexed member);
    event LibraryClosed();
    event LibraryOpen();

    // Modifiers
    modifier minLibraryFee() {
        require(msg.value >= LibraryFee, "Min Library Fee of 0.1 ETH Required");
        _;
    }

    // Mappings
    mapping(uint => Book) public bookById;
    mapping(address => Member) public memberByAddress;

    // Access Control Roles
    bytes32 public constant LIBRARY_OWNER = keccak256("LIBRARY_OWNER");
    bytes32 public constant LIBRARY_ADMIN = keccak256("LIBRARY_ADMIN");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(
        address priceFeed,
        address[3] memory _adminAddr,
        string[3] memory _nickName
    ) {
        owner = payable(msg.sender);

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(LIBRARY_OWNER, owner);

        for (uint i = 0; i < _adminAddr.length; i++) {
            addMember(_adminAddr[i], _nickName[i], MemberRole.Admin); // 0-Member, 1-Admin, 2-Owner
            _grantRole(LIBRARY_ADMIN, _adminAddr[i]);
        }

        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    // Self Service: Join Library
    function joinLibrary(string memory _nickName) external {
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

        emit MemberJoined(msg.sender, _nickName, memberIdCounter); // Emit event
    }

    // Check-out a book
    function checkoutBook(
        uint _bookId
    ) public payable minLibraryFee nonReentrant {
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

        emit BookCheckedOut(_bookId, msg.sender); // Emit event
    }

    // Check-in a book
    function checkinBook(uint _bookId) public nonReentrant {
        require(_bookId > 0 && _bookId <= bookIdCounter, "Invalid book ID");

        Book storage book = bookById[_bookId];
        require(book.owner == msg.sender, "You don't own this book");
        require(book.status == BookStatus.Borrowed, "Book is not borrowed");

        uint refundAmount = 0.05 ether;
        require(
            address(this).balance >= refundAmount,
            "Insufficient contract balance"
        );

        Member storage member = memberByAddress[msg.sender];

        // Update book status and ownership
        book.status = BookStatus.Available;
        book.owner = address(this);

        // Remove the book ID from the member's checked-out list
        _removeBookId(member, _bookId);

        // Safely transfer the refund amount to the user
        (bool success, ) = msg.sender.call{value: refundAmount}("");
        require(success, "Refund transfer failed");

        emit BookCheckedIn(_bookId, msg.sender); // Emit event
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

    // Get member profile
    function getMemberProfile(
        address _memberAddr
    )
        public
        view
        returns (
            uint memberId,
            address memberAddr,
            string memory memberNickName,
            MemberRole memberRole,
            MemberStatus memberStatus,
            uint[] memory memberBooksCheckedOut
        )
    {
        Member storage member = memberByAddress[_memberAddr];

        return (
            member.id,
            member.memberAddr,
            member.nickName,
            member.role,
            member.status,
            member.checkedOutBookIds
        );
    }

    // Add Member
    function addMember(
        address _memberAddr,
        string memory _nickName,
        MemberRole _role
    ) public {
        if (!hasRole(LIBRARY_OWNER, msg.sender))
            revert CryptoLibrary__NotOwner();

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
        memberByAddress[_memberAddr] = members[memberIdCounter - 1];

        // If the new member is an Admin, grant them the admin role
        if (_role == MemberRole.Admin) {
            _grantRole(LIBRARY_ADMIN, _memberAddr);
        }

        emit MemberAdded(_memberAddr, _nickName, memberIdCounter); // Emit event
    }

    // Admin: Add a new book to library
    function addBook(
        string memory _isbn,
        string memory _title,
        string memory _author
    ) public {
        if (!hasRole(LIBRARY_ADMIN, msg.sender))
            revert CryptoLibrary__NotAdmin();

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

        emit BookAdded(bookIdCounter, _isbn, _title, _author); // Emit event
    }
}
