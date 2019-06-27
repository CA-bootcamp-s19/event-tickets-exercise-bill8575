pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details 
        and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to 
        the creator of the contract when it is initialized.
    */

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;
    
    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), 
        totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and 
        how many tickets each buyer purchases.
    */

    struct numberOfTicketsByBuyer {
        mapping(address => uint) numberOfTickets;
    }

    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => numberOfTicketsByBuyer) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */

    mapping (uint => Event) public events;      

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */

    modifier isOwner() { require (owner == msg.sender); _;}

    modifier eventIsOpen(uint eventId) { require (events[eventId].isOpen); _;}

    modifier sufficientFund(uint eventId, uint _numberOfTickets) { require(msg.value >= _numberOfTickets*PRICE_TICKET); _;} 

    modifier enoughTicketsInStock(uint eventId, uint _numberOfTickets) { require(events[eventId].totalTickets >= _numberOfTickets); _;} 

    modifier buyerHasBoughtTicketsBeforeRefund(uint eventId) { require(events[eventId].buyers[msg.sender].numberOfTickets[msg.sender] > 0); _;} 

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, 
        and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */

    function addEvent(string memory _description, string memory _URL, uint _numTickets) 
        public 
        isOwner()
        returns(uint eventID) 
    {
        events[idGenerator].description = _description;
        events[idGenerator].website = _URL;
        events[idGenerator].totalTickets = _numTickets;
        events[idGenerator].isOpen = true;
        uint eventId = idGenerator;
        idGenerator += 1;
        emit LogEventAdded(_description, _URL, _numTickets, eventId);

        return (eventId);
    } 

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */

    function readEvent(uint eventId) 
        public 
        view
        isOwner()
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen) 
    {
        description = events[eventId].description;
        website = events[eventId].website;
        totalTickets = events[eventId].totalTickets;
        sales = events[eventId].sales;
        isOpen = events[eventId].isOpen;
        return (description, website, totalTickets, sales, isOpen);
    }


    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */

    function buyTickets(uint eventId, uint numberOfTickets)
        public
        payable
        eventIsOpen(eventId)
        sufficientFund(eventId, numberOfTickets)
        enoughTicketsInStock(eventId, numberOfTickets)
    {
        address payable ticketBuyer;
        ticketBuyer = msg.sender;

        uint paymentFromBuyer = msg.value;
        uint paymentRequired = numberOfTickets*PRICE_TICKET;

        if ( events[eventId].totalTickets >= numberOfTickets ) {
            events[eventId].buyers[ticketBuyer].numberOfTickets[ticketBuyer] += numberOfTickets;
            events[eventId].totalTickets -= numberOfTickets;
            events[eventId].sales += numberOfTickets;

            // Check for overpayment
            if (paymentFromBuyer > paymentRequired)
            {
                uint surplusToRefund = paymentFromBuyer-paymentRequired;
                ticketBuyer.transfer(surplusToRefund);
                // events[eventId].sales -= surplusToRefund;
            }

            emit LogBuyTickets(ticketBuyer, eventId, numberOfTickets);

        } 

    }    

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */

    function getRefund(uint eventId)
        public
        payable
        buyerHasBoughtTicketsBeforeRefund(eventId)    
    {
        address payable refundRequester;

        refundRequester = msg.sender;

        uint requesterHasTickets = events[eventId].buyers[refundRequester].numberOfTickets[refundRequester];
        if (requesterHasTickets>0) {
            uint amountRefund = requesterHasTickets*PRICE_TICKET;
            events[eventId].totalTickets += requesterHasTickets;
            events[eventId].sales -= requesterHasTickets;
            events[eventId].buyers[refundRequester].numberOfTickets[refundRequester] = 0;
            uint numberOfTicketsRefunded = requesterHasTickets; 

            refundRequester.transfer(amountRefund);           
            emit LogGetRefund(refundRequester, eventId, numberOfTicketsRefunded);
        }

    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets 
        that the msg.sender has purchased.
    */

    function getBuyerNumberTickets(uint eventId)
        public
        view
        returns(uint _numberOfTickets) 
    {
        address buyer = msg.sender;        
        _numberOfTickets = events[eventId].buyers[buyer].numberOfTickets[buyer];
        // _buyer = buyer;
        return (_numberOfTickets);

    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */

    function endSale(uint eventId)
        public
        payable
        isOwner()
    {
        
        address payable contractOwner = msg.sender;

        events[eventId].isOpen = false;
        uint balance = events[eventId].sales*PRICE_TICKET;
        contractOwner.transfer(balance);

        emit LogEndSale(contractOwner, balance, eventId);            
    }    

    function() payable external {
        revert();
    }

}
