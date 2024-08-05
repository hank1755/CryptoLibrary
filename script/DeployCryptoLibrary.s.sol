// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "../lib/forge-std//src/Script.sol";
import {CryptoLibrary} from "../src/CryptoLibrary.sol";

contract DeployCryptoLibrary is Script {
    CryptoLibrary public cryptolibrary;

    function setup() public {}

    function run() public {
        vm.startBroadcast();

        // Declare the LibraryApp libraryAdmins
        address[] memory admins = new address[](3);
        admins[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        admins[1] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        admins[2] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

        // Deploy the LibraryApp contract with three addresses
        cryptolibrary = new CryptoLibrary(admins);
        vm.stopBroadcast();
    }
}
