#####################################################################
#
# CSCB58 Winter 2024 Assembly Final Project
# University of Toronto, Scarborough
#
# Name: Nguyen Hai Long
# Student Number: 1010597418
# UTorID: nguy3744
# Official email: hailong.nguyen@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestoneshave been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3/4 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes
#
# Any additional information that the TA needs to know:
#
#####################################################################
.eqv BASE_ADDRESS 0x10008000
.eqv PLAYER_START_POS 8		# Note: x-coordinate
.eqv ENEMY1_START_POS 24	# Note: x-coordinate
.eqv ENEMY1_END_POS 32	# Note: x-coordinate
.eqv DISPLAY_WIDTH 64
.eqv PLATFORM_START 4
.eqv PLATFORM_END 60
.eqv DISPLAY_HEIGHT 64
.eqv RED 0xff0000
.eqv BLUE 0x0000ff
.eqv GREEN 0x00ff00
.eqv YELLOW 0xffff00
.eqv WHITE 0xffffff
.eqv PLATFORM_HEIGHT 4
.eqv PLATFORM_Y 63

.eqv FLOOR11_Y 59
.eqv FLOOR11_START 12
.eqv FLOOR11_END 20

.eqv FLOOR12_Y 59
.eqv FLOOR12_START 25
.eqv FLOOR12_END 50

.eqv FLOOR13_Y 55
.eqv FLOOR13_START 30
.eqv FLOOR13_END 60

.eqv OBJ_HEIGHT 3	# Define for both players and enemies
### Info for the player
.eqv PLAYER_X 10

## Info for first enemy
.eqv ENEMY11_X 20
.eqv ENEMY12_X 30

.globl main
.text
main:
	li $t0, BASE_ADDRESS 	# $t0 stores the base address for display
	li $t1, GREEN 		# $t1 stores the yellow colour codee
	li $t9, WHITE
	li $t8, RED
	
	li $t2, PLATFORM_Y	# Load Y position
	li $t3, DISPLAY_WIDTH	# Load width
	mul $t2, $t2, $t3	# Y x width = number of pixels to modify
	sll $t2, $t2, 2		# Always remember to multiply by 4 (an int is 4 bytes after all)
	add $t2, $t0, $t2	# Find the exact location of the code
	
	# Initialize an iterator
	li $t3, PLATFORM_START
	li $t4, PLATFORM_END

	platform_draw:	
	sll $t5, $t3, 2
	add $t6, $t2, $t5	# Find pixel address: row_start_address + column_offset (again, units of 4)
	sw $t1, 0($t6)
	addi $t3, $t3, 1
	bne $t3, $t4, platform_draw
	#### Draw the first floor ####
	li $t2, FLOOR11_Y
	li $t3, DISPLAY_WIDTH
	mul $t2, $t2, $t3	# Y x width = number of pixels to modify
	sll $t2, $t2, 2		# Always remember to multiply by 4 (an int is 4 bytes after all)
	add $t2, $t0, $t2	# Find the exact location of the code
	
	li $t3, FLOOR11_START
	li $t4, FLOOR11_END
	
	floor11_draw:
	sll $t5, $t3, 2
	add $t6, $t2, $t5
	sw $t1, 0($t6)
	addi $t3, $t3, 1
	bne $t3, $t4, floor11_draw
	#### Draw the second floor #####
	li $t2, FLOOR12_Y
	li $t3, DISPLAY_WIDTH
	mul $t2, $t2, $t3	
	sll $t2, $t2, 2		
	add $t2, $t0, $t2	
	
	li $t3, FLOOR12_START
	li $t4, FLOOR12_END
	
	floor12_draw:
	sll $t5, $t3, 2
	add $t6, $t2, $t5
	sw $t1, 0($t6)
	addi $t3, $t3, 1
	bne $t3, $t4, floor12_draw
	#### Draw the third floor #####
	li $t2, FLOOR13_Y
	li $t3, DISPLAY_WIDTH
	mul $t2, $t2, $t3	
	sll $t2, $t2, 2		
	add $t2, $t0, $t2	
	
	li $t3, FLOOR13_START
	li $t4, FLOOR13_END
	
	floor13_draw:
	sll $t5, $t3, 2
	add $t6, $t2, $t5
	sw $t1, 0($t6)
	addi $t3, $t3, 1
	bne $t3, $t4, floor13_draw
	
	# Now draw player
	li $t2, PLATFORM_Y
	subi $t2, $t2, 1
	li $t7, OBJ_HEIGHT
	li $t3, 0
	draw_player:
	sub $t4, $t2, $t3
	li $t5, DISPLAY_WIDTH
	mul $t4, $t4, $t5
	sll $t4, $t4, 2
	add $t4, $t0, $t4
	li $t5, PLAYER_X
	sll $t5, $t5, 2
	add $t6, $t4, $t5
	sw $t9, 0($t6)
	add $t3, $t3, 1
	bne $t3, $t7, draw_player
	
	# Draw enemy 1
	li $t2, PLATFORM_Y
	subi $t2, $t2, 1
	li $t7, OBJ_HEIGHT
	li $t3, 0
	draw_enemy11:
	sub $t4, $t2, $t3
	li $t5, DISPLAY_WIDTH
	mul $t4, $t4, $t5
	sll $t4, $t4, 2
	add $t4, $t0, $t4
	li $t5, ENEMY11_X
	sll $t5, $t5, 2
	add $t6, $t4, $t5
	sw $t8, 0($t6)
	add $t3, $t3, 1
	bne $t3, $t7, draw_enemy11
	
	
exit_game:
	li $v0, 10
	syscall