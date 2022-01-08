# <h1 align="center"> DappTools Starter Kit </h1>

## This is a working draft based on [dapptools-template](https://github.com/gakonst/dapptools-template)
See the [#TODO](#todo) list at the bottom for a list of things to complete. 

Implementation of the following 3 Chainlink features using the [DappTools](https://dapp.tools/) development environment:
 - [Chainlink Price Feeds](https://docs.chain.link/docs/using-chainlink-reference-contracts)
 - [Chainlink Keepers](https://docs.chain.link/docs/chainlink-keepers/introduction/)

# Installation

## Requirements
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [DappTools](https://github.com/dapphub/dapptools#installation)

## Getting Started 

```sh
git clone https://github.com/smartcontractkit/dapptools-starter-kit
cd dapptools-starter-kit
make # This installs the project's dependencies.
make test
```

All the commands from [dapptools] work with this repo, like `dapp build`, `ethsign`, and `dapp test`. 

# Deploying

To deploy, you first need to setup your `.env` file and your `ethsign`. 

## Setup your Account/ethsign

To get your private keys into dapptools, you can either use a keystore or `ethsign`. For `ethsign`, run the following:
```bash
ethsign import 
```
And you'll be prompted for your private key, and a password. Once successful, add the address of the private key to your `.env` file under an `ETH_FROM` variable. See the `.env.example` file for an example. 

See the [`Makefile`](./Makefile#25) for more context on how this works under the hood

## Testnet & Mainnet Deployment

Set your `ETH_RPC_URL` in your `.env` file, then run one of the following:

Price Feeds: 
```bash
make deploy-price-feed-consumer
```

Counters (Keeper Compatible Contract):
```bash
make deploy-counter
```

You can change their deployment parameters in their respective `deploy` file in the `scripts` folder. 


### Local Testnet

```
# on one terminal
dapp testnet
```

Change your `ETH_RPC_URL` to `http://127.0.0.1:8545`

Then run your deploy script. 

### Verifying on Etherscan

After deploying your contract you can verify it on Etherscan using:

```
ETHERSCAN_API_KEY=<api-key> dapp verify-contract <contract_directory>/<contract>:<contract_name> <contract_address>
```

For example:

```
ETHERSCAN_API_KEY=123456765 dapp verify-contract ./src/Counter.sol:Counter 0x23456534212536435424
```


Check out the [dapp documentation](https://github.com/dapphub/dapptools/tree/master/src/dapp#dapp-verify-contract) to see how
verifying contracts work with DappTools.


## DappTools Resources

* [DappTools](https://dapp.tools)
    * [Hevm Docs](https://github.com/dapphub/dapptools/blob/master/src/hevm/README.md)
    * [Dapp Docs](https://github.com/dapphub/dapptools/tree/master/src/dapp/README.md)
    * [Seth Docs](https://github.com/dapphub/dapptools/tree/master/src/seth/README.md)
* [DappTools Overview](https://www.youtube.com/watch?v=lPinWgaNceM)
* [Awesome-DappTools](https://github.com/rajivpo/awesome-dapptools)


## TODO 
[ ] Enable network & contract choice from the command line
    ie: make deploy-rinkeby contract=counter 

[ ] Add mockOracle for any API calls 

[ ] Add scripts that interact with deployed contracts 

[ ] Fix Chainlink VRF deploy script 

[ ] Add config for parametatizing variables across networks and contracts 
