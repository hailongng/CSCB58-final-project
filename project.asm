.macro push_ra
	addi $sp, $sp, -4
	sw $ra, 0($sp)
.end_macro
	
.macro pop_ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
.end_macro

.eqv BASE_ADDRESS 0x10008000
.eqv DISPLAY_WIDTH 64
.eqv PLATFORM_START 4
.eqv PLATFORM_END 60
.eqv DISPLAY_HEIGHT 64
.eqv RED 0xff0000
.eqv BLUE 0x0000ff
.eqv GREEN 0x00ff00
.eqv YELLOW 0xffff00
.eqv WHITE 0xffffff
.eqv BLACK 0x000000
.eqv ORANGE 0xffa500
.eqv PLATFORM_HEIGHT 4
.eqv PLATFORM_Y 63

.eqv FLOOR11_Y 59
.eqv FLOOR11_START 12
.eqv FLOOR11_END 20

.eqv FLOOR12_Y 59
.eqv FLOOR12_START 25
.eqv FLOOR12_END 50

.eqv FLOOR13_Y 50
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

.eqv TOTAL_COINS 4

.data
player_x:   	.word 10    # Store player's current x position
player_y:	.word 63	# Y pos
enemy_x:    	.word 54    # Enemy x position (starting at 54)
enemy_y:    	.word 63    # Enemy y position (starting on platform)
coins_x:	.word 15, 30, 35, 40
coins_y:	.word 56, 56, 47, 56
coins_adj_y:	.word 0, 0, 0, 0
coins_collected:	.word 0
coins_active:		.word 1, 1, 1, 1	# 1: not collected, 0: collected
game_won:		.word 0
game_lost:		.word 0
coin_just_collected:	.word 0

.globl main
.text
	j main

draw_coin_counter:
    push_ra
    
    # Base address and color
    li $t0, BASE_ADDRESS
    li $t1, YELLOW       # Gold color for coin stripes
    
    # Draw background for counter (small black rectangle)
    li $t2, 2            # X position of counter
    li $t3, 2            # Y position of counter
    li $t4, 20           # Width of background
    li $t5, 5            # Height of background
    
    # Draw background rectangle
    li $t6, 0            # Y counter
background_y_loop:
    bge $t6, $t5, background_done
    
    li $t7, 0            # X counter
background_x_loop:
    bge $t7, $t4, background_x_done
    
    # Calculate address: BASE + ((y+t3) * WIDTH + (x+t2)) * 4
    add $t8, $t3, $t6    # y + y_offset
    li $t9, DISPLAY_WIDTH
    mul $t8, $t8, $t9    # (y + y_offset) * width
    add $t8, $t8, $t2    # (y + y_offset) * width + x_offset
    add $t8, $t8, $t7    # (y + y_offset) * width + x_offset + x_counter
    sll $t8, $t8, 2      # * 4 (bytes per pixel)
    add $t8, $t0, $t8    # Add base address
    
    # Draw black pixel
    li $t9, BLACK
    sw $t9, 0($t8)
    
    addi $t7, $t7, 1     # Increment x counter
    j background_x_loop
    
background_x_done:
    addi $t6, $t6, 1     # Increment y counter
    j background_y_loop
    
background_done:
    # Now draw the gold bars based on coins collected
    lw $t2, coins_collected  # Get number of collected coins
    beqz $t2, counter_done   # If no coins collected, we're done
    
    li $t3, 0                # Counter for bars
bars_loop:
    beq $t3, $t2, counter_done  # If we've drawn all bars, exit
    
    # Calculate x position for this bar
    li $t4, 4                # Starting x position
    li $t5, 3                # Space between bars
    mul $t6, $t3, $t5        # bar_index * spacing
    add $t4, $t4, $t6        # x_pos = start_x + (bar_index * spacing)
    
    # Draw a vertical bar (height 3)
    li $t5, 3                # Y position
    li $t7, 3                # Height of bar
    
    li $t6, 0                # Counter for height
bar_height_loop:
    beq $t6, $t7, bar_done
    
    # Calculate pixel address
    add $t8, $t5, $t6        # y + height_counter
    li $t9, DISPLAY_WIDTH
    mul $t8, $t8, $t9        # (y + height_counter) * width
    add $t8, $t8, $t4        # (y + height_counter) * width + x
    sll $t8, $t8, 2          # * 4 (bytes per pixel)
    add $t8, $t0, $t8        # Add base address
    
    # Draw yellow pixel
    sw $t1, 0($t8)
    
    addi $t6, $t6, 1         # Increment height counter
    j bar_height_loop
    
