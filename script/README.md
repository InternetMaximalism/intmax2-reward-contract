# Deployment Scripts

This directory contains scripts for deploying the ScrollINTMAXToken and BlockBuilderReward contracts.

## Available Scripts

1. `DeployScrollINTMAXToken.s.sol`: Deploys only the ScrollINTMAXToken contract
2. `DeployBlockBuilderReward.s.sol`: Deploys only the BlockBuilderReward contract with a proxy
3. `DeployAll.s.sol`: Deploys both contracts in sequence and configures them to work together

## Prerequisites

Before running these scripts, make sure you have:

1. [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
2. A wallet with sufficient funds for the target network
3. RPC URL for the target network

## Usage

### Deploy ScrollINTMAXToken

```bash
# Deploy with default parameters
forge script script/DeployScrollINTMAXToken.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast

# Deploy with custom parameters
forge script script/DeployScrollINTMAXToken.s.sol --sig "run(address,address,uint256)" <ADMIN_ADDRESS> <REWARD_CONTRACT_ADDRESS> <INITIAL_SUPPLY> --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

### Deploy BlockBuilderReward

```bash
# Deploy with default parameters
forge script script/DeployBlockBuilderReward.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast

# Deploy with custom parameters
forge script script/DeployBlockBuilderReward.s.sol --sig "run(address,address)" <CONTRIBUTION_CONTRACT_ADDRESS> <INTMAX_TOKEN_ADDRESS> --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

### Deploy Both Contracts

```bash
# Deploy with default parameters
forge script script/DeployAll.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast

# Deploy with custom parameters
forge script script/DeployAll.s.sol --sig "run(address,address,uint256)" <ADMIN_ADDRESS> <CONTRIBUTION_CONTRACT_ADDRESS> <INITIAL_SUPPLY> --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## Parameters

### ScrollINTMAXToken

- `admin`: Address that will be granted the DEFAULT_ADMIN_ROLE
- `rewardContract`: Address that will be granted the DISTRIBUTOR role
- `initialSupply`: Initial amount of tokens to mint to the admin

### BlockBuilderReward

- `contributionContract`: Address of the Contribution contract for accessing contribution scores
- `intmaxToken`: Address of the INTMAX token used for reward distribution

### DeployAll

- `admin`: Address that will be granted the DEFAULT_ADMIN_ROLE for the token
- `contributionContract`: Address of the Contribution contract for accessing contribution scores
- `initialSupply`: Initial amount of tokens to mint to the admin

## Network-Specific Deployment

For deploying to specific networks, you can use the `--fork-url` flag:

```bash
# Deploy to Scroll mainnet
forge script script/DeployAll.s.sol --fork-url https://rpc.scroll.io --private-key <PRIVATE_KEY> --broadcast

# Deploy to Scroll Sepolia testnet
forge script script/DeployAll.s.sol --fork-url https://sepolia-rpc.scroll.io --private-key <PRIVATE_KEY> --broadcast
```

## Verifying Contracts

After deployment, you can verify the contracts on the block explorer:

```bash
# Verify ScrollINTMAXToken
forge verify-contract <DEPLOYED_ADDRESS> src/token/scroll/ScrollINTMAXToken.sol:ScrollINTMAXToken --chain-id <CHAIN_ID> --etherscan-api-key <API_KEY> --constructor-args $(cast abi-encode "constructor(address,address,uint256)" <ADMIN_ADDRESS> <REWARD_CONTRACT_ADDRESS> <INITIAL_SUPPLY>)

# Verify BlockBuilderReward implementation
forge verify-contract <IMPLEMENTATION_ADDRESS> src/block-builder-reward/BlockBuilderReward.sol:BlockBuilderReward --chain-id <CHAIN_ID> --etherscan-api-key <API_KEY>
```

Note: For verifying proxy contracts, you'll need to use the block explorer's UI to verify the proxy as an implementation contract.
