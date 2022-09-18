const { ethers } = require("hardhat");
const { NFT_ADDRESS } = require("../constants");
async function main() {
  const FakeNFTMarketplace = await ethers.getContractFactory(
    "FakeNFTMarketplace"
  );
  const fakeNftMarketplace = await FakeNFTMarketplace.deploy();
  await fakeNftMarketplace.deployed();
  console.log(
    "FakeNFTMarketplace deployed Address: ",
    fakeNftMarketplace.address
  );
  const CryptoDreamDAO = await ethers.getContractFactory("CryptoDreamDAO");
  const cryptoDream = await CryptoDreamDAO.deploy(
    fakeNftMarketplace.address,
    NFT_ADDRESS,
    { value: ethers.utils.parseEther("1") }
  );
  await cryptoDream.deployed();
  console.log("CryptoDream deployed to: ", cryptoDream.address);
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
