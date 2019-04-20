Miner-Registration
===
A smart contract-based miner registration and block validation

## Structure

 Function | Description 
 -------- | -----------
*Contribute()* | Function of miners' putting deposit
*CreateTranset()* | Function of miners' creating a transaction set
*Register()* | Function of miners' registration (controlled by the contract manager)
*CheckHeight()* | Function of checking the block height after *Register()* (controlled by the contract manager)
*CheckBlock()* | Function of checking the validity of blocks (controlled by the contract manager)
*Withdraw()* | Function of the registered miners' withdrawing the deposit

## Useage
### Setup
Install truffle:
```
npm install -g truffle
```
Install ganache: https://github.com/trufflesuite/ganache/releases
### Test
```
truffle test
```
