.data
#Number fonts
font_hole: .byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
font_0: .byte 0x3E, 0x61, 0x61, 0x61, 0x61, 0x61, 0x3E, 0x00
font_1: .byte 0x18, 0x38, 0x18, 0x18, 0x18, 0x18, 0x7E, 0x00
font_2: .byte 0x3E, 0x61, 0x01, 0x3E, 0x40, 0x40, 0x7F, 0x00
font_3: .byte 0x3E, 0x01, 0x01, 0x3E, 0x01, 0x01, 0x3E, 0x00
font_4: .byte 0x06, 0x0E, 0x16, 0x26, 0x7F, 0x06, 0x06, 0x00
font_5: .byte 0x7F, 0x40, 0x40, 0x7E, 0x01, 0x01, 0x7E, 0x00
font_6: .byte 0x3E, 0x40, 0x40, 0x7E, 0x61, 0x61, 0x3E, 0x00
font_7: .byte 0x7F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x10, 0x00
font_8: .byte 0x3E, 0x61, 0x61, 0x3E, 0x61, 0x61, 0x3E, 0x00
font_9: .byte 0x3E, 0x61, 0x61, 0x3F, 0x01, 0x01, 0x3E, 0x00
font_10: .byte 0x00, 0x4E, 0x4A, 0x4A, 0x4A, 0x4A, 0x4E, 0x00

.align 2
font_table: 
	.word font_0    # Index 0
	.word font_1    # Index 1
	.word font_2    # Index 2
	.word font_3    # Index 3
	.word font_4    # Index 4
	.word font_5    # Index 5
	.word font_6    # Index 6
	.word font_7    # Index 7
	.word font_8    # Index 8
	.word font_9    # Index 9
	.word font_10   # Index 10
	.word font_hole # Index 11

#Colors
tile_background: .word 0x00909090 #Grey
tile_border: .word 0x00464646 #Dark Grey
game_background: .word 0x00FFFFFF #White

#Dimensions
game_dimensions: .word 512 #Board is 512 x 512
pixel_dimensions: .word 64 #Pixel is 64 x 64

#Test array
mid_arr: .byte 36, 0, 0, 21, 19, 20, 0, 35, 0, 0, 26, 38, 0, 0, 39, 41, 23, 0, 42, 0, 25
end_arr: .byte 36, 17, 34, 21, 19, 20, 18, 35, 0, 33, 26, 38, 37, 22, 39, 41, 23, 40, 42, 24, 25

.text
main:
	#Fill board with white pixels and draw background
	#jal fill_board
    	jal draw_board
    	
    	#Render midgame array
    	la $a0, mid_arr
	li $a1, 21
	#jal update_board
	
	#Render endgame array
	la $a0, end_arr
	li $a1, 21
	jal update_board
    	
    	#Draw hole
    	la $a0, end_arr
    	li $a1, 21
    	jal draw_hole
    	
	# End program
	li $v0, 10
	syscall



#Parameters: a0 = game array, a1 = array size
#Return: N/A
draw_hole:
	#Setup counters: t0 = x, t1 = array address
	li $t0, 0
	move $t1, $a0
	
search_for_zero:
	#Get byte at index x
	lb $t3, 0($t1)
	
	#Branch if x($t2) = 0
	beq $t3, $zero, found_zero
	#Else, if x = array length, branch
	beq $t0, $a1, exit
	
	#Else, increment address by 1 and x by 1
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	
	#Go to next iteration
	j search_for_zero
	
found_zero:
	#Set zero position to 11 in the array with player 2 color
	li $t4, 43
	
	#Store value
	sb $t4, 0($t1)
	
	#Update board
	jal update_board

exit:
	#Return to caller
	jr $ra
	
	
	
	
#Parameters: a0 = game array, a1 = element index
#Return: v0 = player number, v1 = player value
get_player_data:
	#Get raw value from array
	add $t0, $a0, $a1
	lb $t1, 0($t0)		# $t1 = [PlayerID (MSB) | Number (LSB)]

	#Extract player and number
	move $v0, $t1		
	srl $v0, $t1, 4 	#Shift first 4 bits right to get player number
	andi $v1, $t1, 0x0F	#Mask lower 4 bits to get tile value
	
	#Retrn to caller
	jr $ra
	
	
	
	
#Parameters: a0 = game array, a1 = array size
#Return: N/A
update_board:
	# Store ra, s0-s7 to the stack
	addi $sp, $sp, -36
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	sw $s7, 32($sp)
	
	#s0 = game array, s1 = array size
	move $s0, $a0
	move $s1, $a1
	
	#s2 = current row, s3 = current column offset, s4 = max elements per row, s5 = total elements processed
	li $s2, 2
	li $s3, 3
	li $s4, 1
	li $s5, 0

outer_render_loop:
	li $s6, 0		#Row element counter (i = 0 to s4)
	move $s7, $s3		#Temporary X to increment across the row

