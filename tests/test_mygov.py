import pytest , brownie
from brownie import MyGov , accounts , chain
from scripts.deploy import deploy_mycontract

def test_faucet_gives_coin():
    #Arrange
    mygov = deploy_mycontract(10**7)


    initialBalance = []
    finalBalance=[]

    #Act

    for i in range(10):
        initialBalance.append(mygov.balanceOf(accounts[i]))
        mygov.faucet({"from":accounts[i]})
        finalBalance.append(mygov.balanceOf(accounts[i]))




    #Assert
    for i in range(10):
        assert(finalBalance[i] == initialBalance[i] + 1)

def test_faucet_works_only_once():
    #Arrange
    mygov = deploy_mycontract(10**7)
    #Act
    mygov.faucet({"from": accounts[1]})
    with brownie.reverts():
        mygov.faucet({"from": accounts[1]})
        mygov.faucet({"from": accounts[1]})
    #Assert
    assert(mygov.balanceOf(accounts[1])==1)

def test_totalsupply():
    mygov = deploy_mycontract(10**7)

    assert(mygov.balanceOf(mygov)==10**7)

def test_donate_ether():
    mygov = deploy_mycontract(10**7)                         #arrange
    initialBalance = mygov.balance()

    mygov.donateEther({"from":accounts[1],"value":10})  #act
    finalBalance = mygov.balance()

    assert(finalBalance == initialBalance + 10)         #assert

def test_donate_mygov_token():
    mygov = deploy_mycontract(10**7)                             #arrange
    mygov.transfer(accounts[1],1000, {"from":mygov})
    initialBalance = mygov.balanceOf(mygov)

    mygov.donateMyGovToken(500 , {"from":accounts[1]})      #act
    finalBalance = mygov.balanceOf(mygov)

    assert(finalBalance == initialBalance + 500)            #assert

def test_can_submit_project_proposal_and_get_info(): #unfinished
    #arrange
    mygov = deploy_mycontract(10**7)

    mygov.transfer(accounts[1] , 1000 , {"from":mygov}) #pocket change for submitting proposal

    #act
    mygov.submitProjectProposal("ipfs", 1671095099, [100,100] , [1671195099,1671195100],{"from":accounts[1] , "value":10**17}) #account 1 submits proposal

    #assert
    assert mygov.getProjectOwner(0) == accounts[1] and mygov.getProjectInfo(0)==("ipfs", 1671095099, [100,100] , [1671195099,1671195100]) and mygov.getNoOfProjectProposals() == 1



def test_delegate_vote():
    #Arrange
    mygov = deploy_mycontract(10 ** 7)
    mygov.transfer(accounts[0] , 1000 , {"from":mygov})  #Pocket change for submitting proposals

    for i in range(10):         #All account's use faucet to be member
        mygov.faucet({"from":accounts[i]})


    for i in range(2):      #Account 0 submits two proposals
        mygov.submitProjectProposal("ipfs", 1672524061, [100] , [1672524061+86400],{"from":accounts[0] , "value":10**17})

    #Act
    for i in range(1,3): #Accounts 1,2 delegate their vote to accounts 3,4
        mygov.delegateVoteTo(accounts[i+2],0,{"from":accounts[i]})

    #Assert
    for i in range(1,3):
        assert mygov.getVoted(accounts[i],0,0).return_value == True and mygov.getWeight(accounts[i+2],0,0).return_value == 2  #Vote weight for proposal 0 is 0 for acc's 1,2 and 2 for acc's 3,4

def test_vote_for_project_proposal():
    # Arrange
    mygov = deploy_mycontract(10 ** 7)
    mygov.transfer(accounts[0], 1000, {"from": mygov})  # Pocket change for submitting proposals

    for i in range(10):  # All accounts use faucet to be member
        mygov.faucet({"from": accounts[i]})
    tx = mygov.submitProjectProposal("ipfs", 1672524061, [100, ], [1672524061, ],
                                     {"from": accounts[0], "value": 10 ** 17})
    # print(mygov.getProjectInfo(0))
    # print(mygov.proposals(0))
    # print(mygov.getWeight(accounts[1]).return_value)
    # print(mygov.getProposals(0 , {"from":accounts[1]}).return_value)
    # print(tx.return_value)
    #Act
    for i in range(1,5):    #Acc's 1,2,3,4 votes True && Acc's 6,7 votes False
        mygov.voteForProjectProposal(tx.return_value,True,{"from":accounts[i]})
    for i in range(6,8):
        mygov.voteForProjectProposal(tx.return_value,False,{"from":accounts[i]})
    #Assert
    assert mygov.getVoteCount(tx.return_value).return_value[0] == len(range(1,5)) #VoteCount is equal to the number of members voted True

def test_reserve_project_grant():
    mygov = deploy_mycontract(10 ** 7)
    mygov.transfer(accounts[0], 1000, {"from": mygov})  # Pocket change for submitting proposals

    for i in range(10):  # All accounts use faucet to be member
        mygov.faucet({"from": accounts[i]})
    tx = mygov.submitProjectProposal("ipfs", 1672524061, [10,5], [1672524061 + 86400*2,1672524061 + 86400*3],
                                     {"from": accounts[0], "value": 10 ** 17})

    for i in range(1,5):    #Acc's 1,2,3,4 votes True && Acc's 6,7 votes False therefore %10 of members voted yes
        mygov.voteForProjectProposal(tx.return_value,True,{"from":accounts[i]})
    for i in range(6,8):
        mygov.voteForProjectProposal(tx.return_value,False,{"from":accounts[i]})

    mygov.reserveProjectGrant(tx.return_value, {"from":accounts[0]})

    assert mygov.getReservedAmount().return_value == 15

