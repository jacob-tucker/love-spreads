import LoveSpreads from "../LoveSpreads.cdc"
import NonFungibleToken from "../utility/NonFungibleToken.cdc"

transaction(recipient: Address) {
  let Minter: &LoveSpreads.NFTMinter
  let Recipient: &LoveSpreads.Collection{NonFungibleToken.Receiver}
  prepare(signer: AuthAccount) {
    self.Minter = signer.borrow<&LoveSpreads.NFTMinter>(from: LoveSpreads.MinterStoragePath)
                    ?? panic("This is not the Minter account.")
  
    self.Recipient = getAccount(recipient).getCapability(LoveSpreads.CollectionPublicPath)
                      .borrow<&LoveSpreads.Collection{NonFungibleToken.Receiver}>()
                      ?? panic("This account does not have a collection set up.")
  }

  execute {
    self.Minter.mintNFT(recipient: self.Recipient)
  }
}