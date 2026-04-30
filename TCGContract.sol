// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@5.0.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@5.0.0/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@5.0.0/access/Ownable.sol";

contract TCGCard is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    
    mapping(uint256 => uint256) public cardStats;

    uint256 private _nextTokenId; 

    constructor() ERC721("TCGCards", "TCG") Ownable(msg.sender) {}

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _nextTokenId++; 
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId)));

        uint256 attack    = randomHash % 256;
        uint256 deffence    = (randomHash >> 8) % 256;
        uint256 speed = (randomHash >> 16) % 256;
        uint256 stamina     = (randomHash >> 24) % 256;
        uint256 magic     = (randomHash >> 32) % 256;

        uint256 packedStats = (magic << 32) | (stamina << 24) | (speed << 16) | (deffence << 8) | attack;

        cardStats[tokenId] = packedStats;
    }

    function getCardStats(uint256 tokenId) public view returns (
        uint256 attack, 
        uint256 deffence, 
        uint256 speed, 
        uint256 stamina, 
        uint256 magic
    ) {
        uint256 stats = cardStats[tokenId];
        
        attack    = stats & 255;
        deffence    = (stats >> 8) & 255;
        speed = (stats >> 16) & 255;
        stamina     = (stats >> 24) & 255;
        magic     = (stats >> 32) & 255;
    }

    function getPlayerCards(address player) public view returns (uint256[] memory) {
        uint256 cardCount = balanceOf(player);
        
        uint256[] memory ownedCards = new uint256[](cardCount);
        
        uint256 currentIndex = 0;
        
        for (uint256 i = 0; i < _nextTokenId; i++) {
            if (ownerOf(i) == player) {
                ownedCards[currentIndex] = i;
                currentIndex++;
            }
        }
        
        return ownedCards;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}