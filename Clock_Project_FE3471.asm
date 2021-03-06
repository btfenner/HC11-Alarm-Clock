* Benjamin T. Fenner, FE3471
* This Program will simulate a simple clock with Hours(12) & Minutes(60) on 4 7-Segment Displays.
* Using pin PE7 to adjust time and alarm time.
* The user can change the alarm time by pressing PA0. If the user presses PA0 again The program will allow them to change the time.
* Each digit can be changed by using the Potentiometer. Once the desired digit is displayed press to advance to next digit.
* PM is the dot on the leftmost 7-Segment Display. Once PM/AM is selected the program will return you to regular clock.
* When the alarm time and clock time are equal the buzzer will activate. Press PA0 to turn alarm off. (Note changing time and..
* the alarm will not be active) Alarm automaticly turns off after 30 seconds.
* Version 06

* 12/14/2017

PD2	EQU  %00000100
PD3	EQU  %00001000
PD4	EQU  %00010000	
PD5	EQU  %00100000	
PortDc  EQU  $1009
PortD   EQU  $1008
portB	EQU  $1004
TMSK1	EQU  $1022
TFLG1	EQU  $1023
TMSK2   EQU  $1024
TFLG2   EQU  $1025
PACTL   EQU  $1026
TOC5	EQU  $101E
TCNT	EQU  $100E
Counter EQU  $000C
Alarm30 EQU  $001D
TCTL1a  EQU  $20
TCTL2 	EQU  $21
TFLG1a 	EQU  $23 
ADCTL   EQU  $30
ADR1    EQU  $31
BASE    EQU  $1000
TOC3    EQU  $101A
Alarm1	EQU  $001C
TCTL1	EQU  $1020


	ORG  $0000	* List of Hex Values
	FCB  $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$0A,$00,$00,$00	* Hex values 0-9 for 7-Segment
	ORG  $0010	* Time is stored here.
	FCB  $06,$06,$3F,$3F,$80,$06,$06,$3F,$06,$80,$77,$78,$00,$00,$00,$00		*Time, and then followed by alarm Time

	ORG  $C000	* Start Here
	LDX  #$1000
	LDS  #$8FFF	* Load Stack
	LDAA #%11000011 * configure PD2-PD5 as output
	STAA PortD

		* Turns on A/D conversions

	LDAA #%00100111			* Turns on PE7
        STAA ADCTL,X			* this triggers the A/D

		* Sets up PA0

	LDAA	#$01		* Let TCTL2 to accept a rising edge on PA0.
	STAA	TCTL2,X

		* Output Compare

	LDD  TCNT	* Loads REG D as the current time
	STD  TOC5	* Saves REG D into the time keep REG TOC5 so interrupt can happen
	LDAA #$29	* Loads REG A as 0010 1000
	STAA TFLG1	* Clears Flag OC5F & IC3F
	LDAA #$08
	STAA TMSK1	* Sets the 0C5I to allow intrupts 
	BRA  Back
BackClr	LDAA #$01	* Let TCTL2 to accept a rising edge on PA0.				* PA0 Is reset to accpet a rising edge: PA0 1 in Bit 0
	STAA TFLG1	* Clear Flag at IC3F so a capture can be seen on a falling edge.

Back	CLI		* Unmask IRQ Interrupts						

	LDAA $10	* Load High Digit of Hour	
	STAA portB					
	LDAA #PD5					
	STAA PortDc	* Turn on PD5 7-Display		
	JSR  Delay

	LDAA $11	* Load Low Digit of Hour	
	STAA portB					
	LDAA #PD4					
	STAA PortDc	* Turn on PD4 7-Display		
	JSR  Delay

	LDAA $12	* Load High Digit of Minute	
	STAA portB					
	LDAA #PD3					
	STAA PortDc	* Turn on PD3 7-Display		
	JSR  Delay

	LDAA $13	* Load Low Digit of Minute		
	STAA portB					
	LDAA #PD2					
	STAA PortDc	* Turn on PD2 7-Display		
	JSR  Delay

	LDAA $14	* PM/AM		
	STAA portB					
	LDAA #PD4					
	STAA PortDc	* Turn on PD5 7-Display		
	JSR  Delay

		
		* Following code will check to see if the alarm is on. ie; the current time..
		* equals alarm time and then will wait for the PAO to be pressed.


	LDAA  Alarm1		* Checks if on
	CMPA  #$00
	BNE   AlarmOn
