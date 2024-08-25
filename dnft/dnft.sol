// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract dNFT is ERC721 {
    //用於管理生成唯一的token ID
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    // 儲存每個token id(NFT)的score
    mapping(uint256 => uint256) private _scores;

    event ScoreChanged(uint256 indexed tokenId, uint256 newScore);

    constructor() ERC721("DynamicNFT", "DNFT") {}

    // mint new NFT
    function mint(address recipient) public returns (uint256) {
        _tokenIds.increment(); //ID +=1
        uint256 newTokenId = _tokenIds.current(); // 取得當前ID從1開始
        _safeMint(recipient, newTokenId); //檢查接收地址是否為合約地址
        _scores[newTokenId] = 0; // start from 0
        return newTokenId;
    }

    // 分數變更
    function increaseScore(uint256 tokenId, uint256 amount) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        _scores[tokenId] += amount;
        emit ScoreChanged(tokenId, _scores[tokenId]);
    }

    function decreaseScore(uint256 tokenId, uint256 amount) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(_scores[tokenId] >= amount, "Score cannot be negative");
        _scores[tokenId] -= amount;
        emit ScoreChanged(tokenId, _scores[tokenId]);
    }

    function getScore(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _scores[tokenId];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    // NFT level ?
    function getAttributes(
        uint256 tokenId
    ) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        uint256 score = _scores[tokenId];
        if (score < 100) {
            return "Bronze";
        } else if (score < 200) {
            return "Silver";
        } else {
            return "Gold";
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 score = _scores[tokenId];
        string memory attribute = getAttributes(tokenId);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Dynamic NFT #',
                        tokenId.toString(),
                        ' "description": "A dynamic NFT with changing attributes", ',
                        '"attributes": [',
                        '{"trait_type": "Score", "value":',
                        score.toString(),
                        "}, ",
                        '{"trait_type": "Level", "value":"',
                        attribute,
                        '"}',
                        "]}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
