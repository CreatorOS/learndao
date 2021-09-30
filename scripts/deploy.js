async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const Token = await ethers.getContractFactory("TempToken");
    const token = await Token.deploy();


    const Dao = await ethers.getContractFactory("LearnDao");
    const dao = await Dao.deploy(token.address);//mainnet dai
  
    console.log("Dao address:", dao.address);
    console.log("Token address:", token.address);
    console.log("DaoManager address:", await dao.getManager())
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  