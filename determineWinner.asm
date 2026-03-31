#Author: Logan Gwin
#Date: 3/5/2026
#Description: 
#	This program will determine the winner of the game "Black Hole" by taking
#	an array and summing up all the adjacent "tiles" next to the hole, then decoding
#	them in the process to determine which player owns them and adding them to their
#	running total.

.data

# First 4 LSB's hold the values 0-15, the 4 MSB's hold the player the value belongs to
#Example: Tile that player 1 owns with a value of 9 = 0001 1001 or 9 + 16 = 25
arr1: .byte 42, 20, 41, 24, 36, 21, 37, 11, 25, 19, 38, 21, 33, 17, 35, 39, 26, 22, 34, 18, 40
arr2: .byte 0, 17, 33, 18, 0, 34, 19, 35, 20, 36

player_1_win: .asciiz "Computer wins! Better luck next time!\n"
player_2_win: .asciiz "Player wins! Congratulations!\n"

score1_message: .asciiz "Computer score: "
score2_message: .asciiz "Player score: "

space: .asciiz " "
newline: .asciiz "\n"

.text
la $a0, arr1
li $a1, 7
li $a2, 21

determineWinner:
	#Acquire s0-s5/ra and store them to stack
	addi $sp, $sp, -28
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s5, 20($sp)
	sw $ra, 24($sp)
	
	#Move the array address and hole position to s0 and s1 respectively, and store array size in s5
	move $s0, $a0
	move $s1, $a1
	move $s5, $a2
	
	#Clear s2 and s3 to hold the running total of all their numbers close to the hole (s2 = player1, s3 = player2)
	li $s2, 0
	li $s3, 0
	
	#Determine what row the hole is on
	#t0 is the running total of the sum of elements from each row
	#t1 is the row counter and the amount that will be added to t0 each iteration
	#We will loop until the sum of the elements is greater than our hole, then we will know what row the hole is in
	li $t0, 0
	li $t1, 1
	
	determineRow:
	add $t0, $t0, $t1
	slt $t2, $s1, $t0
	bne $t2, $zero, Exit
	addi $t1, $t1, 1
	j determineRow
	
	#Exit when row is found
	Exit:
	
	#Subtract 1 from t0 to convert it to the end index of the row
	subi $t0, $t0, 1
	
	#If the hole is the top most element, jump to the appropriate calculation
	beq $s1, 0, topHole
	
	#If the hole is on the right end of a row, we handle the calculation of the sum differently
	beq $s1, $t0, rightEdgeHole
	
	#Get the left edge index of the row
	sub $t2, $t0, $t1
	addi $t2, $t2, 1
	
	#Check if the edge is on the left end of a row
	beq $s1, $t2, leftEdgeHole
	
	#Otherwise, it is a normal center hole
	j centerHole
	
	topHole:
		#Decode n+1 tile
		addi $t4, $s0, 1
		jal decodeTile
		
		#Decode n+2 tile
		addi $t4, $s0, 2
		jal decodeTile
		
		#Jump to finish
		j Finish
	
	rightEdgeHole:
		#Copy array address to t4
		move $t4, $s0
		add $t4, $t4, $s1
		
		#Calculate the top tile n-(row)
		sub $t4, $t4, $t1
		jal decodeTile
		
		#Reset address and calculate the side hole n-1
		move $t4, $s0
		add $t4, $t4, $s1
		subi $t4, $t4, 1
		jal decodeTile
		
		#Branch to finish if the hole pos == array size (no tiles beneath it)
		beq $s1, $s5, Finish
		
		#Reset address
		move $t4, $s0
		add $t4, $t4, $s1
		
		#Calculate the tile at n+(row) and n+(row+1)
		add $t4, $t4, $t1
		jal decodeTile
		
		addi $t4, $t4, 1
		jal decodeTile
			
		j Finish
	
	leftEdgeHole:
		#Copy array address to t4
		move $t4, $s0
		add $t4, $t4, $s1
		
		#Calculate the top tile n-(row+1)
		sub $t4, $t4, $t1
		addi $t4, $t4, 1
		jal decodeTile
		
		#Reset address and calculate the side hole n+1
		move $t4, $s0
		add $t4, $t4, $s1
		addi $t4, $t4, 1
		jal decodeTile
		
		#Branch to finish if the hole pos == beginning index of row (no tiles beneath it)
		#Beginning index of row = n(n-1)/2 where n = row
		subi $t5, $t1, 1
		mul $t5, $t5, $t1
		div $t5, $t5, 2
		
		beq $s1, $t5, Finish
		
		#Reset address
		move $t4, $s0
		add $t4, $t4, $s1
		
		#Calculate the tile at n+(row) and n+(row+1)
		add $t4, $t4, $t1
		jal decodeTile
		
		addi $t4, $t4, 1
		jal decodeTile
	
		j Finish
	
	centerHole:
		#Get address, offset it by the hole position
		move $t4, $s0
		add $t4, $t4, $s1
		
		#Calculate tile at n-(row) and n-(row+1)
		sub $t4, $t4, $t1
		jal decodeTile
		addi $t4, $t4, 1
		jal decodeTile
		
		#Reset address
		move $t4, $s0
		add $t4, $t4, $s1
		
		#Calculate tile at n-1 and n+1
		subi $t4, $t4, 1
		jal decodeTile
		addi $t4, $t4, 2
		jal decodeTile
		
		#Check if the hole is on the bottom of the board with n(n+1)/2 == array size, n = row
		addi $t5, $t1, 1
		mul $t5, $t5, $t1
		div $t5, $t5, 2
		beq $t5, $s5, Finish
		
		#Reset address
		move $t4, $s0
		add $t4, $t4, $s1
		
		#Calculate tiles at n+(row) and n+(row+1)
		add $t4, $t4, $t1
		jal decodeTile
		addi $t4, $t4, 1
		jal decodeTile
		
		j Finish
	
	decodeTile:
		#Copy tile to t3
		lb $t3, 0($t4)
		
		#Shift t3 right 4 times to extract the player number from the 4 MSB's
		srl $t7, $t3, 4
		
		#Extract the tile value by masking the 4 LSB's
		andi $t3, $t3, 0x0F
		
		#Check to see what player owns the tile, jump to respective player to add to total
		beq $t7, 1, Player1
		beq $t7, 2, Player2
		
		#Return to caller if player is unrecognized
		jr $ra
		
		Player1:
			#Add tile value to player 1's running total, return to caller
			add $s2, $s2, $t3
			jr $ra
		Player2:
			#Add tile value to player 2's running total, return to caller
			add $s3, $s3, $t3
			jr $ra

	Finish:
		
		#Print computer score msg
		li $v0, SysPrintString
		la $a0, score1_message
		syscall
		
		#Print computer score
		li $v0, SysPrintInt
		move $a0, $s2
		syscall
		
		#Print newline
		li $v0, SysPrintString
		la $a0, newline
		syscall
		
		#Print player score msg
		li $v0, SysPrintString
		la $a0, score2_message
		syscall
		
		#Print player score
		li $v0, SysPrintInt
		move $a0, $s3
		syscall
		
		#Print newline
		li $v0, SysPrintString
		la $a0, newline
		syscall
		
		#Compare scores
		#If s3 > s2, computer wins
		slt $t5, $s2, $s3
		bne $t5, $zero, P1Wins
		
		#If not, player wins
		li $v0, SysPrintString
		la $a0, player_2_win
		syscall
		#Load the player number into the function return register
		li $v0, 2
		j Cleanup

	P1Wins:
		#Print winner and load player number into function return register
		li $v0, SysPrintString
		la $a0, player_1_win
		syscall
		li $v0, 1

	Cleanup:
		#Restore s0-s5 and ra from the stack
		lw $s0, 0($sp)
    		lw $s1, 4($sp)
    		lw $s2, 8($sp)
    		lw $s3, 12($sp)
    		lw $s5, 20($sp)
    		lw $ra, 24($sp)
    		addi $sp, $sp, 28
    		
    		#Jump to caller
		jr $ra