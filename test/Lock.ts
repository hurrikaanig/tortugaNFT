import { expect } from "chai";
import { ethers } from "hardhat";
import { TortugaShip } from "../typechain-types"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";

describe("Tortuga ship", function () {
  let tortuga: TortugaShip;
  let users: SignerWithAddress[];

  before(async function() {
    // Contracts are deployed using the first signer/account by default
    users = (await ethers.getSigners()).splice(15);
    const Tortuga = await ethers.getContractFactory("TortugaShip");
    tortuga = await Tortuga.deploy() as TortugaShip;
  });

  describe("Mint", async function () {

    it("Shouldn't mint before start", function () {
      expect(tortuga.mint(2)).to.be.revertedWith("Sale hasn't started");
    });

    it("Should start mint", async function () {
      tortuga.startDrop();
      expect(await tortuga.hasSaleStarted()).to.be.true;
    });

    it("Shouldn't be able to mint more than 3", function () {
      expect(tortuga.mint(4)).to.be.revertedWith("You can mint maximum 3 ship");
    });

    it("Should be able to mint 3", async function () {

      await tortuga.connect(users[0]).mint(3);
      expect(await tortuga.balanceOf(users[0].address)).to.be.eq(BigNumber.from(3));
    });
  });
});
