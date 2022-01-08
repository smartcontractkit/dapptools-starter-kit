#!/usr/bin/env bash

# Defaults to kovan
interval=1
price_feed=0x9326BFA02ADD2366b30bacB125260Af641031331
link_token=0xa36085F69e2889c224210F603D836748e7dC0088
vrf_coordinator=0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
keyHash=0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
fee=100000000000000000

# Defaults to Counter
arguments=1

if [ "$NETWORK" = "kovan" ]
then 
    interval=1
    price_feed=0x9326BFA02ADD2366b30bacB125260Af641031331
    link_token=0xa36085F69e2889c224210F603D836748e7dC0088
    vrf_coordinator=0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
    keyHash=0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
    fee=100000000000000000
elif [ "$NETWORK" = "rinkeby" ]
then 
    vrf_coordinator=0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
    link_token=0x01be23585060835e02b77ef475b0cc51aa1e0709
    keyhash=0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
    fee=100000000000000000
    price_feed=0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
fi

if [ "$CONTRACT" = "Counter" ]
then 
    arguments=$interval
elif [ "$CONTRACT" = "PriceFeedConsumer" ]
then 
    arguments=$price_feed
elif [ "$CONTRACT" = "VRFConsumer" ]
then 
    arguments="$keyHash $vrf_coordinator $link_token $fee"
fi 
