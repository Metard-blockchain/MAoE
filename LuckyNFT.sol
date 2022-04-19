pragma solidity ^0.8.0;

import "./NFTCollection.sol";
import "./Token.sol";

contract LuckyNFT is Ownable{
    mapping(address => uint256) private luckyWallet;
    mapping(address => uint256) private adminlist;
    mapping(uint256 => uint256) private countRarity;
    mapping(uint256 => uint256) private maxRarity;
    mapping(address => uint256) private userLuckyNFT;

    uint256 private maxLuckyNFT = 1000;
    uint256 private totalLuckyNFT = 0;
    uint256 private userMaxLuckyNFT = 5;

    uint256 private randNonce = 0;
    uint256 private status = 1;
    uint256 private whitelistTime = 1;
    address private tokenAddress;
    address private addressReceiver;
    uint256 private luckyNFTPrice;

    NFTCollection nftCollection;
    MAoE MATK;

    constructor(
        address _tokenAddress,
        address _nftCollection,
        address[] memory accounts,
        uint256[] memory numofNFT,
        address _addressReceiver,
        uint256 _luckyNFTPrice
    ) {
        adminlist[msg.sender] = 1;
        tokenAddress = _tokenAddress;
        nftCollection = NFTCollection(_nftCollection);
        addressReceiver = _addressReceiver;
        luckyNFTPrice = _luckyNFTPrice * 10**18;
        for (uint256 i = 0; i < accounts.length; i++) {
            luckyWallet[accounts[i]] = numofNFT[i];
        }
        maxRarity[4] = 0;
        maxRarity[3] = 5;
        maxRarity[2] = 50;
        maxRarity[1] = 300;
        maxRarity[0] = 645;
        maxLuckyNFT =
            maxRarity[4] +
            maxRarity[3] +
            maxRarity[2] +
            maxRarity[1] +
            maxRarity[0];
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

    modifier onlyLuckyWallet(address wallet) {
        require(luckyWallet[wallet] > 0, "Only Lucky Wallet");
        _;
    }

    modifier eventGoingOn() {
        require(status == 1, "This feature has been stopped!");
        _;
    }

    function random(uint256 scale) internal returns (uint256) {
        uint256 randomNumber= uint256(keccak256(abi.encodePacked(blockhash(block.number-1), randNonce, block.timestamp, block.difficulty, gasleft()))) % scale;
        randNonce++;
        return randomNumber;
    }

    modifier overMaxNFT() {
        require(totalLuckyNFT < maxLuckyNFT, "Run out of lucky box");
        _;
    }

    modifier userMaxLuckyBox(address user) {
        require(userLuckyNFT[user] < userMaxLuckyNFT, "Run out of lucky box");
        _;
    }

    modifier userRemainingBox(address user, uint256 amount) {
        require(
            amount <= userMaxLuckyNFT - userLuckyNFT[user],
            "Exceed the remaining box"
        );
        _;
    }

    // modifier onlyNonContractCall (){
    //     require(msg.sender == tx.origin, "Only non contract call");
    //     _;
    // }

    /* 
================================================================
                        GET LUCKY NFT
================================================================
 */

    function getLuckyNFT(uint256 numNFT)
        public
        userRemainingBox(msg.sender, numNFT)
        returns (uint256[] memory)
    {
        address user = msg.sender;
        if (whitelistTime == 1) {
            uint256[] memory res = openBatchLuckyNFTv1(user, numNFT);
            return res;
        } else {
            uint256[] memory res = openBatchLuckyNFTv2(user, numNFT);
            return res;
        }
    }

    function openBatchLuckyNFTv1(address user, uint256 numNFT)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory listLuckyNFT = new uint256[](numNFT);
        for (uint256 i = 0; i < numNFT; i++) {
            uint256 res = openLuckyNFTv1(user);
            if (res != 0) {
                listLuckyNFT[i] = res;
            }
        }
        return listLuckyNFT;
    }

    function openBatchLuckyNFTv2(address user, uint256 numNFT)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory listLuckyNFT = new uint256[](numNFT);
        for (uint256 i = 0; i < numNFT; i++) {
            uint256 res = openLuckyNFTv2(user);
            if (res != 0) {
                listLuckyNFT[i] = res;
            }
        }
        return listLuckyNFT;
    }

    function openLuckyNFTv1(address recipient)
        internal
        overMaxNFT
        onlyLuckyWallet(recipient)
        eventGoingOn
        returns (uint256)
    {
        uint256 _type = random(5) + 1;
        uint256 _rarity = random(5);

        uint256 temp = 0;

        while (countRarity[_rarity] >= maxRarity[_rarity]) {
            _rarity = random(5);
            temp++;
            if (temp > 10 && countRarity[_rarity] >= maxRarity[_rarity]) {
                return 0;
            }
        }
        string memory _tokenURI = nftCollection.getTokenURI(_type, _rarity);
        MATK = MAoE(tokenAddress);
        MATK.transferFrom(recipient, addressReceiver, luckyNFTPrice);
        uint256 res = nftCollection.mintNFT(
            recipient,
            _tokenURI,
            _type,
            _rarity
        );
        luckyWallet[recipient] -= 1;
        userLuckyNFT[recipient]++;
        totalLuckyNFT++;
        countRarity[_rarity]++;

        emit LuckyNFTOpened(recipient, recipient, _tokenURI);
        return res;
    }

    function openLuckyNFTv2(address recipient)
        internal
        overMaxNFT
        userMaxLuckyBox(recipient)
        eventGoingOn
        returns (uint256)
    {
        uint256 _type = random(5) + 1;
        uint256 _rarity = random(5);

        uint256 temp = 0;
        while (countRarity[_rarity] >= maxRarity[_rarity]) {
            _rarity = random(5);
            temp++;
            if (temp > 10 && countRarity[_rarity] >= maxRarity[_rarity]) {
                return 0;
            }
        }
        string memory _tokenURI = nftCollection.getTokenURI(_type, _rarity);
        MATK = MAoE(tokenAddress);
        MATK.transferFrom(recipient, addressReceiver, luckyNFTPrice);
        uint256 res = nftCollection.mintNFT(
            recipient,
            _tokenURI,
            _type,
            _rarity
        );
        userLuckyNFT[recipient]++;
        totalLuckyNFT++;
        countRarity[_rarity]++;

        emit LuckyNFTOpened(recipient, recipient, _tokenURI);
        return res;
    }

    /* 
================================================================
                ADD TO/REMOVE FROM LIST LUCKY WALLET
================================================================
 */
    function addToLuckyWallet(address wallet, uint256 numNFT) public onlyAdmin {
        luckyWallet[wallet] = numNFT;
        emit LuckyWalletAdded(msg.sender, wallet, numNFT);
    }

    function removeFromLuckyWallet(address wallet) public onlyAdmin {
        luckyWallet[wallet] = 0;
        emit LuckyWalletRemoved(msg.sender, wallet);
    }

    /* 
================================================================
                        UPDATE FUNCTION
================================================================
 */

    function changeTokenAddress(address _token) public onlyAdmin {
        tokenAddress = _token;
    }

    function changeLuckyNFTPrice(uint256 _luckyNFTPrice) public onlyAdmin {
        luckyNFTPrice = _luckyNFTPrice * 10**18;
    }

    function changeMaxRarity(
        uint256 legendary,
        uint256 ultraRare,
        uint256 superRare,
        uint256 rare,
        uint256 common
    ) public onlyAdmin {
        maxRarity[4] = legendary;
        maxRarity[3] = ultraRare;
        maxRarity[2] = superRare;
        maxRarity[1] = rare;
        maxRarity[0] = common;
    }

    function changeAddressReceiver (address _address) public onlyAdmin {
        addressReceiver = _address;
    }

    /* 
================================================================
                        GET FUNCTION
================================================================
 */

    function getTotalLuckyNFT() public view returns (uint256) {
        return totalLuckyNFT;
    }

    function getMaxLuckyNFT() public view returns (uint256) {
        return maxLuckyNFT;
    }

    function getUserLuckyNFT(address user) public view returns (uint256) {
        return userLuckyNFT[user];
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

    function stopWhiteListTime() public onlyAdmin {
        whitelistTime = 0;
    }

    function startWhiteListTime() public onlyAdmin {
        whitelistTime = 1;
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
    event LuckyWalletAdded(address user, address wallet, uint256 numNFT);
    event LuckyWalletRemoved(address user, address wallet);
    event LuckyNFTOpened(address user, address recipient, string tokenURI);
    event EventStarted(address user, uint256 status);
    event EventStopped(address user, uint256 status);
    event WithDraw(uint256 amount);
}
