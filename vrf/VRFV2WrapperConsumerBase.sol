// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {LinkTokenInterface} from "../shared/interfaces/LinkTokenInterface.sol";
import {ErinaceusVRFWrapperInterface} from "./interfaces/ErinaceusVRFWrapperInterface.sol";

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  ErinaceusVRFWrapperInterface internal immutable ERINACEUS_VRF_WRAPPER;

  /**
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _vrfV2Wrapper) {
    ERINACEUS_VRF_WRAPPER = ErinaceusVRFWrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords,
    uint256 paymentAmount
  ) internal returns (uint256 requestId) {
    require(paymentAmount >= ERINACEUS_VRF_WRAPPER.calculateRequestPrice(_callbackGasLimit), "Insufficient payment amount");
    ERINACEUS_VRF_WRAPPER.requestRandomWords{value: ERINACEUS_VRF_WRAPPER.calculateRequestPrice(_callbackGasLimit)}(_callbackGasLimit, _requestConfirmations, _numWords);
    if(paymentAmount > ERINACEUS_VRF_WRAPPER.calculateRequestPrice(_callbackGasLimit)){
      _sendViaCall(payable(msg.sender), paymentAmount - ERINACEUS_VRF_WRAPPER.calculateRequestPrice(_callbackGasLimit));
    }
    return ERINACEUS_VRF_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    // solhint-disable-next-line custom-errors
    require(msg.sender == address(ERINACEUS_VRF_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }

  /**
   * @notice Internal function to safely send FTN.
   * @param to Recipient address.
   * @param amount Amount of ETH to send.
   */
    function _sendViaCall(
      address payable to,
      uint256 amount
  ) internal {
      (bool sent, ) = to.call{value: amount} ("");
      if (!sent) {
          revert();
      }
  }
}
