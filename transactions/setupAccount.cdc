import NonFungibleToken from "../utility/NonFungibleToken.cdc"
import LoveSpreads from "../LoveSpreads.cdc"
import MetadataViews from "../utility/MetadataViews.cdc"

/// This transaction is what an account would run
/// to set itself up to receive NFTs
transaction {

    prepare(signer: AuthAccount) {
        // Return early if the account already has a collection
        if signer.borrow<&LoveSpreads.Collection>(from: LoveSpreads.CollectionStoragePath) != nil {
            return
        }

        // Create a new empty collection
        let collection <- LoveSpreads.createEmptyCollection()

        // save it to the account
        signer.save(<-collection, to: LoveSpreads.CollectionStoragePath)

        // create a public capability for the collection
        signer.link<&LoveSpreads.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, LoveSpreads.CollectionPublic, MetadataViews.ResolverCollection}>(
            LoveSpreads.CollectionPublicPath,
            target: LoveSpreads.CollectionStoragePath
        )
    }
}