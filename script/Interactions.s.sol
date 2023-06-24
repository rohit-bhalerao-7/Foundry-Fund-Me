//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
//fund
//withdraw

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "src/FundMe.sol";

contract FundFundMe is
    Script // this contract FundFundMe script for funding the fundme contract
{
    uint256 constant SEND_VALUE = 0.1 ether; //0.1 ether = 100000000000000000 wei

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}(); //
        vm.stopBroadcast();
        console.log("Funded FundMe contract with %s", SEND_VALUE);
    }

    function run() external {
        //we want to fund our recently deployed contract
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        ); // it looks inside the broadcast folder based of chain ID and finds the most recently deployed contract
        //vm.startBroadcast();
        fundFundMe(mostRecentlyDeployed);
        //vm.startBroadcast();
    }
}

contract WithdrawFundMe is Script {
    // script for withdrawing from the fundme contract
    //uint256 constant SEND_VALUE = 0.1 ether; //0.1 ether = 100000000000000000 wei

    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw(); //
        vm.stopBroadcast();
    }

    function run() external {
        //we want to fund our recently deployed contract
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        ); // it looks inside the broadcast folder based of chain ID and finds the most recently deployed contract

        withdrawFundMe(mostRecentlyDeployed);
    }
}
