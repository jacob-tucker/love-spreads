import LoveSpreads from "../LoveSpreads.cdc"
import NonFungibleToken from "../utility/NonFungibleToken.cdc"

transaction(ids: [UInt64], names: [String], descriptions: [String], thumbnails: [String], metadatas: [{String: AnyStruct}]) {
  let Minter: &LoveSpreads.Administrator
  prepare(signer: AuthAccount) {
    self.Minter = signer.borrow<&LoveSpreads.Administrator>(from: LoveSpreads.MinterStoragePath)
                    ?? panic("This is not the Minter account.")
  }

  pre {
    ids.length == names.length &&
    names.length == descriptions.length &&
    descriptions.length == thumbnails.length &&
    thumbnails.length == metadatas.length:
      "You must pass in the same amount of ids, names, descriptions, thumbnails, and metadatas."
  }

  execute {
    var i = 0
    while i < ids.length {
      self.Minter.addNewTemplate(id: ids[i], name: names[i], description: descriptions[i], thumbnail: thumbnails[i], metadata: metadatas[i])
      i = i + 1
    }
  }
}