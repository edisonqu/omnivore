// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../interfaces/ILinkedERC721.sol";
import { IERC20 } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol";
import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { Upgradable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol";
import { StringToAddress, AddressToString } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol";


contract Marketplace is AxelarExecutable, Upgradable {

  using StringToAddress for string;
  using AddressToString for address;

  error AlreadyInitialized();
  error ItemNotForSale(address nftAddress, uint256 tokenId);
  error NotListed(address nftAddress, uint256 tokenId);
  error AlreadyListed(address nftAddress, uint256 tokenId);
  error NoProceeds();
  error NotApprovedForMarketplace();
  error PriceMustBeAboveZero();

  struct Listing {
    uint256 price;
    address seller;
  }

  event ItemListed(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
  );

  event ItemCanceled(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId
  );

  event ItemBought(
    address indexed buyer,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
  );

  IAxelarGasService immutable gasService;
  string public chainName;
  string public immutable symbol;
  mapping(address => mapping(uint256 => Listing)) private listings;

  
  constructor(address gateway_, address gasReceiver_, string memory symbol_) AxelarExecutable(gateway_) {
    gasService = IAxelarGasService(gasReceiver_);
    symbol = symbol_;
  }
  
  function _setup(bytes calldata params) internal override {
    string memory chainName_ = abi.decode(params, (string));
    if (bytes(chainName).length != 0) revert AlreadyInitialized();
    chainName = chainName_;
  }

  modifier notListed(
    address nftAddress,
    uint256 tokenId
  ) {
    Listing memory listing = listings[nftAddress][tokenId];
    if (listing.price > 0) {
      revert AlreadyListed(nftAddress, tokenId);
    }
    _;
  }

  modifier isListed(address nftAddress, uint256 tokenId) {
    require(isListed(nftAddress, tokenId));
    _;
  }

  modifier isOwner(
    address nftAddress,
    uint256 tokenId,
    address spender
  ) {
    ILinkedERC721 nft = ILinkedERC721(nftAddress);
    address owner = nft.ownerOf(tokenId);
    if (spender != owner) {
      revert NotOwner();
    }
    _;
  }

  function isListed(address nftAddress, uint256 tokenId) public pure returns (bool isListed) {
    Listing memory listing = listings[nftAddress][tokenId];
    return listing.price > 0;
  }

  /*
    * @notice Method for listing NFT
    * @param nftAddress Address of NFT contract
    * @param tokenId Token ID of NFT
    * @param price sale price for each item
  */
  function listItem(
    address nftAddress,
    uint256 tokenId,
    uint256 price
  ) external notListed(nftAddress, tokenId) isOwner(nftAddress, tokenId, msg.sender) { 
    if (price <= 0) {
      revert PriceMustBeAboveZero();
    }

    ILinkedERC721 nft = ILinkedERC721(nftAddress);
    if (nft.getApproved(tokenId) != address(this)) {
      revert NotApprovedForMarketplace();
    }
    listings[nftAddress][tokenId] = Listing(price, msg.sender);
    emit ItemListed(msg.sender, nftAddress, tokenId, price);
  }

  /*
    * @notice Method for cancelling listing 
    * @param nftAddress Address of NFT contract 
    * @param tokenId Token ID of NFT
  */
  function cancelListing(
    address nftAddress, 
    uint256 tokenId
  ) external isOwner(nftAddress, tokenId, msg.sender) isListed(nftAddress, tokenId) {
    delete (listings[nftAddress][tokenId]);
    emit ItemCanceled(msg.sender, nftAddress, tokenId);
  }

  /*
    * @notice Method for buying listing 
    * @param nftAddress Address of NFT contract 
    * @param tokenId Token ID of NFT
  */ 
  function buyItem(
    address nftAddress, 
    uint256 tokenId
  ) external isListed(nftAddress, tokenId)
  {
    Listing memory listedItem = listings[nftAddress][tokenId];
    address tokenAddress = gateway.tokenAddresses(symbol);
    IERC20(tokenAddress).transferFrom(msg.sender, listedItem.seller, listedItem.price);
    ILinkedERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
    emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
  }

  function buyItem(
    address operator, 
    address nftOperator,
    address nftAddress, 
    uint256 tokenId, 
    string memory destinationChain, 
    address destinationAddress,
    uint256 amount
  ) external payable {
    if (operator == address(this)) {
      _buyNative(nftAddress, tokenId);
    } else {
      _buyCrossChain(operator, nftOperator, nftAddress, tokenId, destinationChain, destinationAddress, amount);
    }
  }

  function _buyNative(address nftAddress, uint256 tokenId) internal {
    Listing memory listedItem = listings[nftAddress][tokenId];
    address tokenAddress = gateway.tokenAddresses(symbol);
    IERC20(tokenAddress).transferFrom(msg.sender, listedItem.seller, listedItem.price);
    ILinkedERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
    emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
  }

  function _buyCrossChain(
    address operator, 
    address nftOperator, 
    address nftAddress, 
    uint256 tokenId, 
    string destinationChain, 
    address destinationAddress,
    uint256 amount,
  ) internal {

    address tokenAddress = gateway.tokenAddresses(symbol);
    IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
    IERC20(tokenAddress).approve(address(gateway), amount);

    bytes memory payload = abi.encode(nftAddress, tokenId);


    bytes memory payload = abi.encode(nftOperator, nftAddress, tokenId, destinationAddress);
    string memory stringAddress = address(this).toString();

    gasService.payNativeGasForContractCall{ value: msg.value }(address(this), destinationChain, stringAddress, payload, msg.sender);
    gateway.callContractWithToken(destinationChain, stringAddress, payload, symbol, amount);
  }

  function _executeWithToken(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload,
    string calldata tokenSymbol,
    uint256 amount
  ) internal override {

    (address nftAddress, uint256 tokenId) = abi.decode(payload, (address, uint256));

    Listing memory listedItem = listings[nftAddress][tokenId];

    address tokenAddress = gateway.tokenAddresses(tokenSymbol);
    
    IERC20(tokenAddress).transfer(listedItem.se)

    // send asset cross chain and buy and send stuff back. 
    (string memory originalChain, address operator, address nftOperator, address nftAddress, uint256 tokenId, address destinationAddress) = abi.decode(
      payload,
      (string, address, address, address, uint256, address)
    )
  }

  function _executeWithToken(
        string calldata,
        string calldata,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal override {
        address[] memory recipients = abi.decode(payload, (address[]));
        address tokenAddress = gateway.tokenAddresses(tokenSymbol);

        uint256 sentAmount = amount / recipients.length;
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(tokenAddress).transfer(recipients[i], sentAmount);
        }
    }

  /*
    * @notice Method for updating listing 
    * @param nftAddress Address of NFT contract
    * @param tokenId Token ID of NFT 
    * @param newPrice New price of item 
  */
  function updateListing(
    address nftAddress, 
    uint256 tokenId,
    uint256 newPrice
  ) external isListed(nftAddress, tokenId) isOwner(nftAddress, tokenId, msg.sender) { 
    if (newPrice <= 0) {
      revert PriceMustBeAboveZero();
    }
    listings[nftAddress][tokenId].price = newPrice;
    emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
  }

  function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
    return listings[nftAddress][tokenId];
  }

  function contractId() external pure returns (bytes32) {
    return keccak256("example");
  }
}
