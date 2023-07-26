// SPDX-License-Identifier: MIT

// Basic ERC20 contract that will mint token at 1:1 ratio (ie. deposit 100 native tokens, get 100 ERC20 tokens)

// Demo: Learn about state variables, mappings (similar to dictonaries) & write transfer function

pragma solidity ^0.8.6;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

error InsufficientBalance(uint256 available, uint256 required);
error OnylOwner();
error SupplyCeiling();

contract SimpleFlareTokenWrap is IERC20Metadata {
    // Declare state variables and manage accessibility 
    string public override name;
    string public override symbol;
    uint8 public override decimals;

    // Mapping is similar to a dictionary (key/value store)
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public immutable owner;
    uint256 public immutable maxSupply;
    uint256 public override totalSupply;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnylOwner();
        }
        _;
    }

    constructor(
        uint256 _maxSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        maxSupply = _maxSupply;
        owner = msg.sender;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        // TODO: add check for suffcient balance, update balances and emit transfer event
        if (amount > _balances[msg.sender]) {
            revert InsufficientBalance(_balances[msg.sender], amount);
        }

        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        if (amount > _balances[from]) {
            revert InsufficientBalance(_balances[from], amount);
        }

        if (amount > _allowances[from][msg.sender]) {
            revert InsufficientBalance(_allowances[from][msg.sender], amount);
        }

        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function _mint() private returns (uint256 tokenAmount) {

        tokenAmount = msg.value;

        if (totalSupply + tokenAmount > maxSupply) {
            revert SupplyCeiling();
        }

        _balances[msg.sender] += tokenAmount;
        totalSupply += tokenAmount;

        emit Transfer(address(0), msg.sender, tokenAmount);
    }

    function mint() external payable returns (uint256) {
        return _mint();
    }

    // Forward everything to deposit
    receive() external payable {
        _mint();
    }

    fallback() external payable {
        _mint();
    }

    function withdrawFunds() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function burn(uint256 amount) external {
        if (amount > _balances[msg.sender]) {
            revert InsufficientBalance(_balances[msg.sender], amount);
        }

        _balances[msg.sender] -= amount;
        totalSupply -= amount;

        // Sending back the equivalent amount of ETH
        payable(msg.sender).transfer(amount);

        emit Transfer(msg.sender, address(0), amount);
    }
}