F2	JSR   AlarmCheck
	BRA   Forward
AlarmOn BRCLR	TFLG1a,X 01  Back	* This will check if the flag on TMSK1 bit 0 is flaged to 1.
	LDAA  #$00			* Reset so alarm is off. $01 on, $00 off.
	STAA  Alarm1
	LDAA  #$00                 	* Set OM3 and OL3 in TCTL1 to
        STAA  TCTL1          		* 01 so PA5 will toggle on each compare
BackC1	BRA   BackClr


		* Following code will allow user to change time or alarm with the potentiometer.


Forward	BRCLR	TFLG1a,X 01  Back	* This will check if the flag on TMSK1 bit 0 is flaged to 1.	
	

	LDAA #$01	* Let TCTL2 to accept a rising edge on PA0.
	STAA TFLG1a,X	* Clear Flag at IC3F so a capture can be seen.
	PSHY

	LDY  #$001A	* Set REG Y to Location for A in HEX
	JSR  DisA1T1	* Is a 5 second delay to give user time to press PA0 to...
			* advance to Clock seting, Displays A1.
	
	BRCLR	TFLG1a,X 01  JMPa	* This will check if the flag on TMSK1 bit 0 is flaged to 1.

	LDY  #$001B	* Set REG Y to Location for A in HEX
	JSR  DisA1T1	* Is a 5 second delay Displays t1.

	LDY  #$0010		
	JSR  timeSet	* Will set time for the Clock
	PULY

	JSR  Delay1
	BRA  BackC1	* Resets the PA0 Flag
	
JMPa	LDAA #$01	* Clear TCTL2
	STAA TFLG1a,X	* Set Flag at IC3F
	LDY  #$0015		
	JSR  timeSet	* Will set time for the alarm
	PULY

	JSR  Delay1
	BRA  BackC1	* Resets the PA0 Flag		
	SWI


	* This sub-program will look where the Hex digit is located so that the program...
	* can return the next increment of Hex Digit. if $06 it would change to $5B

	
	ORG  $C150
Convert	LDX  #$0000	* Load X as zero
zLoop1  LDAB $00,X	* Load The Hex digits 1-9
	INX		* Increase X by 1
	CBA		* Compare The Hex code in mem to REG A Hex Code
	BNE  zLoop1
	RTS

	
	* Delay Sub for 5ms so the 7-Segment Display has time to shine


	ORG  $C200
Delay	PSHX
	LDX  #1000	* 1000 is N value for 3ms
dLoop	DEX
	BNE  dLoop
	PULX
	RTS

	* 1 second Delay

Delay1	PSHB	
	PSHX
	LDAB #6
oLoop	LDX  #65535
iLoop   DEX  
        BNE  iLoop
	DECB
	BNE  oLoop
	PULX
	PULB
	RTS

		* Low Hour and Low Minute set with potentiometer


LH	LDAA #$01		* Let TCTL2 to accept a rising edge on PA0.
	STAA TFLG1a,X		* Clear Flag at IC3F so a capture can be seen.
	LDX  #$1000
Loop2   LDAB ADR1,X
	CMPB #25
	BLS  Digit0
	CMPB #50
	BLS  Digit1
	CMPB #75
	BLS  Digit2
	CMPB #100
	BLS  Digit3
	CMPB #125
	BLS  Digit4
	CMPB #150
	BLS  Digit5
	CMPB #175
	BLS  Digit6
	CMPB #200
	BLS  Digit7
	CMPB #225
	BLS  Digit8
	CMPB #255
	BLS  Digit9
