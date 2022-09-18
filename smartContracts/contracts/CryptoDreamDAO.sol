//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
    function getPrice() external view returns (uint);

    function available(uint _tokenId) external view returns (bool);

    function purchase(uint _tokenId) external payable;
}

interface ICryptoDreamers {
    function balanceOf(address owner) external view returns (uint);

    function tokenOfOwnerByIndex(address owner, uint index)
        external
        view
        returns (uint);
}

contract CryptoDreamDAO is Ownable {
    struct Proposal {
        uint nftTokenId;
        uint deadline;
        uint yayVotes;
        uint nayVotes;
        bool executed;
        mapping(uint => bool) voters;
    }

    mapping(uint => Proposal) public proposals;

    uint public numProposals;

    IFakeNFTMarketplace nftMarketplace;

    ICryptoDreamers cryptoDreamers;

    constructor(address _nftMarketplace, address _cryptoDreamers) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDreamers = ICryptoDreamers(_cryptoDreamers);
    }

    modifier nftHolderOnly() {
        require(cryptoDreamers.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    function createProposal(uint _nftTokenId)
        external
        nftHolderOnly
        returns (uint)
    {
        require(nftMarketplace.available(_nftTokenId), "NOT_FOR_SALE");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;
        numProposals++;
        return numProposals - 1;
    }

    modifier activeProposalOnly(uint proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    enum Vote {
        YAY,
        NAY
    }

    function voteOnProposal(uint proposalIndex, Vote vote)
        external
        nftHolderOnly
        activeProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];
        uint voterNFTBalance = cryptoDreamers.balanceOf(msg.sender);
        uint numVotes = 0;
        for (uint i = 0; i < voterNFTBalance; i++) {
            uint tokenId = cryptoDreamers.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");
        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    modifier inactiveProposalOnly(uint proposalindex) {
        require(
            proposals[proposalindex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalindex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    function executeProposal(uint proposalIndex)
        external
        nftHolderOnly
        inactiveProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];
        if (proposal.yayVotes > proposal.nayVotes) {
            uint nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}
