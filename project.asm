#This is a mashup of classic games Sudoku and Connect 4. 
#Bitmap settings are 16 16 128 256 static data OR 8 8 64 512 static data for the debugging experience (recommended the first settings)

#How to play: Follow instructions in terminal; sudoku grid and connect 4 grid act like the 1st quadrant of a 2D graph

.data	
BackgroundColors:
	.space 600	#this is for the background array
	darkGrey: .word 0x505050
	lightGrey: .word 0x909090
	darkBlue: .word 0x5050ff
Map: .space 10000	#this is for bottom sudoku array
Colors:
	.space 224	#this is for top sudoku array
	red: .word 0xff8389
	blue: .word 0x8389ff
	green: .word 0x83ffbb
	yellow: .word 0xfff983
	pink: .word 0xff83c7
	orange: .word 0xffbb83
.space 100
APrompt: .asciiz "Start\n"	
MapPrompt: .asciiz "Pick a number between 1-3 (select a sudoku map to play on)\n"
SColPrompt: .asciiz "\n\nEnter column # from 1-4 (inclusive): "
SRowPrompt: .asciiz "\nEnter row # from 1-4 (inclusive): "
SWrNum: .asciiz "\nYou can either pick 1, 2, 3, or 4. Try again. (Imagine you're plotting coordinates in the first quadrant of a graph)\n"
ColorPrompt: .asciiz "\nEnter your color LOWERcase (g - green, y - yellow, p - pink, o - orange): "
WrPrompt: .asciiz "\nYou have either picked the wrong color or you have picked a spot that was already correctly filled in. Skip turn, doofus.\n"
Nice: .asciiz "\nNice! "
C4Prompt: .asciiz "Pick a column # 1-7 (inclusive) to place your Connect 4 piece: "
C4WrNum: .asciiz "\nTry again. You can only pick 1, 2, 3, 4, 5, 6, or 7. \n"

.text
main:
	jal Bg	#Draw the dark grey and light grey background using bitmap
	jal Setup	#store certain number balues associated with regsters for later use in connect 4
	jal useStack	#satisfy the requirement to utilize a stack to store a return address
	mainloop:
		User:
		li $v0, 42	#generate a random number
		li $a1, 3		#between 1 and 3
		syscall
		li $v0, 1
		syscall
		move $s7, $a0	#store in s7 the value of the current sudoku map being used
		j randMap	#select a random map for the sudoku board(out of 3)
		Phase1:	#First part of the user's turn; fill out the sudoku
			li $s6, 1	#register which keeps track of who's turn it is (1-user, 2-computer, 0-null)
			jal ColNum	#call the function to ask (and validate) an integer from the user for the desired column of the sudoku board
			jal RowNum	#call the function to ask (and validate) an integer from the user for the desired row of the sudoku board
			jal ValidSudoku	#call the function to ask (and validate) a color for their guess at the sudoku board
			Phase2:	#second part of user's turn; only happens upon completion of a correct color being chosen; choose a column in connect 4
			la $a0, Nice	#text to affirm success in phase 1
			li $v0, 4
			syscall
			j Connect4	#jump to function where a column is asked for and processed for connect 4
			aUser:	#point of interest; utilized when deciding which color to make the connect 4 piece
			jal CheckWin	#check for a 4 in a row in connect 4
		Computer:	#start of computer's turn
			li $s6, 2	#register which keeps track of who's turn it is (1-user, 2-computer, 0-null)
			j ComputerTurn	#jump to function to generate a random number for the connect 4 move
			aComputer:	#point of interest; utilized when deciding which color to make the connect 4 piece
			jal CheckWin	#check for a 4 in a row in connect 4
			
j userLoop	#jump to function that switches the sudoku board

li $v0, 10	 #exit program
syscall

##########################################

##########################################
useStack:	#satisfy the requirement to utilize a stack to store a return address; parent function
sw $ra, 0($sp)
jal minimumReq
lw $ra, 0($sp)
jr $ra

minimumReq:	#satisfy the requirement to utilize a stack to store a return address; child function
li $v0, 4
la $a0, APrompt
syscall
jr $ra
##########################################

##########################################
Setup:	#store certain number balues associated with regsters for later use in connect 4
li $s1, 8260543	#blue
li $s2, 16745353	#red

jr $ra
##########################################

##########################################
WColNum:	#display message to try again; incorrect number selection
	la $a0, SWrNum
	li $v0, 4
	syscall
ColNum:	#call the function to ask (and validate) an integer from the user for the desired column of the sudoku board
	li $v0, 4
	la $a0, SColPrompt
	syscall
	li $v0, 5	#gets input
	syscall
	move $t6, $v0
	sltiu $t8, $t6, 5
	bne $t8, 1, WColNum
jr $ra

##########################################

##########################################

WRowNum:	#display message to try again; incorrect number selection
	li $v0, 4
	la $a0, SWrNum
	syscall
RowNum:		#call the function to ask (and validate) an integer from the user for the desired row of the sudoku board
	li $v0, 4
	la $a0, SRowPrompt
	syscall
	li $v0, 5	#gets input
	syscall
	move $t7, $v0
	sltiu $t8, $t7, 5
	bne $t8, 1, WRowNum
