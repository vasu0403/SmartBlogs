const SmartBlogs = artifacts.require("SmartBlogs");

module.exports = function (deployer) {
  deployer.deploy(SmartBlogs);
};
