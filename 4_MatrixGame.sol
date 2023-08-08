// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Convenant is Ownable{

    /*
     *  Events
    */
    event gameCreated(address _ownerAddress, uint256 _courseId, uint256 _courseFee);
    event voteRegistered(address _from, address _destAddr, uint _amount);

    /*
     *  Storage
    */
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter public curr_active_game_id;

    struct gameInfo{
        uint256[] vote;// For bluePill vote value will be 1 and for redPill the vote value will be 2.
        address[] votersDatabase;
        uint256 timestamp;
        uint256 prizePool;
        Counters.Counter currElementId;
    }

    gameInfo[] public gameDatabase;
    uint256 mainPoolSize;

    // Constructor.
    constructor() {// 1e16 = 0.01 matic

        gameInfo memory _currGame;
        _currGame.timestamp = block.timestamp;
        _currGame.prizePool = 0;
        mainPoolSize = 0;

        gameDatabase.push(_currGame);
    }

    function getActiveGameId() external view returns(uint256){
        
        return curr_active_game_id.current();
    }

    function createGame() public onlyOwner{

        uint256 _currGameId = curr_active_game_id.current();
        require(gameDatabase[_currGameId].timestamp.add(86400) < block.timestamp, "Current Game is already running, no need to create a new game.");

        gameInfo memory _currGame;
        _currGame.timestamp = block.timestamp;
        _currGame.prizePool = 0;

        gameDatabase.push(_currGame);
        curr_active_game_id.increment();
    }

    function vote(uint256 _voteValue) external payable returns(uint256 _id) {

        uint256 _currGameId = curr_active_game_id.current();
        require(gameDatabase[_currGameId].timestamp.add(86400) > block.timestamp, "Current Game has ended, wait for the new game and try voting later.");
        require(msg.value == 10000000000000000, "Incorrect Amount being passed, pass 0.01ETH.");

        //Sanity Checks done now allow the vote to get registered, + increase the pool size.
        gameDatabase[_currGameId].vote.push(_voteValue);
        gameDatabase[_currGameId].votersDatabase.push(msg.sender);
        gameDatabase[_currGameId].prizePool.add(10000000000000000);
        _id = gameDatabase[_currGameId].currElementId.current();
        gameDatabase[_currGameId].currElementId.increment();

        mainPoolSize.add(10000000000000000);

    }

    function divide(uint256 numerator, uint256 denominator, uint256 decimals) public pure returns (uint256) {
        require(denominator != 0, "Denominator cannot be zero");
        uint256 factor = 10**decimals;
        return (numerator * factor) / denominator;
    }

    function checkCFPrize() public view returns (uint256 _carryForward) {

        uint256 _currGameId = curr_active_game_id.current();
        require(gameDatabase[_currGameId].timestamp.add(86400) < block.timestamp, "Current Game is active, wait for the results till it ends.");

        uint256 bluePill = 0;
        uint256 redPill = 0;

        uint256 len = gameDatabase[_currGameId].votersDatabase.length;
        
        for(uint256 i=0; i<len; i++){
            if(gameDatabase[_currGameId].vote[i] == 1){
                bluePill.add(1);
            }
            else{
                redPill.add(1);
            }
        }

        if(bluePill !=0 && redPill!=0){
           if(bluePill > redPill){
               uint256 value = divide(bluePill, redPill, 6);
               if(value >= 1500000){
                   _carryForward = 1;
               }
           } 
           else if(redPill > bluePill){
               uint256 value = divide(redPill, bluePill, 6);
               if(value >= 1500000){
                   _carryForward = 2;
               }
           }
        }

        _carryForward = 0;
    }

    function distributeFundsWinners() external { // getResult and disburse money or carryforward to the next prizePool.

        // Sanity Check for whether the voting period has ended or not.
        uint256 _currGameId = curr_active_game_id.current();
        require(gameDatabase[_currGameId].timestamp.add(86400) < block.timestamp, "Current Game is active, wait for the results till it ends.");

        // Determine redPill or bluePill is the winner.
        uint256 winnerVote = checkCFPrize();


        // If there is no winner(prizePool will carry forwarded) then return, the new created Game will be having the consolidated pool. 
        require(winnerVote > 0, "No winner determined, wait for new voting to start");

        // Now identify or get a list of the winners.
        address[] memory winnersList;

        if(gameDatabase)


        // Distribute funds to the winners from the mainPool.
    }

    // function calculateTimestamp(uint256 _courseId, uint256 _sectionId) public view returns(uint256){

    //     require(courseDatabase[_courseId].numSections > _sectionId, "Invalid Section");

    //     uint256 _cummTimestamp = 0;
    //     for(uint256 i=0; i<(_sectionId+1); i++){
    //         _cummTimestamp = _cummTimestamp.add(courseDatabase[_courseId].sectionDeadlines[i]);
    //     }

    //     return _cummTimestamp;
    // }

    // function sectionCompleted(uint256 _courseId, uint256 _sectionId) external {

    //     //Sanity check incorrect course id.
    //     require(_courseId < courseId.current(), "Invalid course id.");

    //     //Sanity Check that the user is enrolled also or not.
    //     require(userEnrolledDatabase[msg.sender][_courseId].timeEnrolled != 0, "User has not enrolled in this course");

    //     //Sanity check whether it has already completed the course or not and re-claiming the refund.
    //     require(courseDatabase[_courseId].numSections > _sectionId, "Invalid Section");
    //     require(userEnrolledDatabase[msg.sender][_courseId].sectionsCompleted[_sectionId] == false, "Section already completed refund isssued.");

    //     //Calculate the exact timestamp to refund amount.
    //     uint256 _cummTimestamp = calculateTimestamp(_courseId, _sectionId);
    //     uint256 _exactDeadline = userEnrolledDatabase[msg.sender][_courseId].timeEnrolled.add(_cummTimestamp); 

    //     require(block.timestamp <= _exactDeadline, "Deadline passed refund not possible.");

    //     //Since sanity checks passed now we can refund the amount.
    //     (bool success, ) = msg.sender.call{value: courseDatabase[_courseId].sectionRefundFee[_sectionId]}("");
    //     require(success, "Failed to send Ether");

    //     userEnrolledDatabase[msg.sender][_courseId].sectionsCompleted[_sectionId] = true;

    // }

    // function transferAmountCreator(uint256 _courseId) external {

    //     //Sanity check incorrect course id.
    //     require(_courseId < courseId.current(), "Invalid course id.");

    //     uint totalAmountPay = 0;

    //     for(uint256 i=0; i<courseDatabase[_courseId].enrolledStudents.length; i++){
    //         address currStudent = courseDatabase[_courseId].enrolledStudents[i];

    //         //Transfer course fee by calculating to the creator only after the student course deadline is met.
    //         uint256 _cummTimestamp = calculateTimestamp(_courseId, courseDatabase[_courseId].numSections.sub(1));
    //         uint256 _exactDeadline = userEnrolledDatabase[currStudent][_courseId].timeEnrolled.add(_cummTimestamp);

    //         if(_exactDeadline >= block.timestamp){
    //             continue;
    //         }

    //         totalAmountPay = totalAmountPay.add(courseDatabase[_courseId].courseFee);

    //         uint256 totalRefundAmount = 0;
    //         for(uint256 j=0; j<courseDatabase[_courseId].numSections; j++){
    //             if(userEnrolledDatabase[currStudent][_courseId].sectionsCompleted[j] == true){
    //                 totalRefundAmount = totalRefundAmount.add(courseDatabase[_courseId].sectionRefundFee[j]);
    //             }
    //         }

    //         totalAmountPay = totalAmountPay.sub(totalRefundAmount);
    //     }

    //     if(totalAmountPay > 0){
    //         (bool success, ) = courseDatabase[_courseId].creatorAddress.call{value: totalAmountPay}("");
    //         require(success, "Failed to send Ether");
    //     }
    // }

    // function getUserData() external view returns(userCustomDatabase memory _userInfo){
        
    //     _userInfo.user = msg.sender;
    //     uint256 numCoursesEnrolled = 0;
    //     for(uint256 _courseId=0; _courseId < courseDatabase.length; _courseId++){
    //         if(userEnrolledDatabase[msg.sender][_courseId].timeEnrolled != 0){
    //             numCoursesEnrolled = numCoursesEnrolled.add(1);
    //         }
    //     }

    //     uint256[] memory _coursesArray = new uint256[](numCoursesEnrolled);
    //     bool[][] memory _sectionsCompleted = new bool[][](numCoursesEnrolled);

    //     uint256 _count = 0;
    //     for(uint256 _courseId=0; _courseId < courseDatabase.length; _courseId++){
    //         if(userEnrolledDatabase[msg.sender][_courseId].timeEnrolled != 0){
    //             _coursesArray[_count] = _courseId;
    //             bool[] memory _currSectionsCompleted = new bool[](courseDatabase[_courseId].numSections);
    //             for(uint256 i=0; i < courseDatabase[_courseId].numSections; i++){
    //                 _currSectionsCompleted[i] = userEnrolledDatabase[msg.sender][_courseId].sectionsCompleted[i];
    //             }
    //             _sectionsCompleted[_count] = _currSectionsCompleted;
    //             _count = _count.add(1);
    //         }
    //     }

    //     _userInfo.enrolledCoursesId = _coursesArray;
    //     _userInfo.sectionsCompleted = _sectionsCompleted;        
    // }
}