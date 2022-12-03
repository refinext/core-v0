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
    IConnext public immutable connext;
    bool public xCallArrived;
    uint256 public val;

    constructor(address _connext) ERC1155("") {
        connext = IConnext(_connext);
        xCallArrived = false;
        val = 0;
    }

    mapping(uint32 => address) public xrefinancers;

    function setRefinancers(uint32 _domain, address _financer)
        external
        onlyOwner
    {
        xrefinancers[_domain] = _financer;
    }

    /**
     *@dev adds liquidity to the contract which will be useful for repayment.
     */
    function liquidityIn(address token_, uint256 amount_) public {
        IERC20(token_).transferFrom(msg.sender, address(this), amount_);
        // _mint(msg.sender, uint256(uint160(token_)), amount_, "");
        emit LiquidityAdded(token_, amount_, msg.sender);
    }

    /**
     *@dev removes liquidity from the contract.
     */
    function liquidityOut(address token_, uint256 amount_) public {
        _burn(msg.sender, uint256(uint160(token_)), amount_);
        IERC20(token_).transfer(msg.sender, amount_);
        emit LiquidityRemoved(token_, amount_, msg.sender);
    }

    //TODO integrate biconomy batch transaction
    function repayAndTransfer(
        uint32 origin_, //origin domain
        uint32 dest_,
        address srcProtocol_,
        address destProtocol_,
        address collateral_,
        address debt_,
        uint256 collAmt_,
        uint256 debtAmt_
    ) external {
        IProtocol lp = IProtocol(srcProtocol_);

        IERC20(debt_).transfer(srcProtocol_, debtAmt_);
        lp.paybackOnBehalf(debt_, debtAmt_, msg.sender);
        lp.withdrawOnBehalf(collateral_, collAmt_, msg.sender);

        bytes memory callData = abi.encodeWithSelector(
            bytes4(
                keccak256(
                    "createDestPos(uint32,address,address,uint256,address,uint256,address)"
                )
            ),
            srcProtocol_,
            destProtocol_,
            collateral_,
            collAmt_,
            debt_,
            debtAmt_,
            msg.sender
        );

        connext.xcall(
            dest_,
            xrefinancers[dest_],
            collateral_,
            msg.sender,
            collAmt_,
            5,
            callData
        );
    }

    function createDestPos(
        uint32 origin_,
        address destProtocol_,
        address collateral_,
        uint256 collateralAmount_,
        address debt_,
        uint256 debtAmount_,
        address user
    ) external {
        xCallArrived = !xCallArrived;
        val = debtAmount_;
        emit xRefinance(msg.sender);
        require(
            // origin domain of the source contract
            IExecutor(msg.sender).origin() == origin_,
            "Expected origin domain"
        );
        require(
            // msg.sender of xcall from the origin domain
            IExecutor(msg.sender).originSender() == xrefinancers[origin_],
            "Expected origin domain contract"
        );

        IProtocol loanProvider = IProtocol(destProtocol_);
        IERC20Mintable(collateral_).allocateTo(
            destProtocol_,
            collateralAmount_
        );
        loanProvider.depositOnBehalf(collateral_, collateralAmount_, user);
        loanProvider.borrowOnBehalf(debt_, debtAmount_, user);
    }
}