jr $ra	
	
##########################################

##########################################

ValidSudoku:	#call the function to ask (and validate) a color for their guess at the sudoku board
	li $v0, 4
	la $a0, ColorPrompt	#display prompt asking for single char/color
	syscall
	li $v0, 12	#gets input
	syscall
	move $t8, $v0
	beq $t8, 103, setGrn	#green
	beq $t8, 121, setYel	#yellow
	beq $t8, 112, setPnk	#pink
	beq $t8, 111, setOng	#orange
	j Error
	
setGrn:	#take 3 digit input and change it into specific code for color
li $t8, 8650683
j LocateCoord	#jump to the function which determines which sudoku map to use this on
setYel:	#take 3 digit input and change it into specific code for color
li $t8, 16775555
j LocateCoord		#jump to the function which determines which sudoku map to use this on
setPnk:	#take 3 digit input and change it into specific code for color
li $t8, 16745415
j LocateCoord		#jump to the function which determines which sudoku map to use this on
setOng:	#take 3 digit input and change it into specific code for color
li $t8, 16759683
j LocateCoord	#jump to the function which determines which sudoku map to use this on
##########################################

##########################################

Wr:	#prompt used when a wrong coordinate/color is input (loops back to computer function, skipping the rest of user turn)
	la $a0, WrPrompt	#prompt to display when the user gets a guess wrong
	li $v0, 4
	syscall
	j Computer	#skip turn
	
	
LocateCoord:	#function which determines which sudoku map to use the color and coordinates on
	la $t0, Colors	#make space in t0 for upcoming data
	li $t0, 268500992	#this number is the origin for the bitmap display (the top left corner's address)
		ColCheck:	#uses the number of the map to determine which answer key to check against the inputs
			beq $s7, 0, S1Col
			beq $s7, 1, S2Col
			beq $s7, 2, S3Col
j	Error	#jump to error message, used for debugging

##########################################

##########################################
Findt3:	
#t3 is the bit that holds the corresponding answer to the input t0, and it is calculated by adding certain
#numbers to t0 and before splitting into a smaller branch of functions
	beq $s7, 0, t9512
	beq $s7, 1, t9768
	beq $s7, 2, t91024
		
t9512:
	lw $t3, 512($t0)	#used if the map number is 0
jr $ra	
t9768:
	lw $t3, 768($t0)	#used if the map number is 1
jr $ra	
t91024:
	lw $t3, 1024($t0)	#used if the map number is 2
jr $ra	#return address takes you back to the main function, before phase 2

Findt4:	#t4 is the bit that holds data if you have already filled in the corresponding space in the past, so data carries over between sudoku map switches
	beq $s7, 0, t41280
	beq $s7, 1, t41536
	beq $s7, 2, t41792
	
t41280:	#used when the map number is 0
	la $t4, 1280($t0)
jr $ra	
t41536:	#used when the map number is 1
	la $t4, 1536($t0)
jr $ra	
t41792:	#used when the map number is 2
	la $t4, 1792($t0)
jr $ra
##########################################

##########################################
ItsGreen:	#used when the correct answer for t0 is determined to be green
	jal Findt3	#jump to previous findt3 function
	bne $t3, 8650683, Wr	#compare t3 with 8650683, if theyre different, then the guess was wrong
	bne $t3, $t8, Wr	#compare t3 with t8, if theyre different, then the guess was wrong
	jal Findt4	#jump to findt4 function which preps t4 for the next function
	 lw $t5, green	#load the color green into t5
	j NextC4	#jump to the function which draws the sudoku dots in the bitmap
ItsYellow:	#used when the correct answer for t0 is determined to be yellow
	jal Findt3	#jump to previous findt3 function
	bne $t3, 16775555, Wr#compare t3 with 8650683, if theyre different, then the guess was wrong
	bne $t3, $t8, Wr	#compare t3 with t8, if theyre different, then the guess was wrong
	jal Findt4	#jump to findt4 function which preps t4 for the next function
	lw $t5, yellow	#load the color yellow into t5
	j NextC4	#jump to the function which draws the sudoku dots in the bitmap
ItsPink:	#used when the correct answer for t0 is determined to be pink
	jal Findt3	#jump to previous findt3 function
	bne $t3, 16745415, Wr#compare t3 with 8650683, if theyre different, then the guess was wrong
	bne $t3, $t8, Wr	#compare t3 with t8, if theyre different, then the guess was wrong
	jal Findt4	#jump to findt4 function which preps t4 for the next function
	 lw $t5, pink	#load the color pink into t5
	j NextC4	#jump to the function which draws the sudoku dots in the bitmap
ItsOrange:	#used when the correct answer for t0 is determined to be orange
	jal Findt3	#jump to previous findt3 function
	bne $t3, 16759683, Wr#compare t3 with 8650683, if theyre different, then the guess was wrong
	bne $t3, $t8, Wr	#compare t3 with t8, if theyre different, then the guess was wrong
	jal Findt4	#jump to findt4 function which preps t4 for the next function
	 lw $t5, orange	#load the color orange into t5
	j NextC4	#jump to the function which draws the sudoku dots in the bitmap


