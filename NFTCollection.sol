//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Token.sol";

contract NFTCollection is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => uint256) private adminlist;
    mapping(address => uint256) private blacklist;

    mapping(address => uint256[]) public nftListByAddress;
    mapping(uint256 => uint256) public TokenIndex;
    mapping(address => uint256) public userNumberBox;
    mapping(address => uint256) public userNumberNFT;

    mapping(uint256 => uint256) public rarityOfTokenId;
    mapping(uint256 => uint256) public typeOfTokenId;

    mapping(uint256 => mapping(uint256 => string)) public tokenURI;

    address private tokenAddress;
    address private addressReceiver;
    uint256 boxPrice;
    uint256 userMaxBox = 50;
    uint256 userMaxNFT = 20;
    uint256 status = 0;

    MAoE MATK;

    constructor(
        address _tokenAddress,
        uint256 _boxPrice,
        address _addressReceiver,
        string[][] memory _tokenURI
    ) public ERC721("MAoE", "Cyborgs") {
        addressReceiver = _addressReceiver;
        adminlist[msg.sender] = 1;
        tokenAddress = _tokenAddress;
        boxPrice = _boxPrice * 10**18;

        tokenURI[1][0] = _tokenURI[0][0];
        tokenURI[1][1] = _tokenURI[0][1];
        tokenURI[1][2] = _tokenURI[0][2];
        tokenURI[1][3] = _tokenURI[0][3];
        tokenURI[1][4] = _tokenURI[0][4];

        tokenURI[2][0] = _tokenURI[1][0];
        tokenURI[2][1] = _tokenURI[1][1];
        tokenURI[2][2] = _tokenURI[1][2];
        tokenURI[2][3] = _tokenURI[1][3];
        tokenURI[2][4] = _tokenURI[1][4];

        tokenURI[3][0] = _tokenURI[2][0];
        tokenURI[3][1] = _tokenURI[2][1];
        tokenURI[3][2] = _tokenURI[2][2];
        tokenURI[3][3] = _tokenURI[2][3];
        tokenURI[3][4] = _tokenURI[2][4];

        tokenURI[4][0] = _tokenURI[3][0];
        tokenURI[4][1] = _tokenURI[3][1];
        tokenURI[4][2] = _tokenURI[3][2];
        tokenURI[4][3] = _tokenURI[3][3];
        tokenURI[4][4] = _tokenURI[3][4];

        tokenURI[5][0] = _tokenURI[4][0];
        tokenURI[5][1] = _tokenURI[4][1];
        tokenURI[5][2] = _tokenURI[4][2];
        tokenURI[5][3] = _tokenURI[4][3];
        tokenURI[5][4] = _tokenURI[4][4];

    }

    /* 
================================================================
                        LIST OF MODIFIERS
================================================================
 */
    modifier onlyAdmin() {
        require(adminlist[msg.sender] == 1, "OnlyAdmin");
        _;
    }

    modifier isNotInBlackList(address account) {
        require(!checkBlackList(account), "Revert blacklist");
        _;
    }
    modifier eventGoingOn() {
        require(status == 1, "This feature has been stopped!");
        _;
    }
    modifier isNotAddressZero(address account) {
        require(account != address(0), "ERC20: transfer from the zero address");
        _;
    }

    modifier avaiableBox(uint256 _totalBox) {
        require(_totalBox > 0, "You don't have enough box to mint");
        _;
    }

    modifier limitUserMaxBox(uint256 _totalBox) {
        require(
            _totalBox < userMaxBox,
            "You can not buy exceed total box limitation"
        );
        _;
    }

    modifier limitMaxNFT(uint256 _totalNFT) {
        require(
            _totalNFT < userMaxNFT,
            "You can not mint exceed total NFT limitation"
        );
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    /* 
================================================================
                        CHECK FUNCTION
================================================================
 */

    function checkAdmin(address account) public view returns (bool) {
        return adminlist[account] > 0;
    }

    function checkBlackList(address account) public view returns (bool) {
        return blacklist[account] > 0;
    }

    /* 
================================================================
                        MINT NFT
================================================================
 */
    function mintNFT(
        address recipient,
        string memory _tokenURI,
        uint256 _type,
        uint256 _rarity
    ) public onlyAdmin returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        uint256 arrayLength = nftListByAddress[recipient].length;
        TokenIndex[newItemId] = arrayLength;
        nftListByAddress[recipient].push(newItemId);
        userNumberNFT[recipient] += 1;
        rarityOfTokenId[newItemId] = _rarity;
        typeOfTokenId[newItemId] = _type;
        emit NFTMinted(
            msg.sender,
            recipient,
            newItemId,
            userNumberNFT[recipient]
        );
        return newItemId;
    }

    function mintNFTByBox(
        address recipient,
        string memory _tokenURI,
        uint256 _type,
        uint256 _rarity
    )
        external
        onlyAdmin
        avaiableBox(userNumberBox[recipient])
        limitMaxNFT(userNumberNFT[recipient])
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        uint256 arrayLength = nftListByAddress[recipient].length;
        TokenIndex[newItemId] = arrayLength;
        nftListByAddress[recipient].push(newItemId);
        userNumberBox[recipient] -= 1;
        userNumberNFT[recipient] += 1;
        rarityOfTokenId[newItemId] = _rarity;
        typeOfTokenId[newItemId] = _type;
        emit NFTByBoxMinted(
            msg.sender,
            recipient,
            newItemId,
            userNumberNFT[recipient],
            userNumberBox[recipient]
        );
        return newItemId;
    }

    /* 
================================================================
                            BOX NFT
================================================================
 */
    function buyBox()
        public
        isNotInBlackList(msg.sender)
        eventGoingOn
        limitUserMaxBox(userNumberBox[msg.sender])
    {
        MATK = MAoE(tokenAddress);
        MATK.transferFrom(msg.sender, addressReceiver, boxPrice);
        userNumberBox[msg.sender] += 1;
        emit BoxBuyed(msg.sender, userNumberBox[msg.sender]);
    }

    /* 

================================================================
                        ADMIN SET BOX NFT
================================================================
 */
    function adminSetBox(address user, uint256 num)
        public
        limitUserMaxBox(userNumberBox[user])
        onlyAdmin
    {
        userNumberBox[user] = num;
        emit BoxAdded(msg.sender, user, userNumberBox[user]);
    }

    /* 
================================================================
                        ADMIN ADD TOKEN URI
================================================================
 */

    function adminAddTokenId(
        uint256 _type,
        uint256 _rarity,
        string memory _tokenURI
    ) public onlyAdmin {
        tokenURI[_type][_rarity] = _tokenURI;
    }

    /* 
================================================================
                        CHANGE TOKEN ADDRESS
================================================================
 */

    function changeTokenAddress(address _token) public onlyAdmin {
        tokenAddress = _token;
    }

    function changeBoxPrice(uint256 _boxPrice) public onlyAdmin {
        boxPrice = _boxPrice * 10**18;
    }

    function changeAddressReceiver (address _address) public onlyAdmin {
        addressReceiver = _address;
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
                        GET - SET FUNCTION
================================================================
*/
    function getUserCollectionList(address user)
        public
        view
        returns (uint256[] memory)
    {
        return nftListByAddress[user];
    }

    function getUserNumberBox(address user) public view returns (uint256) {
        return userNumberBox[user];
    }

    function getUserNumberNFT(address user) public view returns (uint256) {
        return userNumberNFT[user];
    }

    function getRarityOfTokenId(uint256 tokenId) public view returns (uint256) {
        return rarityOfTokenId[tokenId];
    }

    function getTypeOfTokenId(uint256 tokenId) public view returns (uint256) {
        return typeOfTokenId[tokenId];
    }

    function getTokenURI(uint256 _type, uint256 _rarity)
        public
        view
        returns (string memory)
    {
        return tokenURI[_type][_rarity];
    }

    function getBoxPrice() public view returns (uint256) {
        return boxPrice;
    }

    function startEvent() public onlyAdmin {
        status = 1;
        emit EventStarted(msg.sender, status);
    }

    function stopEvent() public onlyAdmin {
        status = 0;
        emit EventStopped(msg.sender, status);
    }

    /* 
================================================================
                        TRANSFER
================================================================
*/
    function checkTokenIndex(uint256 tokenId) public view returns (uint256) {
        return TokenIndex[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        changeOwnerTokenID(from, to, tokenId);
        _transfer(from, to, tokenId);
    }

    function changeOwnerTokenID(
        address from,
        address to,
        uint256 tokenId
    ) public {
        uint256 token_index = checkTokenIndex(tokenId);
        uint256 len = nftListByAddress[from].length;
        if (len == 1) {
            nftListByAddress[from].pop();
        } else {
            uint256 token_pop = nftListByAddress[from][len - 1];
            nftListByAddress[from][token_index] = token_pop;
            nftListByAddress[from].pop();
            TokenIndex[token_pop] = token_index;
        }
        uint256 arrayLength = nftListByAddress[to].length;
        TokenIndex[tokenId] = arrayLength;
        nftListByAddress[to].push(tokenId);
        emit OwnerNFTChanged(from, to, tokenId);
    }

    /* 
================================================================
                        ADMIN LIST
================================================================
 */
    function addToAdminlist(address account) public onlyOwner {
        adminlist[account] = 1;
        emit AdminAdded(account);
    }

    function addBatchToAdminlist(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            adminlist[accounts[i]] = 1;
        }
        emit BatchAdminAdded(accounts);
    }

    function removeFromAdminlist(address account) public onlyOwner {
        adminlist[account] = 0;
        emit AdminRemoved(account);
    }

    /* 
================================================================
                        BLACK LIST
================================================================
 */

    function addToBlacklist(address account) public onlyOwner {
        blacklist[account] = 1;
        emit BlacklistAdded(account);
    }

    function addBatchToBlacklist(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklist[accounts[i]] = 1;
        }
        emit BatchBlacklistAdded(accounts);
    }

    function removeFromBlacklist(address account) public onlyOwner {
        blacklist[account] = 0;
        emit BlacklistRemoved(account);
    }

    /* 
================================================================
                            EVENT
================================================================
 */
    event BlacklistAdded(address account);
    event BatchBlacklistAdded(address[] accounts);
    event BlacklistRemoved(address account);

    event AdminAdded(address account);
    event BatchAdminAdded(address[] accounts);
    event AdminRemoved(address account);

    event OwnerNFTChanged(address from, address to, uint256 tokenID);
    event BoxBuyed(address user, uint256 numBox);
    event BoxAdded(address user, address wallet, uint256 numBox);
    event EventStarted(address user, uint256 status);
    event EventStopped(address user, uint256 status);
    event WithDraw(uint256 amount);


    event NFTMinted(
        address user,
        address wallet,
        uint256 tokenID,
        uint256 numNFT
    );
    event NFTByBoxMinted(
        address user,
        address wallet,
        uint256 tokenID,
        uint256 numNFT,
        uint256 numBox
    );
}
