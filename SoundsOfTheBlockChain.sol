pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC721/ERC721.sol";

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

//author => owen.eth
contract SoundsOfTheBlockchain is ERC721("Sounds of The Blockchain", "SoTB"), HasSecondarySaleFees{

	address owner;
	mapping(address => bool) teamMember;

	struct SoundMould {
		bool live;
		string name;
		string collection;
		uint256 price;
		uint256 mintLimit;
		uint256 amountMinted;
		address[] members;
		uint256[] share;
		string ipfsVideoHash;
		string ipfsMp3Hash;

	}

	struct SoundByte {
		uint256 mouldId;
		uint256 edition;
	}

	event SoundMouldCreated(uint256 id);
	event SoundByteBought(uint256 id);
	event SoundMouldUnlocked(uint256 id);

	mapping(uint256 => SoundMould) soundMoulds;
	mapping(uint256 => SoundByte) soundBytes;
	uint256 mouldCount;
	uint256 totalSoundBytes;
	uint256 totalSales;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	modifier onlyTeam {
		require(teamMember[msg.sender] == true);
		_;
	}

	constructor() public {
		owner = msg.sender;
		teamMember[msg.sender] = true;

		_setBaseURI("https://soundsoftheblockchain.art/api/metadata/");
	}

	function addTeamMember(address[] memory _members) external onlyOwner {
		for(uint i = 0; i < _members.length; i++) {
			teamMember[_members[i]] = true;
		}
	}

	function removeTeamMember(address[] memory _members) external onlyTeam {
		for(uint i = 0; i < _members.length; i++) {
			teamMember[_members[i]] = false;
		}
	}

	function createSoundMould(string memory _name, string memory _collection, uint256  _price, uint128 _mintLimit, address[] memory members, uint256[] memory shares, string memory _ipfsVideoHash, string memory _ipfsMp3Hash) external onlyTeam {
		require(members.length == shares.length, "Amount members not equal to amount shares");
		uint256 total;
		for(uint i = 0; i < members.length; i++) {
			total += shares[i];
		}
		require(total == 100, "Invalid share amount (must equal 100)");

		SoundMould memory mould = SoundMould(false, _name, _collection, _price, _mintLimit, 0, members, shares, _ipfsVideoHash, _ipfsMp3Hash);
		mouldCount += 1;
		soundMoulds[mouldCount] = mould;
		emit SoundMouldCreated(mouldCount);
	}


	function unlockSound(uint256 mouldId) external onlyTeam {
		require(soundMoulds[mouldId].live == false, "Mould is already live!");
		soundMoulds[mouldId].live = true;
		emit SoundMouldUnlocked(mouldId);
	}

	function buy(uint256 mouldID) external payable {
		SoundMould storage soundByte = soundMoulds[mouldID];
		require(soundByte.live == true, "SoundByte is not live!");
		require(soundByte.amountMinted < soundByte.mintLimit, "Max amount minted!");
		require(msg.value == soundByte.price, "Insufficient amount!");

		soundMoulds[mouldID].amountMinted += 1;
		soundBytes[totalSupply() + 1] = SoundByte(mouldID, soundByte.amountMinted);
		_mint(msg.sender, totalSupply() + 1);

		uint256 tax  = (msg.value * 15) / 100;
		payable(owner).transfer(tax);
		uint256 revenue = msg.value - tax;
		for(uint i = 0; i < soundByte.members.length; i++) {
			payable(soundByte.members[i]).transfer((revenue * soundByte.share[i]) / 100);
		}

		totalSales += msg.value;
		emit SoundByteBought(totalSupply());

	}

	function getMetaData(uint256 _id) external view returns
	(uint256 soundId, uint256 soundEdition, uint256 mintLimit, string memory name, string memory _collection, string memory ipfsVideoHash, string memory ipfsMp3Hash) {
       SoundByte memory sound = soundBytes[_id];
       SoundMould memory mould = soundMoulds[sound.mouldId];
       return (sound.mouldId, sound.edition, mould.mintLimit, mould.name, mould.collection, mould.ipfsVideoHash, mould.ipfsMp3Hash);
   }

	function updateTeamAddress(address payable newTeamAddress) public onlyOwner {
        teamAddress = newTeamAddress;
    }

    function updateSecondaryFee(uint256 newSecondaryBps) public onlyOwner {
        teamSecondaryBps = newSecondaryBps;
    }

	function updateURI(string memory newURI) public onlyTeam {
		_setBaseURI(newURI);
	}

	function getTotalSales() external view returns(uint256 sales) {
		return totalSales;
	}




}