##########################################

##########################################
ComputerTurn:	#function to generate a random number between 1-7
	xor $v0, $v0, $0	#hard set v0 to 0
	li $v0, 42	#random number gen syscall
	li $a1, 7
	syscall
	move $t9, $a0
j ComputerInterjectionPoint	#jump to the point in my connect 4 code that places a marker, 
							#between the user input and the actual meat of the code
##########################################

##########################################
Bg:	#function to draw the whole background
la $t0, BackgroundColors	#make space for data on register t0
li $t0, 268500992		#place t0 on the origin of the bitmap display
li $t2, 128	#set up 128 iterations of a loop
lw $t4, darkGrey	#load colors into registers
lw $t5, lightGrey	
lw $t3, darkBlue	
	Background:	#draw dark grey background of display
		sw $t4, 0($t0)
		addi $t0, $t0, 4
		addi $t2, $t2, -1
	bne $t2, 0, Background 	#loop to background
userLoop:	#light grey loop that is called upon after the end of every turn by the user
lw $t4, darkGrey
lw $t5, lightGrey	
li $t2, 6	#set up loop with 6 iterations
li $t0, 268500992	#load t0 at origin of bitmap display
	SdkuBackground:	#loop for drawing the light grey squares behind the sudoku puzzle
		sw $t5, 0($t0)
		addi $t0, $t0, 4
		sw $t5, 0($t0)
		addi $t0, $t0, 4
		sw $t5, 0($t0)
		addi $t0, $t0, 8
		addi $t2, $t2, -1
	bne $t2, 0, SdkuBackground 

li $t2, 6	#set 6 iteration loop
li $t0, 268501120	#set t0 at the top left corner of the bottom half of the light grey squares in the bitmap display
	SdkuBackground2:	#loop for drawing the other two squares
		sw $t5, 0($t0)
		addi $t0, $t0, 4
		sw $t5, 0($t0)
		addi $t0, $t0, 4
		sw $t5, 0($t0)
		addi $t0, $t0, 8
		addi $t2, $t2, -1
	bne $t2, 0, SdkuBackground2 
bgt $s6, 0, User	#branch to user function if the game has advanced past the user function in the past, indicated by 0<s6
	li $t0, 268501088	#set t0 to the bit between the grey squares
	li $t2, 7	#loop iterate 7 times
	loop1:	#loop for drawing the dark grey line between the two sets of squares, for visibility help
		sw $t4, 0($t0)
		addi $t0, $t0, 4
		addi $t2, $t2, -1
	bne $t2, 0, loop1

	li $t0, 268501248	#set t0 the top left corner of the connect 4 board on the bitmap display
	li $t1, 6	#iterate loop 6 times
	Cnct4Background:	#loop for drawing the connect 4 background using dark blue
		li $t2, 7	#set up second loop to iterate 7 times
		loop2:	#nested loop for the purpose of skipping the right side of the screen when coloring in the bitmap
		sw $t3, 0($t0)
		addi $t0, $t0, 4 
		addi $t2, $t2, -1
		bne $t2, 0, loop2
	addi $t0, $t0, 4
	addi $t1, $t1, -1
	bne $t1, 0, Cnct4Background 
	
	
	la $t0, Map	#make space in t0 for more coloring
	lw $t5, lightGrey		#load light grey into t5
	li $t0, 268502272		#set t0 to the top left corner of the initial solution arrays down at the bottom, 
						#for the purpose of saving your answers when you switch between sudoku boards
						#and making it generally just look better in the end
	li $t2, 96	#iterate 96 times
	loop12:	#loop to draw the 4 horizontal lines that form the back of the sudoku solutions
	li $t1, 8	#iterate loop 8 times
	loop123:	#nested loop for making this drawing process more efficient
		sw $t5, 0($t0)
		addi $t0, $t0, 8
		addi $t2, $t2, -1
	bne $t2, 0, loop123
	addi $t1, $t1, -1
	addi $t0, $t0, 64
	bne $t2, 0, loop12
	
	
	s1a:
li $t0, 268501504			#load t0 as top left corner of the array
						# answer key/array for sudoku number 1, used in checking answers
	lw $t5, green	#all of the below commands load colors into register t5 and fill out specific bytes of the bitmap display as an answer key/array
	sw $t5, 0($t0)
	sw $t5, 88($t0)
	sw $t5, 144($t0)
	sw $t5, 200($t0)
	
	lw $t5, yellow
	sw $t5, 8($t0)
	sw $t5, 80($t0)
	sw $t5, 152($t0)
	sw $t5, 192($t0)
	
	lw $t5, pink
	sw $t5, 24($t0)
	sw $t5, 64($t0)
	sw $t5, 136($t0)
	sw $t5, 208($t0)
	
	lw $t5, orange
	sw $t5, 16($t0)
	sw $t5, 72($t0)
	sw $t5, 128($t0)
	sw $t5, 216($t0)
	
