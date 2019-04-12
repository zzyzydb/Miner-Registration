const MinerReg = artifacts.require("MinerRegistration.sol");

module.exports = function(deployer) {
  deployer.deploy(MinerReg, 10000);
};