// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract vKudosSoulbound is ERC721, Ownable, EIP712, ERC721Votes {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // mapping the kudos id of an holder to its wKudos id
    mapping(uint256=>mapping(address=>uint256)) public wKudos;
    // mapping whitelisted kudos ids
    mapping(uint256=>bool) public whitelistedIds;
    // kudos 1155 Collection address on Polygon
    address public constant kudosCollection = 0x60576A64851C5B42e8c57E3E4A5cF3CF4eEb2ED6;
    // kudos ids whitelist is active or not
    bool public activeWhitelist;

    constructor(uint256[] memory ids, bool whitelist)
        ERC721("wKudosVote", "WKV")
        EIP712("wKudosVote", "1")
    {
        _tokenIdCounter.increment();
        _setWhitelistedKudos(ids);
        setWhitelistMode(whitelist);
    }

    // set new whitelisted kudos ids
    function setWhitelistedKudos(uint256[] memory ids) external onlyOwner {
        _setWhitelistedKudos(ids);
    }
    function _setWhitelistedKudos(uint256[] memory ids) internal {
        if (ids.length > 0) {
            for (uint i = 0; i < ids.length; i++) {
            whitelistedIds[ids[i]] = true;
            }
        }
    }

    // true if you want to define a list of whitelisted kudos ids
    function setWhitelistMode(bool whitelist) public onlyOwner {
        activeWhitelist = whitelist;
    }

    // mint vKudos
    function safeMint(uint256 id) public {
        //require(IERC1155(kudosCollection).balanceOf(msg.sender,id) >= 1, "you're not the owner");
        //require(wKudos[id][msg.sender] == 0, "already minted");
        require(whitelistedIds[id] == true || !activeWhitelist, "id not allowed");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        wKudos[id][msg.sender] = tokenId;
    }

    // make the token a soulbound overriding the _beforeTokenTransfer hook
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
      require(from == address(0) || to == address(0), "this token is a soulbound");
      super._beforeTokenTransfer(from, to, tokenId);
   }

    // The following functions are overrides required by Solidity
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Votes) {
        super._afterTokenTransfer(from, to, tokenId);
    }
     
    // ovverride tokenUri to return the same image for all vKudos ids 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return "ipfs://QmRDWUBWVR5gnNFkMo5uri1ZUcYt8rq4Wgg748cdjDYuDa"; 
    }
}
