includes IntMsg;

module AppRingM {
  provides {
	interface StdControl;
  }
  uses {
	interface Timer;
	interface Leds;
	interface StdControl as TempControl;
	interface SendMsg;
	interface ADC;
	interface ReceiveMsg;

  }
}

implementation {
	TOS_Msg msg;
	int wait;

	//Local function to get next node address
	uint16_t nextNode(){
		return ((TOS_LOCAL_ADDRESS+1)%10);
	}

	/* Sensor initialization */
	command result_t StdControl.init(){
		// LEDs initialization
		call Leds.init();
		// Switch on the green LED
		call Leds.greenOn();

		//Initialize module variables
		wait = 0;
		return SUCCESS;
	}

	/* Start everything! For the moment, only the Timer component frequency is defined */
	command result_t StdControl.start() {
		// Start a timer generating a clock signal each 1000 ms for the first node
		if(TOS_LOCAL_ADDRESS==0)
			call Timer.start(TIMER_REPEAT,1000);	
		return SUCCESS;
	}

	/* Stop the application execution.
	   It only deactivates the Timer component.
	*/
	command result_t StdControl.stop() {
		// Call to the stop() function of Timer component
		if(TOS_LOCAL_ADDRESS==0)
			call Timer.stop();
		return SUCCESS;
	}

	/*This is the event handler executed when "Timer.fired" (clock signal) event happens */
	event result_t Timer.fired() {
		//Wait for 5 seconds before asking for data
		//It let the other nodes boot
		if(wait>4)
			return call ADC.getData();
		wait++;
		return SUCCESS;
	}


	/* This is the event handler executed when "dataReady" event happens.
	   When the detection module read is over, the data is put into
	   data field of msg 
	*/
  
	async event result_t ADC.dataReady(uint16_t data){
		//Aliasing between an IntMsg and msg data field
		IntMsg *intmsg = (IntMsg*)(&msg.data);



		//fill the structure
        intmsg->val = data;
		intmsg->src =TOS_LOCAL_ADDRESS; 

		//Switch on the yellow led
		call Leds.yellowOn();
		//switch on the red led
		 call Leds.redOn();
		dbg(DBG_USR1, "Preparing to send {.src = %d, .val = %d} to %d", intmsg->src, intmsg->val, nextNode());
   		
   		//send the message
   		call SendMsg.send(nextNode(),sizeof(IntMsg),&msg);
		return data;
	}


	/* This is the event handler executed when "sendDone" (msg sent) event happens */
	event result_t SendMsg.sendDone(TOS_MsgPtr sentMsg, bool success) {
		IntMsg *intmsg = (IntMsg *)&(sentMsg->data);
		
		//Switch off the yellow led to indicate retransmission is done
		call Leds.yellowOff();
		//Switch off the red led to indicate produced data is sent
		call Leds.redOff();
		// Print a debug message on USR1 profile
		dbg(DBG_USR1, "Sent {.src = %d, .val = %d} to %d", intmsg->src, intmsg->val, nextNode());
		return SUCCESS;
	}

	/* This is the event handler executed when "receive" (msg received) event happens.
	   The yellow led is switched on and the received message "rcvMsg" is sent
	   to the next node in the ring. 
	*/

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr rcvMsg) {
		IntMsg *intmsg = (IntMsg *)&(rcvMsg->data);
		dbg(DBG_USR1, "Received {.src = %d, .val = %d}", intmsg->src, intmsg->val);

		//If the message originates from this node, do nothing
		//otherwise transmit it to the next node
		if (TOS_LOCAL_ADDRESS==0){
			dbg(DBG_USR1, "Loop for {.src = %d, .val = %d}", intmsg->src, intmsg->val);
		}
		else{
			
	       	dbg(DBG_USR1, "Retransmission of {.src = %d, .val = %d} to %d", intmsg->src, intmsg->val, nextNode());
	       	call SendMsg.send(nextNode(),sizeof(IntMsg),rcvMsg);
        }
		return rcvMsg;
	}

}
 