Digit0	LDAA $00
	BRA  LMLoop
Digit1	LDAA $01
	BRA  LMLoop
Digit2	LDAA $02
	BRA  LMLoop
Digit3	LDAA $03
	BRA  LMLoop
Digit4	LDAA $04
	BRA  LMLoop
Digit5	LDAA $05
	BRA  LMLoop
Digit6	LDAA $06
	BRA  LMLoop
Digit7	LDAA $07
	BRA  LMLoop
Digit8	LDAA $08
	BRA  LMLoop
Digit9	LDAA $09
LMLoop	STAA    PortB
	BRCLR	TFLG1a,X 01  Loop2	* This will check if the flag on TMSK1 bit 0 is flaged to 1.
	RTS


		* High Minute Potentiometer sub 0-5


HM	LDAA #PD3					
	STAA PortDc	* Turn on PD3 7-Display	
	LDAA #$01	* Let TCTL2 to accept a rising edge on PA0.
	STAA TFLG1a,X	* Clear Flag at IC3F so a capture can be seen.
Loop22  LDAB ADR1,X
	CMPB #42
	BLS  D0
	CMPB #84
	BLS  D1
	CMPB #126
	BLS  D2
	CMPB #168
	BLS  D3
	CMPB #210
	BLS  D4
	CMPB #255
	BLS  D5
D0	LDAA $00
	BRA  HMLoop
D1	LDAA $01
	BRA  HMLoop
D2	LDAA $02
	BRA  HMLoop
D3	LDAA $03
	BRA  HMLoop
D4	LDAA $04
	BRA  HMLoop
D5	LDAA $05
HMLoop	STAA    PortB
	BRCLR	TFLG1a,X 01  Loop22	* This will check if the flag on TMSK1 bit 0 is flaged to 1.
	RTS


		* Low Hour with High Hour being 1 Potentiometer sub 0-2


IfHH1	LDAA #PD4					
	STAA PortDc	* Turn on PD4 7-Display	
	LDAA #$01	* Let TCTL2 to accept a rising edge on PA0.
	STAA TFLG1a,X	* Clear Flag at IC3F so a capture can be seen.
Loop77  LDAB ADR1,X
	CMPB #85
	BLS  Dis0
	CMPB #170
	BLS  Dis1
	CMPB #255
	BLS  Dis2
Dis0	LDAA $00
	BRA  LOOP17
Dis1	LDAA $01
	BRA  LOOP17
Dis2	LDAA $02
LOOP17	STAA PortB
	BRCLR	TFLG1a,X 01  Loop77	* This will check if the flag on TMSK1 bit 0 is flaged to 1.
	RTS

		* High Hour Set With Potentiometer


Hour	LDAA #PD5					
	STAA PortDc	* Turn on PD5 7-Display	
	LDAA #$01	* Let TCTL2 to accept a rising edge on PA0.
	STAA TFLG1a,X	* Clear Flag at IC3F so a capture can be seen.
Loop66  LDAB ADR1,X
	CMPB #125
	BLS  D00H
	CMPB #255
	BLS  D11H
D00H	LDAA $00
	BRA  HHLoop1
D11H	LDAA $01
HHLoop1	STAA PortB
	BRCLR	TFLG1a,X 01  Loop66	* This will check if the flag on TMSK1 bit 0 is flaged to 1.
	RTS


		* PM or AM Set with Potentiometer


AMPM	LDAA #PD4					
	STAA PortDc	* Turn on PD5 7-Display	
	LDAA #$01	* Let TCTL2 to accept a rising edge on PA0.
	STAA TFLG1a,X	* Clear Flag at IC3F so a capture can be seen.
