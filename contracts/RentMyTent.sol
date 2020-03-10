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

    // Contract Version
    bytes16 public version;

    //
    // Events
    //

    // ...

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
        version = "v0.0.2";
    }

    /***********************************|
    |         Public Functions          |
    |__________________________________*/



    /***********************************|
    |            Only Owner             |
    |__________________________________*/



    /***********************************|
    |         Private Functions         |
    |__________________________________*/



}
