# Love Spreads

## "What is a Template?"

A Template is basically a container for NFT Metadata. It contains a `name`, `description`, `thumbnail` (image hash), and `metadata` dictionary. Each NFT points to a Template for its metadata, and you can update this pointer at any time using the method below.

## How to Update Metadata

The account with the `Administrator` resource would use the `transactions/addNewTemplate.cdc` transaction to do this. You pass in the NFT's id (that you would get from Rarible events or something like that), and pass in a new name, description, thumbnail, and metadata dictionary. This will automatically point the NFT with the specific id to that new metadata.

## Events

