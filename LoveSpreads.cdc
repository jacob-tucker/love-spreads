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

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    // Maps an NFT's sequential `id` to a series of Templates
    access(self) var evolutions: {UInt64: [Template]}

    pub struct Template {
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
    
        pub fun getViews(): [Type] {
          return [
            Type<MetadataViews.Display>()
          ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
          let template = self.getTemplate()
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

        pub fun getTemplate(): Template {
          return LoveSpreads.getTemplate(id: self.id)
        }

        init() {
          self.id = self.uuid
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
    pub resource NFTMinter {
      pub fun mintNFT(recipient: &Collection{NonFungibleToken.Receiver}) {
        recipient.deposit(token: <- create NFT())
      }

      pub fun addNewTemplate(id: UInt64, name: String, description: String, thumbnail: String, metadata: {String: AnyStruct}) {
        let newTemplate = Template(name: name, description: description, thumbnail: thumbnail, metadata: metadata)
        
        if LoveSpreads.evolutions[id] == nil {
          LoveSpreads.evolutions[id] = []
        }
        LoveSpreads.evolutions[id]!.append(newTemplate)
      }

      pub fun removeLastTemplate(id: UInt64) {
        LoveSpreads.evolutions[id]!.removeLast()
      }
    }

    pub fun getTemplate(id: UInt64): Template {
      let evolutions: [Template] = self.evolutions[id] ?? panic("An NFT with this id does not exist.")
      return evolutions[evolutions.length - 1]
    }

    pub fun getEvolutions(): {UInt64: [Template]} {
      return self.evolutions
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0
        self.evolutions = {}

        // Set the named paths
        self.CollectionStoragePath = /storage/LoveSpreadsCollection
        self.CollectionPublicPath = /public/LoveSpreadsCollection
        self.MinterStoragePath = /storage/LoveSpreadsMinter

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}