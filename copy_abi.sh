#!/usr/bin/env bash

# NOTE: Install "jq"
# brew install jq

requireFields='{fileName: .fileName, contractName: .contractName, abi: .abi, compiler: .compiler, networks: .networks}'

rm -f ./RentMyTent.json

echo "Generating JSON file for RentMyTent"
cat ./build/contracts/RentMyTent.json | jq -r "$requireFields" > ./RentMyTent.json