bar_done:
    addi $t3, $t3, 1         # Move to next bar
    j bars_loop
    
counter_done:
    pop_ra
    jr $ra

main:
	# Initialize coin hitboxes
	li $t0, 0                # Counter for coins
init_coin_loop:
	beq $t0, 4, init_coin_end # If processed all 4 coins, exit
	
	# Get coin coordinates
	la $t1, coins_y
	la $t2, coins_adj_y
	sll $t3, $t0, 2          # Multiply counter by 4 to get offset
	add $t1, $t1, $t3        # Add offset to coins_y address
	add $t2, $t2, $t3        # Add offset to coins_adj_y address
	
	lw $t4, 0($t1)           # Load y-coordinate
	addi $t4, $t4, 1         # Add 1 to get the right/bottom corner
	sw $t4, 0($t2)           # Store in coins_adj_y
	
	addi $t0, $t0, 1         # Increment counter
	j init_coin_loop         # Process next coin
	
init_coin_end:
	# Initialize the game
	jal draw_game
	
game_loop:
	lw $t0, game_won
	bnez $t0, game_loop		# If game is won, just loop without processing inputs
	lw $t0, game_lost
	bnez $t0, game_loop		# If game is lost, just loop without processing inputs
	jal check_keyboard_input	# Check for keyboard input
	
	jal check_coin_collection
	jal draw_coin_counter
	jal check_win_condition		# Check if all coins are collected
	
	# Small delay
	li $a0, 20
	jal delay
	
	j game_loop

check_win_condition:
	push_ra
	lw $t0, coins_collected
	li $t1, TOTAL_COINS
	bne $t0, $t1, win_condition_end  # If not all coins collected, return
	
	# All coins collected - player wins!
	li $t0, 1
	sw $t0, game_won  # Set the game_won flag
	
	# Display the "W" for win
	jal draw_win_message
	
win_condition_end:
	pop_ra
	jr $ra
	
delay:
	li $t0, 0
delay_loop:
	addi $t0, $t0, 1
	blt $t0, $a0, delay_loop
	jr $ra
exit_game:
	li $v0, 10
	syscall
	
############# DRAW WIN MESSAGE ###########################################
draw_win_message:
	push_ra
	
	li $t0, BASE_ADDRESS
	li $t1, GREEN  # Green color for the win message
	
	# Draw W in center of screen
	# I draw a simple W shape using pixels at around positions:
	# (24,30) to (24,34) | (28,34) | (32,34) to (32,30)
	# And diagonals from (24,34) to (28,38) and (32,34) to (28,38)
	
	# Left vertical line of W
	li $t2, 24  # X position
	li $t3, 30  # Starting Y position
	li $t4, 34  # Ending Y position
	
left_vertical:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, left_vertical
	
	# Right vertical line of W
	li $t2, 40  # X position
	li $t3, 30  # Starting Y position
	
right_vertical:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, right_vertical
	
	# Left diagonal (down-right)
	li $t2, 24  # Starting X position
	li $t3, 34  # Starting Y position
	li $t9, 32  # Ending X position
	
left_diagonal:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1  # Increment X
	addi $t3, $t3, 1  # Increment Y
	ble $t2, $t9, left_diagonal
	
	# Right diagonal (down-left)
	li $t2, 40  # Starting X position
	li $t3, 34  # Starting Y position
	li $t9, 32  # Ending X position
	
right_diagonal:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	subi $t2, $t2, 1  # Decrement X
	addi $t3, $t3, 1  # Increment Y
	bge $t2, $t9, right_diagonal
	
	# Middle vertical line of W
	li $t2, 32  # X position
	li $t3, 30  # Starting Y position
	li $t4, 38  # Ending Y position
	
middle_vertical:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, middle_vertical
	
	pop_ra
	jr $ra
############# END OF DRAW WIN MESSAGE ###########################################

############# DRAW LOSE MESSAGE ###########################################
draw_lose_message:
	push_ra
	
	li $t0, BASE_ADDRESS
	li $t1, RED  # Red color for the lose message
	
	# Draw L in center of screen
	# Vertical line of L
	li $t2, 28  # X position
	li $t3, 30  # Starting Y position
	li $t4, 38  # Ending Y position
	
