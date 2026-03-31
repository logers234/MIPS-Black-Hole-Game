.text
#Arguements: a0 = game array, a1 = array length, a2 = current number
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
	  	
set_computer_number:

	#Encode value with player number (player 1 = computer)
	ori $a2, 0x10
	
	#Store byte to game array
	sb $a2, 0($t0)
	
	#Return to caller
	jr $ra