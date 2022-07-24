import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

pragma solidity ^0.8.0;

contract TortugaShip is ERC721Enumerable, ERC2981, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_SHIP = 250;
    bool public hasSaleStarted;
    bool public hasWhitelistSaleStarted;
    string public baseURI;

    mapping(address => uint256) public whitelist;
    mapping(address => bool) public hasMinted;

    event Recovered(address token, uint256 amount);
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);
    event Mint(address to, uint256 id);
    event Whitelist(address userAddress);
    event RoyaltyInfo(address receiver, uint96 royaltyBP);

    constructor(address _royaltyReceiver, uint96 _royaltyBP) ERC721("Tortuga Ship", "SHIP") {
        setRoyaltyInfo(_royaltyReceiver, _royaltyBP);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// INTERNAL

    function _baseURI() internal view override returns(string memory){
        return baseURI;
    }

    function  _mint() internal {
        uint256 mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
        emit Mint(msg.sender, mintIndex);
    }

    /// SETTER

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyBP) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyBP);
        emit RoyaltyInfo(_receiver, _royaltyBP);
    }

    function startDrop() external onlyOwner {
        hasSaleStarted = true;
    }

    function pauseDrop() external onlyOwner {
        hasSaleStarted = false;
    }

    function addWhitelist(address[] memory _addresses, uint256 _numberPerWhitelist) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _numberPerWhitelist;
            emit Whitelist(_addresses[i]);
        }
    }

    function removeWhitelist(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = 0;
            emit Whitelist(_addresses[i]);
        }
    }

    function startWhitelistDrop() external onlyOwner {
        hasWhitelistSaleStarted = true;
    }

    function pauseWhitelistDrop() external onlyOwner {
        hasWhitelistSaleStarted = false;
    }

    /// CORE
    
    function mint() external {
        uint256 supply = totalSupply();

        require(hasSaleStarted == true, "Sale hasn't started");
        require(hasMinted[msg.sender] == false, "User already minted");
        require(supply + 1 < MAX_SHIP, "Exceeds MAX_SHIP");

        hasMinted[msg.sender] = true;
        _mint();
    }

    function mintWhitelist(uint256 _numberToMint) external {
        uint256 supply = totalSupply();

        require(hasWhitelistSaleStarted == true);
        require(whitelist[msg.sender] >= _numberToMint);
        require(supply + _numberToMint < MAX_SHIP, "Exceeds MAX_SHIP");
        whitelist[msg.sender] -= _numberToMint;
        hasMinted[msg.sender] = true;
        for (uint256 i = 0; i < _numberToMint; i++) {
            _mint();
        }
    }

    function mintAdmin(uint256 _numberToMint) external onlyOwner {
        uint256 supply = totalSupply();

        require(supply + _numberToMint < MAX_SHIP, "Exceeds MAX_SHIP");
        
        for (uint256 i = 0; i < _numberToMint; i++) {
            _mint();
        }
    }
    
    function withdrawAll() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "Claim::recoverERC20: amount is 0");
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
}