from web3 import Web3
import json

# Connect to local Ethereum node (e.g., Ganache, Anvil) or Infura
infura_url = "https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID"
anvil_url = "http://127.0.0.1:8545"
web3 = Web3(Web3.HTTPProvider(anvil_url))

# Load the contract ABI and address
with open("CryptoLibraryABI.json", "r") as abi_file:
    abi = json.load(abi_file)
contract_address = "0x5fbdb2315678afecb367f032d93f642f64180aa3"
contract = web3.eth.contract(address=contract_address, abi=abi)

# Set your wallet address and private key
wallet_address = "YOUR_METAMASK_WALLET_ADDRESS"
private_key = "YOUR_METAMASK_PRIVATE_KEY"

# Join Library Function
def joinLibrary():
    nickname = input("Enter your nickname: ")
    nonce = web3.eth.getTransactionCount(wallet_address)
    txn = contract.functions.joinLibrary(nickname).buildTransaction({
        'chainId': 1,  # Replace with your network's chain ID
        'gas': 2000000,
        'gasPrice': web3.toWei('20', 'gwei'),
        'nonce': nonce
    })

    #signed_txn = web3.eth.account.sign_transaction(txn, private_key=private_key)
    #txn_hash = web3.eth.sendRawTransaction(signed_txn.rawTransaction)
    #print(f"Transaction hash: {txn_hash.hex()}")

# Search Books by ISBN
def searchBooksIsbn():
    isbn = input("Enter the ISBN of the book: ")
    books = contract.functions.books().call()
    for book in books:
        if book[1] == isbn:
            print(f"Title: {book[2]}, Author: {book[3]}, Status: {book[5]}")

# Search Books by Author
def searchBooksAuthor():
    author = input("Enter the author name: ")
    books = contract.functions.books().call()
    for book in books:
        if book[3] == author:
            print(f"Title: {book[2]}, ISBN: {book[1]}, Status: {book[5]}")

# Search Books by Title
def searchBooksTitle():
    title = input("Enter the title of the book: ")
    books = contract.functions.books().call()
    for book in books:
        if book[2] == title:
            print(f"Author: {book[3]}, ISBN: {book[1]}, Status: {book[5]}")

# Check-Out Book
def checkoutBook():
    book_id = int(input("Enter the book ID to check out: "))
    nonce = web3.eth.getTransactionCount(wallet_address)
    txn = contract.functions.checkoutBook(book_id).buildTransaction({
        'chainId': 1,
        'gas': 2000000,
        'gasPrice': web3.toWei('20', 'gwei'),
        'nonce': nonce
    })

    signed_txn = web3.eth.account.sign_transaction(txn, private_key=private_key)
    txn_hash = web3.eth.sendRawTransaction(signed_txn.rawTransaction)
    print(f"Transaction hash: {txn_hash.hex()}")

# Check-In Book
def checkinBook():
    book_id = int(input("Enter the book ID to check in: "))
    nonce = web3.eth.getTransactionCount(wallet_address)
    txn = contract.functions.returnBook(book_id).buildTransaction({
        'chainId': 1,
        'gas': 2000000,
        'gasPrice': web3.toWei('20', 'gwei'),
        'nonce': nonce
    })

    signed_txn = web3.eth.account.sign_transaction(txn, private_key=private_key)
    txn_hash = web3.eth.sendRawTransaction(signed_txn.rawTransaction)
    print(f"Transaction hash: {txn_hash.hex()}")

# Get My Book Checkouts
def getMyBookCheckouts():
    books = contract.functions.getCheckedOutBooks(wallet_address).call()
    for book in books:
        print(f"Title: {book[2]}, ISBN: {book[1]}, Status: {book[5]}")

# Get My Account Info
def getMyAccountInfo():
    member = contract.functions.memberByAddress(wallet_address).call()
    print(f"ID: {member[0]}, Nickname: {member[2]}, Role: {member[3]}, Status: {member[4]}")

# Main Loop
is_running = True

while is_running:
    print("\nCrypto Library")
    print("1. Search by ISBN")
    print("2. Search by Author")
    print("3. Search by Title")
    print("4. Check-Out Book")
    print("5. Check-In Book")
    print("6. View Account")
    print("7. Join Library")
    print("8. Exit")

    choice = input("Enter selection (1-8): ")

    if choice == '1':
        searchBooksIsbn()
    elif choice == '2':
        searchBooksAuthor()
    elif choice == '3':
        searchBooksTitle()
    elif choice == '4':
        checkoutBook()
    elif choice == '5':
        checkinBook()
    elif choice == '6':
        getMyAccountInfo()
    elif choice == '7':
        joinLibrary()
    elif choice == '8':
        is_running = False
    else:
        print("Invalid selection, please try again.")
