import LoveSpreads from "../LoveSpreads.cdc"

pub fun main(account: Address, id: UInt64,): String {
    let ownerCollection = getAccount(account).getCapability(LoveSpreads.CollectionPublicPath)
                                    .borrow<&LoveSpreads.Collection{LoveSpreads.CollectionPublic}>()
                                    ?? panic("This person does not have a LoveSpreads Collection set up properly.")
    let nftRef = ownerCollection.borrowAuthNFT(id: id) ?? panic("This account does not own an NFT with this id.")
    return nftRef.getMetadata().thumbnail
}