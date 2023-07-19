// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract QlipNFT is ERC1155, Ownable {
    
  string public name;
  string public symbol;

  mapping(uint => string) public tokenURI;

  constructor() ERC1155("") {
    name = "Qlip Token";
    symbol = "QLPT";
  }

  function mint(address _to, uint _id, uint _amount) external {
    _mint(_to, _id, _amount, "");
  }

  function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external {
    _mintBatch(_to, _ids, _amounts, "");
  }

  function burn(uint _id, uint _amount) external {
    _burn(msg.sender, _id, _amount);
  }

  function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
    _burnBatch(msg.sender, _ids, _amounts);
  }

  function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external onlyOwner {
    _burnBatch(_from, _burnIds, _burnAmounts);
    _mintBatch(_from, _mintIds, _mintAmounts, "");
  }

  function setURI(uint _id, string memory _uri) external {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }

  function changeOwner(address newOwner) external onlyOwner {
      _transferOwnership(newOwner);
  }

}