Loop19  LDAB ADR1,X
	CMPB #125
	BLS  AM1
	CMPB #255
	BLS  PM1
AM1	LDAA #$00
	BRA  AMLoop
PM1	LDAA #$80
AMLoop	STAA PortB
	BRCLR	TFLG1a,X 01  Loop19	* This will check if the flag on TMSK1 bit 0 is flaged to 1.
	RTS


		* Lets user set time or alarm.


timeSet JSR  Delay	* Set AM or PM
	JSR  AMPM
	STAA $04,Y

	JSR  Delay	* Sets High Hour of Alarm
	JSR  Hour
	STAA $00,Y

	LDAA $10
	CMPA #$06
	BNE  Not1

	* IF HH is 1 code.
	JSR  Delay
	JSR  IFHH1	* If the High hour is 1 this will only allow Low Hour to be 0,1, or 2.
	STAA $01,Y
	BRA  LMin	* Moves to the next digit.

Not1	LDAA #PD4	* Sets Low hour of Alarm				
	STAA PortDc	* Turn on PD3 7-Display	
	JSR  Delay
	JSR  LH
	STAA $01,Y

LMin	JSR  Delay	* Sets High minute of Alarm
	JSR  HM
	STAA $02,Y

	LDAA #PD2	* Sets Low minute of Alarm				
	STAA PortDc	* Turn on PD5 7-Display	
	JSR  Delay
	JSR  LH
	STAA $03,Y

	JSR  Delay1									* TFLG1 has a 0 in bit 0. So it will not accept a rising edge.

	RTS										

		* This will Display A1 or T1 so the user knows what is active for change.
		* It is a 5 second delay.

	
DisA1t1	PSHB	
	PSHX
	LDAB #120
oLoop5	LDX  #65535
iLoop5  DEX  

	LDAA $00,Y	* Load A in HEX					
	LDAA #PD4					
	STAA PortDc	* Turn on PD4 7-Display		
	JSR  Delay

	LDAA #$06	* Load 1 in HEX	
	STAA portB					
	LDAA #PD3					
	STAA PortDc	* Turn on PD3 7-Display		
	JSR  Delay

        BNE  iLoop5
	DECB
	BNE  oLoop5
	PULX
	PULB
	RTS
	

	* This sub will check to see if the current time equals alarm time.


AlarmCheck LDAA  $10	* Load High Hour
	CMPA  $15	* Compare to Alarm High Hour
	BNE   Back3
	LDAA  $11	* Load Low Hour
	CMPA  $16	* Compare to Alarm Low Hour
	BNE   Back3
	LDAA  $12	* Load High Minute
	CMPA  $17	* Compare to Alarm High Minute
	BNE   Back3
	LDAA  $13	* Load Low Minute
	CMPA  $18	* Compare to Alarm Low Minute
	BNE   Back3
	LDAA  $14	* Load AMPM
	CMPA  $19	* Compare to Alarm AMPM
	BNE   Back3
	LDAA  #$01
	STAA  Alarm1	* Stores 1 into Mem for a check if alarm on.
	PSHX
	LDX   #$0000    * Resets the Alarm30 to #$0000 for a 30second delay.
	STX   Alarm30
	LDX   Counter
	CPX   #100
	BHI   Loop100	* Makes sure buzzer doesn't come back on after alarm is off, 1 min.
	LDAA  #$20
	STAA  TFLG1
	LDAA  #$10      * Set OM3 and OL3 in TCTL1 to
        STAA  TCTL1     * 01 so PA5 will toggle on each compare
