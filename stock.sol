// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/token/ERC1155/ERC1155.sol";

struct issueProposal {
    uint approvedAmount;
    uint tokenAmount;
}

struct redeemProposal {
    uint approvedAmount;
    uint tokenAmount;
}

struct reissueProposal {
    uint approvedAmount;
    uint tokenAmount;
}


contract Stock is ERC1155 {

    mapping(address => mapping(uint => bool)) public isVotedIssue;
    mapping(address => mapping(uint => bool)) public isVotedReissue;
    mapping(address => mapping(uint => bool)) public isVotedRedeem;
    mapping(address => bool) public isBoardMember;
    mapping(uint => issueProposal) public issueProposals;
    mapping(uint => redeemProposal) public redeemProposals;
    mapping(uint => reissueProposal) public reissueProposals;
    uint boardMemberNum = 0;
    address root;
    uint proposalAmount = 0;
    
    constructor() public
    ERC1155("https://raw.githubusercontent.com/fywang0327/SampleERC1155/9b703c566f51a4f45687f42ada09af5cf78ab3de/{id}.json") 
    {
        root = msg.sender;
    }

    function getBoardMemberNum() external view returns (uint) {
        return boardMemberNum;
    }

    function getProposalAmount() external view returns (uint) {
        return proposalAmount;
    }

    modifier onlyRoot() {
        require(root == msg.sender, "Caller is not the root");
        _;
    }

    modifier onlyBoardMember() {
        require(isBoardMember[msg.sender], "Caller is not the boardMember");
        _;
    }

    function addBoardMembers(address member) external onlyRoot {
        isBoardMember[member] = true;
        boardMemberNum++;
    }

    function removeBoardMembers(address member) external onlyRoot {
        isBoardMember[member] = false;
        boardMemberNum--;
    }

    // issue
    function issue(uint tokenAmount) external onlyBoardMember returns (uint) {
        issueProposals[proposalAmount] = issueProposal(0, tokenAmount);
        return proposalAmount++;
    }

    function issueApprove(uint proposalID) external onlyBoardMember {
        require(!isVotedIssue[msg.sender][proposalID], "You have voted!");
        isVotedIssue[msg.sender][proposalID] = true;
        issueProposals[proposalID].approvedAmount += 1;
        if (issueProposals[proposalID].approvedAmount == boardMemberNum) {
            _mint(msg.sender, proposalID, issueProposals[proposalID].tokenAmount, "");
        }
    }

    // reissue
    function reissue(uint proposalID, uint tokenAmount) external onlyBoardMember returns (uint) {
        reissueProposals[proposalID] = reissueProposal(0, tokenAmount);
        return proposalID;
    }

    function reissueApprove(uint proposalID) external onlyBoardMember {
        require(!isVotedReissue[msg.sender][proposalID], "You have voted!");
        isVotedReissue[msg.sender][proposalID] = true;
        reissueProposals[proposalID].approvedAmount += 1;
        if (reissueProposals[proposalID].approvedAmount == boardMemberNum) {
            _burn(msg.sender, proposalID, issueProposals[proposalID].tokenAmount);
            _mint(msg.sender, proposalID, reissueProposals[proposalID].tokenAmount, "");
            issueProposals[proposalID].tokenAmount = reissueProposals[proposalID].tokenAmount;
        }
    }

    // redeem
    function redeem(uint proposalID, uint tokenAmount) external onlyBoardMember returns (uint) {
        redeemProposals[proposalID] = redeemProposal(0, tokenAmount);
        return proposalID;
    }

    function redeemApprove(uint proposalID) external onlyBoardMember {
        require(!isVotedRedeem[msg.sender][proposalID], "You have voted!");
        isVotedRedeem[msg.sender][proposalID] = true;
        redeemProposals[proposalID].approvedAmount += 1;
        if (redeemProposals[proposalID].approvedAmount == boardMemberNum) {
            _burn(msg.sender, proposalID, redeemProposals[proposalID].tokenAmount);
            issueProposals[proposalID].tokenAmount -= redeemProposals[proposalID].tokenAmount;
        }
    }
}
