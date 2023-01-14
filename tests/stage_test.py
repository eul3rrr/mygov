import pytest, brownie
from brownie import MyGov, accounts, chain
from scripts.deploy import deploy_mycontract


def test_myGov_projects():
    mygov = deploy_mycontract(10 ** 7)  # contract is deployed with 10**7 tokensupply
    test_accounts = []

    for i in range(10):
        test_accounts.append(accounts[i])
    for i in range(1, 1):
        test_accounts.append(accounts.load("acc" + str(i)))  # we initialized 10 accounts from ganache that owns 100 eth and 290 local
                                                             # accounts with no eth totaling to 300 acc's

    for i in test_accounts:
        mygov.faucet({"from": i})  # all accounts use the faucet

    mygov.transfer(test_accounts[0], 1000, {"from": mygov})  # we give 1000 MGT to test_accounts[0] for proposals.


    mygov.donateEther({"from": test_accounts[1],
                       "value": 50 * 10 ** 18})  # account 1 donates 50 ETH to the MyGov contract. such a nice person
    no_of_project_proposals_before_submission = mygov.getNoOfProjectProposals()
    tx = mygov.submitProjectProposal("ipfs", 1672520400, [10 ** 18, 10 ** 18],
                                [1672520400 + 7 * 86400, 1672520400 + 14 * 86400], {"from": test_accounts[0],
                                                                                    "value": 10 ** 17})  # a project is being submitted with deadline 01.01.23, requesting funding of 2 eth in two payments at 1 and and 2 weeks after the deadline.also we store the returned projectid

    no_of_project_proposals_after_submission = mygov.getNoOfProjectProposals()
    no_of_funded_projects_before_funding = mygov.getNoOfFundedProjects()
    initial_balance = test_accounts[0].balance()
    first_payment = mygov.getProjectNextPayment(tx.return_value)

    for i in range(int(len(test_accounts)/2), int(len(test_accounts))):
        mygov.delegateVoteTo(test_accounts[i - 50], 0,
                             {"from": test_accounts[i]})  # last 100 voters delegate their vote to the first 100

    for i in range(int(len(test_accounts)/4)):
        mygov.voteForProjectProposal(0, True, {"from": test_accounts[i]})  # first 100 accounts vote for the proposal

    for i in range(int(len(test_accounts)/4), int(len(test_accounts)/2)):
        mygov.voteForProjectProposal(0, False, {"from": test_accounts[i]})  # accounts 100-200 vote against the proposal

    mygov.reserveProjectGrant(0, {"from": test_accounts[0]})  # account 0 reserves grant for their proposal

    for i in test_accounts:
        mygov.voteForProjectPayment(0, True, {"from": i})  # all accounts vote for 1. project payment



    chain.mine(
        timestamp=1672520400 + 7 * 86400 + 1)  # we time travel to 1 seconds after the first payment date and mine a block

    mygov.withdrawProjectPayment(0, {"from": test_accounts[0]})  # account 0 withdraws the first payment


    balance_after_first_withdrawal = test_accounts[0].balance()  # save the balance after first withdrawal

    for i in test_accounts:
        mygov.voteForProjectPayment(0, True, {"from": i})  # all accounts vote for 2. project payment

    chain.mine(
        timestamp=1672520400 + 14 * 86400 + 1)  # we time travel to 1 seconds after the second payment date and mine a block

    mygov.withdrawProjectPayment(0, {"from": test_accounts[0]})  # account 0 withdraws the second payment

    balance_after_second_withdrawal = test_accounts[0].balance()  # save the balance after the second withdrawal



    assert balance_after_first_withdrawal == initial_balance + 10 ** 18 and balance_after_second_withdrawal == balance_after_first_withdrawal + 10 ** 18
    assert mygov.getIsProjectFunded(tx.return_value) == True
    assert mygov.getProjectOwner(tx.return_value) == test_accounts[0]
    assert mygov.getProjectInfo(tx.return_value) == ("ipfs", 1672520400, [10 ** 18, 10 ** 18], [1672520400 + 7 * 86400, 1672520400 + 14 * 86400])
    assert no_of_project_proposals_before_submission + 1 == no_of_project_proposals_after_submission == 1
    assert no_of_funded_projects_before_funding + 1 == mygov.getNoOfFundedProjects() == 1
    assert mygov.getEtherReceivedByProject(tx.return_value) == 2*10**18

def test_mygov_surveys():
    mygov = deploy_mycontract(10 ** 7)  # contract is deployed with 10**7 tokensupply
    test_accounts = []

    for i in range(10):
        test_accounts.append(accounts[i])
    for i in range(1, 191):
        test_accounts.append(
            accounts.load("acc" + str(i)))  # we initialized 10 accounts from ganache that owns 100 eth and 290 local
        # accounts with no eth totaling to 300 acc's

    for i in test_accounts:
        mygov.faucet({"from": i})  # all accounts use the faucet

    mygov.transfer(test_accounts[0], 1000, {"from": mygov})  # we give 1000 MGT to test_accounts[0] for surveys.

    tx = mygov.submitSurvey("ipfs", 1672531200 , 6, 3,{"from":test_accounts[0],"value":4*10**16})

    for i in range(int(len(test_accounts)/2),int(len(test_accounts))):
        mygov.takeSurvey(tx.return_value,[1,2,3],{"from":test_accounts[i]})
    for i in range(int(len(test_accounts)/4),int(len(test_accounts)/2)):
        mygov.takeSurvey(tx.return_value,[5],{"from":test_accounts[i]})

    chain.mine(timestamp =1640984400 +1)
    survey_results = mygov.getSurveyResults(tx.return_value)
    survey_owner = mygov.getSurveyOwner(tx.return_value)
    survey_info = mygov.getSurveyInfo(tx.return_value)
    no_of_surveys = mygov.getNoOfSurveys()

    assert survey_results == (int(len(test_accounts)*3/4),(0,int(len(test_accounts)/2),int(len(test_accounts)/2),int(len(test_accounts)/2),0,int(len(test_accounts)/4)))
    assert survey_info ==("ipfs", 1672531200 , 6, 3)
    assert survey_owner == test_accounts[0]
    assert no_of_surveys == 1












