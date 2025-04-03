// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title Trailium Token (TRLM)
 * @notice Trailium is the native utility token of the TRAILASAUR platform.
 * 
 * TRAILASAUR is a mountain biking app and community ecosystem that gamifies trail riding,
 * offering progression-based rewards, performance insights, leaderboards, and an in-app store.
 *
 * Trailium (TRLM) is used to:
 * - Reward users for ride performance, trail completions, and streaks
 * - Enable purchases in the TRAILASAUR store (gear, merch, digital content)
 * - Power the leaderboard and achievement systems
 * - Fuel community incentives and real-world events
 *
 * Features:
 * - Annual mint cap (5% of total supply per year)
 * - Role-based access control (MINTER_ROLE, BURNER_ROLE, ADMIN_ROLE)
 * - Burnable by authorized users
 * - No minting on deploy for decentralization readiness
 * 
 * Learn more: https://trailasaur.com
 * Token supply: 1,000,000,000 TRLM (18 decimals)
 * Symbol: TRLM
 */

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Trailium ERC-20 Token Contract (AccessControl-based)
contract TrailiumToken is ERC20, ERC20Burnable, AccessControl, ReentrancyGuard {

    uint256 public constant INITIAL_SUPPLY = 1e27; // 1B tokens with 18 decimals
    uint256 public constant MAX_ANNUAL_MINT = INITIAL_SUPPLY / 20; // 5%
    uint256 public constant SECONDS_IN_A_YEAR = 60 * 60 * 24 * 365;

    mapping(uint256 => uint256) private _annualMinted;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    event TokensMinted(uint256 indexed year, address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    constructor(address admin) ERC20("Trailium", "TRLM") {
        require(admin != address(0), "Admin cannot be zero");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(BURNER_ROLE, admin);

        _mint(admin, INITIAL_SUPPLY);
    }

    /// @notice View the total minted Trailium for a given year
    function annualMinted(uint256 year) external view returns (uint256) {
        return _annualMinted[year];
    }

    /// @notice Mint new tokens to a recipient, respecting annual cap
    function mint(address to, uint256 amount) external nonReentrant onlyRole(MINTER_ROLE) {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than zero");

        uint256 year = block.timestamp / SECONDS_IN_A_YEAR;
        uint256 minted = _annualMinted[year];
        require(minted + amount <= MAX_ANNUAL_MINT, "Annual mint cap exceeded");

        _annualMinted[year] = minted + amount;
        _mint(to, amount);

        emit TokensMinted(year, to, amount);
    }

    /// @notice Burn tokens from caller (must have BURNER_ROLE)
    function burnFromSelf(uint256 amount) external nonReentrant onlyRole(BURNER_ROLE) {
        require(amount > 0, "Amount must be greater than zero");
        _burn(_msgSender(), amount);
        emit TokensBurned(_msgSender(), amount);
    }
}