l_vertical:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, l_vertical
	
	# Horizontal line of L
	li $t2, 28  # Starting X position
	li $t3, 38  # Y position
	li $t4, 36  # Ending X position
	
l_horizontal:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1  # Increment X
	ble $t2, $t4, l_horizontal
	
	pop_ra
	jr $ra
############# END OF DRAW LOSE MESSAGE ###########################################

# Draw the entire game state
draw_game:
	# Save return address
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal draw_platforms	# Draw platforms
	jal draw_coins
	jal draw_player		# Draw player at current position
	jal draw_enemy
	jal draw_coin_counter
	
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
	
draw_coins:
	push_ra
	
	li $t0, BASE_ADDRESS     # Base display address
	li $t1, YELLOW           # Yellow color for coins
	
	# We have 4 coins in the array (as per your data section)
	li $t2, 0                # Counter for coins
	
draw_coins_loop:
	beq $t2, 4, draw_coins_end  # If we've drawn all 4 coins, exit
	
	# Check if coin is active
	la $t3, coins_active
	sll $t5, $t2, 2          # Calculate offset
	add $t3, $t3, $t5
	lw $t4, 0($t3)           # Load active status
	beqz $t4, skip_draw_coin  # Skip if coin is already collected
	
	# Get coin coordinates
	la $t3, coins_x
	la $t4, coins_y
	sll $t5, $t2, 2          # Multiply counter by 4 to get offset (each word is 4 bytes)
	add $t3, $t3, $t5        # Add offset to coins_x address
	add $t4, $t4, $t5        # Add offset to coins_y address
	lw $t6, 0($t3)           # Load x-coordinate
	lw $t7, 0($t4)           # Load y-coordinate
	
	# Draw 2x2 square at (x,y)
	# First pixel (top-left)
	li $t8, DISPLAY_WIDTH
	mul $t9, $t7, $t8        # y * width
	add $t9, $t9, $t6        # y * width + x
	sll $t9, $t9, 2          # Multiply by 4 (bytes per pixel)
	add $t9, $t0, $t9        # Add base address
	sw $t1, 0($t9)           # Draw first pixel
	
	# Second pixel (top-right)
	addi $t9, $t9, 4         # Move one pixel right
	sw $t1, 0($t9)           # Draw second pixel
	
	# Third pixel (bottom-left)
	li $t8, DISPLAY_WIDTH
	sll $t8, $t8, 2          # Convert width to bytes
	sub $t9, $t9, 4          # Move back to first column
	add $t9, $t9, $t8        # Move down one row
	sw $t1, 0($t9)           # Draw third pixel
	
	# Fourth pixel (bottom-right)
	addi $t9, $t9, 4         # Move one pixel right
	sw $t1, 0($t9)           # Draw fourth pixel
	
skip_draw_coin:
	addi $t2, $t2, 1         # Increment counter
	j draw_coins_loop        # Process next coin
	
draw_coins_end:
	pop_ra
	jr $ra

# Draw the player at current position
draw_player:
	push_ra
	li $t0, BASE_ADDRESS
	
	# Set player color
	lw $t9, coin_just_collected
	beqz $t9, use_white_color
	li $t9, ORANGE  # Orange if just collected a coin
	j color_chosen
use_white_color:
	li $t9, WHITE  # Default white color
color_chosen:
	
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
	
	pop_ra
	jr $ra

# Erase the player from current position
erase_player:
	push_ra
	
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
	
	pop_ra
	jr $ra

draw_enemy:
    push_ra
    li $t0, BASE_ADDRESS
    li $t9, RED         # Enemy is colored RED
    
    # Get current enemy position
    lw $t1, enemy_x
    lw $t2, enemy_y
    
    # Now draw enemy (same height as player, OBJ_HEIGHT)
    subi $t2, $t2, 1
    li $t7, OBJ_HEIGHT
    li $t3, 0
    
draw_enemy_loop:
    sub $t4, $t2, $t3
    li $t5, DISPLAY_WIDTH
    mul $t4, $t4, $t5
    sll $t4, $t4, 2
    add $t4, $t0, $t4
    move $t5, $t1        # Use current enemy_x
    sll $t5, $t5, 2
    add $t6, $t4, $t5
    sw $t9, 0($t6)       # Draw pixel in red
    add $t3, $t3, 1
    bne $t3, $t7, draw_enemy_loop
    
    pop_ra
    jr $ra

