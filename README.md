## Crypto Library Project Summary

Members can check-out/check-in ERC-1155 NFT's, based on attributes from OpenLibrary, representing each book added by an Admin in the library.

**Owner:** Contract owner and access control.

**Admins:** Manage members and books.

**Members:** Check-out/Check-in NFT of available books in the library and manage their own membership profile.

### Frontend: Python Classic & Responsive React

Use open library api to search books by ISBN and get the books data:

* picture
* title
* author

Users will have the following functions:

* Join the Crypto Library
* Search for books owned by the library by isbn, title, author and books they have checked out
* Check books out/in

Admins will have all User functions plus:

* Search for books owned by the library by status and owner

### Backend: Solidity Contract Functions

Member functions:

* joinLibrary: join the Crypto Library
* checkoutBook: check-out NFT book
* returnBook: return checked-out NFT book

Admin functions:

* addMember: Admin function: add member to Crypto Library
* addBook: Admin function: add new book to library

Roadmap:

* Add ETH deposit for check-out & refund on return
* Research if way to auto return NFT via expiry
