pragma solidity ^0.5.0;

    /*
        The EventTickets contract keeps track of the details and ticket sales of one event.
     */

contract EventTickets {

    /*
        Create a public state variable called owner.
        Use the appropriate keyword to create an associated getter function.
        Use the appropriate keyword to allow ether transfers.
     */

    uint   TICKET_PRICE = 100 wei;

    address public owner;

    // function getTickets public ret
    /*
        Create a struct called "Event".
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
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

    Event myEvent;

    /*
        Define 3 logging events.
        LogBuyTickets should provide information about the purchaser and the number of tickets purchased.
        LogGetRefund should provide information about the refund requester and the number of tickets refunded.
        LogEndSale should provide infromation about the contract owner and the balance transferred to them.
    */

    event LogBuyTickets(address buyer, uint numberOfTickets );

    event LogGetRefund(address buyerToRefund, uint numberOfTicketsToRefund);

    event LogEndSale(address owner, uint balanceTransfer);

    // event LogTicketCount(uint )

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */

    modifier isOwner() { require (owner == msg.sender); _;}

    modifier eventIsOpen() { require (myEvent.isOpen); _;}

    modifier sufficientFund(uint _numberOfTickets) { require(msg.value >= _numberOfTickets*TICKET_PRICE); _;} 

    modifier enoughTicketsInStock(uint _numberOfTickets) { require(myEvent.totalTickets >= _numberOfTickets); _;} 


    /*
        Define a constructor.
        The constructor takes 3 arguments, the description, the URL and the number of tickets for sale.
        Set the owner to the creator of the contract.
        Set the appropriate myEvent details.
    */

    constructor(string memory _description, string memory _URL, uint _numberOfTicketsForSale) public {
    /* Here, set the event specifics and 
       the isOpen flag to true */
        owner = msg.sender;
        myEvent.description = _description;
        myEvent.website = _URL;
        myEvent.totalTickets = _numberOfTicketsForSale;
        myEvent.isOpen = true;
    }

    
    /*
        Define a funciton called readEvent() that returns the event details.
        This function does not modify state, add the appropriate keyword.
        The returned details should be called description, website, uint totalTickets, uint sales, bool isOpen in that order.
    */
    function readEvent() 

        public 
        view
        isOwner()
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen) 
    {
        description = myEvent.description;
        website = myEvent.website;
        totalTickets = myEvent.totalTickets;
        sales = myEvent.sales;
        isOpen = myEvent.isOpen;
        return (description, website, totalTickets, sales, isOpen);
    }

    /*
        Define a function called getBuyerTicketCount().
        This function takes 1 argument, an address and
        returns the number of tickets that address has purchased.
    */
    function getBuyerTicketCount(address buyer)
        public
        view
        returns(uint _numberOfTickets) 
    {
        _numberOfTickets = myEvent.buyers[buyer].numberOfTickets[buyer];
        // _buyer = buyer;
        return (_numberOfTickets);

    }

    /*
        Define a function called buyTickets().
        This function allows someone to purchase tickets for the event.
        This function takes one argument, the number of tickets to be purchased.
        This function can accept Ether.
        Be sure to check:
            - That the event isOpen
            - That the transaction value is sufficient for the number of tickets purchased
            - That there are enough tickets in stock
        Then:
            - add the appropriate number of tickets to the purchasers count
            - account for the purchase in the remaining number of available tickets
            - refund any surplus value sent with the transaction
            - emit the appropriate event
    */
    function buyTickets(uint numberOfTickets)
        public
        payable
        eventIsOpen()
        sufficientFund(numberOfTickets)
        enoughTicketsInStock(numberOfTickets)
    {
        address payable ticketBuyer;
        ticketBuyer = msg.sender;

        uint paymentFromBuyer = msg.value;
        uint paymentRequired = numberOfTickets*TICKET_PRICE;

        if ( myEvent.totalTickets >= numberOfTickets ) {
            myEvent.buyers[ticketBuyer].numberOfTickets[ticketBuyer] += numberOfTickets;
            myEvent.totalTickets -= numberOfTickets;
            myEvent.sales += numberOfTickets;

            // Check for overpayment

            if (paymentFromBuyer > paymentRequired)
            {
                uint surplusToRefund = paymentFromBuyer-paymentRequired;

                // surplusToRefund *= 10;
                // Why would mulitplying by 10 blow up on the transfer??
                // Should be just a logic not a system bug!!
                ticketBuyer.transfer(surplusToRefund);
                myEvent.sales -= surplusToRefund;
            }

            emit LogBuyTickets(ticketBuyer, numberOfTickets);

        } 

    }
    
    /*
        Define a function called getRefund().
        This function allows someone to get a refund for tickets for the account they purchased from.
        TODO:
            - Check that the requester has purchased tickets.
            - Make sure the refunded tickets go back into the pool of avialable tickets.
            - Transfer the appropriate amount to the refund requester.
            - Emit the appropriate event.
    */

    function getRefund()
        public
        payable    
    {
        address payable refundRequester;

        refundRequester = msg.sender;

        uint requesterHasTickets = myEvent.buyers[refundRequester].numberOfTickets[refundRequester];
        if (requesterHasTickets>0) {
            uint amountRefund = requesterHasTickets*TICKET_PRICE;
            myEvent.totalTickets += requesterHasTickets;
            myEvent.sales -= requesterHasTickets;
            myEvent.buyers[refundRequester].numberOfTickets[refundRequester] = 0;
            uint numberOfTicketsRefunded = requesterHasTickets; 

            refundRequester.transfer(amountRefund);           
            emit LogGetRefund(refundRequester, numberOfTicketsRefunded);
        }

    }

    /*
        Define a function called endSale().
        This function will close the ticket sales.
        This function can only be called by the contract owner.
        TODO:
            - close the event
            - transfer the contract balance to the owner
            - emit the appropriate event
    */
    function endSale()
        public
        payable
        isOwner()
    {
        address payable eventOwner = msg.sender;
        
        myEvent.isOpen = false;
        eventOwner.transfer(myEvent.sales*TICKET_PRICE);

        emit LogEndSale(owner, myEvent.sales);
    }    

    function() payable external {
        revert();
    }

}