s2a:
li $t0, 268501760				# answer key/array for sudoku number 2, used in checking answers
	lw $t5, green#all of the below commands load colors into register t5 and fill out specific bytes of the bitmap display as an answer key/array
	sw $t5, 0($t0)
	sw $t5, 88($t0)
	sw $t5, 144($t0)
	sw $t5, 200($t0)
	
	lw $t5, yellow
	sw $t5, 8($t0)
	sw $t5, 80($t0)
	sw $t5, 128($t0)
	sw $t5, 216($t0)
	
	lw $t5, pink
	sw $t5, 24($t0)
	sw $t5, 64($t0)
	sw $t5, 136($t0)
	sw $t5, 208($t0)
	
	lw $t5, orange
	sw $t5, 16($t0)
	sw $t5, 72($t0)
	sw $t5, 152($t0)
	sw $t5, 192($t0)
	
s3a:
li $t0, 268502016
						# answer key/array for sudoku number 3, used in checking answers
	lw $t5, green#all of the below commands load colors into register t5 and fill out specific bytes of the bitmap display as an answer key/array
	sw $t5, 16($t0)
	sw $t5, 72($t0)
	sw $t5, 128($t0)
	sw $t5, 216($t0)
	
	lw $t5, yellow
	sw $t5, 8($t0)
	sw $t5, 80($t0)
	sw $t5, 152($t0)
	sw $t5, 192($t0)
	
	lw $t5, pink
	sw $t5, 0($t0)
	sw $t5, 88($t0)
	sw $t5, 144($t0)
	sw $t5, 200($t0)
	
	lw $t5, orange
	sw $t5, 24($t0)
	sw $t5, 64($t0)
	sw $t5, 136($t0)
	sw $t5, 208($t0)

	jr $ra


##########################################

##########################################

	randMap:	#function for choosing which map to dislpay based on the randomly generated s7 register
	beq $s7, 0, S1
	beq $s7, 1, S2
	beq $s7, 2, S3 
	
	j Error


##########################################

##########################################

NextC4:	# function that displays your chosed sudoku color not only in the display, but also in the "hidden display" for later use
	sw $t5, 0($t0)
	sw $t5, 0($t4)
	j Phase2	#jump to phase 2, the computers turn

##########################################

##########################################

WC4Num:		#displays prompt for when a wrong connect 4 column is selected (columns over 7, under 1, etc)
	la $a0, C4WrNum
	li $v0, 4
	syscall
Connect4:	#function that displays a prompt asking for your color of choice for the connect 4 board
	li $v0, 4
	la $a0, C4Prompt
	syscall
	li $v0, 5	#gets input
	syscall
	move $t9, $v0
	sltiu $t8, $t9, 8	#set up t8 to be the register to check if the number entered was within the range of the board
	bne $t8, 1, WC4Num	#regulate what was set up in the previous line
ComputerInterjectionPoint:	#this is where the cumputer cpu interjects to continue using these functions as if it is another player
	li $t0, 268501248	#set t0 to the top left corner of the connect 4 grid in the bitmap display
		C4Col:	#this uses t9 to determine which column of the connect 4 board the player/computer has selected
			beq, $t9, 1, C41
			beq, $t9, 2, C42
			beq, $t9, 3, C43
			beq, $t9, 4, C44
			beq, $t9, 5, C45
			beq, $t9, 6, C46
			beq, $t9, 7, C47
j WC4Num	#send the code back to the prompt for a column number if the given number doesnt match an existing column
	
##########################################

##########################################

C41:
	addi $t0, $t0, 0	#column offset
	jal Calct0	#jump and link to function which determines where the farthest down open space in this column is (for connect 4 marker placement)
	j CalcT2	#jump and link to function which determines which color to make the connect 4 piece based on who is placing it
C42:
	addi $t0, $t0, 4	#column offset
	jal Calct0	#jump and link to function which determines where the farthest down open space in this column is (for connect 4 marker placement)
	j CalcT2	#jump and link to function which determines which color to make the connect 4 piece based on who is placing it
C43:
	addi $t0, $t0, 8	#column offset
	jal Calct0	#jump and link to function which determines where the farthest down open space in this column is (for connect 4 marker placement)
	j CalcT2	#jump and link to function which determines which color to make the connect 4 piece based on who is placing it
C44:
	addi $t0, $t0, 12	#column offset
	jal Calct0	#jump and link to function which determines where the farthest down open space in this column is (for connect 4 marker placement)
	j CalcT2	#jump and link to function which determines which color to make the connect 4 piece based on who is placing it
C45:
	addi $t0, $t0, 16	#column offset
	jal Calct0	#jump and link to function which determines where the farthest down open space in this column is (for connect 4 marker placement)
	j CalcT2	#jump and link to function which determines which color to make the connect 4 piece based on who is placing it
C46:
	addi $t0, $t0, 20	#column offset
	jal Calct0	#jump and link to function which determines where the farthest down open space in this column is (for connect 4 marker placement)
	j CalcT2	#jump and link to function which determines which color to make the connect 4 piece based on who is placing it
