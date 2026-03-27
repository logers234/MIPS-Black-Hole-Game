.include "SysCalls.asm"

.data

newline1: .asciiz "\n"
space1: .asciiz " "

game_arr: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
game_arr_length: .byte 21
game_arr1: .byte 42, 20, 41, 24, 36, 21, 37, 0, 25, 19, 38, 21, 33, 17, 35, 39, 26, 22, 34, 18, 40
.text
main:
	#Fill board with white pixels and draw background
	#jal fill_board
    	jal draw_board
    	
    	#x = 0, s1 = game array length
    	li $s0, 0
    	li $s1, 21
    	
    	#j main_exit
main_loop:
	
	#Player 1 move
	la $a0, game_arr
	move $a1, $s1
	jal computerMove
	
	#Render array
	la $a0, game_arr
	move $a1, $s1
	jal update_board
	
	#Player 2 move
	la $a0, game_arr
	jal playerMove
	
	#Render array
	la $a0, game_arr
	move $a1, $s1
	jal update_board
    	
    	#Main loop iterates 10 times, with 2 turns per loop,
    	#so 20 turns total and 1 space left for the hole
    	beq $s0, 9, main_exit
    	addi $s0, $s0, 1
    	j main_loop

main_exit:
		
		#Render array
		la $a0, game_arr
		move $a1, $s1
		jal update_board
		
		#Print input message
		li $v0, SysPrintString
		la $a0, input_message
		syscall
		
		#Copy array address
		la $t4, game_arr
		move $t3, $zero
		
		printArray1:
			li $v0, SysPrintInt
			#Get byte at pos, get tile value
			lb $a0, 0($t4)
			syscall
			
			li $v0, SysPrintString
			la $a0, space1
			syscall
			
			#Increment the address and counter by 1
			addi $t4, $t4, 1
			addi $t3, $t3, 1
			
			#Check if the current iteration is greater than or equal to the size of the array
			blt $t3, $s1, printArray1
		#Print newline
		li $v0, SysPrintString
		la $a0, newline1
		syscall
	
	#Get hole pos
	la $a0, game_arr
	move $a1, $s1
	jal determineHole
	
	#Determine winner
    	la $a0, game_arr
    	move $a1, $v0
    	move $a2, $s1
    	jal determineWinner
    	
    	#Draw hole
    	la $a0, game_arr
    	li $a1, 21
    	jal draw_hole
    	
	# End program
	li $v0, SysExit
	syscall

#Arguments: a0 = game array, a1 = array length
#Return: v0 = hole position
determineHole:

	#Setup counters: t0 = x, t1 = array address
	li $t0, 0
	move $t1, $a0
	
search_for_hole:
	#Get byte at index x
	lb $t3, 0($t1)
	
	#Branch if x($t3) = 0
	beq $t3, $zero, found_hole
	
	#Else, increment address by 1 and x by 1
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	
	#Go to next iteration
	j search_for_hole
	
found_hole:
	
	#Hole = x index
	move $v0, $t0
	
	#Return to caller
	jr $ra




.include "playerMove.asm"
.include "determineWinner.asm"
.include "bitMapDisplay.asm"
.include "computerMove.asm"