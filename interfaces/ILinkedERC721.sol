// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import { IERC721 } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC721.sol";

interface ILinkedERC721 is IERC721 {

  function sendNFT(
    address operator, 
    uint256 tokenId,
    string memory destinationChain,
    address destinationAddress
  ) external payable;

  function contractId() external pure returns (bytes32);

}