Loop100	PULX
Back3	RTS


		* Keeping Time Interrupts


	ORG  $00D9	* Speaker Interrupt
	JMP  $C500

	ORG  $00D3	* Clock Interrupt
	JMP  $C550

		* This Interrupt will allow the speaker to be heard.

	ORG  $C500	* Speaker interrupt
	LDD  TOC3	* TOC3 is connected to PA5
	ADDD #12000
	STD  TOC3
	LDAA #$20	* Sets Flag
	STAA TFLG1
	RTI	

		* This interrupt will Increment time 1 minute at a time.


	ORG  $C550	
	LDAA #$08	* Loads REG A as 0000 1000
	STAA TFLG1	* Clears Flag OC5F
	STAA TMSK1	* Sets the 0C5I to allow intrupts 
	CLI		* Unmask IRQ Interrupts

	LDAA Alarm1
	CMPA #$01 	* Checks if alarm is on.
	BNE  Aoff
	LDX  Alarm30
	INX
	STX  Alarm30
	CPX  #916 	* Check if 30 seconds have passed.
	BNE  Aoff
	LDAA #$00 	* Turns off alarm.
	STAA Alarm1 
	LDX  #$0000 	* Resets alarm for future use.
	STX  Alarm30

Aoff	LDX  Counter
	INX
	STX  Counter
	CPX  #1830
	BNE  Temp1

	LDD  TCNT
	ADDD #61800	* 60/0.03277 = 1830.942935; .942935*.03277/.0005m = 61800
	STD  TOC5
	BRA  Branch2
Temp1	CPX  #1831
	BNE  Branch2
	LDX  #$0000
	STX  Counter

	* now 1 minute has passed. We need to increase minutes by 1. 

	LDAA $13	* Load Low Minute
	JSR  Convert	* Convert to a num from 7-Segment Hex
	LDAA 00,X	* Load New Hex
	STAA $13	* Changes A to next Hex value
	CMPA #$0A	* compare is X = 0009
	BNE  Branch2	* branch if !=0 Branch back

	LDAA $00	* Load A as zero
	STAA $13	* Reset low minute to zero	
	LDAA $12	* Load High Minute
	JSR  Convert	* Convert to a num from 7-Segment Hex
	LDAA 00,X	* Load new Hex
	STAA $12	* Changes A to next Hex value
	CMPA #$7D	* If High Minute = 6
	BNE  Branch2	* If !=0 branch back
 
		* If 60 Minutes Increase hour By 1

	LDAA $00	* Load A as zero
	STAA $12	* Reset High minute to zero
	LDAA $10	* Loading High bit to see if It's a 0,1
	JSR  Convert
	CMPA #$06	* Compare to 1
	BNE  Skip	* Branch to bits 0-9 if less than 1
	LDAA $11	* Load low Hour
	JSR  Convert	* Convert to a num from 7-Segment Hex
	LDAA 00,X	* Load New Hex
	STAA $11	* Changes A to next Hex value

	CMPA #$5B	* Seeing if AM/PM Changed
	BNE  Pass
	LDAA $14
	CMPA #$80	* Check if it is PM or not
	BNE  Branch4
	LDAA #$00	* Set to AM
	STAA $14
	BRA  Branch2
Branch4 LDAA #$80	* Set to PM

Pass	CMPA #$4F	* If Low Hours = 3
	BNE  Branch2	* If !=0 branch back
	LDAA $01	* Load A as 01:00
	STAA $11	* Reset Low Hour to 01:00
	LDAA $00	* Seting High Hour to 0
	STAA $10
	BRA  Branch2

		* If High Hour <= 1

Skip	LDAA $11	* Load low Hour
	JSR  Convert	* Convert to a num from 7-Segment Hex
	LDAA 00,X	* Load New Hex
	STAA $11	* Changes A to next Hex value
	CMPA #$0A	* If Low Hours = 10
	BNE  Branch2	* If !=0 branch back

		* If High Hour > 1

Skip2	LDAA $00	* Load A as zero
	STAA $11	* Reset Low Hour to zero	
	LDAA $10	* Load High Hour
	JSR  Convert	* Convert to a num from 7-Segment Hex
	LDAA 00,X	* Load New Hex
	STAA $10	* Changes A to next Hex value
Branch2	RTI