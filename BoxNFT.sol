//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";
import "./NFTCollection.sol";

contract BoxNFT is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    NFTCollection nftCollection;
    mapping(address => uint256) private adminlist;
    mapping(address => uint256) private blacklist;
    mapping(uint256 => uint256) private countRarity;
    mapping(uint256 => uint256) private maxRarity;

    uint256 randNonce = 0;
    uint256 private status = 1;

    uint256 private legendaryThreshold = 999;
    uint256 private ultraRareThreshold = 995;
    uint256 private superRareThreshold = 950;
    uint256 private rareThreshold = 800;
    uint256 private commonThreshold = 0;

    MAoE MATK;

    constructor(address _nftCollection) public {
        adminlist[msg.sender] = 1;
        adminlist[address(this)] = 1;
        nftCollection = NFTCollection(_nftCollection);

        maxRarity[4] = 1;
        maxRarity[3] = 10;
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

    modifier isNotAddressZero(address account) {
        require(account != address(0), "ERC20: transfer from the zero address");
        _;
    }
    modifier eventGoingOn() {
        require(status == 1, "This feature has been stopped!");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    modifier onlyNonContractCall (){
        require(msg.sender == tx.origin, "Only non contract call");
        _;
    }

    function random(uint256 scale) internal returns (uint256) {
        uint256 randomNumber= uint256(keccak256(abi.encodePacked(blockhash(block.number-1), randNonce, block.timestamp, block.difficulty, gasleft()))) % scale;
        randNonce++;
        return randomNumber;
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

    function getNFT(
        address recipient,
        uint256 _type,
        uint256 _rarity
    ) internal returns (uint256) {
        string memory _tokenURI = nftCollection.getTokenURI(_type, _rarity);
        if (_rarity == 4 || _rarity == 3) {
            countRarity[_rarity]++;
        } else if (_rarity == 5) {
            return 0;
        }
        uint256 res = nftCollection.mintNFTByBox(
            recipient,
            _tokenURI,
            _type,
            _rarity
        );
        return res;
    }

    function isRarity(uint256 randomNumber) internal view returns (uint256) {
        if (randomNumber < rareThreshold) {
            return 0;
        } else if (randomNumber < superRareThreshold) {
            return 1;
        } else if (randomNumber < ultraRareThreshold) {
            return 2;
        } else if (randomNumber < legendaryThreshold) {
            return 3;
        } else {
            return 4;
        }
    }

    function openBox()
        public
        onlyNonContractCall
        isNotInBlackList(msg.sender)
        eventGoingOn
        returns (uint256)
    {
        address recipient = msg.sender;
        uint256 randomNumber = random(1000);
        uint256 _type = random(5) + 1;
        uint256 _rarity = isRarity(randomNumber);
        if (_rarity == 4 || _rarity == 3) {
            uint256 temp = 0;
            while (countRarity[_rarity] >= maxRarity[_rarity]) {
                randomNumber = random(1000);
                _rarity = isRarity(randomNumber);
                if (_rarity != 4 && _rarity != 3) {
                    break;
                }
                temp++;
                if (temp > 10 && countRarity[_rarity] >= maxRarity[_rarity]) {
                    return 0;
                }
            }

            // for (uint256 i = 0; i < 11; i++) {
            //     randomNumber = random(1000);
            //     _rarity = isRarity(randomNumber);
            //     if (_rarity != 4 && _rarity != 3) {
            //         break;
            //     }
            //     if (countRarity[_rarity] < maxRarity[_rarity]) {
            //         break;
            //     }
            //     _rarity = 5;
            // }
        }
        uint256 res = getNFT(recipient, _type, _rarity);
        return res;
    }

    /* 
================================================================
                        ADMIN CHANGE THRESHOLD
================================================================
 */

    function adminChangeThreshold(
        uint256 _legendary,
        uint256 _ultrarare,
        uint256 _superrare,
        uint256 _rare,
        uint256 _common
    ) public onlyAdmin {
        legendaryThreshold = _legendary;
        ultraRareThreshold = _ultrarare;
        superRareThreshold = _superrare;
        rareThreshold = _rare;
        commonThreshold = _common;
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
    event EventStarted(address user, uint256 status);
    event EventStopped(address user, uint256 status);
}
