import { BigInt, log } from "@graphprotocol/graph-ts";
import {
  InviteClaimed,
  MemberInvited,
} from "../generated/DefinitelyInvites/DefinitelyInvites";
import {
  DefaultMetadataUpdated,
  DefinitelyMemberships,
  DefinitelyShipping,
  MetadataOverridden,
  MetadataResetToDefault,
  Transfer as TransferEvent,
} from "../generated/DefinitelyMemberships/DefinitelyMemberships";
import { MetadataContract, Registry, Token, Wallet } from "../generated/schema";

export function handleInit(event: DefinitelyShipping): void {
  let registry = Registry.load("DefinitelyMemberships:registry");
  if (!registry) {
    registry = new Registry("DefinitelyMemberships:registry");
    registry.address = event.address;
    registry.save();
  }
}

export function handleTransfer(event: TransferEvent): void {
  const contract = DefinitelyMemberships.bind(event.address);

  const id = event.params.id;
  const fromAddress = event.params.from;
  const toAddress = event.params.to;
  const defaultMetadataAddress = contract.defaultMetadataAddress();

  let fromWallet = Wallet.load(fromAddress.toHexString());
  if (!fromWallet) {
    fromWallet = new Wallet(fromAddress.toHexString());
    fromWallet.address = fromAddress;
    fromWallet.isMember = false;
    fromWallet.joinedTimestamp = BigInt.fromI32(0);
    fromWallet.joinedBlockNumber = BigInt.fromI32(0);
    fromWallet.save();
  }

  let toWallet = Wallet.load(toAddress.toHexString());
  if (!toWallet) {
    toWallet = new Wallet(toAddress.toHexString());
    toWallet.address = toAddress;
  }
  toWallet.isMember = true;
  toWallet.joinedTimestamp = event.block.timestamp;
  toWallet.joinedBlockNumber = event.block.number;
  toWallet.save();

  let metadata = MetadataContract.load(defaultMetadataAddress.toHexString());
  if (!metadata) {
    metadata = new MetadataContract(defaultMetadataAddress.toHexString());
    metadata.address = defaultMetadataAddress;
    metadata.save();
  }

  let token = Token.load(id.toString());
  if (!token) {
    token = new Token(id.toString());
    const uri = contract.try_tokenURI(id);
    if (uri.reverted) {
      log.info("URI reverted", [id.toHexString()]);
    } else {
      token.tokenURI = uri.value;
    }
    token.metadata = metadata.id;
  }
  token.owner = toWallet.id;
  token.save();
}

export function handleDefaultMetadataUpdated(
  event: DefaultMetadataUpdated
): void {}

export function handleMetadataOverridden(event: MetadataOverridden): void {}

export function handleMetadataResetToDefault(
  event: MetadataResetToDefault
): void {}

export function handleMemberInvited(event: MemberInvited): void {
  const invitedAddress = event.params.invited;
  const invitedByAddress = event.params.invitedBy;

  let invitedByWallet = Wallet.load(invitedByAddress.toHexString());

  let invitedWallet = Wallet.load(invitedAddress.toHexString());
  if (!invitedWallet) {
    invitedWallet = new Wallet(invitedAddress.toHexString());
    invitedWallet.address = invitedAddress;
    invitedWallet.isMember = false;
    invitedWallet.joinedTimestamp = BigInt.fromI32(0);
    invitedWallet.joinedBlockNumber = BigInt.fromI32(0);
    invitedWallet.save();
  }

  if (invitedByWallet) {
    invitedWallet.invitedBy = invitedByWallet.id;
    invitedWallet.save();

    let invitedWallets = invitedByWallet.invited;
    if (!invitedWallets) {
      invitedWallets = [invitedWallet.id];
    } else {
      invitedWallets.push(invitedWallet.id);
    }
    invitedByWallet.invited = invitedWallets;
    invitedByWallet.save();
  }
}

export function handleInviteClaimed(event: InviteClaimed): void {
  const invitedAddress = event.params.invited;

  let invitedWallet = Wallet.load(invitedAddress.toHexString());
  if (!invitedWallet) {
    invitedWallet = new Wallet(invitedAddress.toHexString());
    invitedWallet.address = invitedAddress;
  }
  invitedWallet.isMember = true;
  invitedWallet.joinedTimestamp = event.block.timestamp;
  invitedWallet.joinedBlockNumber = event.block.number;
  invitedWallet.save();
}
