.data

player_move: .asciiz "Player, make your move! Number being played: "
player_move_x: .asciiz "X-coordinate for move: "
player_move_y: .asciiz "Y-coordinate for move: "
player_move_invalid: .asciiz "Invalid move! Please enter a valid set of coordinates and ensure the tile is empty.\n"
player_newline: .asciiz "\n"

.text
#Arguements: a0 = game array, a1 = current number being played
#Return: N/A
playerMove:
	#Save a0 to t9
	move $t9, $a0
	
	#Tell player to make a move
	li $v0, SysPrintString
	la $a0, player_move
	syscall
	
	#Print the current number being played
	li $v0, SysPrintInt
	move $a0, $a1
	syscall
	
	#Print newline
	li $v0, SysPrintString
	la $a0, player_newline
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
	
	#Print newline
	li $v0, SysPrintString
	la $a0, player_newline
	syscall
	
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
    	
set_number:

	#Calculate the position in the array using the x and y coordinates
	addi $t3, $t1, -1	#t3 = y - 1
    	mul $t3, $t1, $t3	#t3 = y * (y - 1)
    	sra $t3, $t3, 1		#t3 = (y * (y - 1)) / 2
    	add $t3, $t3, $t0	#t3 = t3 + t0 (x)
    	addi $t3, $t3, -1	#t3 = t3 - 1
    	add $t3, $t3, $t9	#t3 = t3 + game array address
    	
    	#Encode value with player
    	ori $a1, 0x20		#Adds the value 32 to number
    	sb $a1, 0($t3)		#Store byte at (x,y)
    	
    	#Return to caller
    	jr $ra
