pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

interface IRouter {
    function WETH() external pure returns (address);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

contract HasSecondarySaleFees is ERC165 {
    address payable teamAddress;
    uint256 teamSecondaryBps;

	/*
    * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
    * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
    *
    * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
    */

    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    constructor() public {
        _registerInterface(_INTERFACE_ID_FEES);
    }

    function getFeeRecipients(uint256 id) public view returns (address payable[] memory){
        address payable[] memory addressArray = new address payable[](1);
        addressArray[0] = teamAddress;
        return addressArray;
    }

    function getFeeBps(uint256 id) public view returns (uint[] memory){
        uint[] memory bpsArray = new uint[](1);
        bpsArray[0] = teamSecondaryBps;
        return bpsArray;
    }
}

contract SoundPack is ERC20("Sounds of The Blockchain", "SoTB"), HasSecondarySaleFees, VRFConsumerBase {

    struct Pack {
        Token token1;
        Token token2;
        Token token3;
    }

    struct Token {
        string shape;
        string color;
        string ipfsGifHash;
        string ipfsVideoHash;
        string ipfsSoundHash;
        uint256 mintNumber;
    }

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    mapping(uint256 => Token) tokens;
    string packName;
    uint256 packPrice;

    IRouter router;
    constructor(string memory _packName, uint256 _packPrice)
    VRFConsumerBase(0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9,0xa36085F69e2889c224210F603D836748e7dC0088)
    public {
        packName = _packName;
        packPrice = _packPrice;
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = (0.1 * 10) ** 18;

        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _setBaseURI("https://soundsoftheblockchain.art/pack/metadata/");
    }

    function getRandomSeed() internal returns (uint) {
        return uint(keccak256(block.difficulty, now));
    }

    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough Link");
        return requestRandomness(keyHash, fee, uint256(getRandomSeed()));

    }

    function fufillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    function createToken() internal returns (Token) {

        return Token();
    }

    function createPack() internal returns (Pack) {
        Token token1 = createToken();
        Token token2 = createToken();
        Token token3 = createToken();
        return Pack(token1, token2, token3);
    }

    function buyPack(uint128 _quantity) external payable {
        require(_quantity * packPrice == msg.value, "!amount");
        uint256 amountsOut;
        address[] path;
        path[0] = router.WETH();
        path[1] = address(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        amountsOut = router.swapETHForExactTokens(100000000000000000, path, address(this), block.timestamp + 15);
        for(uint128 i = 0; i < _quantity; i++) {
            bytes32 id = getRandomNumber();
            Pack pack = createPack();
            Token token1 = pack.token1;
            Token token2 = pack.token2;
            Token token3 = pack.token3;

        }

    }

}