# Check for keyboard input
check_keyboard_input:
	push_ra
	
	# Check if key pressed
	lw $t0, KEYBOARD_CONTROL
	andi $t0, $t0, 1
	beqz $t0, check_keyboard_end   # No key pressed
	
	# Reset coin_just_collected to 0
	sw $zero, coin_just_collected
	# Key was pressed, get the value
	lw $t1, KEYBOARD_DATA
	
	beq $t1, KEY_A, move_left
	beq $t1, KEY_D, move_right
	beq $t1, KEY_W, jump_up
	beq $t1, KEY_S, drop_down
	# Quit if 'q' is pressed
	beq $t1, KEY_Q, exit_game
	
	j check_keyboard_end

move_left:
	# First erase the player
	jal erase_player
	
	# Get current position
	lw $t0, player_x
	lw $t1, player_y
	
	# Move player left
	subi $t0, $t0, 1
	sw $t0, player_x
	
	jal check_fall_off_platform	# Check if the player fall out of the platform
	lw $t0, game_lost
	bnez $t0, check_keyboard_end
	
	jal check_platform_beneath	# Check if player is at valid pos
	
	jal draw_player			# Draw player
	j check_keyboard_end
	
move_right:
	# First erase the player
	jal erase_player
	
	# Get current position
	lw $t0, player_x
	lw $t1, player_y
	
	# Move player right
	addi $t0, $t0, 1
	sw $t0, player_x
	
	jal check_fall_off_platform	# Check if the player fall out of the platform
	lw $t0, game_lost
	bnez $t0, check_keyboard_end
	
	jal check_platform_beneath
	jal draw_player
	j check_keyboard_end

# New function to check if player has fallen off the platform
check_fall_off_platform:
	push_ra
	
	lw $t0, player_x
	lw $t1, player_y
	
	# Check if player is out of bounds horizontally
	blt $t0, 0, player_lost
	bge $t0, DISPLAY_WIDTH, player_lost
	
	# If player is at the bottom platform level
	li $t2, PLATFORM_Y
	bne $t1, $t2, check_fall_off_end
	
	# Check if player is not on platform
	blt $t0, PLATFORM_START, player_lost
	bge $t0, PLATFORM_END, player_lost
	
check_fall_off_end:
	pop_ra
	jr $ra
	
player_lost:
	# Player has fallen off platform or out of bounds
	li $t0, 1
	sw $t0, game_lost
	
	# Draw lose message
	jal draw_lose_message
	
	pop_ra
	jr $ra

check_platform_beneath:
	push_ra
	
	lw $t0, player_x
	lw $t1, player_y
	
	li $t2, FLOOR13_Y
	beq $t1, $t2, check_floor13_bounds
	
	li $t2, FLOOR12_Y
	beq $t1, $t2, check_floor11_and_12_bounds
	
	li $t2, PLATFORM_Y
	beq $t1, $t2, check_platform_bounds
	
	j fall_to_platform

check_platform_bounds:
	blt $t0, PLATFORM_START, adjust_to_platform_start
	bgt $t0, PLATFORM_END, adjust_to_platform_end
	j check_platform_end

check_floor13_bounds:
	blt $t0, FLOOR13_START, fall_from_floor13
	bgt $t0, FLOOR13_END, fall_from_floor13
	j check_platform_end
	
check_floor11_and_12_bounds:
	blt $t0, FLOOR11_START, check_if_on_floor12
	ble $t0, FLOOR11_END, check_platform_end  # Player is on floor11
	
check_if_on_floor12:
	blt $t0, FLOOR12_START, low_fall
	ble $t0, FLOOR12_END, check_platform_end

low_fall:
	j fall_to_platform

fall_from_floor13:
	# First check if there's floor11 or floor12 beneath
	# Check for floor11
	blt $t0, FLOOR12_START, check_floor13_to_floor11
	ble $t0, FLOOR12_END, land_on_floor12

check_floor13_to_floor11:
	blt $t0, FLOOR11_START, fall_to_platform      # Not above any floor, fall to platform
	ble $t0, FLOOR11_END, land_on_floor11         # Above floor11, land on it
	
	# If not above any floor, fall to main platform
	j fall_to_platform