C47:
	addi $t0, $t0, 24	#column offset
	jal Calct0	#jump and link to function which determines where the farthest down open space in this column is (for connect 4 marker placement)
	j CalcT2	#jump and link to function which determines which color to make the connect 4 piece based on who is placing it
	
##########################################

##########################################
C4PosCalc:	#return to column functions
jr $ra

Calct0:	#calculates the address of the piece thats about to be placed
addi $t0, $t0, 160#addi $t0, $t0, 192
li $t1, 6	#iterate loop 6 times
loop5:	#check for lowest possible spot to place a marker (connect 4 pieces fall due to gravity)
lw $t4, 0($t0)
beq $t4, 5263615, C4PosCalc
beq $t4, 5263440, C4PosCalc	#expand this to save lines, instead of checking if the space has a color, check if its still background color
addi $t0, $t0, -32
addi $t1, $t1, -1
bne $t1, 0, loop5

jr $ra


##########################################

##########################################
CalcT2:	#use s6 to choose a color for the piece thats about to be placed based on whos turn it is
	beq $s6, 1, MyTurn
	beq $s6, 2, CompTurn
j Error

MyTurn:	#set color to red if my turn
	lw $t2, red
	sw $t2, 0($t0)
j aUser	#jump back to main function
CompTurn:	#set color to blue if computer turn
	lw $t2, blue
	sw $t2, 0($t0)
j aComputer	#jump back to main function
##########################################

##########################################
CheckWin:	#Check the surrounding 8 cells for matching colors
li $t1, 1
	lw $t4, -36($t0)
	beq $t2, $t4, NegOne	#top row match found, investigate
	Next2:
li $t1, 2
	lw $t4, -32($t0)
	beq $t2, $t4, Inspiration
	Next3:
li $t1, 3
	lw $t4, -28($t0)
	beq $t2, $t4, One
	Next4:
li $t1, 4
	lw $t4, -4($t0)
	beq $t2, $t4, Zebra	#middle row match found, investigate
	Next5:
li $t1, 5
	lw $t4, 4($t0) 
	beq $t2, $t4, Zebra
	Next6:
li $t1, 6
	lw $t4, 28($t0)
	beq $t2, $t4, One	#bottom row match found, investigate
	Next7:
li $t1, 7
	lw $t4,  32($t0) 
	beq $t2, $t4, Inspiration
	Next8:
li $t1, 8
	lw $t4, 36($t0)
	beq $t2, $t4, NegOne
	Next9:
li $t1, 9
jr $ra	#very important $ra

##########################################

##########################################
#the following functions iterate through every single way to get a combniation of 4 in a row starting from a single point, t0
	
NegOne:	#this function is used if a line of multiple matching connect 4 pieces appear together with a slope of negative 1
	lw $t4, -108($t0)
	beq $t2, $t4, NegOnePos1
	nNegOnePos1:
	lw $t4, -72($t0)
	beq $t2, $t4, NegOnePos2
	nNegOnePos2:
	lw $t4, 72($t0)
	beq $t2, $t4, NegOnePos3
	nNegOnePos3:
	lw $t4, 108($t0)
	beq $t2, $t4, NegOnePos4
	nNegOnePos4:
	beq $t1, 1, Next2
	beq $t1, 2, Next3
	beq $t1, 3, Next4
	beq $t1, 4, Next5
	beq $t1, 5, Next6
	beq $t1, 6, Next7
	beq $t1, 7, Next8
	beq $t1, 8, Next9
	
	
	
NegOnePos1:
	lw $t4, -72($t0)
	bne $t2, $t4, nNegOnePos1
	lw $t4, -36($t0)
	bne $t2, $t4, nNegOnePos1
	j Winner
NegOnePos2:
	lw $t4, -36($t0)
	bne $t2, $t4, nNegOnePos2
	lw $t4, 36($t0)
	bne $t2, $t4, nNegOnePos2
	j Winner
NegOnePos3:
	lw $t4, -36($t0)
	bne $t2, $t4, nNegOnePos3
	lw $t4, 36($t0)
	bne $t2, $t4, nNegOnePos3
	j Winner
NegOnePos4:
	lw $t4, 36($t0)
	bne $t2, $t4, nNegOnePos4
	lw $t4, 72($t0)
	bne $t2, $t4, nNegOnePos4
	j Winner
	
	
Inspiration:	#this function is used if a line of multiple matching connect 4 pieces appear together with a slope of infinity
	lw $t4, -96($t0)
	beq $t2, $t4, InspirationPos1
	nInspirationPos1:
	lw $t4, -64($t0)
	beq $t2, $t4, InspirationPos2
	nInspirationPos2:
	lw $t4, 64($t0)
	beq $t2, $t4, InspirationPos3
	nInspirationPos3:
	lw $t4, 96($t0)
	beq $t2, $t4, InspirationPos4
	nInspirationPos4:
	beq $t1, 1, Next2
	beq $t1, 2, Next3
	beq $t1, 3, Next4
	beq $t1, 4, Next5
	beq $t1, 5, Next6
	beq $t1, 6, Next7
	beq $t1, 7, Next8
	beq $t1, 8, Next9
	
