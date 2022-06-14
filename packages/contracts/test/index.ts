import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Definitely Membership contracts", function () {
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let memberA: SignerWithAddress;
  let memberB: SignerWithAddress;
  let memberC: SignerWithAddress;
  let priorMember: SignerWithAddress;
  let deniedMember: SignerWithAddress;

  beforeEach(async () => {
    [deployer, owner, memberA, memberB, memberC, priorMember, deniedMember] =
      await ethers.getSigners();
  });

  it("should say hello", async function () {
    expect("Hello DEF").to.be.equal("Hello DEF");
  });
});
