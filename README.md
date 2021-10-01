# LearnDAO specification

A DAO to facilitate the process of making decisions on which grants to accept.

This DAO has been designed with Learning/Education related Grants in mind, however the semantics are more widely applicable. 

Below are the key elements in this DAO

## No Coin Based Voting
Tradable token based voting are prone to attacks.
An attacker may borrow the said governance token from defi projects like Compound by depositing ETH, cast malicious votes and return the governance tokens to get their ETH back. Thereby, altering decision making of the DAO without any financial exposure. 

Governors in the LearnDAO are voted in or voted out. Each Governor is also assigned a weight to their vote. Not all votes are equal. 

### Proposals
There are 4 kinds of proposals 
- Add, remove or modify governor
  - e.g. GovernorProposal(address=madhavanmalolan.eth, weight=25)
- Update DAO policy. Policy defines the rules the governors must use to evaluate proposals.
  - e.g. PolicyProposal(newPolicy=https://link.com/hash123123)
- Spend Treasury. The treasury might have various ERC20 tokens that can be transferred out.
  - e.g. SpendProposal(token=dai.eth, to=madhavanmalolan.eth, value=100)
- Grant proposals are 2 phase voting processes defined later in this doc

### Execution
Proposal votings are open for a duration of 7 days. 
After 7 days, anyone can execute the proposal, if the proposal has 51% votes. 
Each of the proposal types in the above section can be executed to make the proposals effect on-chain. 

## Wrapped Tokens And Treasury
The DAO treasury is maintained in a Wrapped Currency. To fund this DAO, one may deposit - say - DAI into the DAO and convert it into LEARN-DAI. 

This forces the grants to ear-mark education funds. The presence of funds that have been earmarked for a particular use will attract more members to come and compete to win the grant. 

### AMM
All payouts to the grants are made in the wrapped token. These tokens can be converted back by unwrapping. 
However, the cost of conversion between a wrapped token and base token keeps increasing. 

The early grantees who hold on to the wrapped token, can unwrap at a much higher price - and get back more base tokens.

The cost itself follows a Bancour's curve (todo).

## 2 Phase Grant Proposals
Every proposal goes through two rounds of voting. 

### Escrow
When a proposal is made, it is open to voting for 7 days. 
A proposal consists of 
- The promised outcome
- Date of delivery
- Amount in wrapped token requested

If 51% of the governor votes are in favour of the motion, the amount of wrapped token is frozen into an escrow. That way, the potential-grantee knows that the money has been set aside for them - if they deliver.

### Liquidation
Once the Date of delivery of the proposal has passed another 7 day voting starts.
If there is 51% consensus that the promised outcome was delivered by the proposer, the escrow is liquidated and the grantee can claim those rewards. 


## Project Tokens (Retrofunding)
When the first phase of the Grant is passed, 100K project tokens are minted. 
All these 100K tokens are transferred to the proposer. The proposer may choose to distribute those tokens among the team members  and contributors. This mechanism will align the incentives of the contributors to work towards accomplishing the promise in the proposal.

If the proposal's phase two has been approved and the escrow has been liquidated, the contributors can claim the wrapped token by giving the project tokens to the DAO. The number of wrapped token claimable is proportional to the number of project tokens produced. 

The DAO holds the project tokens in it's treasury and can spend it subject to a standard voting.

# Installation
The LearnDAO `contract` is ready to be deployed on to testnet/mainnet/polygon/optimism.

The `app` acts as the UI to carry out the operations in the contract, however all the operations can be done using _Etherscan contract write_ or [ethcontract.app](https://ethcontract.app). There is no backend code - only UI and Contract. 