InspirationPos1:
	lw $t4, -64($t0)
	bne $t2, $t4, nInspirationPos1
	lw $t4, -32($t0)
	bne $t2, $t4, nInspirationPos1
	j Winner
InspirationPos2:
	lw $t4, -32($t0)
	bne $t2, $t4, nInspirationPos2
	lw $t4, 32($t0)
	bne $t2, $t4, nInspirationPos2
	j Winner
InspirationPos3:
	lw $t4, -32($t0)
	bne $t2, $t4, nInspirationPos3
	lw $t4, 32($t0)
	bne $t2, $t4, nInspirationPos3
	j Winner
InspirationPos4:
	lw $t4, 32($t0)
	bne $t2, $t4, nInspirationPos4
	lw $t4, 64($t0)
	bne $t2, $t4, nInspirationPos4
	j Winner
	
	
	
One:	#this function is used if a line of multiple matching connect 4 pieces appear together with a slope of one
	lw $t4, -84($t0)
	beq $t2, $t4, OnePos1
	nOnePos1:
	lw $t4, -56($t0)
	beq $t2, $t4, OnePos2
	nOnePos2:
	lw $t4, 56($t0)
	beq $t2, $t4, OnePos3
	nOnePos3:
	lw $t4, 84($t0)
	beq $t2, $t4, OnePos4
	nOnePos4:
	beq $t1, 1, Next2
	beq $t1, 2, Next3
	beq $t1, 3, Next4
	beq $t1, 4, Next5
	beq $t1, 5, Next6
	beq $t1, 6, Next7
	beq $t1, 7, Next8
	beq $t1, 8, Next9
	
OnePos1:
	lw $t4, -56($t0)
	bne $t2, $t4, nOnePos1
	lw $t4, -28($t0)
	bne $t2, $t4, nOnePos1
	j Winner
OnePos2:
	lw $t4, -28($t0)
	bne $t2, $t4, nOnePos2
	lw $t4, 28($t0)
	bne $t2, $t4, nOnePos2
	j Winner
OnePos3:
	lw $t4, -28($t0)
	bne $t2, $t4, nOnePos3
	lw $t4, 28($t0)
	bne $t2, $t4, nOnePos3
	j Winner
OnePos4:
	lw $t4, 28($t0)
	bne $t2, $t4, nOnePos4
	lw $t4, 56($t0)
	bne $t2, $t4, nOnePos4
	j Winner

	
Zebra:	#this function is used if a line of multiple matching connect 4 pieces appear together with a slope of zero
	lw $t4, -12($t0)
	beq $t2, $t4, ZebraPos1
	nZebraPos1:
	lw $t4, -8($t0)
	beq $t2, $t4, ZebraPos2
	nZebraPos2:
	lw $t4, 8($t0)
	beq $t2, $t4, ZebraPos3
	nZebraPos3:
	lw $t4, 12($t0)
	beq $t2, $t4, ZebraPos4
	nZebraPos4:
	beq $t1, 1, Next2
	beq $t1, 2, Next3
	beq $t1, 3, Next4
	beq $t1, 4, Next5
	beq $t1, 5, Next6
	beq $t1, 6, Next7
	beq $t1, 7, Next8
	beq $t1, 8, Next9
	
	
ZebraPos1:
	lw $t4, -8($t0)
	bne $t2, $t4, nZebraPos1
	lw $t4, -4($t0)
	bne $t2, $t4, nZebraPos1
	j Winner
ZebraPos2:
	lw $t4, -4($t0)
	bne $t2, $t4, nZebraPos2
	lw $t4, 4($t0)
	bne $t2, $t4, nZebraPos2
	j Winner
ZebraPos3:
	lw $t4, -4($t0)
	bne $t2, $t4, nZebraPos3
	lw $t4, 4($t0)
	bne $t2, $t4, nZebraPos3
	j Winner
ZebraPos4:
	lw $t4, 4($t0)
	bne $t2, $t4, nZebraPos4
	lw $t4, 8($t0)
	bne $t2, $t4, nZebraPos4
	j Winner


##########################################

##########################################

S1:	#function to load the first sudoku puzzle into the bitmap display, while at the same time displaying it hidden underneath the display
	jal s1
j Phase1
S1Col:
	beq, $t6, 1, s1Col1
	beq, $t6, 2, s1Col2
	beq, $t6, 3, s1Col3
	beq, $t6, 4, s1Col4
############	
s1:
sudoku1:							# sudoku map
	
	li $t0, 268502272
						# memory sudoku map
	lw $t5, green
	sw $t5, 0($t0)
	
	lw $t5, yellow
	sw $t5, 80($t0)
	
	lw $t5, pink
	sw $t5, 136($t0)
	
	lw $t5, orange
	sw $t5, 216($t0)
	
li $t0, 268500992
addi $t0, $t0, 1280

