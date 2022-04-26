pragma solidity ^0.8.10;

contract CoinFlip{

    /*****************VRF DECLARATION**************/
    
    function vrf() public view returns (bytes32 result) {
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
    
    constructor(){
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
    //Bet Options
    enum BetOption {HEAD,TAIL}
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
        require(_option >=0 && _option<=1);
        BetOption temp;
        if(_option == 0) temp = BetOption.HEAD;
        else temp = BetOption.TAIL; 
        Bet memory _newBet = Bet(msg.sender, msg.value,temp);
        BetsInTheSession[SessionId] = _newBet; 
        OnGoing = true;
        emit NewBetPlaced(SessionId, msg.sender, msg.value, temp); 

    }
    // Function to get a draw inside the contract. This draw will be used to declare the winner. 
    function GenerateDraw() private view Owner returns(BetOption) {
        return (BetOption(uint(vrf())%2)); 
    }
    function getBalance(address _user) private view returns (uint){
        return (_user.balance); 
    }
    function pay(address payable _playerAddr, uint _reward) public payable{
        (bool sent,) = _playerAddr.call{value: _reward}("");
        require(sent,"Error while Paying"); 
    }
    function rewardBets() public payable Owner{
        BetOption draw = GenerateDraw(); 
        Bet memory CurrBet = BetsInTheSession[SessionId]; 
        if(CurrBet.option == draw)
            giveReward(payable(msg.sender), CurrBet.BetAmount); 
        else
            deductReward(CurrBet.BetAmount);
    }
    function giveReward(address payable player, uint _BetAmount) private Owner{
        uint CurrBalance = getBalance(player);
        uint reward = 2*_BetAmount; 
        pay(player,CurrBalance+reward); 
    }
    function deductReward(uint _BetAmount) private Owner{
        pay(payable(owner), _BetAmount);
    }
}
