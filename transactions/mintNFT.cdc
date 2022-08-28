import LoveSpreads from "../LoveSpreads.cdc"
import NonFungibleToken from "../utility/NonFungibleToken.cdc"

transaction(
  recipient: Address,
  name: String,
  description: String,
  thumbnail: String,
  metadata: {String: AnyStruct}
) {

  let Minter: &LoveSpreads.Administrator
  let Recipient: &LoveSpreads.Collection{NonFungibleToken.Receiver}

  prepare(signer: AuthAccount) {
    self.Minter = signer.borrow<&LoveSpreads.Administrator>(from: LoveSpreads.MinterStoragePath)
                    ?? panic("This is not the Minter account.")
  
    self.Recipient = getAccount(recipient).getCapability(LoveSpreads.CollectionPublicPath)
                      .borrow<&LoveSpreads.Collection{NonFungibleToken.Receiver}>()
                      ?? panic("This account does not have a collection set up.")
  }

  execute {
    self.Minter.mintNFT(
      recipient: self.Recipient,
      name: name,
      description: description,
      thumbnail: thumbnail,
      metadata: metadata
    )
  }
}