const MinerReg = artifacts.require("./MinerRegistration.sol");
const assert = require('assert');
const Web3 = require('web3');
const web3 = new Web3('http://localhost:7545');

contract('MinerReg', function(accounts){
    
    let instance;
    let manager = accounts[0];
    let miner = accounts[1];

    beforeEach(async() => {
        instance = await MinerReg.new(web3.utils.toWei('1','ether'), { from: manager }); // create a contract instance
    });
    
    it("deploys a contract", async() => {
        assert.equal(await instance.manager.call(), manager, "The manager is who deploys the smart contract.");
    }); // check the contract manager

    it("requires miners to contribute money", async() => {
        await instance.Contribute({
            value: web3.utils.toWei('1','ether'),
            from: miner
        });
        assert.ok(await instance.miners.call(miner));
    }); // check if the miner put 1 ether
    
    it("create a new transaction set", async() => {
        await instance.Contribute({
            value: web3.utils.toWei('1','ether'),
            from: miner
        });
        await instance.CreateTranset(2, ['0xb6dec9180ddb217f0cf1b1a3f73df4270dd5252c8d89b5b868b290738d4913',
            '0x3565c92c7393a6599a4f937f9e8f57a57b0140b6aba66b42faca6ee5b3842e83'], 1, { from: miner });
        assert.ok(await instance.tranSet.call());
    }); // check if the miner creates a transaction set

    it("The process of registering transactions", async() => {
        await instance.Contribute({
            value: web3.utils.toWei('1','ether'),
            from: miner
        });
        await instance.CreateTranset(2, ['0xb6dec9180ddb217f0cf1b1a3f73df4270dd5252c8d89b5b868b290738d491307',
            '0x3565c92c7393a6599a4f937f9e8f57a57b0140b6aba66b42faca6ee5b3842e83'], 1, { from: miner });
        const voucher = await instance.Register({ from: manager });
        console.log(voucher.logs[0].args._voucher);
        await instance.CheckHeight({ from: manager });
        assert.equal(await instance.blockheight.call(), 1, "The block height submitted by the miner is valid.");
        const regResult = await instance.miners.call(miner);
        assert.equal(regResult[1], "registered", "This miner has passed the registration.");
    }); // check if the miner passes the registration and gets a voucher

    it("check the validity of one chain", async() => {
        await instance.Contribute({
            value: web3.utils.toWei('1','ether'),
            from: miner
        });
        await instance.CreateTranset(2, ['0xb6dec2180ddb217f0cf1b1a3f73df4270dd5232c8d89b5b868b290738d491307',
            '0x3565f92c7313a6599a4f937f9e8f57a57b0140b6aba66b4afaca6ee5b3842e83'], 1, { from: miner });
        await instance.Register({ from: manager });
        await instance.CheckHeight({ from: manager });
        const isValid = await instance.CheckBlock('0x15bb15af9cd1b782f9618bcb75fd9cc56e37fb1b8b087f45196b816d741e7f05', 
            '0x56496778973345ffd5af9d6874d647612ae3ceb8ee231099fd9991578e3af56b', 
            '0x5f0d44e8f7277180bd11735ae6c43d41b0f7195311986a9c99010a7a92b53d82', 1, { from: manager });
        console.log(isValid.logs[0].args.isvalid);
    }); // check if the new block is valid (in this test, we submit a invalid block)

    it("withdraw the deposit", async() => {
        await instance.Contribute({
            value: web3.utils.toWei('1','ether'),
            from: accounts[2]
        });
        await instance.CreateTranset(2, ['0xb6dec9180ddb217f0cf1b1a3f73df4270dd5252c8d89b5b868b290738d491307',
            '0x3565c92c7393a6599a4f937f9e8f57a57b0140b6aba66b42faca6ee5b3842e83'], 1, { from: accounts[2] });
        await instance.Register({ from: manager });
        await instance.CheckHeight({ from: manager });
        await instance.Withdraw({ from: accounts[2] });
        let balance = await web3.eth.getBalance(accounts[2]);
        balance = web3.utils.fromWei(balance,'ether');
        balance = parseFloat(balance);
        console.log(balance);
        assert(balance > 99);
    }); // check if the registered miner can withdraw his deposit (1 ether)
});
