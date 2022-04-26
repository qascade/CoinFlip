pragma solidity ^0.8.10;

contract CoinFlip{
    //Bet options 
    enum BetOption {Head,Tail}
    /*****************VRF DECLARATION**************/
    
    function vrf() public view returns (uint result) {
    uint[1] memory bn;
    bn[0] = block.number;
    assembly {
      let memPtr := mload(0x40)
      if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
        invalid()
      }
      result := mload(memPtr)
     }
   }
   /**************************************************/
    /************event Declarations for debugging**************/
    event NewBetPlaced(uint betSessionId, address player, uint amount, BetOption option);
    //NOTE only a single player allowed in a single session. 

    //Address of Contract 
    address public owner;
    //Session Id
    uint private SessionId; 
    
    constructor() public {
        owner = msg.sender;
    }
    //All the modifiers 
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    modifier Owner(){
        require(msg.sender == owner);
        _;
    }
     
    //To define a session for a single bet placed by player 
    struct Bet{
        address playerAdd; //address to identify the better
        uint BetAmount; 
        BetOption option; //option chosen by player 
    }
    // Mapping the Session Id to the bet placed in that particular session 
    mapping(uint => Bet) BetsInTheSession; 
    //flag to check whether a session is going on or not 
    bool OnGoing = false; 
    
    //player place a bet on an option
    function PlaceBet(uint _option) external payable notOwner{
        require(msg.value<=100);
        require(option <= uint(BetOption.TAIL));
        Bet _newBet = Bet(msg.sender, msg.value,_option);
        BetsInTheSession[SessionId] = _newBet; 
        emit NewBetPlaced(SessionId, msg.sender, msg.value, BetOption(_option)); 

    }
    
    function GenerateDraw() private view Owner returns(BetOption) {
        return (BetOption(vrf()%2)); 
    }
    function getBalance(address _user) public view returns (uint){
        returns (_user.balance); 
    }
    function pay(address payable _playerAddr, uint _reward) public payable{
        (bool sent, bytes memory data) = _playerAddr.call{value: _reward}("");
        require(sent,"Error while Paying"); 
    }
    function rewardBets() private Owner{
        BetOption draw = GenerateDraw(); 
        Bet CurrBet = BetsInTheSession[SessionId]; 
        if(CurrBet.option == draw)
            giveReward(msg.sender, CurrBet.BetAmount); 
        else
            deductReward(CurrBet.BetAmount);
    }
    function giveReward(address payable player, uint _BetAmount){
        uint CurrBalance = getBalance(player);
        uint reward = 2*_BetAmount; 
        pay(player,CurrBet+reward); 
    }
    function deductReward(uint _BetAmount){
        pay(owner, _BetAmount);
    }
}
