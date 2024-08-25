// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "../lib/forge-std//src/Script.sol";
import {CryptoLibrary} from "../src/CryptoLibrary.sol";

contract DeployCryptoLibrary is Script {
    function setUp() public {}

    function run() external {
        vm.startBroadcast();

        // Get price feed address
        address _priceFeedAddr = vm.envAddress("PRICE_FEED_ETHUSD_SEPOLIA");

        // Declare the Crypto Library libraryAdmins
        address[3] memory _adminAddr = [
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
        ];
        string[3] memory _nickName = ["Admin1", "Admin2", "Admin3"];

        // Deploy the Crypto Library contract with three addresses
        new CryptoLibrary(_priceFeedAddr, _adminAddr, _nickName);
        vm.stopBroadcast();
    }
}
