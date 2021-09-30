// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";


enum ProposalStatus{PENDING, WAITING, APPROVED, REJECTED}

contract TempToken is ERC20 {
    constructor() ERC20("TEMP", "temp") {
        _mint(msg.sender, 1000000);
    }
}

contract ProjectToken is ERC20{
    address owner;
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        owner = msg.sender;
    }
    function mint(address user, uint amount) external {
        require(msg.sender == owner,"Only owner contract can mint");
        _mint(user, amount);
    }
}

contract LearnToken is ERC20 {
    address owner;
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        owner = msg.sender;
    }
    function mint(address user, uint amount) external {
        require(msg.sender == owner,"Only owner contract can mint");
        _mint(user, amount);
    }
}

struct ChangePolicyProposal {
    string newContent;
    address proposer;
    ProposalStatus status;
    int votes;
    uint votingCapacity;
    uint proposedInBlock;
}

struct GrantProposal {
    string title;
    string proposedContent;
    string finalContent;
    address proposer;
    uint amount;
    ProposalStatus status;
    int votesForEscrowing;
    int votesForLiquidating;
    uint votingCapacity;
    uint proposedInBlock;
    uint deadlineTimestamp;
    address tokenAddress;
}

struct ChangeMemberProposal {
    address user;
    string description;
    address proposer;
    ProposalStatus status;
    uint amount;
    int votes;
    uint votingCapacity;
    uint proposedInBlock;
}

struct SpendProposal {
    address projectTokenAddress;
    address proposer;
    uint amount;
    address receiver;
    ProposalStatus status;
    int votes;
    uint votingCapacity;
    uint proposedInBlock;
}

contract LearnDaoManager {
    //broken into 2 contracts because eip170
    address _baseTokenAddress;
    ERC20 baseToken;
    LearnToken learnToken;
    string name;
    string symbol;
    uint availableFunds; //learn tokens
    uint votingCapacity;
    mapping(address => uint) memberVotes;
    address owner;

    mapping(bytes32 => bool) voteCasted;

    uint memberProposalsCounter;
    mapping(uint => ChangeMemberProposal) memberProposals;
    
    string policy;
    uint policyProposalCounter;
    mapping(uint => ChangePolicyProposal) policyProposals;

    function requireVoteNotCasted(address voter, string memory category, uint proposalId) public view {
        require(voteCasted[keccak256(abi.encodePacked(voter, category, proposalId))], "Vote already casted");
    }

    function random() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(address(this)))) % 1000;
    }

    // wrappableTokenAddress - the dao can accept funding in exactly 1 erc20 token
    constructor(address admin, address wrappableTokenAddress) {
        owner = msg.sender;
        _baseTokenAddress = wrappableTokenAddress;
        baseToken = ERC20(wrappableTokenAddress);
        uint suffix = random();
        symbol = string(abi.encodePacked("LEARN-",baseToken.symbol(), "-",uintToString(suffix)));
        name = string(abi.encodePacked("Learn ",baseToken.name(), "(",uintToString(suffix),")"));
        votingCapacity = 100;
        memberVotes[admin] = 100;
        learnToken = new LearnToken(name, symbol);
    }

        function fund(uint amount) external {
        baseToken.transferFrom(msg.sender, address(this), amount);
        uint amountToTransfer = amount; // todo: change based on AMM (availableFunds)
        availableFunds+=amountToTransfer;
        learnToken.mint(address(this), amountToTransfer);
    }

    function redeem(uint amount) external {
        uint amountToTransfer = amount; // todo: change based on AMM (availableFunds)
        learnToken.transferFrom(msg.sender, address(0), amount);
        baseToken.transfer(msg.sender, amountToTransfer);
        availableFunds -= amount;
    }

    function getFunds() public view returns(uint){
        console.log("Hello world");
        return availableFunds;
    }


        function getPolicy() external view returns(string memory) {
        return policy;
    }

    function proposePolicy(string memory newPolicy) external returns(uint){
        policyProposals[policyProposalCounter++] = ChangePolicyProposal({
            status: ProposalStatus.PENDING,
            newContent: newPolicy,
            proposer: msg.sender,
            votes: 0,
            votingCapacity: votingCapacity,
            proposedInBlock: block.number
        });
        return policyProposalCounter;
    }

    function getPolicyProposalsCount() external view returns(uint){
        return policyProposalCounter;
    }

    function getPolicyProposalAtIndex(uint i) external view returns(string memory, ProposalStatus, address, int, uint, uint){
        return (policyProposals[i].newContent, policyProposals[i].status, policyProposals[i].proposer,policyProposals[i].votes, policyProposals[i].votingCapacity, policyProposals[i].proposedInBlock );
    }

    function voteOnPolicyChange(uint index, bool isSupporting) external {
        requireVoteNotCasted(msg.sender, "POLICY", index);
        int votes = int(memberVotes[msg.sender]);
        if(!isSupporting)
            votes *= -1;
        policyProposals[index].votes += votes;
    }

    function executePolicyChange(uint index) external {
        uint MIN_BLOCKS = 1;
        uint MAX_BLOCKS = 1000;
        ChangePolicyProposal memory proposal = policyProposals[index];
        require(proposal.votes > 0 && proposal.votes > int(proposal.votingCapacity/2), "No consensus");
        require(block.number > proposal.proposedInBlock + MIN_BLOCKS, "Voting hasn't ended yet"); 
        require(block.number < proposal.proposedInBlock + MAX_BLOCKS, "Execution date passed");
        policy = proposal.newContent;
        policyProposals[index].status = ProposalStatus.APPROVED;
    }

    function proposeMemberChange(address user, string memory description, uint amount) external returns(uint){
        memberProposals[memberProposalsCounter++] = ChangeMemberProposal({
            user: user,
            description: description, 
            amount: amount, 
            proposer: msg.sender,
            proposedInBlock: block.number,
            votes: 0,
            status: ProposalStatus.PENDING,
            votingCapacity: votingCapacity
        });
        return memberProposalsCounter;
    }

    function getChangeMemberProposalsCounter() public view returns(uint){
        return memberProposalsCounter;
    }

    function getChangeMemberProposalsByIndex(uint index) public view returns(address, uint, string memory, address, int, uint, uint) {
        ChangeMemberProposal memory proposal = memberProposals[index];
        return (proposal.user, proposal.amount, proposal.description, proposal.proposer, proposal.votes, proposal.votingCapacity, proposal.proposedInBlock);
    }

    function voteOnChangeMember(uint index, bool isSupporting) external {
        requireVoteNotCasted(msg.sender, "MEMBER", index);
        int votes = int(memberVotes[msg.sender]);
        if(!isSupporting)
            votes *= -1;
        policyProposals[index].votes += votes;
    }

    function executeChangeMember(uint index) external {
        uint MIN_BLOCKS = 1;
        uint MAX_BLOCKS = 1000;
        ChangeMemberProposal memory proposal = memberProposals[index];
        require(proposal.votes > 0 && proposal.votes > int(proposal.votingCapacity/2), "No consensus");
        require(block.number > proposal.proposedInBlock + MIN_BLOCKS, "Voting hasn't ended yet"); 
        require(block.number < proposal.proposedInBlock + MAX_BLOCKS, "Execution date passed");
        memberProposals[index].status = ProposalStatus.APPROVED;
        memberVotes[proposal.user] = proposal.amount;
    }

    function getSymbol() public view returns(string memory){
        console.log(symbol);
        return symbol;
    } 

    function getVotingCapacity() external view returns(uint){
        return votingCapacity;
    }

    function getMemberVotes(address user) external view returns(uint) {
        return memberVotes[user];
    }
    
    function escrow(uint amount) external {
        require(msg.sender == owner, "Escrowing must be done from the DAO");
        require(amount > availableFunds, "Not enough learn tokens to escrow");
        availableFunds -= amount;
    }

    function unescrow(uint amount) external {
        require(msg.sender == owner, "UnEscrowing must be done from the DAO");
        availableFunds += amount;
    }

    function transferLearnTokens(address to, uint amount) external{
        require(msg.sender == owner, "Trasfer must be done from the DAO");
        learnToken.transfer(to, amount);
    }

    function getLearnTokenAddress() external view returns(address){
        return address(learnToken);
    }

}

