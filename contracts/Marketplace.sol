// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/tokne/ERC20/IERC20.sol";

error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();

contract Marketplace is Ownable {
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

  IERC20 public immutable usdc;
  mapping(address => mapping(uint256 => Listing)) private listings;

  constructor(address usdc_) Ownable() {
    usdc = IERC20(usdc_);
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
    Listing memory listing = listings[nftAddress][tokenId];
    if (listing.price <= 0) {
      revert NotListed(nftAddress, tokenId);
    }
    _;
  }

  modifier isOwner(
    address nftAddress,
    uint256 tokenId,
    address spender
  ) {
    IERC721 nft = IERC721(nftAddress);
    address owner = nft.ownerOf(tokenId);
    if (spender != owner) {
      revert NotOwner();
    }
    _;
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
  )
    external
    notListed(nftAddress, tokenId)
    isOwner(nftAddress, tokenId, msg.sender)
  { 
    if (price <= 0) {
      revert PriceMustBeAboveZero();
    }

    IERC721 nft = IERC721(nftAddress);
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
  function cancelListing(address nftAddress, uint256 tokenId)
    external
    isOwner(nftAddress, tokenId, msg.sender)
    isListed(nftAddress, tokenId)
  {
    delete (listings[nftAddress][tokenId]);
    emit ItemCanceled(msg.sender, nftAddress, tokenId);
  }

  /*
    * @notice Method for buying listing 
    * @param nftAddress Address of NFT contract 
    * @param tokenId Token ID of NFT
  */ 
  function buyItem(address nftAddress, uint256 tokenId)
    external
    isListed(nftAddress, tokenId)
  {
    Listing memory listedItem = listings[nftAddress][tokenId];
    usdc.transferFrom(msg.sender, listedItem.seller, listedItem.price);
    IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
    emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
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
  )
    external
    isListed(nftAddress, tokenId)
    isOwner(nftAddress, tokenId, msg.sender)
  { 
    if (newPrice <= 0) {
      revert PriceMustBeAboveZero();
    }
    listings[nftAddress][tokenId].price = newPrice;
    emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
  }

  function getListing(address nftAddress, uint256 tokenId)
    external
    view
    returns (Listing memory)
  {
    return listings[nftAddress][tokenId];
  }
}
