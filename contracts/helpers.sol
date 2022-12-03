// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// Import this file to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces.sol";
import "./events.sol";

abstract contract XRefiHelper is ERC1155, Ownable, Pausable, Events {
    //infinte liquidity ---
    //refinance to aave
    //repay on chain 1
    //transfer to chain2
    //getback on chain2
    IConnext public immutable connext;

    address public testToken;
    bool public xCallArrived;
    uint256 public val;

    constructor(address _connext) ERC1155("") {
        connext = IConnext(_connext);
        xCallArrived = false;
        val = 0;
    }

    mapping(uint32 => address) public xrefinancers;

    function setTestToken(address _testToken) external onlyOwner {
        testToken = _testToken;
    }

    function setRefinancers(uint32 _domain, address _financer)
        external
        onlyOwner
    {
        xrefinancers[_domain] = _financer;
    }

    /**
     *@dev adds liquidity to the contract which will be useful for repayment.
     */
    function liquidityIn(
        address[] memory tokens_,
        uint256[] memory amounts_,
        address onBehalfOf_
    ) public {
        //add liquidity to this contract
        uint256 len_ = tokens_.length;
        require(amounts_.length == len_, "length-mismatch");

        for (uint256 i = 0; i < len_; i++) {
            IERC20(tokens_[i]).transferFrom(
                onBehalfOf_,
                address(this),
                amounts_[i]
            );
            _mint(onBehalfOf_, uint256(uint160(tokens_[i])), amounts_[i], "");
            emit LiquidityAdded(tokens_[i], amounts_[i], onBehalfOf_);
        }
    }

    /**
     *@dev removes liquidity from the contract.
     */
    function liquidityOut(
        address[] memory tokens_,
        uint256[] memory amounts_,
        address onBehalfOf_
    ) public {
        uint256 len_ = tokens_.length;
        require(amounts_.length == len_, "length-mismatch");

        for (uint256 i = 0; i < len_; i++) {
            address token_ = tokens_[i];
            uint256 amount_ = amounts_[i];
            _burn(onBehalfOf_, uint256(uint160(token_)), amount_);
            IERC20(token_).transfer(onBehalfOf_, amount_);
            emit LiquidityRemoved(token_, amount_, onBehalfOf_);
        }
    }

    //TODO integrate biconomy batch transaction
    function repayAndTransfer(
        uint32 origin_, //origin domain
        uint32 dest_,
        address srcProtocol_,
        address destProtocol_,
        address[] memory collaterals_,
        address[] memory debts_,
        uint256[] memory collAmts_,
        uint256[] memory debtAmts_
    ) external {
        IProtocol lp = IProtocol(srcProtocol_);

        for (uint256 i = 0; i < debts_.length; i++) {
            (address aDebt, address dtoken, address vtoken) = IAaveProtocolDataProvider(
                0x9BE876c6DC42215B00d7efe892E2691C3bc35d10
            ).getReserveTokensAddresses(debts_[i]);
            IERC20(aDebt).transfer(srcProtocol_, debtAmts_[i]);
            lp.paybackOnBehalf(debts_[i], debtAmts_[i], msg.sender);
            lp.withdrawOnBehalf(collaterals_[i], collAmts_[i], msg.sender);
        }

        bytes memory callData = abi.encodeWithSelector(
            bytes4(
                keccak256(
                    "createDestPos(uint32,address,address,uint256,address,uint256,address)"
                )
            ),
            srcProtocol_,
            destProtocol_,
            collaterals_,
            collAmts_,
            debts_,
            debtAmts_,
            msg.sender
        );

        IConnext.CallParams memory callParams = IConnext.CallParams({
            _destination: xrefinancers[dest_],
            _to: xrefinancers[dest_],
            _asset: collaterals, /////////////////////////switch to single token
            _delegate: msg.sender,
            _amount: amounts_,
            _slippage: 5,
            _callData: callData
        });

        connext.xcall(xcallArgs);
    }

    function xReceive(
    uint32 origin_,
    address destProtocol_,
    address[] memory collaterals_,
    uint256[] memory collAmts_,
    address[] memory debts_,
    uint256[] memory debtAmts_,
    address user
  ) external {


    xCallArrived = !xCallArrived;
    val = debtAmount;

    emit xRefinance(msg.sender);

    // IProtocol lp = IProtocol(destProtocol_);
    // IERC20Mintable erc20 = IERC20Mintable(collateralAsset);
    // erc20.mint(collateralAmount); 
    // erc20.transfer(address(lProvider), collateralAmount);
    // lProvider.depositOnBehalf(collateralAsset, collateralAmount, address(this));

    // // 2.2 - borrow
    // IDebtToken(lProvider.debtTokenMap(debtAsset)).approveDelegation(address(lProvider), debtAmount);
    // lProvider.borrowOnBehalf(debtAsset, debtAmount, address(this));
}