def test_withdraw_project_payment():
    #Arrange: same with the above, project gets submitted, fundings get reserved
    mygov = deploy_mycontract(10 ** 7)
    mygov.transfer(accounts[0], 1000, {"from": mygov})  # Pocket change for submitting proposals
    mygov.donateEther( {"from":accounts[9],"value":100*10**18}) # Account 9 donates 100 ether to MyGov. Such a nice person, decentralization is the future.

    for i in range(10):  # All accounts use faucet to be member
        mygov.faucet({"from": accounts[i]})
    tx = mygov.submitProjectProposal("ipfs", 1672524061, [10*10**18,5*10**18,], [1672524061 + 86400*2,1672524061 + 86400*3,],
                                     {"from": accounts[0], "value": 10 ** 17})

    for i in range(1,5):    #Acc's 1,2,3,4 votes True && Acc's 6,7 votes False therefore %10 of members voted yes
        mygov.voteForProjectProposal(tx.return_value,True,{"from":accounts[i]})
    for i in range(6,8):
        mygov.voteForProjectProposal(tx.return_value,False,{"from":accounts[i]})

    next_payment_before_1st_period = mygov.getProjectNextPayment(tx.return_value)

    mygov.reserveProjectGrant(tx.return_value)
    mygov.voteForProjectPayment(0, True, {"from": accounts[0]})



    chain.mine(timestamp=1672524061 + 86400*2 + 1)

    initial_balance = accounts[0].balance()

    next_payment_after_1st_period = mygov.getProjectNextPayment(tx.return_value)

    mygov.withdrawProjectPayment(0 , {"from":accounts[0]})

    intermediary_balance = accounts[0].balance()



    mygov.voteForProjectPayment(0, True, {"from": accounts[0]})
    chain.mine(timestamp=1672524061 + 86400*3 + 1)


    mygov.withdrawProjectPayment(0,{"from":accounts[0]})

    final_balance = accounts[0].balance()

    assert initial_balance == intermediary_balance - 10**19
    assert final_balance == intermediary_balance + 5*10**18
    assert mygov.getIsProjectFunded(tx.return_value) == True and mygov.getNoOfFundedProjects() == 1 and mygov.getEtherReceivedByProject(tx.return_value)==15*10**18
    assert next_payment_before_1st_period == 10**19 and next_payment_after_1st_period == 5*10**18



def test_submit_survey_info_owner():
    mygov = deploy_mycontract(10 ** 7)
    mygov.transfer(accounts[0], 1000, {"from": mygov})  # Pocket change for submitting surveys

    tx = mygov.submitSurvey("ipfs", 1672524061, 5,2 , {"from":accounts[0] , "value":4*10**16})

    print(tx.return_value)

    assert mygov.getSurveyInfo(tx.return_value) == ("ipfs", 1672524061, 5,2) and mygov.getSurveyOwner(tx.return_value) == accounts[0]

def test_take_survey():
    mygov = deploy_mycontract(10 ** 7)

    for i in range(10):  # All accounts use faucet to be member
        mygov.faucet({"from": accounts[i]})

    mygov.transfer(accounts[0], 1000, {"from": mygov})  # Pocket change for submitting surveys
    tx = []
    for i in range(5):
        tx.append(mygov.submitSurvey("ipfs", 1672524061, 5, 2, {"from": accounts[0], "value": 4 * 10 ** 16}).return_value)

    chain.mine(timestamp=1672524061 + 1000)

    mygov.takeSurvey(tx[0],[3,4],{"from":accounts[1]})

    print(mygov.getNoOfSurveys())
    print(mygov.getSurveyResults(0))



    assert (mygov.getSurveyResults(0) == (1,(0,0,0,1,1)))


# def test_local_accounts():
#     mygov = deploy_mycontract(10 ** 7)
#     myAccounts = []
#     myAccounts.append(accounts.load("acc150"))
#
#
# def test_map():
#     mygov = deploy_mycontract(10 ** 7)
#     print(mygov.test().return_value)

# def test_op_delegate():
#     mygov = deploy_mycontract(10 ** 7)  # contract is deployed with 10**7 tokensupply
#     test_accounts = []
#
#     for i in range(10):
#         test_accounts.append(accounts[i])
#     for i in range(1, 91):
#         test_accounts.append(accounts.load("acc" + str(i)))
#
#     for i in test_accounts:
#         mygov.faucet({"from": i})  # all accounts use the faucet
#         print(mygov.balanceOf(i))
#
#
#
#     mygov.transfer(test_accounts[0], 1000, {"from": mygov})  # we give 1000 MGT to test_accounts[0] for proposals.
#
#     print("donating account is" , test_accounts[1], " and their balance is", test_accounts[1].balance())
#
#     mygov.donateEther({"from":test_accounts[1],"value":50*10**18}) #account 1 donates 50 ETH to the MyGov contract. such a nice person
#
#     mygov.submitProjectProposal("ipfs",1672520400,[10**18,10**18],[1672520400 + 7*86400, 1672520400 + 8*86400],{"from":test_accounts[0],"value":10**17}) #a project is being submitted with deadline 01.01.23, requesting funding of 2 eth in two payments at 1 and and 2 weeks after the deadline.also we store the returned projectid
#
#
#     for i in range(50):
#         mygov.delegateVoteTo(test_accounts[i+50],0,{"from":test_accounts[i]})
#
#     for i in range(50,75):
#         mygov.delegateVoteTo(test_accounts[i+25],0, {"from":test_accounts[i]})
#
#     for i in range(100):
#         print(mygov.getWeight(test_accounts[i],0,0).return_value)
#
#
#
#
#
#
