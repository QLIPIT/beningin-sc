// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract Beningin is ReentrancyGuard, ERC721Holder {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;

    struct Player {
      address payable playerAddress;
      uint256 scriptId;
      uint256 scriptPurchaseDate;
      bool activeScript;
    }

    mapping(address => Player) private _player;

    // event buy_Script(_from, scriptId, amount);


    // buy scripts
    // Verify that a player has our NFT

    function buyScript(address nftAddres, string memory scriptId ) public payable nonReentrant {
      // Check if msg.sender has an nft from a nftcollection

    }

    // check if player has script and if it is active



    
}