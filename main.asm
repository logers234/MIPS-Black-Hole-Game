.include "SysCalls.asm"

.data

newline: .asciiz "\n"

game_arr: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
game_arr_length: .byte 21

.text
main:
	#Fill board with white pixels and draw background
	#jal fill_board
    	#jal draw_board
    	
    	#x = 0
    	li $s0, 0
    	
main_loop:
	
	#Player 2 move
	la $a0, game_arr
	jal playerMove
	
	#Render endgame array
	la $a0, game_arr
	li $a1, 21
	jal update_board
    	
    	#Test loop for iterating 10 times
    	beq $s0, 10, main_exit
    	addi $s0, $s0, 1
    	j main_loop

main_exit:

    	#Draw hole
    	la $a0, game_arr
    	li $a1, 21
    	jal draw_hole
    	
	# End program
	li $v0, SysExit
	syscall
	
.include "playerMove.asm"
.include "determineWinner.asm"
.include "bitMapDisplay.asm"