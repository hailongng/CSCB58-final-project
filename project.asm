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
.eqv BLACK 0x000000     # Added black color for erasing
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
.eqv FLOOR13_END 55

.eqv OBJ_HEIGHT 3	# Define for both players and enemies
### Info for the player
.eqv PLAYER_X 10

## Info for first enemy
.eqv ENEMY11_X 20
.eqv ENEMY12_X 30

# Keyboard input addresses
.eqv KEYBOARD_CONTROL 0xffff0000
.eqv KEYBOARD_DATA 0xffff0004

# Movement keys
.eqv KEY_A 97          # ASCII for 'a' - move left
.eqv KEY_D 100         # ASCII for 'd' - move right
.eqv KEY_W 119		# ASCII for 'w' - jump
.eqv KEY_S 115		# ASCII for 's' - moving down
.eqv KEY_Q 113         # ASCII for 'q'
.eqv KEY_R 114         # ASCII for 'r'


.data
player_x:   .word 10    # Store player's current x position
player_y:	.word 63	# Y pos
player_vy:	.word 0		# Velocity

.globl main
.text
main:
	# Initialize the game
	jal draw_game
	
game_loop:
	# Check for keyboard input
	jal check_keyboard_input
	
	# Small delay
	li $a0, 50
	jal delay
	
	j game_loop

# Draw the entire game state
draw_game:
	# Save return address
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Draw platforms
	jal draw_platforms
	
	# Draw player at current position
	jal draw_player
	
	# Draw enemies
	jal draw_enemies
	
	# Restore return address and return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Draw all platforms
draw_platforms:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $t0, BASE_ADDRESS 	# $t0 stores the base address for display
	li $t1, GREEN 		# $t1 stores the green colour code
	
	# Draw main platform
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
	
	# Restore return address and return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Draw the player at current position
draw_player:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $t0, BASE_ADDRESS
	li $t9, WHITE        # Player color
	
	# Get current player x position
	lw $t1, player_x
	lw $t2, player_y
	# Now draw player

	subi $t2, $t2, 1
	li $t7, OBJ_HEIGHT
	li $t3, 0
	draw_player_loop:
	sub $t4, $t2, $t3
	li $t5, DISPLAY_WIDTH
	mul $t4, $t4, $t5
	sll $t4, $t4, 2
	add $t4, $t0, $t4
	move $t5, $t1        # Use current player_x
	sll $t5, $t5, 2
	add $t6, $t4, $t5
	sw $t9, 0($t6)
	add $t3, $t3, 1
	bne $t3, $t7, draw_player_loop
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Erase the player from current position
erase_player:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $t0, BASE_ADDRESS
	li $t9, BLACK        # Color to erase with
	
	# Get current player x position
	lw $t1, player_x
	lw $t2, player_y	
	# Erase player

	subi $t2, $t2, 1
	li $t7, OBJ_HEIGHT
	li $t3, 0
	erase_player_loop:
	sub $t4, $t2, $t3
	li $t5, DISPLAY_WIDTH
	mul $t4, $t4, $t5
	sll $t4, $t4, 2
	add $t4, $t0, $t4
	move $t5, $t1        # Use current player_x
	sll $t5, $t5, 2
	add $t6, $t4, $t5
	sw $t9, 0($t6)
	add $t3, $t3, 1
	bne $t3, $t7, erase_player_loop
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Draw all enemies
draw_enemies:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $t0, BASE_ADDRESS
	li $t8, RED         # Enemy color
	
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
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Check for keyboard input
check_keyboard_input:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Check if key pressed
	lw $t0, KEYBOARD_CONTROL
	andi $t0, $t0, 1
	beqz $t0, check_keyboard_end   # No key pressed
	
	# Key was pressed, get the value
	lw $t1, KEYBOARD_DATA
	
	# Move left if 'a' is pressed
	beq $t1, KEY_A, move_left
	
	# Move right if 'd' is pressed
	beq $t1, KEY_D, move_right
	beq $t1, KEY_W, jump_up
	# Quit if 'q' is pressed
	beq $t1, KEY_Q, exit_game
	
	j check_keyboard_end

move_left:
	# First erase the player
	jal erase_player
	
	# Get current position
	lw $t0, player_x
	
	# Check boundary (don't move beyond left edge)
	ble $t0, PLATFORM_START, skip_move_left
	
	# Move player left
	subi $t0, $t0, 1
	sw $t0, player_x
	
skip_move_left:
	# Draw player at new position
	jal draw_player
	j check_keyboard_end

move_right:
	# First erase the player
	jal erase_player
	
	# Get current position
	lw $t0, player_x
	
	# Check boundary (don't move beyond right edge)
	bge $t0, PLATFORM_END, skip_move_right
	
	# Move player right
	addi $t0, $t0, 1
	sw $t0, player_x
	
skip_move_right:
	# Draw player at new position
	jal draw_player
	j check_keyboard_end

jump_up:
	jal erase_player
	
	lw $t0, player_x
	lw $t1, player_y
	li $t2, PLATFORM_Y
	beq $t1, $t2, check_jump_from_platform
	li $t2, FLOOR11_Y
	beq $t1, $t2, check_jump_from_floor11
	li $t2, FLOOR12_Y
	subi $t2, $t2, 3
	beq $t1, $t2, check_jump_from_floor12
	j skip_jump

check_jump_from_platform:
	# If player is under floor11
	blt $t0, FLOOR11_START, check_floor12
	bgt $t0, FLOOR11_END, check_floor12
	#Can jump to floor11
	li $t2, FLOOR11_Y
	sw $t2, player_y
	j perform_jump

check_floor12:
	blt $t0, FLOOR12_START, check_floor13
	bgt $t0, FLOOR12_END, check_floor13
	# Can jump to floor13
	li $t2, FLOOR12_Y
	sw $t2, player_y
	j perform_jump

check_floor13:
	# Check if under floor13
	blt $t0, FLOOR13_START, skip_jump
	bgt $t0, FLOOR13_END, skip_jump
	
	# Can jump to floor13
	li $t2, FLOOR13_Y
	sw $t2, player_y
	j perform_jump

check_jump_from_floor11:
	# Check if player can jump from floor11 to floor13
	blt $t0, FLOOR13_START, skip_jump
	bgt $t0, FLOOR13_END, skip_jump
	
	# Can jump to floor13
	li $t2, FLOOR13_Y
	sw $t2, player_y
	j perform_jump
	
check_jump_from_floor12:
	# Check if player can jump from floor12 to floor13
	blt $t0, FLOOR13_START, skip_jump
	bgt $t0, FLOOR13_END, skip_jump
	
	# Can jump to floor13
	li $t2, FLOOR13_Y
	sw $t2, player_y
	j perform_jump

perform_jump:
	# Draw player at new position
	jal draw_player
	j check_keyboard_end
	
skip_jump:
	# Just redraw the player at the current position
	jal draw_player
	j check_keyboard_end
	
check_keyboard_end:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Delay function
delay:
	# $a0 contains the delay amount
	li $t0, 0
delay_loop:
	addi $t0, $t0, 1
	blt $t0, $a0, delay_loop
	jr $ra

exit_game:
	li $v0, 10
	syscall
