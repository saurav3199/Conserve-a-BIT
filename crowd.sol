pragma solidity >=0.4.22 <0.6.0;

contract ProjectGenerator {
    Project[] public Projects;
    mapping (address => uint) public balances;
    
    function createProject(string memory project_name ,uint deadline, string memory description, uint projectGoal) public {
        Project newProject = new Project(msg.sender, deadline, description, projectGoal, project_name);
        Projects.push(newProject);
    }
    
    function AllProjects() public view returns (Project[] memory) {
        return Projects;
    }
    
     function insert(uint val, address contri) external {
        balances[contri] = balances[contri] + val;
    }
}

contract Project {
    
    ProjectGenerator ProjectGeneratorInstance = ProjectGenerator(0xe46b2D8B3A5CCf2dF628468dEe2F3Ec1e85E7A28);
    
    struct Request {
        string description;
        uint value;
        bool complete;
        uint disapprovalCount;
        mapping(address => bool) disapprovals;
    }
    
    enum State {
        Fundraising,
        Expired,
        Successful
    }
    
    
    string public description;
    address payable public creator;
    address[] public contributors;
    bool[] public contributorsvote;
    Request[] public requests;
    uint public warning;
    uint public contributorsCount;
    uint public withdrawn_amount;
    uint public projectGoal;
    uint public startTime;
    uint public deadline;
    uint public moneyRaised;
    string public projectname;
    
    mapping (address => uint) public contributions;
    
    State public state = State.Fundraising;
    
    modifier inState(State _state) {
        require(state == _state);
        _;
    }
    
    function getDetails() public view returns 
    (
        string memory projectName,
        address payable projectCreator,
        string memory projectDesc,
        uint deadlines,
        State currentState,
        uint amountCollected,
        uint goalAmount
    ) {
        projectName = projectname;
        projectCreator = creator;
        projectDesc = description;
        deadlines = deadline;
        currentState = state;
        amountCollected = moneyRaised;
        goalAmount = projectGoal;
        
    }
    
    constructor (address payable manager, uint duration, string memory descript, uint goal, string memory name) public {
        creator = manager;
        projectname= name;
        startTime = now;
        deadline = now + (duration * 1 days);
        description = descript;
        projectGoal = goal;
        moneyRaised = 0;
        contributorsCount = 0;
        
    }
    
    function support () inState(State.Fundraising) payable public{
        require(msg.sender != creator);
        contributors.push(msg.sender);
        contributions[msg.sender] = contributions[msg.sender] + (msg.value);
        moneyRaised = moneyRaised + (msg.value);
        contributorsCount++;
        FundingCompleteOrExpired();
        //creator.transfer(msg.value);
    }
    
    function FundingCompleteOrExpired() public
    {
        if (now > deadline) 
        {
            if (moneyRaised >= projectGoal)
            {
                state = State.Successful;
                //vendorAllotment();
            }
            else
            {
                state = State.Expired;
            }
            //checkGoalStatus();
        }
    }

    function requestFunds(uint requireFundAmount, string memory  reason) public 
    {
        require(creator==msg.sender);
        Request memory newRequest = Request({
           description: reason,
           value: requireFundAmount,
           complete: false,
           disapprovalCount: 0
        });
        
        requests.push(newRequest);
    }
    
    function DisapproveRequest(uint index) public {
        Request storage request = requests[index];
            //
            bool check=false;
            for (uint i=0; i<contributors.length; i++) {
            if (contributors[i] == msg.sender) {
                check=true;
            }
        }
            // 
        require(check == true);
        require(!request.disapprovals[msg.sender]);

        request.disapprovals[msg.sender] = true;
        request.disapprovalCount++;
    }
    
    
    // function callFinalizeRequest(uint index) public
    // {
    //     if(now > deadline)
    //     finalizeRequest(index);
    // }
    
    function finalizeRequest(uint index) public  {
        Request storage request = requests[index];
        require(!request.complete);
        uint hundredtimes=100*request.disapprovalCount;
        if(hundredtimes>=50*contributorsCount){
            warning++;
        }
        if(hundredtimes>=60*contributorsCount){
            warning++;
        }
        if(hundredtimes >=70*contributorsCount){
            warning++;
        }
        if(hundredtimes>=80*contributorsCount){
            warning++;
        }
        if(hundredtimes>=90*contributorsCount){
            warning++;
        }
        if(warning>=2){
            // project quit funds given back
            uint remaining_amount = moneyRaised - withdrawn_amount;
            for (uint i=0; i<contributors.length; i++) {
                ProjectGeneratorInstance.insert(contributions[contributors[i]], contributors[i]);
                
            }
            state=State.Expired;
        }
        else{
            // give to creator
            creator.transfer(request.value);
            withdrawn_amount = withdrawn_amount + request.value;
        }
    }
}
