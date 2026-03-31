#Author: Logan Gwin
#Date: 3/24/2026
#Description: 
#	This program will render the game board of "Black Hole" by taking
#	the game array and decoding the player data of each tile to get the number and the
#	color of the number in the process in order to draw the tile to the screen.
#
#Bitmap Usage:
#	In order for the board to display properly, the following settings need to be applied to the bitmap display:
#
#	Unit Width in Pixels: 1	
#	Unit Height in Pixels: 1
#	Display Width in Pixels: 512
#	Display Height in Pixels: 512
#	Base Address for display: 0x10040000 (heap)

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
	
#Halfword array for the tile layout
.align 1
tile_layout: .half 0xFFFF, 0x8001, 0x8001, 0x8001, 0x8001, 0x8001, 0x8001, 0x8001, 0x8001, 0x8001, 0x8001, 0x8001, 0x8001, 0x8001, 0x8001, 0xFFFF

#Colors
tile_background: .word 0x00909090 #Grey
tile_border: .word 0x00464646 #Dark Grey
game_background: .word 0x00FFFFFF #White

#Dimensions
game_dimensions: .word 512 #Board is 512 x 512
pixel_dimensions: .word 64 #Pixel is 64 x 64

#Buffer array, stores the game board from previous move
#Used to skip over numbers that have already been drawn
buffer: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text
#Parameters: a0 = game array, a1 = array size
#Return: v0 = hole index
draw_hole:
	#Store ra to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
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
	
	#Restore ra from stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
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
	
	#Check if the number has already been drawn
	la $t3, buffer
	add $t4, $t3, $s5
	lb $t3, 0($t4)
	bne $t3, $zero, skip_num
	
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
	
	#Add the pos to the buffer so it can be skipped next update
	la $t3, buffer
	add $t4, $t3, $s5
	li $t0, 1
	sb $t0, 0($t4)

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
	# Save ra, s0, s1, and s2 on the stack
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)

	# Convert tile indices to pixel coordinates (64x64 chunks)
	sll $s0, $a0, 6        # s0 = x_pixel
	sll $s1, $a1, 6        # s1 = y_pixel
    	
    	#Store colors in s2 and s3
    	la $s2, tile_border
    	lw $s2, 0($s2)
    	
    	la $s3, tile_background
    	lw $s3, 0($s3)
    	
    	#a3 = tile bit layout array
    	la $a3, tile_layout
    	
	# Check if the row is even (y % 2 == 0)
	andi $t6, $a1, 1
	beq  $t6, 1, skip_offset
    	
    	# If even, offset X by 32 pixels
	addi $s0, $s0, 32      
	
skip_offset:

	li $t0, 0              # Row counter (0-15)
    
draw_tile_loop:
	lh $t1, 0($a3)          # Load tile row halfword
	li $t2, 0               # Column counter (0-15)
	li $t3, 0x8000          # Mask

tile_bit_loop:
	# Calculate Address for the 4x4 block
	sll $t7, $t0, 2         # row * 4
	add $t7, $t7, $s1       # + y_pixel_start
    
	sll $t8, $t2, 2         # col * 4
	add $t8, $t8, $s0       # + x_pixel_start

	sll $t9, $t7, 9         # y * 512
	add $t9, $t9, $t8       # + x
	sll $t9, $t9, 2         # * 4
	addi $t5, $t9, 0x10040000 # Base
    	
    	#Preload the tile background color if the mask doesn't line up
    	move $a2, $s3
    	
    	#Check if the bit in the mask and the font data line up
	and $t4, $t1, $t3
	beq $t4, $zero, background_color
	
	#Change color to border color if mask lines up
	move $a2, $s2
	
background_color:
	# Draw the chunk
	jal draw_chunk

	# Shift the mask over, increment the column
	srl $t3, $t3, 1
	addi $t2, $t2, 1
	blt $t2, 16, tile_bit_loop
	
	# Increment row by 1 and move to the next halfword in the tile
	addi $a3, $a3, 2
	addi $t0, $t0, 1
	blt $t0, 16, draw_tile_loop
	
	#Restore s0 and s1 from stack
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	
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
