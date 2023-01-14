from brownie import accounts , MyGov

def deploy_mycontract(tokensupply):
    myaccounts = []

    account = accounts[0]

    mygov = MyGov.deploy(tokensupply,{"from" : account})
    return(mygov)
def main():
    deploy_mycontract()