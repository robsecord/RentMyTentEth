## Rent My Tent - Solidity Contracts v0.0.5

### Frameworks/Software used:
- OpenZeppelin CLI **v2.6.0**
- OpenZeppelin Ethereum Contracts **v2.4.0**
- OpenZeppelin Upgrades **v2.6.0**
- Solidity  **v0.5.13** (solc-js)
- NodeJS **v12.14.1**
- Web3.js **v1.2.1**

### Prepare environment:
    
 Create a local .env file with the following (replace __placeholders__ with your keys):
 
```bash
    INFURA_API_KEY="__api_key_only_no_url__"
    
    ROPSTEN_PROXY_ADDRESS="__public_address__"
    ROPSTEN_PROXY_MNEMONIC="__12-word_mnemonic__"
    
    ROPSTEN_OWNER_ADDRESS="__public_address__"
    ROPSTEN_OWNER_MNEMONIC="__12-word_mnemonic__"
    
    MAINNET_PROXY_ADDRESS="__public_address__"
    MAINNET_PROXY_MNEMONIC="__12-word_mnemonic__"
    
    MAINNET_OWNER_ADDRESS="__public_address__"
    MAINNET_OWNER_MNEMONIC="__12-word_mnemonic__"
```

### To run the Main Repo (Testnet or Mainnet only):
    
 1. npm install
 2. npx ganache-cli --deterministic
 3. npm run deploy-dev

See package.json for more scripts


### Development

1. install version updater:

    npm install -g version-updater
    
2. install OpenZeppelin CLI:

    npm install -g @openzeppelin/cli
    
3. install jq (Max OSX):

    brew install jq
    
update version in files:
    
    version update [-p | -m | -M]

compile contracts

    oz compile


~~__________________________________~~

_MIT License_

Copyright (c) 2020 Rent-My-Tent-Team
