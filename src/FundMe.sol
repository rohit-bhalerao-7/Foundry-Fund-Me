//SPDX-License-Identifier: MIT

//Get funds from user, withdraw funds, set minimum funding value in USD
pragma solidity ^0.8.0;
import {PriceConverter} from "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//instead of writing require statements and increasing gas price we declare error at top

error FundMe__notOwner();

contract FundMe {
    using PriceConverter for uint256;

    //to decrease gas prices we use 'constant' & 'immutable' for variables
    //const variables are in CAPITAL

    mapping(address => uint256) public s_addressToAmountFunded;
    address[] public s_funders;

    uint256 public constant MINIMUM_USD = 50 * 1e18; //1e18= 1*10**18
    address private immutable i_owner;    
    AggregatorV3Interface private s_priceFeed;
    //s_variable means storage variable and make them private to be gas efficient and make them public/external/view as we need
    //immutable variables naming is 'i_variable'
    //in const we just declare once and in immutable we can declare it once again in constructor

    //constructor is a func which is immediately called after deploying
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    modifier onlyOwner() {
        //require(msg.sender == owner," Sender is not the owner");
        if (msg.sender != i_owner) {
            revert FundMe__notOwner();
        }
        _; //This means run rest of the code after require/if
    }

    function fund() public payable {
        //Want to able to set minimum fund amount in USD
        //1. How do we send ETH to this contract?
        //number = 5;
        //getConversionRate(msg.value) = msg.value.getConversionRate()
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        ); // 1e18= 1 x 10 x 10...(18 times 10)
        s_funders.push(msg.sender); //it will push the address of sender
        s_addressToAmountFunded[msg.sender] += msg.value;

        //Undo any action before and send remaining gas back is called reverting.
        //In this case if requirement isn't met, it will revert. Anything after revert gas wont be paid for it.
        //Anything before revert gas will be paid for the computations. eg here is changing number to 5
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }
    
    function cheaperWithdraw() public onlyOwner{
      uint256 fundersLength = s_funders.length; //Reading once from storage
      for(uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++){
          address funder = s_funders[funderIndex];
          s_addressToAmountFunded[funder] = 0;
      }
      (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed!");
    }


    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length; // reading from storage everytime we loop which is expensive
            funderIndex++
        ) {
            address funder = s_funders[funderIndex]; //we get funder address from storage 
            s_addressToAmountFunded[funder] = 0;
        }

        //resetting array
        //instead of looping through for each array we can reset funders to a
        //new address with 0 objects in it ie blank
        s_funders = new address[](0);
        //transfer,send,call(use this)
        //we are not calling a function so ("")
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed!");
    }

    //receive will trigger when calldata is empty and fallback triggered when calldata filled
    //incase receive not there and calldata empty fallback triggered otherwise error
    //can use receive and fallback only once in a contract
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
/** 
   View/Pure functions (Getters/Getter Function) 
  */ // when functions are private we can't call them from outside therefore we use getters
  function getAddressToAmountFunded( 
        address fundingAddress 
  )external view returns(uint256){
      return s_addressToAmountFunded[fundingAddress];
  }
  function getFunder(uint256 index) external view returns (address){
      return s_funders[index];
  }
  function getOwner() external view returns (address){
      return i_owner;
  }

}
