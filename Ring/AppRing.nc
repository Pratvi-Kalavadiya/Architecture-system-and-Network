configuration AppRing {
}

implementation {
	// Les differents composants que necessite la mise en oeuvre de l'application.
	components Main, AppRingM,  LedsC, Temp, TimerC, GenericComm as Comm;

	// Liaison entre les composants 
	// different controls
 	Main.StdControl -> AppRingM.StdControl;
 	Main.StdControl -> TimerC;
	Main.StdControl -> Comm;

	//Implementation
	AppRingM.Timer -> TimerC.Timer[unique("Timer")]; 
    AppRingM.Leds -> LedsC; 
	AppRingM.TempControl -> Temp.StdControl;
 	AppRingM.ADC -> Temp;

	 //send and receive 
	AppRingM.SendMsg -> Comm.SendMsg[AM_INTMSG];
    AppRingM.ReceiveMsg -> Comm.ReceiveMsg[AM_INTMSG];
}
