// SPDX-License-Identifier: UNLICENSED

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title Beningin
 * @author Great Adams
 *
 */

contract Beningin is ReentrancyGuard, Ownable {
    /////////////////////
    // Errors //
    /////////////////////

    error Beningin__ZeroNFT();
    error Beningin__NotEqualScriptPrice();
    error Beningin__UnclaimedReward();
    error Beningin__BuyScriptUnSuccessful();
    error Beningin__ScriptExist();
    error Beningin__RewardTransferFailed();
    error Beningin__RewardNotReady();
    error Beningin__NotAllowedToken();

    /////////////////////
    // State variables //
    /////////////////////

    using Counters for Counters.Counter;

    Counters.Counter private _scriptIds;

    struct PlayerScript {
        uint256 scriptId;
        uint256 tokenId;
        uint256 lifeSpan;
        uint256 purchaseTimeStamp;
        uint256 reward;
    }

    struct Script {
        uint256 scriptId;
        string name;
        uint256 lifeSpan;
        uint256 price;
        uint256 reward;
    }

    uint256 private constant TWENTY_FOUR_HOURS = 86400;
    mapping(address user => mapping(uint256 scriptId => PlayerScript playerScript)) private s_playerScripts;

    Script[] private s_scripts;

    address private immutable i_qlipToken;
    address private immutable i_nftAddress;

    /////////////////////
    // Events        ///
    ////////////////////

    event ScriptItemCreated(
        uint256 indexed scriptId, string indexed name, uint256 indexed lifeSpan, uint256 price, uint256 reward
    );
    event purchasedScript(address indexed _from, uint256 indexed scriptId, uint256 indexed price);

    /////////////////////
    // Modifiers      ///
    /////////////////////

    modifier hasNft(uint256 id) {
        uint256 bal = IERC1155(i_nftAddress).balanceOf(msg.sender, id);
        if (bal <= 0) {
            revert Beningin__ZeroNFT();
        }
        _;
    }

    modifier NotAllowedToken(address token) {
        
        if (token != address(i_qlipToken)) {
            revert Beningin__NotAllowedToken();
        }
        _;
    }

    /////////////////////
    // Functions       //
    /////////////////////
    constructor(address _qlipToken, address _nftAddress) {
        i_qlipToken = _qlipToken;
        i_nftAddress = _nftAddress;
    }

    ////////////////////////
    // External Functions //
    ///////////////////////

    function createScript(string memory name, uint256 lifeSpan, uint256 price, uint256 reward) external onlyOwner {
        _scriptIds.increment();
        uint256 scriptId = _scriptIds.current();

        Script memory script = Script(scriptId, name, lifeSpan, price, reward);

        s_scripts.push(script);

        emit ScriptItemCreated(scriptId, name, lifeSpan, price, reward);
    }

    // Verify that a player has our NFT
    // buy scripts
    function buyScript(uint256 tokenId, uint256 scriptId, address token) external payable nonReentrant hasNft(tokenId) NotAllowedToken(token) {
        // Find script
        Script memory script = getScript(scriptId);

        // check if user already has the script
        PlayerScript storage playerScript = s_playerScripts[msg.sender][scriptId];

        // Script Amount
        uint256 amount = script.price * 1e18;

        if (playerScript.scriptId == scriptId) {
            // check if user has unclaimed rewards
            if (playerScript.lifeSpan > 0) {
                revert Beningin__UnclaimedReward();
            }

            playerScript.lifeSpan = script.lifeSpan;
            playerScript.purchaseTimeStamp = block.timestamp;
            playerScript.reward = script.reward;

            bool success = IERC20(i_qlipToken).transferFrom(msg.sender, address(this), amount);

            if (!success) {
                revert Beningin__BuyScriptUnSuccessful();
            }

            emit purchasedScript(msg.sender, scriptId, script.price);
        } else {
            uint256 lifeSpan = script.lifeSpan;
            uint256 purchaseTimeStamp = block.timestamp;
            uint256 reward = script.reward;
            s_playerScripts[msg.sender][scriptId] = PlayerScript(scriptId, tokenId, lifeSpan, purchaseTimeStamp, reward);

            bool success = IERC20(i_qlipToken).transferFrom(msg.sender, address(this), amount);

            if (!success) {
                revert Beningin__BuyScriptUnSuccessful();
            }

            emit purchasedScript(msg.sender, scriptId, script.price);
        }
    }

    function claimRewards(address player, uint256 scriptId) external payable nonReentrant returns (bool) {
        PlayerScript memory playerScript = s_playerScripts[player][scriptId];

        uint256 playerReward = playerScript.reward * 1e18;
        uint256 duration = calculateDuration(playerScript.lifeSpan);

        uint256 elapsedTimeMinutes = (block.timestamp - playerScript.purchaseTimeStamp) / 60;

        s_playerScripts[player][scriptId].lifeSpan = 0;
        s_playerScripts[player][scriptId].reward = 0;
        s_playerScripts[player][scriptId].purchaseTimeStamp = 0;
        s_playerScripts[player][scriptId].tokenId = 0;

        if (elapsedTimeMinutes >= duration) {
            bool success = IERC20(i_qlipToken).transfer(msg.sender, playerReward);
            if (!success) {
                revert Beningin__RewardTransferFailed();
            }
            return success;
        } else {
            revert Beningin__RewardNotReady();
        }
    }

    ///////////////////////////
    // Public view Functions //
    //////////////////////////

    function getScripts() public view returns (Script[] memory) {
        Script[] memory scripts = new Script[](s_scripts.length);

        for (uint256 i = 0; i < s_scripts.length; i++) {
            scripts[i] = s_scripts[i];
        }

        return scripts;
    }

    function getScript(uint256 scriptId) public view returns (Script memory script) {
        for (uint256 i = 0; i < s_scripts.length; i++) {
            if (s_scripts[i].scriptId == scriptId) {
                return s_scripts[i];
            }
        }
    }

    function calculatePlayerScriptRewards(address player, uint256 scriptId) public view returns (uint256 rewards) {
        PlayerScript memory playerScript = s_playerScripts[player][scriptId];

        uint256 playerReward = playerScript.reward;
        uint256 duration = calculateDuration(playerScript.lifeSpan);

        uint256 elapsedTimeMinutes = (block.timestamp - playerScript.purchaseTimeStamp) / 60;

        if (elapsedTimeMinutes >= duration) {
            return playerReward;
        } else {
            return (playerReward * elapsedTimeMinutes) / duration;
        }
    }

    /////////////////////////////
    // Internal pure Functions //
    ////////////////////////////

    function calculateDuration(uint256 lifeSpan) internal pure returns (uint256) {
        if (lifeSpan == 96) {
            return TWENTY_FOUR_HOURS * 4;
        } else if (lifeSpan == 72) {
            return TWENTY_FOUR_HOURS * 3;
        } else if (lifeSpan == 48) {
            return TWENTY_FOUR_HOURS * 2;
        } else {
            return TWENTY_FOUR_HOURS;
        }
    }
}