contract LearnDao{

    LearnDaoManager manager;
    constructor(address tokenAddress) {
        manager = new LearnDaoManager(msg.sender, tokenAddress);
    }

    function getManager() public view returns(address){
        return address(manager);
    }
   

    uint grantProposalCounter;
    mapping(uint => GrantProposal) grantProposals;

    uint spendProposalsCounter;
    mapping(uint => SpendProposal) spendProposals;

    function proposeGrant(string memory title, string memory proposedContent, uint amount, uint deadlineTimestampInEpoch) external returns(uint grantProposalsCounter){
        grantProposals[grantProposalsCounter++] = GrantProposal({
            title: title, 
            proposedContent: proposedContent,
            finalContent: "",
            amount: amount,
            proposer: msg.sender,
            status: ProposalStatus.PENDING,
            votesForEscrowing : 0, 
            votesForLiquidating: 0, 
            votingCapacity: manager.getVotingCapacity(),
            proposedInBlock: block.number,
            deadlineTimestamp: deadlineTimestampInEpoch,
            tokenAddress: address(0)
        });


    }

    function proposeFinalContent(uint index, string memory finalContent) external {
        require(grantProposals[index].proposer == msg.sender, "Only proposer can submit final");
        grantProposals[index].finalContent = finalContent;
    }

    function getGrantProposalCounter() external view returns(uint){
        return grantProposalCounter;
    }

    function getGrantProposalAtIndex(uint index) external view returns (string memory, string memory, string memory, address, address, ProposalStatus, int, int, uint, uint) {
        GrantProposal memory proposal = grantProposals[index];
        return (proposal.title, proposal.proposedContent, proposal.finalContent, proposal.proposer, proposal.tokenAddress, proposal.status, proposal.votesForEscrowing, proposal.votesForLiquidating, proposal.votingCapacity, proposal.proposedInBlock);
    }

    function voteOnGrantEscrow(uint index, bool isSupporting) external {
        manager.requireVoteNotCasted(msg.sender, "ESCROW", index);
        int votes = int(manager.getMemberVotes(msg.sender));
        if(!isSupporting)
            votes *= -1;
        grantProposals[index].votesForEscrowing += votes;
    }

    function executeEscrow(uint index) public {
        GrantProposal memory proposal = grantProposals[index];
        require(proposal.votesForEscrowing > 0 && proposal.votesForEscrowing > int(proposal.votingCapacity / 2), "No consensus");
        
        grantProposals[index].status = ProposalStatus.WAITING;
        
        manager.escrow(proposal.amount);
        string memory tokenName = string(abi.encodePacked(manager.getSymbol(),"-", uintToString(manager.random())));
        ProjectToken projectToken = new ProjectToken(tokenName, tokenName);
        projectToken.mint(proposal.proposer, 100000);
        grantProposals[index].tokenAddress = address(projectToken);
    }

    function voteOnGrantLiquidating(uint index, bool isSupporting) external {
        manager.requireVoteNotCasted(msg.sender, "LIQUIDATE", index);
        require(block.timestamp > grantProposals[index].deadlineTimestamp, "Deadline awaited");
        int votes = int(manager.getMemberVotes(msg.sender));
        if(!isSupporting)
            votes *= -1;
        grantProposals[index].votesForLiquidating += votes;
    }

    uint MIN_TIME = 1;
    uint MAX_TIME = 1000;

    function executeLiquidation(uint index) public {
        require(block.timestamp > grantProposals[index].deadlineTimestamp + MIN_TIME, "Voting not started");
        require(block.timestamp < grantProposals[index].deadlineTimestamp + MAX_TIME, "Voting ended");
        GrantProposal memory proposal = grantProposals[index];
        if(proposal.votesForLiquidating > int(proposal.votingCapacity / 2)) {
            grantProposals[index].status = ProposalStatus.APPROVED;
        }
        else {
            grantProposals[index].status = ProposalStatus.REJECTED;
            manager.unescrow(proposal.amount);
        }
    }
    bool reentrancySemaphore = false;
    function claim(uint index, uint amount) public {
        require(!reentrancySemaphore, "Locked");
        reentrancySemaphore = true;
        GrantProposal memory proposal = grantProposals[index];
        require(block.timestamp > grantProposals[index].deadlineTimestamp + MAX_TIME, "Voting not yet ended");
        require(proposal.status == ProposalStatus.APPROVED, "Proposal not approved");
        ERC20 projectToken = ERC20(proposal.tokenAddress);
        projectToken.transferFrom(msg.sender, address(this), amount);
        //learnToken.transfer(msg.sender, ((amount * 1e18) / (proposal.amount * 100000)));
        manager.transferLearnTokens(msg.sender, ((amount * 1e18) / (proposal.amount * 100000)));
        reentrancySemaphore = false;
    }



    function proposeSpend(address projectTokenAddress, address to, uint amount ) external returns(uint){
        spendProposals[spendProposalsCounter ++ ] = SpendProposal({
            projectTokenAddress: projectTokenAddress,
            receiver: to,
            amount: amount,
            proposer: msg.sender,
            proposedInBlock: block.number,
            votes: 0,
            votingCapacity: manager.getVotingCapacity(),
            status: ProposalStatus.PENDING
        });
        return spendProposalsCounter;
    }

    function getSpendProposalsCounter() public view returns(uint){
        return spendProposalsCounter;
    }

    function getSpendProposalsByIndex(uint index) public view returns(address, uint, address, int, uint, uint) {
        SpendProposal memory proposal = spendProposals[index];
        return (proposal.receiver, proposal.amount, proposal.proposer, proposal.votes, proposal.votingCapacity, proposal.proposedInBlock);
    }

    function voteOnSpend(uint index, bool isSupporting) external {
        int votes = int(manager.getMemberVotes(msg.sender));
        if(!isSupporting)
            votes *= -1;
        spendProposals[index].votes += votes;
    }

    function executeSpend(uint index) external {
        uint MIN_BLOCKS = 1;
        uint MAX_BLOCKS = 1000;
        SpendProposal memory proposal = spendProposals[index];
        require(proposal.votes > 0 && proposal.votes > int(proposal.votingCapacity/2), "No consensus");
        require(block.number > proposal.proposedInBlock + MIN_BLOCKS, "Voting hasn't ended yet"); 
        require(block.number < proposal.proposedInBlock + MAX_BLOCKS, "Execution date passed");
        spendProposals[index].status = ProposalStatus.APPROVED;
        ERC20 projectToken = ERC20(proposal.projectTokenAddress);
        projectToken.transfer(proposal.receiver, proposal.amount);
    }
}


function uintToString(uint256 value) pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }