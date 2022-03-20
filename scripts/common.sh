#!/usr/bin/env bash

set -eo pipefail

if [[ ${DEBUG} ]]; then
	set -x
fi

# All contracts are output to `out/addresses.json` by default
OUT_DIR=${OUT_DIR:-$PWD/out}
ADDRESSES_FILE=${ADDRESSES_FILE:-$OUT_DIR/"addresses.json"}
# default to localhost rpc
ETH_RPC_URL=${ETH_RPC_URL:-http://localhost:8545}

# green log helper
GREEN='\033[0;32m'
NC='\033[0m' # No Color
log() {
	printf '%b\n' "${GREEN}${*}${NC}"
	echo ""
}

# Coloured output helpers
if command -v tput >/dev/null 2>&1; then
	if [ $(($(tput colors 2>/dev/null))) -ge 8 ]; then
		# Enable colors
		TPUT_RESET="$(tput sgr 0)"
		TPUT_YELLOW="$(tput setaf 3)"
		TPUT_RED="$(tput setaf 1)"
		TPUT_BLUE="$(tput setaf 4)"
		TPUT_GREEN="$(tput setaf 2)"
		TPUT_WHITE="$(tput setaf 7)"
		TPUT_BOLD="$(tput bold)"
	fi
fi

# ensure ETH_FROM is set and give a meaningful error message
if [[ -z ${ETH_FROM} ]]; then
	echo "ETH_FROM not found, please set it and re-run the last command." >&2
	exit 1
fi

# Make sure address is checksummed
if [ "$ETH_FROM" != "$(seth --to-checksum-address "$ETH_FROM")" ]; then
	echo "ETH_FROM not checksummed, please format it with 'seth --to-checksum-address <address>'" >&2
	exit 1
fi

# Setup addresses file
cat >"$ADDRESSES_FILE" <<EOF
{
    "DEPLOYER": "$ETH_FROM"
}
EOF

# Call as `ETH_FROM=0x... ETH_RPC_URL=<url> deploy ContractName arg1 arg2 arg3`
# (or omit the env vars if you have already set them)
deploy() {
	NAME=$1
	ARGS=${@:2}

	if [[ -z "${NAME}" ]]; then
		echo "ERROR. File name not provided" >&2
		exit 1
	fi

	# find file path
	CONTRACT_PATH=$(find ./src -name $NAME.sol)
	CONTRACT_PATH=${CONTRACT_PATH:2}
	if [[ -z "${CONTRACT_PATH}" ]]; then
		echo "ERROR. File \"${NAME}\" does not exist" >&2
		exit 1
	fi

	# select the filename and the contract in it
	PATTERN=".contracts[\"$CONTRACT_PATH\"].$NAME"

	# Compile / Build
	dapp build
	if [[ $? -ne 0 ]]; then
		echo "ERROR. dapp build failed" >&2
		exit 1
	fi

	# get the constructor's signature
	ABI=$(jq -r "$PATTERN.abi // empty" out/dapp.sol.json)
	if [[ $? -ne 0 ]] || [[ -z "${ABI}" ]]; then
		echo "ERROR. Unable to get the contract ABI" >&2
		exit 1
	fi

	SIG=$(echo "$ABI" | seth --abi-constructor)
	if [[ $? -ne 0 ]] || [[ -z "${SIG}" ]]; then
		echo "ERROR. Unable to get the constructor signature" >&2
		exit 1
	fi

	# get the bytecode from the compiled file
	BYTECODE=0x$(jq -r "$PATTERN.evm.bytecode.object" out/dapp.sol.json)
	if [[ $? -ne 0 ]]; then
		echo "ERROR. Unable to get the bytecode from the compiled file" >&2
		exit 1
	fi

	# estimate gas
	GAS=$(seth estimate --create "$BYTECODE" "$SIG" $ARGS --rpc-url "$ETH_RPC_URL")
	if [[ $? -ne 0 ]]; then
		echo "ERROR. Unable to estimate gas" >&2
		exit 1
	fi

	# deploy
	ADDRESS=$(dapp create "$NAME" $ARGS -- --gas "$GAS" --rpc-url "$ETH_RPC_URL")
	if [[ $? -ne 0 ]]; then
		echo "ERROR. Unable to deploy app" >&2
		exit 1
	fi

	# save the addrs to the json
	# TODO: It'd be nice if we could evolve this into a minimal versioning system
	# e.g. via commit / chainid etc.
	saveContract "$NAME" "$ADDRESS"

	echo "$ADDRESS"
}

# Call as `saveContract ContractName 0xYourAddress` to store the contract name
# & address to the addresses json file
saveContract() {
	# create an empty json if it does not exist
	if [[ ! -e $ADDRESSES_FILE ]]; then
		echo "{}" >"$ADDRESSES_FILE"
	fi
	result=$(cat "$ADDRESSES_FILE" | jq -r ". + {\"$1\": \"$2\"}")
	printf %s "$result" >"$ADDRESSES_FILE"
}

estimate_gas() {
	NAME=$1
	ARGS=${@:2}

	if [[ -z "${NAME}" ]]; then
		echo "ERROR. File name not provided" >&2
		exit 1
	fi

	# select the filename and the contract in it
	PATTERN=".contracts[\"src/$NAME.sol\"].$NAME"

	# get the constructor's signature
	ABI=$(jq -r "$PATTERN.abi // empty" out/dapp.sol.json)
	if [[ $? -ne 0 ]] || [[ -z "${ABI}" ]]; then
		echo "ERROR. Unable to get the contract ABI" >&2
		exit 1
	fi

	SIG=$(echo "$ABI" | seth --abi-constructor)
	if [[ $? -ne 0 ]] || [[ -z "${SIG}" ]]; then
		echo "ERROR. Unable to get the constructor signature" >&2
		exit 1
	fi

	# get the bytecode from the compiled file
	BYTECODE=0x$(jq -r "$PATTERN.evm.bytecode.object" out/dapp.sol.json)
	if [[ $? -ne 0 ]]; then
		echo "ERROR. Unable to get the bytecode from the compiled file" >&2
		exit 1
	fi
	# estimate gas
	GAS=$(seth estimate --create "$BYTECODE" "$SIG" $ARGS --rpc-url "$ETH_RPC_URL")
	if [[ $? -ne 0 ]]; then
		echo "ERROR. Unable to estimate gas" >&2
		exit 1
	fi

	TXPRICE_RESPONSE=$(curl -sL https://api.txprice.com/v1)
	response=$(jq '.code' <<<"$TXPRICE_RESPONSE")
	if [[ $response != "200" ]]; then
		echo "Could not get gas information from ${TPUT_BOLD}txprice.com${TPUT_RESET}: https://api.txprice.com/v1"
		echo "response code: $response"
	else
		rapid=$(($(jq '.blockPrices[0].estimatedPrices[0].maxFeePerGas' <<<"$TXPRICE_RESPONSE")))
		fast=$(($(jq '.blockPrices[0].estimatedPrices[1].maxFeePerGas' <<<"$TXPRICE_RESPONSE")))
		standard=$(($(jq '.blockPrices[0].estimatedPrices[2].maxFeePerGas' <<<"$TXPRICE_RESPONSE")))
		slow=$(($(jq '.blockPrices[0].estimatedPrices[3].maxFeePerGas' <<<"$TXPRICE_RESPONSE")))
		basefee$(($(jq '.blockPrices[0].baseFeePerGas' <<<"$TXPRICE_RESPONSE")))
		echo "Gas prices from ${TPUT_BOLD}txprice.com${TPUT_RESET}: https://api.txprice.com/v1"
		echo " \
     ${TPUT_RED}Rapid: $rapid gwei ${TPUT_RESET} \n
     ${TPUT_YELLOW}Fast: $fast gwei \n
     ${TPUT_BLUE}Standard: $standard gwei \n
     ${TPUT_GREEN}Slow: $slow gwei${TPUT_RESET}" | column -t
		size=$(contract_size "$NAME")
		echo "Estimated Gas cost for deployment of $NAME: ${TPUT_BOLD}$GAS${TPUT_RESET} units of gas"
		echo "Contract Size: ${size} bytes"
		echo "Total cost for deployment:"
		rapid_cost=$(echo "scale=5; $GAS*$rapid" | bc)
		fast_cost=$(echo "scale=5; $GAS*$fast" | bc)
		standard_cost=$(echo "scale=5; $GAS*$standard" | bc)
		slow_cost=$(echo "scale=5; $GAS*$slow" | bc)
		echo " \
     ${TPUT_RED}Rapid: $rapid_cost ETH ${TPUT_RESET} \n
     ${TPUT_YELLOW}Fast: $fast_cost ETH \n
     ${TPUT_BLUE}Standard: $standard_cost ETH \n
     ${TPUT_GREEN}Slow: $slow_cost ETH ${TPUT_RESET}" | column -t
	fi
}

contract_size() {
	NAME=$1
	ARGS=${@:2}
	# select the filename and the contract in it
	PATTERN=".contracts[\"src/$NAME.sol\"].$NAME"

	# get the bytecode from the compiled file
	BYTECODE=0x$(jq -r "$PATTERN.evm.bytecode.object" out/dapp.sol.json)
	length=$(echo "$BYTECODE" | wc -m)
	echo $(($length / 2))
}