inner_render_loop:
	#Extract player data (v0 = player num, v1 = tile val)
	move $a0, $s0
	move $a1, $s5
	jal get_player_data
	
	#Determine Color based on Player
	li $a2, 0x00000000	# Default: Black (Player 2)
	bne $v0, 1, color_set
	li $a2, 0x00FF0000	# Set Red (Player 1)
	
	
color_set:

	#Extract player data (v0 = player num, v1 = tile val)
	move $a0, $s0
	move $a1, $s5
	jal get_player_data
	
	#Draw number if valid (1-10) (v1 = num value)
	beq $v1, $zero, skip_num
	bge $v1, 12, skip_num

	#Get font address from table [(num * 4) + font table address]
	la $t0, font_table
	sll $t3, $v1, 2	
	add $t0, $t0, $t3
	lw $a3, 0($t0)		#Get specific font address
	
	#Draw number on tile (x, y) (a2 already set)
	move $a0, $s7
	move $a1, $s2
	jal draw_number

skip_num:
	addi $s7, $s7, 1		#Move to next tile column
	addi $s5, $s5, 1		#Increment total elements processed
	addi $s6, $s6, 1		#Increment row element counter
	
	# Loop if we haven't reached max elements for this row
	blt $s6, $s4, inner_render_loop

	#Update offsets for the next row
	addi $s2, $s2, 1		#Row++
	addi $s4, $s4, 1		#Elements per row++
	
	#If row is even, decrement column offset (y % 2 == 0)
	andi $t0, $s2, 1
	bne $t0, $zero, check_exit
	addi $s3, $s3, -1		#Adjust pyramid center left

check_exit:
	#Exit if we processed all elements (21) or row count is too high [6 (row amount) + 2 (row offset) = 7 (final row)]
	li $t0, 8
	bge $s2, $t0, cleanup
	blt $s5, $s1, outer_render_loop

cleanup:
	#Restore ra, s0-s7 from the stack
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	lw $s7, 32($sp)
	addi $sp, $sp, 36
	
	#Return to caller
	jr $ra
	
	

		
#Parameters: N/A
#Return: N/A
draw_board:
	# Store ra, s0-s7 to the stack
	addi $sp, $sp, -36
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	sw $s7, 32($sp)
	
	#Max tiles
	li $s1, 21
	
	#s2 = current row, s3 = current column offset, s4 = max elements per row, s5 = total elements processed
	li $s2, 2
	li $s3, 3
	li $s4, 1
	li $s5, 0

outer_draw_loop:
	li $s6, 0		#Row element counter (i = 0 to s4)
	move $s7, $s3		#Temporary X to increment across the row

inner_draw_loop:

	#Draw default tile (x, y)
	move $a0, $s7
	move $a1, $s2
	jal draw_tile

	addi $s7, $s7, 1		#Move to next tile column
	addi $s5, $s5, 1		#Increment total elements processed
	addi $s6, $s6, 1		#Increment row element counter
	
	# Loop if we haven't reached max elements for this row
	blt $s6, $s4, inner_draw_loop

	#Update offsets for the next row
	addi $s2, $s2, 1		#Row++
	addi $s4, $s4, 1		#Elements per row++
	
	#If row is even, decrement column offset (y % 2 == 0)
	andi $t0, $s2, 1
	bne $t0, $zero, check_exit1
	addi $s3, $s3, -1		#Adjust pyramid center left

check_exit1:
	#Exit if we processed all elements (21) or row count is too high [6 (row amount) + 2 (row offset) = 7 (final row)]
	li $t0, 8
	bge $s2, $t0, cleanup1
	blt $s5, $s1, outer_draw_loop

cleanup1:
	#Restore ra, s0-s7 from the stack
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	lw $s7, 32($sp)
	addi $sp, $sp, 36
	
	#Return to caller
	jr $ra
	
	
	
	
#Fill board with white pixels
fill_board:
	#t1 = x
	li $t1, 0
	
	#Address
	addi $t3, $t3, 0x10040000
	
	#Get background color (Normal Grey)
	la $t4, game_background
	lw $t4, 0($t4)
	
	#Dimensions of screen (n x n)
	li $t5, 512
	
	#Get num of iterations (t5 * t5)
	mul $t5, $t5, $t5
	
	loop:
		#Draw pixel at position
		sw $t4, 0($t3)
			
		addi $t3, $t3, 4     # t3 to next pixel
		addi $t1, $t1, 1     # x++
        	blt $t1, $t5, loop # If x < iterations, keep drawing
	
	jr $ra




#Parameters: $a0 = x (tile index), $a1 = y (tile index)
#Return: N/A
draw_tile:
	#Store s0 and s1 to stack
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	
	#Check what row the tile is on, if y is even, offset by 32 pixels
	andi $t2, $a1, 1
	
	#Convert tile indices to pixel coordinates (64x64 chunks)
	sll $a0, $a0, 6		#a0 = x * 64
	sll $a1, $a1, 6		#a1 = y * 64
    
	#Calculate Start Address in $t1
	li $t0, 512              # Screen Width
	mul $t1, $a1, $t0        # y * 512
	add $t1, $t1, $a0        # (y * 512) + x
	sll $t1, $t1, 2          # Multiply by 4 for bytes
	add $t1, $t1, 0x10040000 # Add Base Address
	
	#Add 128 offset to address if y is even (32 * 4 for bytes)
	beq $t2, 1, skip_offset
	addi $t1, $t1, 128
	
