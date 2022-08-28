/* 
*
*  This is an example implementation of a Flow Non-Fungible Token
*  It is not part of the official standard but it assumed to be
*  similar to how many NFTs would implement the core functionality.
*
*  This contract does not implement any sophisticated classification
*  system for its NFTs. It defines a simple NFT with minimal metadata.
*   
*/

import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"

pub contract LoveSpreads: NonFungibleToken {

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, by: Address, name: String, description: String, thumbnail: String)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    pub struct NFTMetadata {
      pub let name: String
      pub let description: String
      pub let thumbnail: String
      access(self) let metadata: {String: AnyStruct}

      init(
        name: String,
        description: String,
        thumbnail: String,
        metadata: {String: AnyStruct}
      ) {
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.metadata = metadata
      }
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let sequence: UInt64
        pub var metadata: NFTMetadata
    
        pub fun getViews(): [Type] {
          return [
            Type<MetadataViews.Display>()
          ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
          let template = self.getMetadata()
          switch view {
            case Type<MetadataViews.Display>():
              return MetadataViews.Display(
                name: template.name,
                description: template.description,
                thumbnail: MetadataViews.HTTPFile(
                  url: template.thumbnail
                )
              )
          }
          return nil
        }

        pub fun getMetadata(): NFTMetadata {
          return self.metadata
        }

        access(contract) fun updateMetadata(newMetadata: NFTMetadata) {
          self.metadata = newMetadata
        }

        init(metadata: NFTMetadata) {
          self.id = self.uuid
          self.sequence = LoveSpreads.totalSupply
          self.metadata = metadata
          LoveSpreads.totalSupply = LoveSpreads.totalSupply + 1
        }
    }

    pub resource interface CollectionPublic {
      pub fun deposit(token: @NonFungibleToken.NFT)
      pub fun getIDs(): [UInt64]
      pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
      pub fun borrowAuthNFT(id: UInt64): &LoveSpreads.NFT? {
        post {
            (result == nil) || (result?.id == id):
                "Cannot borrow LoveSpreads reference: the ID of the returned reference is incorrect"
        }
      }
    }

    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
      // dictionary of NFT conforming tokens
      // NFT is a resource type with an `UInt64` ID field
      pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

      // withdraw removes an NFT from the collection and moves it to the caller
      pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
        let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

        emit Withdraw(id: token.id, from: self.owner?.address)

        return <-token
      }

      // deposit takes a NFT and adds it to the collections dictionary
      // and adds the ID to the id array
      pub fun deposit(token: @NonFungibleToken.NFT) {
        let token <- token as! @LoveSpreads.NFT

        let id: UInt64 = token.id

        // add the new token to the dictionary which removes the old one
        let oldToken <- self.ownedNFTs[id] <- token

        emit Deposit(id: id, to: self.owner?.address)

        destroy oldToken
      }

      // getIDs returns an array of the IDs that are in the collection
      pub fun getIDs(): [UInt64] {
        return self.ownedNFTs.keys
      }

      // borrowNFT gets a reference to an NFT in the collection
      // so that the caller can read its metadata and call its methods
      pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
        return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
      }

      pub fun borrowAuthNFT(id: UInt64): &LoveSpreads.NFT? {
        if self.ownedNFTs[id] != nil {
          // Create an authorized reference to allow downcasting
          let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
          return ref as! &LoveSpreads.NFT
        }

        return nil
      }

      pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
        let token = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        let nft = token as! &LoveSpreads.NFT
        return nft as &AnyResource{MetadataViews.Resolver}
      }

      init () {
        self.ownedNFTs <- {}
      }

      destroy() {
          destroy self.ownedNFTs
      }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
      return <- create Collection()
    }

    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource Administrator {
      pub fun mintNFT(
        recipient: &Collection{NonFungibleToken.Receiver}, 
        name: String, 
        description: String, 
        thumbnail: String, 
        metadata: {String: AnyStruct}
      ) {
        let nft <- create NFT(metadata: NFTMetadata(name: name, description: description, thumbnail: thumbnail, metadata: metadata))
        emit Minted(id: nft.id, by: self.owner!.address, name: name, description: description, thumbnail: thumbnail)
        recipient.deposit(token: <- nft)
      }

      pub fun updateMetadata(
        id: UInt64, 
        currentOwner: Address, 
        name: String, 
        description: String, 
        thumbnail: String, 
        metadata: {String: AnyStruct}
      ) {
        let newMetadata = NFTMetadata(name: name, description: description, thumbnail: thumbnail, metadata: metadata)

        let ownerCollection = getAccount(currentOwner).getCapability(LoveSpreads.CollectionPublicPath)
                                .borrow<&Collection{CollectionPublic}>()
                                ?? panic("This person does not have a LoveSpreads Collection set up properly.")
        let nftRef = ownerCollection.borrowAuthNFT(id: id) ?? panic("This account does not own an NFT with this id.")
        nftRef.updateMetadata(newMetadata: newMetadata)
      }
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = /storage/LoveSpreadsCollection
        self.CollectionPublicPath = /public/LoveSpreadsCollection
        self.MinterStoragePath = /storage/LoveSpreadsMinter

        // Create a Minter resource and save it to storage
        let minter <- create Administrator()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}