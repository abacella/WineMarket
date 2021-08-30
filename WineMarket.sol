pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "WineAuction.sol";

contract WineMarket is ERC721Full, Ownable {

    constructor() ERC721Full("WineMarket", "VINO") public {}

    using Counters for Counters.Counter;
    Counters.Counter token_ids;
    
    struct Wine {
        string uri;
        //string name;
        //string variety; // type of wine/grape (cab sauv, pinot, etc.)
        //uint vintage;   // year                 
        //string producer; // string region;
        //uint quantity;
        //uint bottle_size; //750mL or larger
        //uint appraisal_value;
        //bool bottle_unopened; //True if unopened            
    }
    

    address payable seller_address = msg.sender;
    
    mapping(uint => Wine) public wine_inventory;

    mapping(uint => WineAuction) public auctions;

    modifier bottleRegistered(uint token_id) {
        require(_exists(token_id), "Wine bottle is not registered!");
        _;
    }

    function createAuction(uint token_id) public onlyOwner {
        auctions[token_id] = new WineAuction(seller_address);
    }

    function registerBottle(string memory uri) public payable onlyOwner {
        token_ids.increment();
        uint token_id = token_ids.current();
        _mint(seller_address, token_id);
        _setTokenURI(token_id, uri);
        createAuction(token_id);
    }

    function endAuction(uint token_id) public onlyOwner bottleRegistered(token_id) {
        WineAuction auction = auctions[token_id];
        auction.auctionEnd();
        safeTransferFrom(owner(), auction.highestBidder(), token_id);
    }

    function auctionEnded(uint token_id) public view returns(bool) {
        WineAuction auction = auctions[token_id];
        return auction.ended();
    }

    function highestBid(uint token_id) public view bottleRegistered(token_id) returns(uint) {
        WineAuction auction = auctions[token_id];
        return auction.highestBid();
    }

    function pendingReturn(uint token_id, address sender) public view bottleRegistered(token_id) returns(uint) {
        WineAuction auction = auctions[token_id];
        return auction.pendingReturn(sender);
    }

    function bid(uint token_id) public payable bottleRegistered(token_id) {
        WineAuction auction = auctions[token_id];
        auction.bid.value(msg.value)(msg.sender);
    }

}
