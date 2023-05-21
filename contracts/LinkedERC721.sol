// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC20 } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol";
import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { Upgradable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol";
import { StringToAddress, AddressToString } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol";

contract LinkedERC721 is ERC721, AxelarExecutable, Upgradable {

  using StringToAddress for string;
  using AddressToString for address;

  error AlreadyInitialized();

  mapping(uint256 => bytes) public original; //abi.encode(originalChain, operator, tokenId);
  string public chainName;
  IAxelarGasService public immutable gasService;

  constructor(address gateway_, address gasReceiver_, string memory name_, string memory symbol_) ERC721(name_, symbol_) AxelarExecutable(gateway_) {
    gasService = IAxelarGasService(gasReceiver_);
  }

  function mint(uint256 tokenId) external {
    _safeMint(_msgSender(), tokenId);
  }

  function _setup(bytes calldata params) internal override {
    string memory chainName_ = abi.decode(params, (string));
    if (bytes(chainName).length != 0) revert AlreadyInitialized();
    chainName = chainName_;
  }

  function sendNFT(
    address operator, 
    uint256 tokenId,
    string memory destinationChain,
    address destinationAddress
  ) external payable {
    if (operator == address(this)) {
      require(ownerOf(tokenId) == _msgSender(), 'NOT_YOUR_TOKEN');
      _sendMintedToken(tokenId, destinationChain, destinationAddress);
    } else {
      IERC721(operator).transferFrom(_msgSender(), address(this), tokenId);
      _sendNativeToken(operator, tokenId, destinationChain, destinationAddress);
    }
  }

  function _sendMintedToken(
    uint256 tokenId,
    string memory destinationChain,
    address destinationAddress
  ) internal {
    _burn(tokenId);
    (string memory originalChain, address operator, uint256 originalTokenId) = abi.decode(
      original[tokenId],
      (string, address, uint256)
    );

    bytes memory payload = abi.encode(originalChain, operator, originalTokenId, destinationAddress);
    string memory stringAddress = address(this).toString();

    gasService.payNativeGasForContractCall{ value: msg.value }(address(this), destinationChain, stringAddress, payload, msg.sender);
    gateway.callContract(destinationChain, stringAddress, payload);
  }

  function _sendNativeToken(
    address operator,
    uint256 tokenId,
    string memory destinationChain,
    address destinationAddress
  ) internal {
    bytes memory payload = abi.encode(chainName, operator, tokenId, destinationAddress);
    string memory stringAddress = address(this).toString();

    gasService.payNativeGasForContractCall{ value: msg.value }(address(this), destinationChain, stringAddress, payload, msg.sender);
    gateway.callContract(destinationChain, stringAddress, payload);
  }

  function _execute(
    string calldata,
    string calldata sourceAddress,
    bytes calldata payload
  ) internal override {
    require(sourceAddress.toAddress() == address(this), "NOT_A_LINKER");
    (string memory originalChain, address operator, uint256 tokenId, address destinationAddress) = abi.decode(
      payload,
      (string, address, uint256, address)
    );

    if (keccak256(bytes(originalChain)) == keccak256(bytes(chainName))) {
      IERC721(operator).transferFrom(address(this), destinationAddress, tokenId);
    } else {
      bytes memory originalData = abi.encode(originalChain, operator, tokenId);

      uint256 newTokenId = uint256(keccak256(originalData));
      original[newTokenId] = originalData;
      _safeMint(destinationAddress, newTokenId);
    }
  }

  function contractId() external pure returns (bytes32) {
    return keccak256("example");
  }

}