li $t2, 4
s1loop:
	li $t1, 4
	s1loop2:
	lw $t5, 0($t0)
	sw $t5, -1280($t0)
	addi $t0, $t0, 8
	addi $t1, $t1, -1
	bne $t1, 0, s1loop2
addi $t0, $t0, 32
addi $t2, $t2, -1
bne $t2, 0, s1loop
	
jr $ra

s1Col1:	#the following functions correspond to individual bytes in the sudoku array (for the answer key) and they are used to determine if 
		#the given color was correct
	beq $t7, 1, s1C1R1
	beq $t7, 2, s1C1R2
	beq $t7, 3, s1C1R3
	beq $t7, 4, s1C1R4
s1Col2:
	beq $t7, 1, s1C2R1
	beq $t7, 2, s1C2R2
	beq $t7, 3, s1C2R3
	beq $t7, 4, s1C2R4
s1Col3:
	beq $t7, 1, s1C3R1
	beq $t7, 2, s1C3R2
	beq $t7, 3, s1C3R3
	beq $t7, 4, s1C3R4
s1Col4:
	beq $t7, 1, s1C4R1
	beq $t7, 2, s1C4R2
	beq $t7, 3, s1C4R3
	beq $t7, 4, s1C4R4
	
j Error
	
s1C1R1:
	addi $t0, $t0, 192
	j ItsYellow
s1C1R2:
	addi $t0, $t0, 128
	j ItsOrange
s1C1R3:
	addi $t0, $t0, 64
	j ItsPink

s1C1R4:
	addi $t0, $t0, 0
	j ItsGreen
	
s1C2R1:
	addi $t0, $t0, 200
	j ItsGreen
s1C2R2:
	addi $t0, $t0, 136
	j ItsPink

s1C2R3:
	addi $t0, $t0, 72
	j ItsOrange
s1C2R4:
	addi $t0, $t0, 8
	j ItsYellow

s1C3R1:
	addi $t0, $t0, 208
	j ItsPink

s1C3R2:
	addi $t0, $t0, 144
	j ItsGreen
s1C3R3:
	addi $t0, $t0, 80
	j ItsYellow
s1C3R4:
	addi $t0, $t0, 16
	j ItsOrange
	
s1C4R1:
	addi $t0, $t0, 216
	j ItsOrange
s1C4R2:
	addi $t0, $t0, 152
	j ItsYellow
s1C4R3:
	addi $t0, $t0, 88
	j ItsGreen
s1C4R4:
	addi $t0, $t0, 24
	j ItsPink

##########################################

##########################################

S2:
	jal s2
j Phase1

S2Col:
	beq, $t6, 1, s2Col1
	beq, $t6, 2, s2Col2
	beq, $t6, 3, s2Col3
	beq, $t6, 4, s2Col4

	jr $ra
############	
	
s2:	#function to load the second sudoku puzzle into the bitmap display, while at the same time displaying it hidden underneath the display

li $t0, 268500992
sudoku2:							# sudoku map
	lw $t5, green
	sw $t5, 0($t0)
	sw $t5, 200($t0)
	
	lw $t5, yellow
	sw $t5, 216($t0)
	
	lw $t5, orange
	sw $t5, 16($t0)
	
	
li $t0, 268502528					# mem sudoku map
	lw $t5, green
	sw $t5, 0($t0)
	sw $t5, 200($t0)
	
	lw $t5, yellow
	sw $t5, 216($t0)
	
	lw $t5, orange
	sw $t5, 16($t0)
	
	li $t0, 268500992
addi $t0, $t0, 1536
li $t2, 4
s2loop:
	li $t1, 4
	s2loop2:
	lw $t5, 0($t0)
	sw $t5, -1536($t0)
	addi $t0, $t0, 8
	addi $t1, $t1, -1
	bne $t1, 0, s2loop2
addi $t0, $t0, 32
addi $t2, $t2, -1
bne $t2, 0, s2loop
	
jr $ra
#the following functions correspond to individual bytes in the sudoku array (for the answer key) and they are used to determine if 
		#the given color was correct
s2Col1:
	beq $t7, 1, s2C1R1
	beq $t7, 2, s2C1R2
	beq $t7, 3, s2C1R3
	beq $t7, 4, s2C1R4
s2Col2:
	beq $t7, 1, s2C2R1
	beq $t7, 2, s2C2R2
	beq $t7, 3, s2C2R3
	beq $t7, 4, s2C2R4
s2Col3:
	beq $t7, 1, s2C3R1
	beq $t7, 2, s2C3R2
	beq $t7, 3, s2C3R3
	beq $t7, 4, s2C3R4
s2Col4:
	beq $t7, 1, s2C4R1
	beq $t7, 2, s2C4R2
	beq $t7, 3, s2C4R3
	beq $t7, 4, s2C4R4
	
j Error
	

s2C1R1:
	addi $t0, $t0, 192
	j ItsOrange
s2C1R2:
	addi $t0, $t0, 128
	j ItsYellow
s2C1R3:
	addi $t0, $t0, 64
	j ItsPink
s2C1R4:
	addi $t0, $t0, 0
	j ItsGreen
		
