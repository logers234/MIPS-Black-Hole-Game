.data

#Store the moves the computer has already made
computer_moves: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

.text
#Arguements: a0 = game array, a1 = array length
#Return: N/A
computerMove:
	
	#Save array address to t8, array length to t9
	move $t8, $a0
	move $t9, $a1
	
generateRandMove:
	
	#Generate random index from 0-20
	li $v0, SysRandIntRange
	li $a0, 1
	move $a1, $t9
	syscall
	
	#Check value at index to see if it is already taken
	add $t0, $t8, $a0
	lb $t1, 0($t0)
	
	#If arr[i] != 0, we need to generate a new number and check again
	bne $t1, $zero, generateRandMove
	
generateRandValue:
	
	#Generate random index from 0-10
	li $v0, SysRandIntRange
	li $a0, 1
	li $a1, 11
	syscall
	
	#Move random number to t2
	move $t2, $a0
	
	#Generate new number if it is 0
	blt $t2, 1, generateRandValue
	
	#Check if the number has been played by the computer
	li $t3, 0 		#t3 = i
    	la $t4, computer_moves	#t4 = all moves on the board from the computer currently
    	
check_computer_number:
	#If i == 9, exit loop
    	beq $t3, 9, set_computer_number
    	
    	#Load array[i] into t5
    	lb $t5, 0($t4)
    	
    	#If a zero is encountered, the number hasn't been played
    	beq $t5, $zero, set_computer_number
    	
    	#If array[i] == t2, the number has already been played so it is invalid
    	beq $t5, $t2, generateRandValue

    	addi $t4, $t4, 1	#Move pointer to next byte
    	addi $t3, $t3, 1	#i++
    	j check_computer_number
    	
set_computer_number:

	#Add the value to the computer moves so it cant be played again
	sb $t2, 0($t4)
	
	#Encode value with player number (player 1 = computer)
	ori $t2, 0x10
	
	#Store byte to game array
	sb $t2, 0($t0)
	
	#Return to caller
	jr $ra