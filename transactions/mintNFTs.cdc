import LoveSpreads from "../LoveSpreads.cdc"
import NonFungibleToken from "../utility/NonFungibleToken.cdc"

transaction(recipient: Address, amount: Int) {
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
    var i = 0
    while i < amount {
      self.Minter.mintNFT(recipient: self.Recipient)
      i = i + 1
    }
  }
}