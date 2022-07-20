// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./NftGen.sol";



contract Vendor is ERC20 {
  address public owner;

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

  // token price for ETH
  uint256 public tokensPerEth = 100;

  // Event that log buy operation
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

   constructor() ERC20("Tanget ETH Token", "TAN") {
        _mint(msg.sender, 1000 * 10 ** 18);
        owner = msg.sender;
  }


  /**
  * @notice Allow users to buy tokens for ETH
  */
  function buyTokens(uint256 tokenAmount) public payable {
    require(msg.value > 0, "Send ETH to buy some tokens");

    uint256 amountToBuy = msg.value * tokensPerEth;

    // check if the Vendor Contract has enough amount of tokens for the transaction
    uint256 vendorBalance = balanceOf(address(this));
    require(vendorBalance >= amountToBuy, "Vendor contract has not enough tokens in its balance");

    // Transfer token to the msg.sender
    (bool sent) = transfer(msg.sender, amountToBuy);
    require(sent, "Failed to transfer token to user");

    // emit the event
    emit BuyTokens(msg.sender, msg.value, amountToBuy);

  }

  modifier onlyOwner() {
        require(msg.sender == owner, "You're not authorised to perform this function");
        _;
    }

  /**
  * @notice Allow users to sell tokens for ETH
  */
  function sellTokens(uint256 tokenAmountToSell) public {
    // Check that the requested amount of tokens to sell is more than 0
    require(tokenAmountToSell > 0, "Specify an amount of token greater than zero");

    // Check that the user's token balance is enough to do the swap
    uint256 userBalance = balanceOf(msg.sender);
    require(userBalance >= tokenAmountToSell, "Your balance is lower than the amount of tokens you want to sell");

    // Check that the Vendor's balance is enough to do the swap
    uint256 amountOfETHToTransfer = tokenAmountToSell / tokensPerEth;
    uint256 ownerETHBalance = address(this).balance;
    require(ownerETHBalance >= amountOfETHToTransfer, "Vendor has not enough funds to accept the sell request");

    (bool sent) = transferFrom(msg.sender, address(this), tokenAmountToSell);
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

  //Function to Batch Reward clients who purchase products from our vendors
    function rewardClients(address[] calldata addressesTo, uint256[] calldata amounts) external
    onlyOwner returns (uint, bool)
    {
        require(addressesTo.length == amounts.length, "Invalid input parameters");

        uint256 sum = 0;
        for(uint256 i = 0; i < addressesTo.length; i++) {
            require(addressesTo[i] != address(0), "Invalid Address");
            require(amounts[i] != 0, "You cant't trasnfer 0 tokens");
            require(addressesTo.length <= 200, "exceeds number of allowed addressess");
            require(amounts.length <= 200, "exceeds number of allowed amounts");
            require(transfer(addressesTo[i], amounts[i]* 10 ** 18), "Unable to transfer token to the account");
            sum += amounts[i];
        }
        return(sum, true);
    }

     //Function to check the remainig token after rewarding clients
    function checkTangetBalance() public view onlyOwner  returns(uint256)  {
        return balanceOf(msg.sender);
    }

}