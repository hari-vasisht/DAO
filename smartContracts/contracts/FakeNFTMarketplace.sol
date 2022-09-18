// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FakeNFTMarketplace {
    mapping(uint => address) public tokens;
    uint nftPrice = 0.1 ether;

    function purchase(uint _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT costs 0.1 Ether");
        tokens[_tokenId] = msg.sender;
    }

    function getPrice() external view returns (uint) {
        return nftPrice;
    }

    function available(uint _tokenId) external view returns (bool) {
        if (tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }
}
