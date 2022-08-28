import LoveSpreads from "../LoveSpreads.cdc"
import NonFungibleToken from "../utility/NonFungibleToken.cdc"

transaction(
  amount: Int,
  recipients: [Address], 
  names: [String],
  descriptions: [String],
  thumbnails: [String],
  metadatas: [{String: AnyStruct}]
) {
  let Minter: &LoveSpreads.Administrator
  let Recipients: [&LoveSpreads.Collection{NonFungibleToken.Receiver}]
  prepare(signer: AuthAccount) {
    self.Minter = signer.borrow<&LoveSpreads.Administrator>(from: LoveSpreads.MinterStoragePath)
                    ?? panic("This is not the Minter account.")
  
    self.Recipients = []
    for recipient in recipients {
      let recipientCollection = getAccount(recipient).getCapability(LoveSpreads.CollectionPublicPath)
                      .borrow<&LoveSpreads.Collection{NonFungibleToken.Receiver}>()
                      ?? panic("This account does not have a collection set up.")
      self.Recipients.append(recipientCollection)
    }
  }

  pre {
    names.length == amount && 
    descriptions.length == amount && 
    thumbnails.length == amount && 
    self.Recipients.length == amount: "You did not pass in an equal amount of data."
  }

  execute {
    var i = 0
    while i < amount {
      self.Minter.mintNFT(
        recipient: self.Recipients[i],
        name: names[i],
        description: descriptions[i],
        thumbnail: thumbnails[i],
        metadata: metadatas[i]
      )
      i = i + 1
    }
  }
}