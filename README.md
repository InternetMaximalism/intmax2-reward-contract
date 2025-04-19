# intmax2-reward-contract

This repository contains smart contracts for the INTMAX reward system, including the ScrollINTMAXToken and BlockBuilderReward contracts.

## Setup

### Install foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
```

### Install dependencies

```bash
forge install
```

### Compile

```bash
forge compile
```

## Contracts

### ScrollINTMAXToken

An ERC20 token implementation for INTMAX on the Scroll network. It includes access control and transfer restrictions that can be lifted by an admin. It also includes a DISTRIBUTOR role for privileged transfers.

### BlockBuilderReward

A contract for managing and distributing rewards to block builders. It calculates and distributes rewards based on users' contributions to block building as recorded in the Contribution contract. It implements the UUPS upgradeable pattern and is owned by a designated admin.

## Deployment

The repository includes deployment scripts for both contracts. See [script/README.md](script/README.md) for detailed deployment instructions.

### Quick Deployment

To deploy both contracts in sequence:

```bash
# Deploy with default parameters
forge script script/DeployAll.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast

# Deploy with custom parameters
forge script script/DeployAll.s.sol --sig "run(address,address,uint256)" <ADMIN_ADDRESS> <CONTRIBUTION_CONTRACT_ADDRESS> <INITIAL_SUPPLY> --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## Testing

Run the tests with:

```bash
forge test
```

For more verbose output:

```bash
forge test -vvv
```
