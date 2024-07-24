// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "../lib/forge-std//src/Script.sol";
import {LibraryApp} from "../src/LibraryApp.sol";

contract DeployLibraryApp is Script {
    function run() external returns(LibraryApp) {
        vm.startBroadcast();
        
        // Declare the LibraryApp libraryAdmins
        address[] memory admins = new address[](3);
        admins[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        admins[1] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        admins[2] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

        // Deploy the LibraryApp contract with three addresses
        LibraryApp libraryApp = new LibraryApp(admins);
        vm.stopBroadcast();
        return libraryApp;
    }
}

