.data

player_move: .asciiz "Player, make your move!\n"
player_move_x: .asciiz "X-coordinate for move: "
player_move_y: .asciiz "Y-coordinate for move: "
player_move_num: .asciiz "Number for move: "
player_move_invalid: .asciiz "Invalid move! Please enter a valid set of coordinates and ensure the tile is empty.\n"
player_number_invalid: .asciiz "You have already used this number! Please enter a number between 1 - 10 that you haven't used yet.\n"
player_newline: .asciiz "\n"

#Store the moves that the player has already made
number_moves: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
.text
#Arguements: a0 = game array
#Return: N/A
playerMove:
	#Save a0 to t9
	move $t9, $a0
	
	#Tell player to make a move
	li $v0, SysPrintString
	la $a0, player_move
	syscall

read_coordinates:

	#Tell player to input x coordinate
	li $v0, SysPrintString
	la $a0, player_move_x
	syscall
	
	#Get the x coordinate
	li $v0, SysReadInt
	syscall
	move $t0, $v0
	
	#Tell player to input y coordinate
	li $v0, SysPrintString
	la $a0, player_move_y
	syscall
	
	#Get the y coordinate
	li $v0, SysReadInt
	syscall
	move $t1, $v0
	
	#If x is greater than y, then the move is invalid and must be re-entered
	#Otherwise, check the array to see if the position is occupied
	#Check if x is negative
	blt $t0, $zero, invalid_move
	
	#Check if y is negative
	blt $t1, $zero, invalid_move
	
	#Check if x > y
    	bgt $t0, $t1, invalid_move

    	#Check if y is within pyramid height
    	bgt $t1, 6, invalid_move

    	#If all checks are passed, it's a valid coordinate set
    	j check_array
	
invalid_move:

	#Player move is invalid, must re-enter valid coordinates
	li $v0, SysPrintString
	la $a0, player_move_invalid
	syscall
	
	j read_coordinates
	
check_array:
	
	#Calculate the position in the array using the x and y coordinates
	addi $t3, $t1, -1	#t3 = y - 1
    	mul $t3, $t1, $t3	#t3 = y * (y - 1)
    	sra $t3, $t3, 1		#t3 = (y * (y - 1)) / 2
    	add $t3, $t3, $t0	#t3 = t3 + t0 (x)
    	addi $t3, $t3, -1	#t3 = t3 - 1
    	
    	#Get the value at the position
    	add $t3, $t3, $t9	#t3 = t3 + game array address
    	lb $t3, 0($t3)		#Get byte at (x,y)
    	
    	#If byte != 0, then the move is invalid
    	bne $t3, $zero, invalid_move
    	
read_number:
	
	#Tell player input move value
	li $v0, SysPrintString
	la $a0, player_move_num
	syscall
	
	#Get the value
	li $v0, SysReadInt
	syscall
	move $t2, $v0
	
	#Print newline
	li $v0, SysPrintString
	la $a0, player_newline
	syscall
	
	#Validate number (Should be in range of 1 <= n <= 10)
	bgt $t2, 10, invalid_number
	blt $t2, 1, invalid_number
	
	#If number is valid, check if it has been played by player 2 yet
	li $t3, 0 		#t3 = i
    	la $t4, number_moves	#t4 = all moves on the board from player 2 currently

check_number:

	#If i == 9, exit loop
    	beq $t3, 9, set_number
    	
    	#Load array[i] into t5
    	lb $t5, 0($t4)
    	
    	#If a zero is encountered, the number hasn't been played
    	beq $t5, $zero, set_number
    	
    	#If array[i] == t2, the number has already been played so it is invalid
    	beq $t5, $t2, invalid_number

    	addi $t4, $t4, 1	#Move pointer to next byte
    	addi $t3, $t3, 1	#i++
    	j check_number		#Next iteration

invalid_number:

	#Player number is invalid, must re-enter valid number for move
	li $v0, SysPrintString
	la $a0, player_number_invalid
	syscall
	
	#Get another number from the player
	j read_number
	
set_number:

	#Add the number to the moves array so it can't be played on future moves
	sb $t2, 0($t4)
	
	#Calculate the position in the array using the x and y coordinates
	addi $t3, $t1, -1	#t3 = y - 1
    	mul $t3, $t1, $t3	#t3 = y * (y - 1)
    	sra $t3, $t3, 1		#t3 = (y * (y - 1)) / 2
    	add $t3, $t3, $t0	#t3 = t3 + t0 (x)
    	addi $t3, $t3, -1	#t3 = t3 - 1
    	add $t3, $t3, $t9	#t3 = t3 + game array address
    	
    	#Encode value with player
    	ori $t2, 0x20		#Adds the value 32 to number
    	sb $t2, 0($t3)		#Store byte at (x,y)
    	
    	#Return to caller
    	jr $ra