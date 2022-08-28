# Love Spreads

## Steps to Mint

1. `flow emulator start`
2. `flow project deploy`
3. `flow transactions send ./transactions/setupAccount.cdc`
4. `flow transactions send ./transactions/mintNFT.cdc 0xf8d6e0586b0a20c7 "Example Name" "Example Description" "Random CID" {}`

## How to Update Metadata

The account with the `Administrator` resource would use the `transactions/updateNFTMetadata.cdc` transaction to do this. You pass in the NFT's id (that you would get from Rarible events or something like that) as well as the current owner of the NFT, and pass in a new name, description, thumbnail, and metadata dictionary. This will automatically update the NFT owned by the current owner with the specific id to that new metadata.

## Events

There is a `Minted` event in the contract you can track to see when an NFT is initially minted. It looks like this: `pub event Minted(id: UInt64, by: Address, name: String, description: String, thumbnail: String)`
