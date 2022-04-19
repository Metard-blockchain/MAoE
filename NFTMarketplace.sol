// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollection.sol";
import "./Token.sol";

contract NFTMarketplace is Ownable{
    mapping(address => uint256) private adminlist;

    uint256 public offerCount = 0;
    mapping(uint256 => _Offer) public offers;
    mapping(address => uint256) public userFunds;
    mapping(address => uint256[]) public offerListByAddress;
    mapping(uint256 => uint256) public TokenIndex;
    mapping(uint256 => uint256) public offerIndex;
    mapping(uint256 => uint256) public tokenIdToOffer;
    address private tokenAddress;

    uint256[] offerList;
    uint256 private feeRate = 1000;
    address addressFeeReceive;
    uint256 private status = 1;
    MAoE MATK;

    NFTCollection nftCollection;
    struct _Offer {
        uint256 offerId;
        uint256 id;
        address user;
        uint256 price;
        bool fulfilled;
        bool cancelled;
    }

    constructor(
        address _nftCollection,
        address _tokenAddress,
        address _addressFeeReceive
    ) {
        nftCollection = NFTCollection(_nftCollection);
        tokenAddress = _tokenAddress;
        addressFeeReceive = _addressFeeReceive;
    }

    /* 
================================================================
                            MODIFIERS
================================================================
 */

    modifier onlyAdmin() {
        require(adminlist[msg.sender] == 1, "OnlyAdmin");
        _;
    }

    modifier eventGoingOn() {
        require(status == 1, "This feature has been stopped!");
        _;
    }

    modifier priceGreaterThanZero(uint256 price) {
        require(price > 0, "Price must be greater than 0!");
        _;
    }

    /* 
================================================================
                        CHECK FUNCTION
================================================================
 */

    function checkTokenIndex(uint256 tokenId) public view returns (uint256) {
        return TokenIndex[tokenId];
    }

    function checkOfferIndex(uint256 tokenId) public view returns (uint256) {
        return offerIndex[tokenId];
    }

    /* 
================================================================
                    MAKE OFFER TO SELL FUNCTION
================================================================
 */

    function makeOffer(uint256 _id, uint256 _price)
        public
        eventGoingOn
        priceGreaterThanZero(_price)
    {
        bool check_double = true;
        uint256 check_order = tokenIdToOffer[_id];
        if (check_order != 0) {
            _Offer storage _offer = offers[check_order];
            check_double = _offer.fulfilled || _offer.cancelled;
        }
        require(check_double, "This TokenId has been offered!");
        nftCollection.transferFrom(msg.sender, address(this), _id);
        offerCount++;
        offers[offerCount] = _Offer(
            offerCount,
            _id,
            msg.sender,
            _price,
            false,
            false
        );
        tokenIdToOffer[_id] = offerCount;
        uint256 arrayLength = offerListByAddress[msg.sender].length;
        TokenIndex[_id] = arrayLength;
        offerListByAddress[msg.sender].push(_id);
        uint256 offerLength = offerList.length;
        offerIndex[_id] = offerLength;
        offerList.push(_id);
        // emit Offer(offerCount, _id, msg.sender, _price, false, false);
    }

    /* 
================================================================
                            BUY NFT
================================================================
 */

    function fillOffer(uint256 _offerId, uint256 amount) public {
        _Offer storage _offer = offers[_offerId];
        require(_offer.offerId == _offerId, "The offer must exist");
        require(
            _offer.user != msg.sender,
            "The owner of the offer cannot fill it"
        );
        require(!_offer.fulfilled, "An offer cannot be fulfilled twice");
        require(!_offer.cancelled, "A cancelled offer cannot be fulfilled");
        require(
            amount == _offer.price,
            "The MAoE amount should match with the NFT Price"
        );
        nftCollection.transferFrom(address(this), msg.sender, _offer.id);
        MATK = MAoE(tokenAddress);
        if (feeRate > 0) {
            uint256 _fee = (amount * feeRate) / 10000;
            MATK.transferFrom(msg.sender, addressFeeReceive, _fee);
            amount = amount - _fee;
        }
        MATK.transferFrom(msg.sender, _offer.user, amount);
        _offer.fulfilled = true;

        uint256 token_index = checkTokenIndex(_offer.id);
        uint256 len = offerListByAddress[_offer.user].length;
        if (len == 1) {
            offerListByAddress[_offer.user].pop();
        } else {
            uint256 token_pop = offerListByAddress[_offer.user][len - 1];
            offerListByAddress[_offer.user][token_index] = token_pop;
            offerListByAddress[_offer.user].pop();
            TokenIndex[token_pop] = token_index;
        }

        uint256 offer_index = checkOfferIndex(_offer.id);
        uint256 offerlen = offerList.length;
        if (offerlen == 1) {
            offerList.pop();
        } else {
            uint256 offer_pop = offerList[offerlen - 1];
            offerList[offer_index] = offer_pop;
            offerList.pop();
            offerIndex[offer_pop] = offer_index;
        }

        tokenIdToOffer[_offer.id] = 0;
        // userFunds[_offer.user] += msg.value;
        emit OfferFilled(_offerId, _offer.id, msg.sender);
    }

    /* 
================================================================
                    CANCEL OFFER FUNCTION
================================================================
 */

    function cancelOffer(uint256 _offerId) public {
        _Offer storage _offer = offers[_offerId];
        require(_offer.offerId == _offerId, "The offer must exist");
        require(
            _offer.user == msg.sender,
            "The offer can only be canceled by the owner"
        );
        require(
            _offer.fulfilled == false,
            "A fulfilled offer cannot be cancelled"
        );
        require(
            _offer.cancelled == false,
            "An offer cannot be cancelled twice"
        );
        nftCollection.transferFrom(address(this), msg.sender, _offer.id);
        _offer.cancelled = true;
        uint256 token_index = checkTokenIndex(_offer.id);
        uint256 len = offerListByAddress[msg.sender].length;
        if (len == 1) {
            offerListByAddress[msg.sender].pop();
        } else {
            uint256 token_pop = offerListByAddress[msg.sender][len - 1];
            offerListByAddress[msg.sender][token_index] = token_pop;
            offerListByAddress[msg.sender].pop();
            TokenIndex[token_pop] = token_index;
        }

        uint256 offer_index = checkOfferIndex(_offer.id);
        uint256 offerlen = offerList.length;
        if (offerlen == 1) {
            offerList.pop();
        } else {
            uint256 offer_pop = offerList[offerlen - 1];
            offerList[offer_index] = offer_pop;
            offerList.pop();
            offerIndex[offer_pop] = offer_index;
        }
        tokenIdToOffer[_offer.id] = 0;
        emit OfferCancelled(_offerId, _offer.id, msg.sender);
    }

    /* 
================================================================
                        GET - SET FUNCTION
================================================================
 */

    function getNFTOfferList() public view returns (uint256[] memory) {
        return offerList;
    }

    function getNFTOfferListByUser(address user)
        public
        view
        returns (uint256[] memory)
    {
        return offerListByAddress[user];
    }

    function getOfferId(uint256 TokenId) public view returns (uint256) {
        return tokenIdToOffer[TokenId];
    }

    function getOfferPrice(uint256 TokenId) public view returns (uint256) {
        uint256 OfferId = getOfferId(TokenId);
        _Offer storage _offer = offers[OfferId];
        return _offer.price;
    }

    function getFeeRate() public view returns (uint256) {
        return feeRate;
    }

    function changeAddressFeeReceiver (address _address) public onlyAdmin {
        addressFeeReceive = _address;
    }

    /* 
================================================================
                        OPEN/CLOSE EVENT
================================================================
 */
    function startEvent() public onlyAdmin {
        status = 1;
        emit EventStarted(msg.sender, status);
    }

    function stopEvent() public onlyAdmin {
        status = 0;
        emit EventStopped(msg.sender, status);
    }

    function changeTokenAddress(address _token) public onlyAdmin {
        tokenAddress = _token;
    }
/*
================================================================
                        WITHDRAW
 ================================================================
 */
    function withdrawTokenForOwner(uint256 amount) public onlyOwner {
        MATK = MAoE(tokenAddress);
        MATK.transfer(owner(), amount);
        emit WithDraw(amount);
    }

    function withdrawBUSDForOwner(address token_address, uint256 amount)
        public
        onlyOwner
    {
        IERC20 busd = IERC20(token_address);
        busd.transfer(owner(), amount);
        emit WithDraw(amount);
    }
    /* 
================================================================
                            EVENT
================================================================
*/
    event Offer(
        uint256 offerId,
        uint256 id,
        address user,
        uint256 price,
        bool fulfilled,
        bool cancelled
    );
    event OfferFilled(uint256 offerId, uint256 id, address newOwner);
    event OfferCancelled(uint256 offerId, uint256 id, address owner);
    event ClaimFunds(address user, uint256 amount);
    event DonateEvent(address user, uint256 amount);
    event EventStarted(address user, uint256 status);
    event EventStopped(address user, uint256 status);
    event WithDraw(uint256 amount);


    fallback() external {
        revert();
    }
}