check_floor13_to_floor12:
	blt $t0, FLOOR12_START, fall_to_platform
	ble $t0, FLOOR12_END, land_on_floor12
	
	# If no floor beneath, fall to platform
	j fall_to_platform

land_on_floor11:
	li $t1, FLOOR11_Y
	sw $t1, player_y
	j check_platform_end

land_on_floor12:
	li $t1, FLOOR12_Y
	sw $t1, player_y
	j check_platform_end

fall_to_platform:
	li $t1, PLATFORM_Y
	sw $t1, player_y
	
	#Ensure within bound
	blt $t0, PLATFORM_START, adjust_to_platform_start
	bge $t0, PLATFORM_END, adjust_to_platform_end
	j check_platform_end

adjust_to_platform_start:
	li $t0, PLATFORM_START
	sw $t0, player_x
	j check_platform_end

	
adjust_to_platform_end:
	li $t0, PLATFORM_END
	subi $t0, $t0, 1  # Subtract 1 to stay within bounds
	sw $t0, player_x
	
check_platform_end:
	pop_ra
	jr $ra
	
jump_up:
	jal erase_player
	
	lw $t0, player_x
	lw $t1, player_y
	li $t2, PLATFORM_Y
	beq $t1, $t2, check_jump_from_platform
	li $t2, FLOOR11_Y
	beq $t1, $t2, check_jump_from_floor11
	li $t2, FLOOR12_Y
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
	# Can jump to floor12
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

drop_down:
	# First erase the player from current position
	jal erase_player
	
	# Get current position
	lw $t0, player_x
	lw $t1, player_y
	
	# Check which floor the player is on
	li $t2, FLOOR13_Y
	beq $t1, $t2, drop_from_floor13
	
	li $t2, FLOOR11_Y
	beq $t1, $t2, drop_from_floor11_or_12
	
	li $t2, FLOOR12_Y
	beq $t1, $t2, drop_from_floor11_or_12
	
	# If on the platform, can't drop any further
	j skip_drop

drop_from_floor13:
	# Check if player can drop to floor11 or floor12
	# First check if above floor11
	blt $t0, FLOOR11_START, check_drop_to_floor12
	ble $t0, FLOOR11_END, drop_to_floor11
	
check_drop_to_floor12:
	# Check if above floor12
	blt $t0, FLOOR12_START, drop_to_platform
	ble $t0, FLOOR12_END, drop_to_floor12
	
	# If not above any floor, drop to platform
	j drop_to_platform

drop_from_floor11_or_12:
	# If on floor11 or floor12, can only drop to platform
	j drop_to_platform

drop_to_floor11:
	# Set position to floor11
	li $t1, FLOOR11_Y
	sw $t1, player_y
	j finish_drop

drop_to_floor12:
	# Set position to floor12
	li $t1, FLOOR12_Y
	sw $t1, player_y
	j finish_drop

drop_to_platform:
	# Set position to platform
	li $t1, PLATFORM_Y
	sw $t1, player_y
	
	# Ensure within platform bounds
	blt $t0, PLATFORM_START, adjust_drop_to_platform_start
	bge $t0, PLATFORM_END, adjust_drop_to_platform_end
	j finish_drop

adjust_drop_to_platform_start:
	li $t0, PLATFORM_START
	sw $t0, player_x
	j finish_drop

adjust_drop_to_platform_end:
	li $t0, PLATFORM_END
	subi $t0, $t0, 1  # Subtract 1 to stay within bounds
	sw $t0, player_x
	j finish_drop

finish_drop:
	# Draw player at new position
	jal draw_player
	j check_keyboard_end

skip_drop:
	# Just redraw the player at the current position
	jal draw_player
	j check_keyboard_end
	
check_keyboard_end:
	pop_ra
	jr $ra
	
check_coin_collection:
	# Save the return address properly
	push_ra
	lw $t0, player_x
	lw $t1, player_y
	
	li $t2, 0	# Initialize coin counter loop
