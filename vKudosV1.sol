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

    // mapping the kudos id of an holder to its vKudos id
    mapping(uint256 => mapping(address => uint256)) public vKudos;
    // mapping whitelisted kudos ids
    mapping(uint256 => bool) public whitelistedIds;
    // kudos 1155 Collection address on Polygon Mumbai testnet
    address public constant kudosCollection = 0xB876baF8F69cD35fb96A17a599b070FBdD18A6a1;
    // kudos ids whitelist is active or not
    bool public activeWhitelist;
    // whitelist after contract initialization is active or not
    bool public whitelistAfterInitialization;
    // same token uri string for all the vKudos of the same Collection contract address
    string public tokenUri;

    /**
     * @dev Constructor: initialize vKudos contract
     * @param ids The Kudos Ids allowed to be uesd to mint a vKudos token
     * @param _activeWhitelist If ids is empty and _activeWhitelist is false, every Kudos Ids can be uesd to mint a vKudos token
     * @param _whitelistAfterInitialization If the contract owner (msg.sender) can add new whitelisted Kudos Ids after contract initialization using the setWhitelistedKudos function
     */
    constructor(uint256[] memory ids, string memory _tokenUri, bool _activeWhitelist, bool _whitelistAfterInitialization)
        ERC721("vKudosVote", "vKV")
        EIP712("vKudosVote", "1")
    {
        _tokenIdCounter.increment();
        _setWhitelistedKudos(ids);
        tokenUri = _tokenUri;
        activeWhitelist = _activeWhitelist;
        whitelistAfterInitialization = _whitelistAfterInitialization;
    }

    /**
     * @dev add new whitelisted Kudos Ids after contract initialization. This function can be calle donly by the contract owner (contract deployer address)
     * @param ids New Kudos Ids allowed to be uesd to mint a vKudos token
     */
    function setWhitelistedKudos(uint256[] memory ids) external onlyOwner {
        require(whitelistAfterInitialization, "you can't add new whitelisted ids");
        _setWhitelistedKudos(ids);
    }

    /**
     * @dev A whitelisted Kudos Id holder (or anyone if !activeWhitelist ) can mint its vKudos token
     * @param id Kudos Id uesd to mint a vKudos token
     */
    function safeMint(uint256 id) public {
        require(IERC1155(kudosCollection).balanceOf(msg.sender,id) >= 1, "you're not the owner");
        require(vKudos[id][msg.sender] == 0, "already minted");
        require(whitelistedIds[id] == true || !activeWhitelist, "id not allowed");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        vKudos[id][msg.sender] = tokenId;
    }

    /**
     * @dev Ovverride the standard tokenUri function to return the same image for all vKudos ids of the same contract address 
     * @param tokenId vKudos Id
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenUri; 
    }

    // internal function used both by Constructor and setWhitelistedKudos to add whitelisted Kudos Ids
    function _setWhitelistedKudos(uint256[] memory ids) internal {
        if (ids.length > 0) {
            for (uint i = 0; i < ids.length; i++) {
            whitelistedIds[ids[i]] = true;
            }
        }
    }

    // make the token a soulbound overriding the _beforeTokenTransfer hook
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
      require(from == address(0) || to == address(0), "this token is a soulbound");
      super._beforeTokenTransfer(from, to, tokenId);
   }

    // function override required by Solidity
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Votes) {
        super._afterTokenTransfer(from, to, tokenId);
    }
}
