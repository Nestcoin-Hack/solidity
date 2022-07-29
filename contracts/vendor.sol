// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./NFTGen.sol";

interface INftGen {
  function makeAnEpicNFT() external;
}

contract Vendor is ERC20 {
  address public owner;
  address NftGenAddr;

  
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
  uint256 public tangetTokenPerEth = 10;

  // Event that log buy operation
  event BuyTokens(uint256 amountOfTangetToken);

   constructor() ERC20("TangetToken", "TAN") {
        _mint(msg.sender, 1000 * 10 ** 18);
        owner = msg.sender;
  }

  /**
  * @notice Allow users to buy tokens for ETH
  */
  function buyTokens(uint256 amountOfTangetToken) public payable {
    require(msg.value == amountOfTangetToken * tangetTokenPerEth, 'Need to send exact amount of wei');
    
    transfer(msg.sender, amountOfTangetToken);
    
    // emit the event
    emit BuyTokens(amountOfTangetToken);

  }

  modifier onlyOwner() {
        require(msg.sender == owner, "You're not authorised to perform this function");
        _;
    }

    /// @notice This function mints nft to the msg.sender and transfers eth to the vendor address
    /// @param _productPrice cost of the product in ethers
    function purchaseSubscription(uint _productPrice, address payable _vendorWallet) payable public {
        _productPrice = _productPrice * 10 ** 18;
        require(msg.value == _productPrice,"Amount not enough"); 
        _vendorWallet.transfer(msg.value);
        INftGen(NftGenAddr).makeAnEpicNFT();
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