// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./TangetToken.sol";
import "./NFTGen.sol";

// Learn more about the ERC20 implementation 
// on OpenZeppelin docs: https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vendor is Ownable, MyEpicNFT {

// Model a vendor
  struct vendor {
        uint id;
        string BusinessName;
        string product;
        string price;
        string description;
        address customer;
    }

  address[] public vendorList;

  /// @notice mapping an address to the vendor structs, used to add vendors
    mapping(address => vendor) public vendors;

  //store vendors count
    uint public vendorsCount;

    //checking if a vendor already exists
    mapping (address => bool) public vendorExists;

  // Our Token Contract
  TangetToken tangetToken;

  // token price for ETH
  uint256 public tokensPerEth = 100;

  // Event that log buy operation
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

  constructor(address tokenAddress) {
    tangetToken = TangetToken(tokenAddress);
  }


  /**
  * @notice Allow users to buy tokens for ETH
  */
  function buyTokens() public payable returns (uint256 tokenAmount) {
    require(msg.value > 0, "Send ETH to buy some tokens");

    uint256 amountToBuy = msg.value * tokensPerEth;

    // check if the Vendor Contract has enough amount of tokens for the transaction
    uint256 vendorBalance = tangetToken.balanceOf(address(this));
    require(vendorBalance >= amountToBuy, "Vendor contract has not enough tokens in its balance");

    // Transfer token to the msg.sender
    (bool sent) = tangetToken.transfer(msg.sender, amountToBuy);
    require(sent, "Failed to transfer token to user");

    // emit the event
    emit BuyTokens(msg.sender, msg.value, amountToBuy);

    return amountToBuy;
  }

  /**
  * @notice Allow users to sell tokens for ETH
  */
  function sellTokens(uint256 tokenAmountToSell) public {
    // Check that the requested amount of tokens to sell is more than 0
    require(tokenAmountToSell > 0, "Specify an amount of token greater than zero");

    // Check that the user's token balance is enough to do the swap
    uint256 userBalance = tangetToken.balanceOf(msg.sender);
    require(userBalance >= tokenAmountToSell, "Your balance is lower than the amount of tokens you want to sell");

    // Check that the Vendor's balance is enough to do the swap
    uint256 amountOfETHToTransfer = tokenAmountToSell / tokensPerEth;
    uint256 ownerETHBalance = address(this).balance;
    require(ownerETHBalance >= amountOfETHToTransfer, "Vendor has not enough funds to accept the sell request");

    (bool sent) = tangetToken.transferFrom(msg.sender, address(this), tokenAmountToSell);
    require(sent, "Failed to transfer tokens from user to vendor");


    (sent,) = msg.sender.call{value: amountOfETHToTransfer}("");
    require(sent, "Failed to send ETH to the user");
  }

  /**
  * @notice Allow the owner of the contract to withdraw ETH
  */
  function withdraw() public onlyOwner {
    uint256 ownerBalance = address(this).balance;
    require(ownerBalance > 0, "Owner has not balance to withdraw");

    (bool sent,) = msg.sender.call{value: address(this).balance}("");
    require(sent, "Failed to send user balance back to the owner");
  }

    /// @notice This function mints nft to the msg.sender and transfers eth to the vendor address
    /// @param _productPrice cost of the product in ethers
    /// @param _vendorWallet wallet address of the vendor
    function purchaseSubscription(uint _productPrice, address payable _vendorWallet) payable public {
        _productPrice = _productPrice * 10 ** 18;
        require(msg.value == _productPrice,"Amount not enough"); 
        _vendorWallet.transfer(msg.value);
        makeAnEpicNFT();
    }

   /// @notice Add vendors with their id, Business name, product, price, description and address.
   /// @param  _id is the registration ID of the vendor to add to vendors
   /// @param  _BusinessName is the business name of the vendor to add to vendors 
   /// @param _product represents the product the vendor will be offering to customers
   /// @param _price represents the price of the product the vendor will be offering to customers
   /// @param _description provides details on the vendor and the type of product they will be offering
   /// @param _customer represents the wallet address of the vendor

    function addVendors (uint _id, string memory _BusinessName,string memory _product, string memory _price, string memory _description, address _customer) public onlyOwner {
        require(vendorExists[_customer] == false, "This address is already a vendor");
        vendorsCount ++;

        vendor memory customerDetails = vendor(_id,_BusinessName,_product,_price,_description,_customer); 
        vendors[_customer] = customerDetails;
        vendorExists[_customer] = true;
        vendorList.push(_customer);
    }

     // function to get the details of the signer 
    function getvendorDetails() public view returns ( uint id, string memory BusinessName, string memory product, string memory price, string memory description, address customer){
        require(vendorExists[msg.sender] == true, "Not a vendor");
        vendor memory p = vendors[msg.sender];
        return (p.id, p.BusinessName, p.product, p.price, p.description, p.customer); 

    }

}