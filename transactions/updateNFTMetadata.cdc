import LoveSpreads from "../LoveSpreads.cdc"
import NonFungibleToken from "../utility/NonFungibleToken.cdc"

transaction(
  currentOwner: Address,
  id: UInt64,
  name: String,
  description: String,
  thumbnail: String,
  metadata: {String: AnyStruct}
) {

  let Admin: &LoveSpreads.Administrator

  prepare(signer: AuthAccount) {
    self.Admin = signer.borrow<&LoveSpreads.Administrator>(from: LoveSpreads.MinterStoragePath)
                    ?? panic("This is not the Minter account.")
  }

  execute {
    self.Admin.updateMetadata(
      id: id, 
      currentOwner: currentOwner, 
      name: name, 
      description: description, 
      thumbnail: thumbnail, 
      metadata: metadata
    )
  }
}