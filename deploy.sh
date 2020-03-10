#!/usr/bin/env bash

# Parse env vars from .env file
export $(egrep -v '^#' .env | xargs)

# Change this to the correct address after deploying
addrRentMyTent="0x254dffcd3277C0b1660F6d42EFbB754edaBAbC2B"

ownerAccount=
networkName="development"
silent=
init=
update=

usage() {
    echo "usage: ./deploy.sh [[-n [development|ropsten|mainnet] [-i] [-u] [-v] [-s]] | [-h]]"
    echo "  -n    | --network [development|ropsten|mainnet]  Deploys contracts to the specified network (default is local)"
    echo "  -i    | --init                                   Initialize contracts after deployment"
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

    echo " "
    echo " "
    echo "OWNER: ${ownerAccount}"
    echo " "
    echo " "

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
    echoBeep
}

initialize() {
    getOwnerAccount

    echoHeader
    echo "Initializing RentMyTent.."

#    echo " "
#    echo "setDepositFee: $depositFee"
#    result=$(oz send-tx --no-interactive --to ${addrRentMyTent} --method 'setDepositFee' --args ${depositFee})

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
        -i | --init )           init="yes"
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

if [[ -n "$init" ]]; then
    initialize
elif [[ -n "$update" ]]; then
    deployUpdate
else
    deployFresh
fi

