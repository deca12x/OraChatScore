// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IAIOracle} from "OAO/contracts/interfaces/IAIOracle.sol";
import {AIOracleCallbackReceiver} from "OAO/contracts/AIOracleCallbackReceiver.sol";

contract Prompt is AIOracleCallbackReceiver {
    event ScoreCalculated(uint256 requestId, uint256 score);

    uint256 public constant MODEL_ID = 11;
    uint64 public constant CALLBACK_GAS_LIMIT = 5_000_000;

    constructor(IAIOracle _aiOracle) AIOracleCallbackReceiver(_aiOracle) {}

    function calculateScore(string calldata chatHistory) external payable {
        string memory prompt = string(
            abi.encodePacked(
                "Generate a score from 1 to 100 describing how good is the match between these two developers, to build the project they want to build together. Only return a number from 1 to 100 and nothing else. Chat history: ",
                chatHistory
            )
        );

        aiOracle.requestCallback{value: msg.value}(
            MODEL_ID,
            bytes(prompt),
            address(this),
            CALLBACK_GAS_LIMIT,
            ""
        );
    }

    function aiOracleCallback(
        uint256 requestId,
        bytes calldata output,
        bytes calldata
    ) external override onlyAIOracleCallback {
        uint256 score = abi.decode(output, (uint256));
        require(score >= 1 && score <= 100, "Invalid score range");
        emit ScoreCalculated(requestId, score);
    }

    function estimateFee() public view returns (uint256) {
        return aiOracle.estimateFee(MODEL_ID, CALLBACK_GAS_LIMIT);
    }
}
