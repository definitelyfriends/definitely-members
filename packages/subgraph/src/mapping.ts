import {
  DefinitelyMemberships,
  Transfer,
} from "../generated/DefinitelyMemberships/DefinitelyMemberships";
import { MembershipToken } from "../generated/schema";

export function handleTransfer(event: Transfer): void {
  const contract = DefinitelyMemberships.bind(event.address);
  const token = new MembershipToken(event.params.tokenId.toString());
  token.owner = event.params.to;
  token.tokenURI = contract.tokenURI(event.params.tokenId);
  token.save();
}