skip_offset:
	#Pre-load colors into registers
	la $t8, tile_border
	lw $s0, 0($t8)           # $s0 = Border Color
	la $t8, tile_background
	lw $s1, 0($t8)           # $s1 = Background Color

	#Setup Loop Counters
	li $t2, 0                # Counter y = 0
	li $t4, 1792             # Skip: (512 - 64) * 4

outer_tile_loop:
	li $t3, 0                # Counter x = 0

inner_tile_loop:
	#Determine color for this pixel
	#Check Y-Border: if (y < 4 || y >= 60)
	slti $t6, $t2, 4
	sge  $t7, $t2, 60
	or   $t6, $t6, $t7       #$t6 is 1 if y is on the border
    
	#Check X-Border: if (x < 4 || x >= 60)
	slti $t8, $t3, 4
	sge  $t9, $t3, 60
	or   $t8, $t8, $t9       #$t8 is 1 if x is on the border
    
	#Combine: if (Y-Border OR X-Border)
	or   $t6, $t6, $t8
    
	#Choose color
	beq  $t6, $zero, paint_bg
	move $t5, $s0            #Use Border color
	j paint_pixel

paint_bg:
	move $t5, $s1            #Use Background color

paint_pixel:
	sw $t5, 0($t1)           #Draw to memory
	addi $t1, $t1, 4         #Move pointer
    
	addi $t3, $t3, 1         #x++
	blt $t3, 64, inner_tile_loop

	#End of row: Add skip to jump to next screen line
	add $t1, $t1, $t4        
    
	addi $t2, $t2, 1         #y++
	blt $t2, 64, outer_tile_loop
	
	#Restore s0 and s1 from stack
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	
	#Return to caller
	jr $ra
	
	

		
#Parameters: $a0 = x (tile index), $a1 = y (tile index), $a2 = color, $a3 = font_address
#Return: N/A
draw_number:
	# Save ra, s0, s1, and s2 on the stack
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)

	# Convert tile indices to pixel coordinates (64x64 chunks)
	sll $s0, $a0, 6        # s0 = x_pixel
	sll $s1, $a1, 6        # s1 = y_pixel
    	
    	# Store font color
    	move $s2, $a2
    	
	# Check if the row is even (y % 2 == 0)
	andi $t6, $a1, 1
	beq  $t6, 1, start_loops
    
	addi $s0, $s0, 32      # If even, offset X by 32 pixels 

start_loops:
	li $t0, 0              # Row counter (0-7)
    
draw_row_loop:
	lb $t1, 0($a3)          # Load font row byte
	li $t2, 0               # Column counter (0-7)
	li $t3, 0x80            # Mask

draw_bit_loop:
	# Calculate Address for the 4x4 block
	sll $t7, $t0, 2         # row * 4
	add $t7, $t7, $s1       # + y_pixel_start
	addi $t7, $t7, 16       # + 16 centering
    
	sll $t8, $t2, 2         # col * 4
	add $t8, $t8, $s0       # + x_pixel_start
	addi $t8, $t8, 16       # + 16 centering

	sll $t9, $t7, 9         # y * 512
	add $t9, $t9, $t8       # + x
	sll $t9, $t9, 2         # * 4
	addi $t5, $t9, 0x10040000 # Base
    	
    	#Preload the tile background color if the mask doesn't line up
    	la $t7, tile_background
    	lw $a2, 0($t7)
    	
    	#Check if the bit in the mask and the font data line up
	and $t4, $t1, $t3
	beq $t4, $zero, default_color
	
	#Change color to font color if mask lines up
	move $a2, $s2
	
default_color:
	# Draw the chunk
	jal draw_chunk

	# Shift the mask over, increment the column
	srl $t3, $t3, 1
	addi $t2, $t2, 1
	blt $t2, 8, draw_bit_loop
	
	# Increment row by 1 and move to the next byte in the font
	addi $a3, $a3, 1
	addi $t0, $t0, 1
	blt $t0, 8, draw_row_loop
    
	# Restore and Return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	
	#Return
	jr $ra



#Parameters: t5 = address to draw chunk, a2 = color of chunk
#Return: N/A
draw_chunk:
	li $t6, 0              # y_counter
	move $t7, $t5          # current_address
    
outer_chunk_loop:
	li $t8, 0              # x_counter
inner_chunk_loop:
	sw $a2, 0($t7)
	addi $t7, $t7, 4       # Next pixel
	addi $t8, $t8, 1       # x++
	blt $t8, 4, inner_chunk_loop 
    
	addi $t7, $t7, 2032    # Skip to next row: (512*4) - (4*4)
	addi $t6, $t6, 1       # y++
	blt $t6, 4, outer_chunk_loop
    	
    	# Return to caller
	jr $ra