s2C2R1:
	addi $t0, $t0, 200
	j ItsGreen
s2C2R2:
	addi $t0, $t0, 136
	j ItsPink

s2C2R3:
	addi $t0, $t0, 72
	j ItsOrange
s2C2R4:
	addi $t0, $t0, 8
	j ItsYellow

s2C3R1:
	addi $t0, $t0, 208
	j ItsPink

s2C3R2:
	addi $t0, $t0, 144
	j ItsGreen
s2C3R3:
	addi $t0, $t0, 80
	j ItsYellow
s2C3R4:
	addi $t0, $t0, 16
	j ItsOrange
	
s2C4R1:
	addi $t0, $t0, 216
	j ItsYellow
s2C4R2:
	addi $t0, $t0, 152
	j ItsOrange
s2C4R3:
	addi $t0, $t0, 88
	j ItsGreen
s2C4R4:
	addi $t0, $t0, 24
	j ItsPink


##########################################

##########################################

S3:
	jal s3
j Phase1

S3Col:
	beq, $t6, 1, s3Col1
	beq, $t6, 2, s3Col2
	beq, $t6, 3, s3Col3
	beq, $t6, 4, s3Col4

	jr $ra
############	
	
s3:	#function to load the third sudoku puzzle into the bitmap display, while at the same time displaying it hidden underneath the display

li $t0, 268500992
sudoku3:							# sudoku map
	lw $t5, green
	sw $t5, 16($t0)
	
	lw $t5, yellow
	sw $t5, 152($t0)
	
	lw $t5, pink
	sw $t5, 200($t0)
	
	lw $t5, orange
	sw $t5, 64($t0)
	
	
	li $t0, 268502784					# sudoku map
	lw $t5, green
	sw $t5, 16($t0)
	
	lw $t5, yellow
	sw $t5, 152($t0)
	
	lw $t5, pink
	sw $t5, 200($t0)
	
	lw $t5, orange
	sw $t5, 64($t0)
	
	li $t0, 268500992
addi $t0, $t0, 1792
li $t2, 4
s3loop:
	li $t1, 4
	s3loop2:
	lw $t5, 0($t0)
	sw $t5, -1792($t0)
	addi $t0, $t0, 8
	addi $t1, $t1, -1
	bne $t1, 0, s3loop2
addi $t0, $t0, 32
addi $t2, $t2, -1
bne $t2, 0, s3loop
	
	
jr $ra
#the following functions correspond to individual bytes in the sudoku array (for the answer key) and they are used to determine if 
		#the given color was correct
s3Col1:
	beq $t7, 1, s3C1R1
	beq $t7, 2, s3C1R2
	beq $t7, 3, s3C1R3
	beq $t7, 4, s3C1R4
s3Col2:
	beq $t7, 1, s3C2R1
	beq $t7, 2, s3C2R2
	beq $t7, 3, s3C2R3
	beq $t7, 4, s3C2R4
s3Col3:
	beq $t7, 1, s3C3R1
	beq $t7, 2, s3C3R2
	beq $t7, 3, s3C3R3
	beq $t7, 4, s3C3R4
s3Col4:
	beq $t7, 1, s3C4R1
	beq $t7, 2, s3C4R2
	beq $t7, 3, s3C4R3
	beq $t7, 4, s3C4R4
	
j Error
	

s3C1R1:
	addi $t0, $t0, 192
	j ItsYellow
s3C1R2:
	addi $t0, $t0, 128
	j ItsGreen
s3C1R3:
	addi $t0, $t0, 64
	j ItsOrange
s3C1R4:
	addi $t0, $t0, 0
	j ItsPink
	
s3C2R1:
	addi $t0, $t0, 200
	j ItsPink
s3C2R2:
	addi $t0, $t0, 136
	j ItsOrange
s3C2R3:
	addi $t0, $t0, 72
	j ItsGreen
s3C2R4:
	addi $t0, $t0, 8
	j ItsYellow

s3C3R1:
	addi $t0, $t0, 208
	j ItsOrange
s3C3R2:
	addi $t0, $t0, 144
	j ItsPink
s3C3R3:
	addi $t0, $t0, 80
	j ItsYellow
s3C3R4:
	addi $t0, $t0, 16
	j ItsGreen
	
s3C4R1:
	addi $t0, $t0, 216
	j ItsGreen
s3C4R2:
	addi $t0, $t0, 152
	j ItsYellow
s3C4R3:
	addi $t0, $t0, 88
	j ItsPink
s3C4R4:
	addi $t0, $t0, 24
	j ItsOrange


##########################################

##########################################
Error:	#error message that displays if an unexpected number is used in my computations, ends the program
li $t1, 999999999999999
li $v0, 10
syscall
		
##########################################

##########################################
Winner:	#unction to display a prompt that says NICE if the player or the computer wins
	la $a0, Nice
	li $v0, 4
	li $t1, 10
	WinLoop:
	syscall
	addi $t1, $t1, -1
	bne $t1, 0, WinLoop
	
	li $v0, 10
	syscall
