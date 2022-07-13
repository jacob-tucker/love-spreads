import LoveSpreads from "../LoveSpreads.cdc"
import NonFungibleToken from "../utility/NonFungibleToken.cdc"

transaction(id: UInt64, name: String, description: String, thumbnail: String, metadata: {String: AnyStruct}) {
  let Minter: &LoveSpreads.NFTMinter
  prepare(signer: AuthAccount) {
    self.Minter = signer.borrow<&LoveSpreads.NFTMinter>(from: LoveSpreads.MinterStoragePath)
                    ?? panic("This is not the Minter account.")
  }

  execute {
    self.Minter.addNewTemplate(id: id, name: name, description: description, thumbnail: thumbnail, metadata: metadata)
  }
}