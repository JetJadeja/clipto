// SPDX-License-Identifier: None
pragma solidity 0.8.10;

import {CliptoExchange} from "../CliptoExchange.sol";
import {CliptoToken} from "../CliptoToken.sol";
import {DSTestPlus} from "lib/solmate/src/test/utils/DSTestPlus.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract CliptoExchangeTest is DSTestPlus, IERC721Receiver {
    CliptoExchange internal exchange;

    function setUp() external {
        exchange = new CliptoExchange();
    }

    function testCreatorRegistration() public {
        // Register creator.
        address tokenAddress = exchange.registerCreator(
            "Gabriel", 
            "https://arweave.net/BlrobCrH2-uAq9OvRkMrFFOIZcbrVdzAdtl-uu9TLpk", 
            1e18, 
            2 days
        );

        // Retrieve creator information.
        (string memory profileUrl, uint256 cost, address token, uint minTimeToDeliver) = exchange.creators(address(this));

        // Ensure the data returned is correct.
        assertEq(profileUrl, "https://arweave.net/BlrobCrH2-uAq9OvRkMrFFOIZcbrVdzAdtl-uu9TLpk");
        assertEq(cost, 1e18);
        assertEq(token, tokenAddress);
        assertEq(minTimeToDeliver, 2 days);
    }

    function testRequestCreation() public {
        // Register a creator.
        testCreatorRegistration();

        // Create a new request (the creator address is address(this))
        exchange.newRequest{value: 1e18}(address(this), block.timestamp + 2 days);

        // Check that the request was created
        (address requester, uint256 value, bool delivered, uint256 deadline, bool refunded) = exchange.requests(address(this), 0);

        // Ensure the data returned is correct.
        assertEq(requester, address(this));
        assertEq(value, 1e18);
        assertFalse(delivered);
        assertEq(deadline, block.timestamp + 2 days);
        assertFalse(refunded);
    }


    function testRequestDelivery() public {
        testRequestCreation();

        uint256 balanceBefore = address(this).balance;
        exchange.deliverRequest(0, "https://arweave.net/BlrobCrH2-uAq9OvRkMrFFOIZcbrVdzAdtl-uu9TLpk");
        (, , bool delivered, , ) = exchange.requests(address(this), 0);

        assertTrue(delivered);
        assertTrue(address(this).balance > balanceBefore + 9e17);
    }

    function modifyCreator() public {
        exchange.modifyCreator(
            "https://arweave.net/BlrobCrH2-uAq9OvRkMrFFOIZcbrVdzAdtl-uu9TLpl", 
            2e18, 
            3 days
        );

        (string memory profileUrl, uint256 cost, address token, uint minTimeToDeliver) = exchange.creators(address(this));
        // Ensure the data returned is correct.
        assertEq(profileUrl, "https://arweave.net/BlrobCrH2-uAq9OvRkMrFFOIZcbrVdzAdtl-uu9TLpl");
        assertEq(cost, 2e18);
        assertEq(minTimeToDeliver, 3 days);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        assertEq(tokenId, 0);
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
