#!/usr/bin/env bash

# Parse env vars from .env file
export $(egrep -v '^#' .env | xargs)

membershipFee="10000000000000000"   # 0.01 ETH
transferFee="1000000000000000"      # 0.001 ETH

addressRentMyTent=
ownerAccount=
networkName="development"
silent=
update=

usage() {
    echo "usage: ./deploy.sh [[-n [development|ropsten|mainnet] [-i] [-u] [-v] [-s]] | [-h]]"
    echo "  -n    | --network [development|ropsten|mainnet]  Deploys contracts to the specified network (default is local)"
    echo "  -u    | --update                                 Push updates to deployments"
    echo "  -s    | --silent                                 Suppresses the Beep at the end of the script"
    echo "  -h    | --help                                   Displays this help screen"
}

echoHeader() {
    echo " "
    echo "-----------------------------------------------------------"
    echo "-----------------------------------------------------------"
}

echoBeep() {
    [[ -z "$silent" ]] && {
        afplay /System/Library/Sounds/Glass.aiff
    }
}

getOwnerAccount() {
    if [[ "$networkName" == "development" ]]; then
        ownerAccount=$(oz accounts -n ${networkName} --no-interactive 2>&1 | head -n 9 | tail -n 1) # Get Account 3
        ownerAccount="${ownerAccount:(-42)}"
    elif [[ "$networkName" == "ropsten" ]]; then
        ownerAccount="$ROPSTEN_OWNER_ADDRESS"
    elif [[ "$networkName" == "mainnet" ]]; then
        ownerAccount="$MAINNET_OWNER_ADDRESS"
    fi

    oz session --no-interactive --from "$ownerAccount" -n "$networkName"
#    oz balance --from "$ownerAccount" -n "$networkName" --no-interactive
}

deployFresh() {
    getOwnerAccount

    if [[ "$networkName" != "mainnet" ]]; then
        echoHeader
        echo "Clearing previous build..."
        rm -rf build/
        rm -f "./.openzeppelin/$networkName.json"
    fi

    echo "Compiling contracts.."
    oz compile

    echoHeader
    echo "Creating Contract: RentMyTent"
    oz add RentMyTent --push --skip-compile
    addressRentMyTent=$(oz create RentMyTent --init initializeAll --args ${ownerAccount} --no-interactive | tail -n 1)
    sleep 1s

    echoHeader
    echo "Contract Addresses: "
    echo " - RentMyTent: $addressRentMyTent"

    echoHeader
    echo "Contract Deployment Complete!"
    echo " "

    echoHeader
    echo "Initializing RentMyTent.."

    echo " "
    echo "registerInitialMember: $ownerAccount"
    result=$(oz send-tx --no-interactive --to ${addressRentMyTent} --method 'registerInitialMember' --args ${ownerAccount})

    echo " "
    echo "setMembershipFee: $membershipFee"
    result=$(oz send-tx --no-interactive --to ${addressRentMyTent} --method 'setMembershipFee' --args ${membershipFee})

    echo " "
    echo "setTransferFee: $transferFee"
    result=$(oz send-tx --no-interactive --to ${addressRentMyTent} --method 'setTransferFee' --args ${transferFee})

    echoHeader
    echo "Contract Initialization Complete!"
    echo " "
    echoBeep
}

deployUpdate() {
    getOwnerAccount

    echoHeader
    echo "Pushing Contract Updates to network \"$networkName\".."

    oz upgrade --all --no-interactive

    echo " "
    echo "Contract Updates Complete!"
    echo " "
    echoBeep
}


while [[ "$1" != "" ]]; do
    case $1 in
        -n | --network )        shift
                                networkName=$1
                                ;;
        -u | --update )         update="yes"
                                ;;
        -s | --silent )         silent="yes"
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [[ -n "$update" ]]; then
    deployUpdate
else
    deployFresh
fi

