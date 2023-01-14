// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";

contract MyGov is ERC20{ // The governance token is named as "MyGov".

    constructor(uint tokensupply) ERC20("MyGov", "MGT") {   // ERC2O token contract is implemented to our contract, the symbol of the new token is declared as "MGV".
        tokensupply = 10**7;                                // MyGov token supply is fixed at 10 million.
        _mint(address(this), tokensupply);                  // 10 million tokens are minted into the address of the contract.
    }

    uint reservedAmount = 0;   // This variable defines the total reserved money by the successful project proposals.
    uint memberCount = 0;      // This variable defines the total member number.
    uint surveyCount = 0;      // This variable defines the total survey number.
    uint proposalCount = 0;    // This variable defines the total proposal number.
    address[] memberAddresses;    // This array holds the member addresses.

    struct Individuals{                                         // This struct defines the following informations about the addresses:
        bool receivedFaucet;                                    // - Whether the address received faucet from the contract or not,
        mapping(uint => mapping(uint => uint)) voteWeight;      // - The vote weights (the first index is project id, the second index is payment period),
        mapping(uint => mapping(uint => bool)) isVoted;         // - Whether the address has already voted or not (the first index is project id, the second index is payment period),
        mapping(uint => mapping(uint => bool)) votes;           // - The votes given (the first index is project id, the second index is payment period),
        mapping(uint => mapping(uint => uint)) delegatedVotes;
        mapping(uint => bool) tookSurvey;                                      // - Whether the address has already took the surveys or not (the index is survey id),
        uint restrictionDeadline;                               // - The deadline until when the individual cannot reduce his/her balance to zero.
    }

    mapping(address => Individuals) public individuals;   // This mapping declares a state variable that stores a `Individuals` struct for each possible address.

    struct Proposal{          // This struct defines the following informations about the proposals:
        address owner;        // - The address of the project owner,
        uint id;              // - The unique id of the project,
        string context;       // - The project context,
        uint deadline;        // - The deadline for members to vote for the project proposal,
        uint[] payments;      // - The payment amounts needed for the project proposal (the index is payment period + 1),
        uint[] schedule;      // - The payment dates of the payment amounts above (the index is payment period + 1),
        uint paymentPeriod;   // - The current payment period (equals to 0 if the proposal cannot get 10% votes),
        uint[] voteCount;     // - The amount of votes equal to "true" (the index is payment period),
        bool isReserved;      // - Whether the total payment amount is reserved or not,
        uint fundBalance;     // - The amount of ether received by the project.
    }

    struct Survey {              // This struct defines the following informations about the surveys:
        address owner;           // - The address of the survey owner,
        uint id;                 // - The unique id of the survey,
        string context;          // - The survey context,
        uint deadline;           // - The deadline for members to take the survey,
        uint choiceNum;          // - The number of choices given in the survey,
        uint allowedChoiceNum;   // - Max. number of choices that one participant can choose,
        uint[] result;           // - The results of the survey,
        uint participantCount;   // - The number of members that took the survey.
    }

    Proposal[] public proposals;   // An struct array is initalized which stores the submitted project proposals.
    Survey[] public surveys;       // An struct array is initalized which stores the submitted surveys.

    //    function test() public returns(bool){
//        bool sonuc;
//        if(!(test_map[45]>0)){sonuc = true;}
//        else{sonuc = false;}
//        return sonuc;
//
//    }
    function getWeight(address member , uint projectid, uint period) public view returns(uint){
        return individuals[member].delegatedVotes[projectid][period]+1;
    }
//    function getPeriod(uint projectid) public returns(uint){
//        return proposals[projectid].paymentPeriod;
//    }
    function getVoted(address member , uint projectid , uint period) public view returns(bool){
        return individuals[member].isVoted[projectid][period];
    }
    function getVoteCount(uint projectid) public view returns(uint[] memory){
        return proposals[projectid].voteCount;
    }
//
    function getReservedAmount() public view returns(uint){
        return reservedAmount;
    }
//
//    function getPayments(uint projectid) public returns(uint[] memory){
//        return proposals[projectid].schedule;
//    }
//
//    function getIsReserved(uint projectid) public returns(bool){
//        return proposals[projectid].isReserved;
//    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {   // The transfer function of the ERC20 contract is overridden for the membership conditions.
        if(block.timestamp < individuals[_msgSender()].restrictionDeadline &&               // If msg.sender has voted or delegated for a proposal, he/she cannot reduce his/her balance
        (balanceOf(_msgSender()) - amount <= 0)){                                           // to zero until the voting deadline of that proposal (transaction resctriction).
            revert();
        }
        _transfer(_msgSender(), recipient, amount);           // This line is not changed.
        if(balanceOf(recipient) - amount == 0){               // If the recipient address has zero balance before the current transfer,
            memberCount++;                                    // the member number is incremented by one and
            memberAddresses.push(recipient);                  // the recipient address is added into the array that holds the member addresses.
        }
        if(balanceOf(_msgSender()) == 0){                     // If msg.sender has zero balance after the current transfer,
            memberCount--;                                    // the member number is reduced by one and
            for(uint i=0; i < memberAddresses.length; i++){
                if(memberAddresses[i] == _msgSender()){
                    delete memberAddresses[i];                // msg.sender is changed with the zero address in the array that holds the member addresses.
                    break;
                }
            }
        }
        return true;
    }

    function faucet() public{                                     // This function makes it possible for all individuals to receive faucet from the contract.
        require(individuals[msg.sender].receivedFaucet != true,   // If the msg.sender already received faucet from the contract, he/she cannot take more.
        "You have already received free tokens.");
        require(balanceOf(address(this)) - 1 >= 0,                // If "MyGov" balance of the contract goes below zero after the current give away, the operation is not allowed.
        "There is no free tokens left.");
        _transfer(address(this),msg.sender, 1);                   // msg.sender receives 1 MyGov from contract if there is no problem with the requirements above.
        individuals[msg.sender].receivedFaucet = true;            // The operation is stored in the individual's struct, so that he/she becomes unable to take more token with "faucet" function.
        if(balanceOf(msg.sender) - 1 == 0){                       // If msg.sender has zero balance before the current transfer,
            memberCount++;                                        // the member count is incremented by one and
            memberAddresses.push(msg.sender);                     // msg.sender is added into the "memberAddresses" array.
        }

    }

    function donateEther() public payable{   // This function makes it possible for anyone to donate Ether // to the contract address.
    }

    function donateMyGovToken(uint amount) public{   // This function makes it possible for anyone to donate MyGov tokens
        transfer(address(this), amount);             // to the contract address.
    }

    function submitProjectProposal(string memory ipfshash, uint votedeadline, uint [] memory   // This function makes it possible for the members to submit a project proposal. The member gives
     paymentamounts,uint [] memory payschedule) public payable returns (uint projectid){       // information to the function about the proposal and the function returns the id of the submitted proposal.
        require(balanceOf(msg.sender) > 5, "You don't have enough MGT.");                      // To submit a survey, msg.sender must have a balance greater than 0 (membership requirement). In addition,
        require(msg.value >= 10**17, "You don't have enough ethers.");                         // he/she must be able to afford the submit cost which is equal to 5 MyGov tokens + 0.1 ether.
        transfer(address(this), 5);                                                            // The submit cost of the survey is transferred from msg.sender to the address of the contract.
        projectid = proposalCount;                              // For the project id algorithm, consecutive integers are used. Every new project has a id greater than the id of the previous project by one.
        proposalCount++;                                        // "proposalCount" variable which holds the total number of submitted proposals incremented by one if there is no problem with the requirements above.
        proposals.push(Proposal({                               // A new "Proposal" struct with the following conditions is added to the "proposals" array:
            owner: msg.sender,                                  // The address of the project owner is msg.sender.
            id: projectid,                                      // The id of the project is initalized to the "projectid" variable which is equal to the total number of submitted proposals.
            context : ipfshash,                                 // The context of the proposal (in IPSF hash) is the input "ipfshash".
            deadline : votedeadline,                            // The deadline of the proposal is the input "votedeadline".
            payments : paymentamounts,                          // The payment amounts needed for the project proposal are given in the input array "paymentamounts".
            schedule : payschedule,                             // The payment dates of the payment amounts above are given in the input array "payschedule".
            paymentPeriod : 0,                                  // The current payment period is initalized to 0.
            voteCount : new uint[](paymentamounts.length + 1),  // The array that holds the amount of the votes is an empty array with the length greater than the input array "paymentamounts" by 1.
            isReserved : false,                                 // The reserving situation of the proposal is initalized to "false".
            fundBalance : 0                                     // The amount of ether received by the project is initalized to 0.
            }));
        return projectid;
    }

    function reserveProjectGrant(uint projectid) public{                  // This function makes it possible for project owners to reserve the total payments of the project proposals.
        uint totalpayment= 0;                                             // An integer named "totalpayment" is initialized at 0.
        for(uint i=0; i < (proposals[projectid].payments).length; i++){   // By a for loop, the payment amounts of the proposal is added cumulatively and
            totalpayment += proposals[projectid].payments[i];             // stored in the "totalpayment".
        }
        require(address(this).balance - reservedAmount >= totalpayment,   // If there is not sufficient ether in the contract,
        "There is not sufficient ether in the contract, your funding is lost.");
        require(block.timestamp < proposals[projectid].deadline,          // msg.sender did not reserve the funding by the proposal deadline,
        "The deadline is over, your funding is lost.");
        require(proposals[projectid].voteCount[0] != 0 &&                 // nobody has voted "true" yet, or
        proposals[projectid].voteCount[0] >= memberCount/10,              // 10% of the members did not vote "true" for the proposal, the funding is lost.
        "There is not enough votes, your funding is lost.");
        reservedAmount += totalpayment;                                   // The total payment of the proposal is added to the global "reservedAmount" varible if there is no problem with the requirements above.
        proposals[projectid].isReserved = true;                           // The operation is stored in the proposal's struct, so that the reserving situation of the proposal is stored for the next operations.
        proposals[projectid].paymentPeriod++;                             // The payment period of the proposal is increased to 1, so that payment votings can start.
    }

    function delegateVoteTo(address memberaddr,uint projectid) public {          // This function makes it possible for the members to delegate their vote to another address.
        uint period = proposals[projectid].paymentPeriod;                        // An integer equals to the current payment period of the given project is initialized.
        require(balanceOf(msg.sender) > 0,                                       // To delegate vote for a project proposal, msg.sender must have a balance greater than 0 (membership requirement).
        "Only members can delegate vote.");
        if(period == 0){
            require(block.timestamp < proposals[projectid].deadline,             // The operation must be done before the voting deadline of the proposal or
            "The deadline is over, you cannot delegate vote anymore.");
        } else{
            require(block.timestamp < proposals[projectid].schedule[period-1],   // the next payment date.
            "The deadline is over, you cannot delegate vote anymore.");
        }
        require(individuals[msg.sender].isVoted[projectid][period] != true,      // he/she must not have been already voted for the proposal with the given "projectid".
        "You have already voted for this voting.");
        require(memberaddr != msg.sender,                                        // In addition, the recipient address must be different from msg.sender.
        "Self-delegation is not allowed.");                                      // If there is no problem with the requirements above, there are 4 conditions which will be checked.
        if(!(individuals[memberaddr].delegatedVotes[projectid][period] > 0) &&         // 1) If both msg.sender and the recipient address were not delegated votes before, and
         !(individuals[msg.sender].delegatedVotes[projectid][period] > 0)){
            if (individuals[memberaddr].isVoted[projectid][period]){
                if (individuals[memberaddr].votes[projectid][period] == true)          // the recipient address has already voted "true",
                    proposals[projectid].voteCount[period] += 1;                       // the vote count of the proposal or the payment is incremented by one.
            }
            else{                                                                      // If the recipient address has not voted yet,
                individuals[memberaddr].delegatedVotes[projectid][period] = 1;         // his/her delegatedVotes is initalized to 1.
            }
        }
        else if(individuals[memberaddr].delegatedVotes[projectid][period] > 0 &&       // 2) If the recipient address was delegated votes before but msg.sender was not, and
         !(individuals[msg.sender].delegatedVotes[projectid][period] > 0)){
            if (individuals[memberaddr].isVoted[projectid][period]){
                if(individuals[memberaddr].votes[projectid][period] == true)           // the recipient address has already voted "true",
                proposals[projectid].voteCount[period] += 1;                           // the vote count of the proposal or the payment is incremented by one.
            }
            else{                                                                      // If the recipient address has not voted yet,
                individuals[memberaddr].delegatedVotes[projectid][period] += 1;        // his/her delegatedVotes is incremented by one.
                }
        }
        else if(!(individuals[memberaddr].delegatedVotes[projectid][period] > 0) &&    // 3) If msg.sender was delegated votes before but the recipient address was not, and
         individuals[msg.sender].delegatedVotes[projectid][period] > 0){
            if (individuals[memberaddr].isVoted[projectid][period]){
                if(individuals[memberaddr].votes[projectid][period] == true)           // the recipient address has already voted "true",
                   proposals[projectid].voteCount[period] +=
                   individuals[msg.sender].delegatedVotes[projectid][period] + 1;      // the vote count of the proposal or the payment is incremented by msg.sender's delegated votes + 1.
                }
            else{                                                                      // If the recipient address has not voted yet,
                individuals[memberaddr].delegatedVotes[projectid][period] =
                individuals[msg.sender].delegatedVotes[projectid][period] + 1;         // his/her delegatedVotes is initalized to msg.sender's delegated votes + 1.
               }
        }
        else{                                                                          // 4) If both msg.sender and the recipient address were delegated votes before, and
               if (individuals[memberaddr].isVoted[projectid][period]){
                   if(individuals[memberaddr].votes[projectid][period] == true)        // the recipient address has already voted "true",
                        proposals[projectid].voteCount[period] +=
                        individuals[msg.sender].delegatedVotes[projectid][period] + 1; // the vote count of the proposal or the payment is incremented by msg.sender's delegated votes + 1.
               }
               else{                                                                   // If the recipient address has not voted yet,
                   individuals[memberaddr].delegatedVotes[projectid][period] +=
               individuals[msg.sender].delegatedVotes[projectid][period]+ 1;           // his/her delegatedVotes is incremented by msg.sender's delegated votes + 1.
               }
        }
        individuals[msg.sender].isVoted[projectid][period] = true;                         // The operation is stored in the individual's struct, so that he/she becomes unable to vote or delegate vote again.
        if(proposals[projectid].deadline > individuals[msg.sender].restrictionDeadline){   // The transaction restriction of the member is extended if the voting deadline is later
            individuals[msg.sender].restrictionDeadline = proposals[projectid].deadline;   // than his/her current restriction deadline.
        }
    }

    function voteForProjectProposal(uint projectid, bool choice) public{                  // This function makes it possible for the members to vote for the project proposals.
        uint period = proposals[projectid].paymentPeriod;                                 // An integer equals to the current payment period of the given project is initialized.
        require(balanceOf(msg.sender) > 0,                                                // To vote for a project proposal, msg.sender must have a balance greater than 0 (membership requirement).
        "Only members can vote.");
        require(period == 0 && block.timestamp < proposals[projectid].deadline,           // The vote must be sent before the voting deadline of the proposal.
        "The deadline is over, you cannot vote anymore.");
        require(individuals[msg.sender].isVoted[projectid][period] != true,               // he/she must not have been already voted for the proposal with the given "projectid".
        "You have already voted for this voting.");
        individuals[msg.sender].votes[projectid][period] = choice;                        // The vote of the msg.sender is stored into the "Individuals" struct if there is no problem with the requirements above.
        if(individuals[msg.sender].delegatedVotes[projectid][period] > 0){                // If msg.sender was delegated votes before, and
            if(choice == true){                                                           // his/her vote equals to "true",
            proposals[projectid].voteCount[period] +=
            individuals[msg.sender].delegatedVotes[projectid][period] + 1;                // the vote count of the proposal is incremented by the msg.sender's delegated votes + 1.
            }
        }
        else{                                                                             // Else if msg.sender was not delegated votes before, and
            if(choice == true){                                                           // his/her vote equals to "true",
            proposals[projectid].voteCount[period] += 1;                                  // the vote count of the proposal is incremented by one.
            }
        }
        individuals[msg.sender].voteWeight[projectid][period] = 0;                        // After that, the vote weight of the member for the proposal is reduced to 0, and
        individuals[msg.sender].isVoted[projectid][period] = true;                        // the operation is stored in the individual's struct, so that he/she becomes unable to vote again for the proposal.
        if(proposals[projectid].deadline > individuals[msg.sender].restrictionDeadline){  // The transaction restriction of the member is extended if the voting deadline of the proposal is later
            individuals[msg.sender].restrictionDeadline = proposals[projectid].deadline;  // than his/her current restriction deadline.
        }
    }

    function voteForProjectPayment(uint projectid, bool choice) public{      // This function makes it possible for the members to vote for the project payments.
        uint period = proposals[projectid].paymentPeriod;                    // An integer equals to the current payment period of the given project is initialized.
        require(balanceOf(msg.sender) > 0,                                   // To vote for a project payment, msg.sender must have a balance greater than 0 (membership requirement).
        "Only members can vote.");
        require(proposals[projectid].isReserved,                             // For the members to be able to vote for the payment of a project, the payments of the project must be actively reserved.
        "This project is no longer funded.");
        require(block.timestamp < proposals[projectid].schedule[period-1],   // The vote must be sent before the next payment date.
        "The deadline is over, you cannot vote anymore.");
        require(individuals[msg.sender].isVoted[projectid][period] != true,  // he/she must not have been already voted for the proposal with the given "projectid".
        "You have already voted for this voting.");
        if(individuals[msg.sender].delegatedVotes[projectid][period] > 0){   // If msg.sender was delegated votes before, and
            if(choice == true){                                              // his/her vote equals to "true",
            proposals[projectid].voteCount[period] +=
            individuals[msg.sender].delegatedVotes[projectid][period] + 1;   // the vote count of the proposal is incremented by by the msg.sender's delegated votes + 1.
            }
        }
        else{                                                                // Else if msg.sender was not delegated votes before, and
            if(choice == true){                                              // his/her vote equals to "true",
            proposals[projectid].voteCount[period] += 1;                     // the vote count of the proposal is incremented by one.
            }
        }
        individuals[msg.sender].voteWeight[projectid][period] = 0;           // After that, the vote weight of the member for the proposal is reduced to 0, and
        individuals[msg.sender].isVoted[projectid][period] = true;           // the operation is stored in the individual's struct, so that the member becomes unable to vote again for the payment.
        if(proposals[projectid].schedule[period-1] >
        individuals[msg.sender].restrictionDeadline){                        // The transaction restriction of the member is extended if the planned date of the
            individuals[msg.sender].restrictionDeadline =
            proposals[projectid].schedule[period-1];                         // payment is later than his/her current restriction deadline.
        }
    }

    function withdrawProjectPayment(uint projectid) public{                          // This function makes it possible for project owners to withdraw the next project payment.
        uint period = proposals[projectid].paymentPeriod;                            // An integer equals to the current payment period of the given project is initialized.
        require(proposals[projectid].owner == msg.sender,                            // Only project owners are allowed to call this function.
        "This project does not belong to you.");
        require(proposals[projectid].isReserved,                                     // To withdraw a payment, the payments of the project must be actively reserved.
        "Your project is no longer funded.");
        require(block.timestamp < proposals[projectid].schedule[period-1] + 1 days,  // If 1 day is past over the declared payment date, the project owner is no longer able to withdraw the payment.
        "The deadline is over, your project is no longer funded.");
        uint amount;                                                                 // An integer for the payment amount that the project owner trying to withdraw is initialized.
        if(proposals[projectid].voteCount[period] != 0 &&                            // If the vote count is greater than 0 and
        proposals[projectid].voteCount[period] >= memberCount/100){                  // the vote count for the current payment period is greater than the 1% of the all members,
            amount = proposals[projectid].payments[period-1];                        // the amount is equalized to the amount of current payment period
            payable(proposals[projectid].owner).transfer(amount);                    // and transferred to the project owner's account.
            proposals[projectid].paymentPeriod++;                                    // After the transfer, the next payment period starts.
        } else{                                                                      // If the vote count is not sufficient,
            uint remainingPayment = 0;                                               // an integer named "remainingPayment" equals to 0 is initalized.
            for(uint i=period-1; i < (proposals[projectid].payments).length; i++){   // The remaining payment is calculated through a for loop,
                remainingPayment += proposals[projectid].payments[i];                // and stored in the variable "remainingPayment".
            }
            reservedAmount -= remainingPayment;                                      // Then, this integer is subtracted from the "reservedAmount" of the contract.
            proposals[projectid].isReserved = false;                                 // In conclusion, the payments of the project with given "projectid" is no longer reserved.
        }
        proposals[projectid].fundBalance += amount;

    }

    function getProjectOwner(uint projectid) public view returns(address projectowner){   // This function returns the owner of the project with the given "projectid".
        projectowner = proposals[projectid].owner;                                        // The owner of the project is taken from the struct which is an element of the "proposals" array
        return projectowner;                                                              // and returned.
    }

    function getProjectInfo(uint projectid) public view returns(string memory ipfshash,   // This function returns information about the project with the given "projectid".
    uint votedeadline,uint [] memory paymentamounts, uint [] memory payschedule){
        ipfshash = proposals[projectid].context;                                          // The context of the proposal (in IPFS hash),
        votedeadline = proposals[projectid].deadline;                                     // the deadline for members to vote for the project proposal,
        paymentamounts = proposals[projectid].payments;                                   // the payment amounts needed for the project proposal, and
        payschedule = proposals[projectid].schedule;                                      // the payment dates of the payment amounts above are all taken from the "Proposal" struct with
        return (ipfshash, votedeadline, paymentamounts, payschedule);                     // the given "projectid".
    }

    function getNoOfProjectProposals() public view returns(uint numproposals){   // This function returns the total number of submitted project proposals.
        numproposals = proposals.length;                                         // The total number is taken from length of the "proposals" array which holds the all submitted project proposals.
        return numproposals;
    }

    function getIsProjectFunded(uint projectid) public view returns(bool funded){   // This function returns the information of whether the project with the given "projectid" is funded, or not.
        if(proposals[projectid].fundBalance > 0){                                   // If "Proposal" struct with the given "projectid" has a fund balance greater than 0,
            funded = true;                                                          // the function returns "true".
        } else{                                                                     // Else (the fund balance equals to 0),
            funded = false;                                                         // the function returns "false".
        }
        return funded;
    }

    function getNoOfFundedProjects () public view returns(uint numfunded){   // This function returns the total number of funded projects.
        numfunded = 0;                                                       // The output variable "numfunded" is intialized to zero in the beginning.
        for (uint i=0; i < proposals.length; i++){                           // In the for loop, all submitted project proposals are checked one by one.
            if(getIsProjectFunded(i)){                                       // If "getIsProjectFunded" function returns "true" for the project proposal,
                numfunded++;                                                 // variable "numfunded" is incremented by one.
            }
        }
        return numfunded;
    }

    function getEtherReceivedByProject (uint projectid) public view returns(uint amount){   // This function returns the total amount currently paid to the project with the given "projectid".
        amount = proposals[projectid].fundBalance;                                          // The amount is taken from the the "Proposal" struct with the given "projectid".
        return amount;
    }

    function getProjectNextPayment(uint projectid) public view returns(uint next){   // This function returns the next payment amount that the project with the given "projectid" will be voted for.
        next = proposals[projectid].payments[proposals[projectid].paymentPeriod];    // The amount is taken from the "payments" array inside the "Proposal" struct with the index of the current payment period.
        return next;
    }

    function submitSurvey(string memory ipfshash, uint surveydeadline, uint numchoices,   // This function makes it possible for the members to submit a survey. The member gives information to the function
    uint atmostchoice) public payable returns (uint surveyid){                            // about the survey and the function returns the id of the submitted survey.
        require(balanceOf(msg.sender) > 2, "You don't have enough MGT.");                 // To submit a survey, msg.sender must have a balance greater than 0 (membership requirement). In addition, he/she must
        require(msg.value >= 4*10**16, "You don't have enough ethers.");                  // be able to afford the submit cost which is equal to 2 MyGov tokens + 0.04 ether.
        transfer(address(this), 2);                                                       // The submit cost of the survey is transferred from msg.sender to the address of the contract.
        surveyid = surveyCount;                // For the survey id algorithm, consecutive integers are used. Every new survey has a id greater than the id of the previous survey by one.
        surveyCount++;                         // "surveyCount" variable which holds the total number of submitted surveys incremented by one if there is no problem with the requirements above.
        surveys.push(Survey({                  // A new "Survey" struct with the following conditions is added to the "surveys" array:
            owner : msg.sender,                // The address of the survey owner is msg.sender.
            id: surveyid,                      // The id of the survey is initalized to the "surveyid" variable which is equal to the total number of submitted surveys.
            context : ipfshash,                // The context of the survey (in IPSF hash) is the input "ipfshash".
            deadline : surveydeadline,         // The deadline of the survey is the input "surveydeadline".
            choiceNum : numchoices,            // The number of choices given in the survey is the input "numchoices".
            allowedChoiceNum : atmostchoice,   // Max. number of choices that one participant can choose is the input "atmostchoice".
            result : new uint[](numchoices),   // The result array is an empty array with the length equals to the input "numchoices".
            participantCount : 0               // The participant count is initalized to 0.
        }));
        return surveyid;
    }

    function takeSurvey(uint surveyid, uint [] memory choices) public{   // This function makes it possible for the members to take the survey.
        require(balanceOf(msg.sender) > 0,                               // If the msg.sender has a balance greater than 0, it means that he/she is a member and can take the survey.
        "Only members can take the survey.");
        require(block.timestamp < surveys[surveyid].deadline,            // The member must take the survey before the survey deadline.
        "The deadline is over, you cannot take the survey anymore.");
        require(individuals[msg.sender].tookSurvey[surveyid] != true,    // If the msg.sender already took the survey, he/she cannot take it again.
        "You have already participated.");
        require(choices.length <= surveys[surveyid].allowedChoiceNum,    // If the msg.sender chose more than allowed number of choices, his/her choices are not valid.
        "You chose more than allowed number of choices." );
            for (uint m=0; m < surveys[surveyid].choiceNum; m++){        // The member can take the survey if there is no problem with the requirements above. By nested for loops,
                for (uint n=0; n < choices.length; n++){                 // the choices of the member are stored.
                    if(m == choices[n]){
                        surveys[surveyid].result[m]++;                   // The elements of the "result" array of the "Survey" struct with the given "surveyid" are updated with the
                }                                                        // choices of the member.
            }
        }
        individuals[msg.sender].tookSurvey[surveyid] = true;             // The operation is stored in the individual's struct, so that he/she becomes unable to take the survey again.
        surveys[surveyid].participantCount++;
    }

    function getSurveyOwner(uint surveyid) public view returns(address surveyowner){   // This function returns the owner of the survey with the given "surveyid".
        surveyowner = surveys[surveyid].owner;                                         // The owner of the survey is taken from the struct which is an element of the "surveys" array
        return surveyowner;
    }

    function getSurveyInfo(uint surveyid) public view returns(string memory ipfshash,   // This function returns information about the survey with the given "surveyid".
    uint surveydeadline,uint numchoices, uint atmostchoice){
        ipfshash = surveys[surveyid].context;                                           // The context of the survey (in IPFS hash),
        surveydeadline = surveys[surveyid].deadline;                                    // the deadline of the survey,
        numchoices = surveys[surveyid].choiceNum;                                       // the number of choices given in the survey, and
        atmostchoice = surveys[surveyid].allowedChoiceNum;                              // max. number of choices that one participant can choose are all taken from the "Survey" struct with
        return (ipfshash, surveydeadline, numchoices, atmostchoice);                    // the given "survevid".
    }

    function getSurveyResults(uint surveyid) public view returns(uint numtaken,   // This function returns the results and number of participants of the survey with the given "surveyid".
    uint [] memory results){
        numtaken = surveys[surveyid].participantCount;                            // Both the number of participants and results are stored inside a "Survey" struct with the given "surveyid"
        results = surveys[surveyid].result;                                       // and taken from there.
        return (numtaken, results);
    }

    function getNoOfSurveys() public view returns(uint numsurveys){   // This function returns the total number of submitted surveys.
        numsurveys = surveys.length;                                  // The total number is taken from the length of the "surveys" array which holds the all submitted surveys.
        return numsurveys;
    }

}