check_coin_loop:
	beq $t2, 4, check_coins_end
	# Check if the coin is collected
	la $t3, coins_active
	sll $t4, $t2, 2		# Find offset
	add $t3, $t3, $t4	# Add offset to current coin address
	lw $t5, 0($t3)		# Load active status
	beqz $t5, next_coin	# Skip if the coin is already collected
		
	la $t6, coins_x		
	la $t7, coins_y
	la $t8, coins_adj_y
	add $t6, $t6, $t4	# Offset adjustment
	add $t7, $t7, $t4
	add $t8, $t8, $t4   # Correct access to coins_adj_y
	lw $s0, 0($t6)		# Load coin x-coordinate
	lw $s1, 0($t7)		# Load coin y-coordinate
	lw $s2, 0($t8)		# Load coin y+1 coordinate
	
	# Check if player x matches either left or right edge of coin
	beq $t0, $s0, check_y_match    # Player x matches coin left edge
	addi $s3, $s0, 1              # Right edge of coin (x+1)
	bne $t0, $s3, next_coin       # If player x doesn't match coin right edge either, skip
	
check_y_match:
	# Check if player y is within range of the coin's hitbox
	# Check against top edge of coin
	sub $s4, $t1, $s1
	abs $s4, $s4
	bgt $s4, 3, check_bottom_y    # If not within top range, check bottom
	j collect_coin                # Within range, collect the coin
	
check_bottom_y:
	# Check against bottom edge of coin
	sub $s4, $t1, $s2
	abs $s4, $s4
	bgt $s4, 3, next_coin        # If not within bottom range either, skip

collect_coin:
    # We encounter a coin. Deal with it
    sw $zero, 0($t3)
    
    # Increase the number of coins collected
    lw $t9, coins_collected
    addi $t9, $t9, 1
    sw $t9, coins_collected
    
    # Set the coin_just_collected flag
    li $t9, 1
    sw $t9, coin_just_collected
    
    # 1. First erase the coin (inline code)
    # Use the already loaded values for coin coordinates
    li $a0, BASE_ADDRESS
    li $a1, BLACK
    
    # Erase 2x2 square
    li $s5, DISPLAY_WIDTH
    mul $s6, $s1, $s5       # y * width
    add $s6, $s6, $s0       # y * width + x
    sll $s6, $s6, 2         # * 4 bytes per pixel
    add $s6, $a0, $s6
    
    # Top-left pixel
    sw $a1, 0($s6)
    
    # Top-right pixel
    addi $s6, $s6, 4
    sw $a1, 0($s6)
    
    # Bottom-left pixel
    li $s5, DISPLAY_WIDTH
    sll $s5, $s5, 2
    sub $s6, $s6, 4
    add $s6, $s6, $s5
    sw $a1, 0($s6)
    
    # Bottom-right pixel
    addi $s6, $s6, 4
    sw $a1, 0($s6)
    
    # Now redraw the player inline
    # First erase player
    li $a0, BASE_ADDRESS
    li $a1, BLACK        # Color to erase with
    
    # Get current player x position
    lw $a2, player_x
    lw $a3, player_y    
    
    # Erase player
    subi $a3, $a3, 1
    li $s0, OBJ_HEIGHT
    li $s1, 0
erase_player_inline_loop:
    sub $s2, $a3, $s1
    li $s3, DISPLAY_WIDTH
    mul $s2, $s2, $s3
    sll $s2, $s2, 2
    add $s2, $a0, $s2
    move $s3, $a2        # Use current player_x
    sll $s3, $s3, 2
    add $s4, $s2, $s3
    sw $a1, 0($s4)
    add $s1, $s1, 1
    bne $s1, $s0, erase_player_inline_loop
    
    # Now draw player in orange
    li $a0, BASE_ADDRESS
    li $a1, ORANGE  # Orange color for player
    
    # Get current player x position
    lw $a2, player_x
    lw $a3, player_y
    
    # Draw player
    subi $a3, $a3, 1
    li $s0, OBJ_HEIGHT
    li $s1, 0
draw_player_inline_loop:
    sub $s2, $a3, $s1
    li $s3, DISPLAY_WIDTH
    mul $s2, $s2, $s3
    sll $s2, $s2, 2
    add $s2, $a0, $s2
    move $s3, $a2        # Use current player_x
    sll $s3, $s3, 2
    add $s4, $s2, $s3
    sw $a1, 0($s4)
    add $s1, $s1, 1
    bne $s1, $s0, draw_player_inline_loop
    jal draw_coin_counter
    
next_coin:
    addi $t2, $t2, 1
    j check_coin_loop
	
check_coins_end:
	# Restore return address and return
	pop_ra
	jr $ra