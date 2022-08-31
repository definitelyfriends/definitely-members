# Expects jq to be installed

source .env
source .env.local

if [ -z "$CHAIN_ID" ]; then
  echo "CHAIN_ID is not set"
  exit 1
fi

forge script script/InitialDeploy.s.sol:InitialDeploy --optimizer-runs 200 --use 0.8.15 --ffi -vvv \
    --chain-id $CHAIN_ID \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --broadcast \
    --verify --etherscan-api-key $ETHERSCAN_API_KEY

mkdir -p deploys/$CHAIN_ID

MEMBERSHIPS="deploys/$CHAIN_ID/DefinitelyMemberships.json"
jq '{deployedTo: .receipts[0].contractAddress, deployer: .receipts[0].tx.from, transactionHash: .receipts[0].transactionHash}' ./broadcast/InitialDeploy.s.sol/$CHAIN_ID/run-latest.json > $MEMBERSHIPS

METADATA="deploys/$CHAIN_ID/DefinitelyMetadata.json"
jq '{deployedTo: .receipts[1].contractAddress, deployer: .receipts[1].tx.from, transactionHash: .receipts[1].transactionHash}' ./broadcast/InitialDeploy.s.sol/$CHAIN_ID/run-latest.json > $METADATA

FAMILY="deploys/$CHAIN_ID/DefinitelyFamily.json"
jq '{deployedTo: .receipts[2].contractAddress, deployer: .receipts[2].tx.from, transactionHash: .receipts[2].transactionHash}' ./broadcast/InitialDeploy.s.sol/$CHAIN_ID/run-latest.json > $FAMILY