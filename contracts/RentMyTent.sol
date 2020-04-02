// RentMyTent.sol
// MIT License
// Copyright (c) 2020 Rent-My-Tent-Team
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.5.16;

import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/introspection/IERC165.sol";
import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Full.sol";
import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Mintable.sol";
import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Burnable.sol";
import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Pausable.sol";


/**
 * @notice RentMyTent Contract
 */
contract RentMyTent is Initializable, Ownable, ReentrancyGuard, ERC721Full, ERC721Mintable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Address for address payable;

    /***********************************|
    |        Variables and Events       |
    |__________________________________*/

    // Required Deposit for Tent == Listing Price * depositPercentage / 100
    uint256 internal depositPercentage;

    // Array with all available tents, used for enumeration
    uint256[] internal availableTents;

    //      Tent ID => Positional-index in the availableTents array
    mapping(uint256 => uint256) internal availableTentsIndex;

    //      Tent ID => Current Listing Price
    mapping(uint256 => uint256) internal tentListingPrice;

    //      Tent ID => Current Address for Reservation
    mapping(uint256 => address) internal tentReservationAddress;

    //      Tent ID => Current Deposit for Reservation
    mapping(uint256 => uint256) internal tentReservationDeposit;

    //      Tent ID => Current Custodian of Tent
    mapping(uint256 => address) internal tentCustodian;

    //      Tent ID => Current Deposit
    mapping(uint256 => uint256) internal tentDeposit;

    //      Tent ID => Current Tent Rental Period
    mapping(uint256 => uint256) internal tentLockedRentalPeriod;

    uint256 deteriorationProfits;

    // Contract Version
    bytes16 public version;

    //
    // Events
    //
    event NewTent(uint256 indexed _tokenId, uint256 _listingPrice, string _uri);
    event TentReservationStarted(uint256 indexed _tokenId, address indexed _reservationAddress, uint256 _reservationDeposit);
    event TentReservationCancelled(uint256 indexed _tokenId);
    event TentReservationCompleted(uint256 indexed _tokenId, address indexed _newCustodian);


    /***********************************|
    |          Initialization           |
    |__________________________________*/

    function initializeAll(address sender) public initializer {
        Ownable.initialize(sender);
        ReentrancyGuard.initialize();
        ERC721.initialize();
        ERC721Enumerable.initialize();
        ERC721Metadata.initialize("RentMyTent", "TENT");
        ERC721Mintable.initialize(sender);
        ERC721Pausable.initialize(sender);

        depositPercentage = 100;
        version = "v0.0.2";
    }

    /***********************************|
    |         Public Functions          |
    |__________________________________*/

    /**
     * @dev Gets the total amount of tents available for rent
     * @return uint256 representing the total amount of tents
     */
    function totalAvailable() public view returns (uint256) {
        return availableTents.length;
    }

    /**
     * @dev Gets the tent ID at a given index of all the available tents
     * Reverts if the index is greater or equal to the total number of available tents.
     * @param index uint256 representing the index to be accessed of the available tents list
     * @return uint256 tent ID at the given index of the available tents list
     */
    function availableTentByIndex(uint256 index) public view returns (uint256) {
        require(index < totalAvailable(), "tent index out of bounds");
        return availableTents[index];
    }


    function listNewTent(uint256 _initialListingPrice, string memory _uri) public returns (uint256) {
        // Mint new Token
        uint256 _tokenId = totalSupply().add(1);
        _safeMint(msg.sender, _tokenId);

        // Set Token URI
        _setTokenURI(_tokenId, _uri);

        // Set Listing Price
        tentListingPrice[_tokenId] = _initialListingPrice;

        // Set Current Custodian
        tentCustodian[_tokenId] = msg.sender;

        return _tokenId;
    }


    function reserveTent(uint256 _tokenId) public nonReentrant {
        require(_exists(_tokenId), "Invalid TokenID for Tent");
        require(tentReservationAddress[_tokenId] == address(0x0), "Tent is already reserved");
        require(tentCustodian[_tokenId] != msg.sender, "You are already in custody of this Tent");
        require(now > tentLockedRentalPeriod[_tokenId], "Tent is currently being Rented");

        // Get Deposit Price for Reservation
        (, uint256 _deposit) = _getRentalPrice(_tokenId);
        require(msg.value >= _deposit, "Insufficient funds for deposit");

        // Track Reservation Address + Deposit
        tentReservationDeposit[_tokenId] = _deposit;
        tentReservationAddress[_tokenId] = msg.sender;

        // Log Event
        emit TentReservationStarted(_tokenId, msg.sender, _deposit);

        // Refund over-payment
        uint256 _overage = msg.value.sub(_deposit);
        if (_overage > 0) {
            msg.sender.sendValue(_overage);
        }
    }


    function cancelReservation(uint256 _tokenId) public {
        require(_exists(_tokenId), "Invalid TokenID for Tent");
        require(tentReservationAddress[_tokenId] == msg.sender, "You have not reserved this Tent");

        // Track Reservation Address + Deposit
        uint256 _refund = tentReservationDeposit[_tokenId];
        address payable _address = tentReservationAddress[_tokenId].toPayable();

        // Clear Reservation
        tentReservationDeposit[_tokenId] = 0;
        tentReservationAddress[_tokenId] = address(0x0);

        // Log Event
        emit TentReservationCancelled(_tokenId);

        // Refund Deposit to Reservation Address
        if (_refund > 0) {
            _address.sendValue(_refund);
        }
    }


    // Called by same address that reserves the tent
    function completeTentTransfer(uint256 _tokenId, string memory _uri, uint256 _confirmedTentQuality, uint256 _rentalPeriodInDays) public nonReentrant {
        require(_exists(_tokenId), "Invalid TokenID for Tent");
        require(tentReservationAddress[_tokenId] == msg.sender, "You have not reserved this Tent");
        require(now > tentLockedRentalPeriod[_tokenId], "Tent is currently being Rented");
        require(_confirmedTentQuality > 0, "Tent Quality must be greater than Zero");
        require(_confirmedTentQuality <= 100, "Tent Quality must be less than or equal to 100");

        // Determine New Price based on Tent Quality
        address payable _oldCustodian = tentCustodian[_tokenId].toPayable();
        uint256 _oldPrice = tentListingPrice[_tokenId];
        uint256 _oldDeposit = tentDeposit[_tokenId];
        uint256 _newPrice = (_oldPrice * _confirmedTentQuality) / 100;
        uint256 _newDeposit = (_newPrice * depositPercentage) / 100;
        require(msg.value >= _newPrice, "Insufficient funds for Rental");

        // Track Profits from Tent Deterioration
        uint256 _depositDiff = _oldDeposit.sub(_newDeposit);
        deteriorationProfits = deteriorationProfits.add(_depositDiff);

        // Set New Listing Price based on Tent Quality
        tentListingPrice[_tokenId] = _newPrice;

        // Track New Tent Custodian
        tentCustodian[_tokenId] = msg.sender;
        tentDeposit[_tokenId] = _newDeposit;

        // Clear Reservation
        uint256 _reserveDeposit = tentReservationDeposit[_tokenId];
        tentReservationDeposit[_tokenId] = 0;
        tentReservationAddress[_tokenId] = address(0x0);

        // Lock Tent for Rental-Period
        tentLockedRentalPeriod[_tokenId] = now + (_rentalPeriodInDays * 1 days);

        // Log Event
        emit TentReservationCompleted(_tokenId, msg.sender);

        // Previous Custodian receives New Deposit + New Tent Price (based on Quality of Tent)
        uint256 _oldCustodianRefund = _newPrice.add(_newDeposit);
        if (_oldCustodianRefund > 0) {
            _oldCustodian.sendValue(_oldCustodianRefund);
        }

        // New Custodian Pays New Price, gets Refund for difference between old/new Deposit value
        uint256 _excessDeposit = _reserveDeposit.sub(_newDeposit);
        uint256 _overage = msg.value.sub(_newPrice).add(_excessDeposit);
        if (_overage > 0) {
            msg.sender.sendValue(_overage);
        }
    }



    /***********************************|
    |            Only Owner             |
    |__________________________________*/

    function setDepositPercentage(uint256 _percent) public onlyOwner {
        depositPercentage = _percent;
    }

    function withdrawProfits() public onlyOwner {
        require(deteriorationProfits > 0, "No profits available");

        uint256 _profits = deteriorationProfits;
        deteriorationProfits = 0;
        msg.sender.sendValue(_profits);
    }


    /***********************************|
    |         Private Functions         |
    |__________________________________*/

    function _getRentalPrice(uint256 _tokenId) internal returns (uint256, uint256) {
        uint256 listingPrice = tentListingPrice[_tokenId];
        uint256 deposit = (listingPrice * depositPercentage) / 100;
        return (listingPrice, deposit);
    }

    /**
     * @dev Private function to add a tent to list of available tents
     * @param tokenId uint256 ID of the tent to be added to the available tents list
     */
    function _addAvailableTent(uint256 tokenId) private {
        availableTents[tokenId] = availableTents.length;
        availableTents.push(tokenId);
    }

    /**
     * @dev Private function to remove a tent from the list of available tents
     * This has O(1) time complexity, but alters the order of the "availableTents" array.
     * @param tokenId uint256 ID of the tent to be removed from the available tents list
     */
    function _removeAvailableTent(uint256 tokenId) private {
        uint256 lastTokenIndex = availableTents.length.sub(1);
        uint256 tokenIndex = availableTentsIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = availableTents[lastTokenIndex];

        availableTents[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        availableTentsIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        availableTents.length--;
        availableTentsIndex[tokenId] = 0;
    }

}
