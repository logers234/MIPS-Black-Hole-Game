.include "SysCalls.asm"

.data

newline1: .asciiz "\n"
space1: .asciiz " "

game_arr: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
game_arr_length: .byte 21
game_arr1: .byte 33, 34, 35, 26, 18, 21, 41, 23, 22, 25, 24, 42, 19, 39, 0, 36, 37, 20, 40, 17, 38
.text
main:
	#Fill board with white pixels and draw background
	#jal fill_board
    	jal draw_board
    	
    	#x = 1, s1 = game array length
    	li $s0, 1
    	li $s1, 21
    	
main_loop:
	
	#Computer move
	la $a0, game_arr
	move $a1, $s1
	move $a2, $s0
	jal computerMove
	
	#Render board
	la $a0, game_arr
	move $a1, $s1
	jal update_board
	
	#Player move
	la $a0, game_arr
	move $a1, $s0
	jal playerMove
	
	#Render board
	la $a0, game_arr
	move $a1, $s1
	jal update_board
	
    	#Main loop iterates 10 times, with 2 turns per loop,
    	#so 20 turns total and 1 space left for the hole
    	beq $s0, 10, main_exit
    	
    	#Increment turn by 1
    	addi $s0, $s0, 1
    	j main_loop

main_exit:
    	
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