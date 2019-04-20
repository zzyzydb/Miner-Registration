pragma solidity ^0.5.0;
/// @title Smart contract-based miner registration and block validation
/// @author Shijie Zhang

contract MinerRegistration{
    // Structure of each transaction set
    struct TranSet{
        bytes32[] transHash;  // Array of hash values of transactions
        address creator; // Address of miner who creates this set
        uint height; // Block height the set belongs to
    }
    
    // Structure of each miner
    struct Miner{
        address miner;  // Address (120bit) of miner
        string regState; // "unregistered" or "registered"
        bool isValid; // Whether this miner exists in the hash table
    }
    
    // Address of a node who delpoys and controls this contract
    address public manager;
    // Instantiation of TranSet
    TranSet public tranSet;
    // Mapping hash table of Miner
    mapping(address => Miner) public miners;
    // A logger that stores the voucher at each block height
    mapping(uint => mapping(bytes32 => bool)) public logger;
    // Check if the hash of one block passes the verification
    mapping(bytes32 => bool) public verifiedBlock;
    // Record the verificaiton status of voucher in each block
    mapping(bytes32 => bool) public verifiedVoucher;
    // Money each miner must deposit
    uint public deposit;
    // Counter of block height
    uint public blockheight;
    // Voucher issued by this contract
    bytes32 private voucher;
    event GetVoucher(bytes32 _voucher); // For test
    event isValid(bool isvalid); // For test
    
    // Operation permissions of some functions
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    // Constructor function
    constructor(uint _deposit) public {
        manager = msg.sender;
        deposit = _deposit;
        voucher = '';
        blockheight = 0; // "0" is used for test, real-use is: blockheight = block.number;
    }
    
    // Function of the miner's deposit
    function Contribute() public payable {
        // Ensure the miner has put into some money
        require(msg.value == deposit);
        
        // Ensure existing miners cannot pay again
        require(!miners[msg.sender].isValid);
        
        // Initialize Miner
        miners[msg.sender] = Miner(msg.sender, 'unregistered', true);
    }
    
    // Function of the miner's creating transaction set
    function CreateTranset(uint count, bytes32[] memory _trans, uint _height) public {
         /* Save storage space by deleting the previous set 
            before each miner creates a new set */
        delete tranSet;
        
        // Add hash value of each transaction into tranSet
        for(uint i=0; i<count; i++){
            tranSet.transHash.push(_trans[i]);
        }
            tranSet.creator = msg.sender;
            tranSet.height = _height;
    }
    
    // Function of registration
    function Register() public restricted returns (bytes32) {
        // Ensure the transaction set belongs to the next block height
        require(tranSet.height == blockheight + 1);
        
        // Randomly select a hash value of transaction in a set
        uint index = uint(keccak256(abi.encodePacked(now, tranSet.transHash[0]))) 
                     % tranSet.transHash.length;
        bytes32 selectedTran = tranSet.transHash[index];
        
        // Use sha256 to form a voucher
        voucher = keccak256(abi.encodePacked(now, selectedTran, index+1));
       
        // Record each voucher in the logger
        logger[tranSet.height][voucher] = true;
        
        blockheight += 1;
        // return voucher;
        emit GetVoucher(voucher); // For test
    }
    
    // Function of checking block height
    function CheckHeight() public restricted {
        /* Cancel voucher record for malicious miners
           who do not actually publish blocks */
        if(blockheight != 1){ // "1" is used for test, real-use is: blockheight != block.number
            logger[blockheight][voucher] = false;
            blockheight -= 1;
        }else {
            
            // Change registration state of valid miners
            miners[tranSet.creator].regState = 'registered';
        }
        voucher = '';
    }
    
    // Function of checking the validity of blocks
    function CheckBlock(bytes32 _voucher, bytes32 pre_hash,
        bytes32 current_hash, uint _height) public restricted returns (bool) {
        // Check condition
        if(logger[_height][_voucher] && !verifiedVoucher[_voucher] 
            && verifiedBlock[pre_hash])
        {
            verifiedVoucher[_voucher] = true;
            verifiedBlock[current_hash] = true;
            //return true;
            emit isValid(true); // For test
        }else {
            if(_height == blockheight){
                blockheight -= 1;
            }
            // return false;
            emit isValid(false); // For test
        }
    }
    
    // Function of withdrawing the deposit
    function Withdraw() public payable {
        string storage _regState = miners[msg.sender].regState;
        
        // Only the miners with "registered" can withdraw the deposit     
        require(bytes(_regState).length == bytes('registered').length);
        msg.sender.transfer(deposit);
        delete miners[msg.sender];
    }
}
