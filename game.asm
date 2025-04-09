#####################################################################
#
# CSCB58 Winter 2024 Assembly Final Project
# University of Toronto, Scarborough
# Name: Nguyen Hai Long
# Student Number: 1010597418
# UTorID: nguy3744
# Official email: hailong.nguyen@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 
# - Unit height in pixels: 4 
# - Display width in pixels: 256 
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestoneshave been reached in this submission? 
# (See the assignment handout for descriptions of the milestones)
# - Milestone 4
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. Moving objects [2 mark]
# 2. Shoot enemies [2 marks]
# 3. Start menu [1 mark]
#
# Link to video demonstration for final submission:
# 
# Are you OK with us sharing the video with people outside course staff? YES
#
# Any additional information that the TA needs to know:
# Some display issue:
# 1) When I shoot, the player lose 1 pixel at the middle of the body
# 2) The bullet flickers really fast, almost to the point of non-existent
# 3) When I move to the right 1 step to far, my character can still "hover" above the platform
# These issues are not too consequential, the logic of the game is still consistent.
# It is just aesthetically unpleasant.
# 4) In the main menu, I intentionally choose to not have start or restart, since I feel the logic 
# is simple enough that a restart and quit using 'r' and 'q' is not too significant in this case
#####################################################################

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
.eqv LIGHT_BLUE 0x87cefa    
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
.eqv KEY_ENTER 10      # ASCII for Enter key

.eqv TOTAL_COINS 4

.eqv KEY_SPACE 32      # ASCII for 'space' - shoot
.eqv MAX_BULLETS 3     # Maximum number of bullets on screen at once
.eqv BULLET_SPEED 1    # How many pixels bullet moves per update
.eqv BULLET_ACTIVE 1   # Flag for active bullet
.eqv BULLET_INACTIVE 0 # Flag for inactive bullet
.eqv BULLET_DIRECTION_RIGHT 1  # Bullet direction
.eqv BULLET_DIRECTION_LEFT -1  # Bullet direction

.eqv MENU_STATE 0
.eqv GAME_STATE 1
.eqv MENU_START_OPTION 0
.eqv MENU_QUIT_OPTION 1

.data
player_x:   .word 10    # Store player's current x position
player_y:	.word 63	# Y pos
enemy_x:	.word 50
enemy_y:	.word 63
enemy_direction: .word 1   # 1 = moving right, -1 = moving left
enemy_move_counter: .word 0
enemy_move_delay:   .word 200  # Adjust this value to change speed (higher = slower)
enemy_active:   .word 1     # 1 = enemy alive, 0 = enemy dead
coins_x:	.word 15, 30, 35, 40
coins_y:	.word 56, 56, 47, 56
coins_adj_y:	.word 0, 0, 0, 0
coins_collected:	.word 0
coins_active:		.word 1, 1, 1, 1	# 1: not collected, 0: collected
game_won:		.word 0
game_lost:		.word 0
coin_just_collected:	.word 0
bullets_x:      .space 12     # Space for 3 bullets (each word is 4 bytes)
bullets_y:      .space 12     # Y positions of bullets
bullets_dir:    .space 12     # Direction of bullets (1 = right, -1 = left)
bullets_active: .space 12     # Whether each bullet is active (1) or not (0)
last_direction: .word 1       # Remember player's facing direction (1 = right, -1 = left)
game_state:     .word 0     # 0 = menu, 1 = game
selected_option: .word 0     # 0 = Start, 1 = Quit

.globl main
.text
main:
	# Initialize the game
	jal init_game
	
	# Display menu
	jal draw_menu
	
main_loop:
	# Check game state
	lw $t0, game_state
	beq $t0, MENU_STATE, menu_state
	beq $t0, GAME_STATE, ingame
	
menu_state:
	# Handle menu input
	jal handle_menu_input
	j main_loop
	
ingame:
	# First clear the screen before drawing the game
    li $t0, BASE_ADDRESS
    li $t1, BLACK
    li $t2, 0  # X counter
    li $t3, 0  # Y counter
    
clear_game_screen_y:
    li $t2, 0  # Reset X counter
    
clear_game_screen_x:
    # Calculate address: BASE + (y * WIDTH + x) * 4
    li $t4, DISPLAY_WIDTH
    mul $t5, $t3, $t4
    add $t5, $t5, $t2
    sll $t5, $t5, 2
    add $t5, $t0, $t5
    sw $t1, 0($t5)  # Draw black pixel
    
    addi $t2, $t2, 1
    blt $t2, DISPLAY_WIDTH, clear_game_screen_x
    
    addi $t3, $t3, 1
    blt $t3, DISPLAY_HEIGHT, clear_game_screen_y
	# Initialize coin hitboxes if coming from menu
	lw $t0, game_state
	li $t1, GAME_STATE
	bne $t0, $t1, main_loop  # If not in game state, skip
	
	# First draw game before entering game loop
	jal draw_game
	
	# Now continue with game loop
	j game_loop
	
init_game:
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
	# Initialize bullets
	li $t0, 0                   # Counter
	la $t1, bullets_active      # Address of bullets_active array
init_bullets_loop:
	beq $t0, MAX_BULLETS, init_bullets_end # If initialized all bullets, exit loop
	sll $t2, $t0, 2             # Multiply by 4 to get offset
	add $t3, $t1, $t2           # Add offset to array address
	sw $zero, 0($t3)            # Set bullet to inactive
	addi $t0, $t0, 1            # Increment counter
	j init_bullets_loop         # Continue loop
init_bullets_end:
	
	jr $ra
	
game_loop:
	jal check_keyboard_input	# Check for keyboard input
	lw $t0, game_won
	bnez $t0, game_loop		# If game is won, just loop without processing inputs
	lw $t0, game_lost
	bnez $t0, game_loop		# If game is lost, just loop without processing inputs

	jal check_coin_collection
	jal check_win_condition		# Check if all coins are collected
	jal check_enemy_collision
	
	# Small delay
	li $a0, 20
	jal delay
	
	jal update_bullets
	jal check_bullet_enemy_collision
	jal update_enemy
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
	
	# Draw "WIN" text in center of screen
	# First, draw "W"
	# Left vertical line of W
	li $t2, 20  # X position
	li $t3, 30  # Starting Y position
	li $t4, 36  # Ending Y position
	
left_vertical_w:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, left_vertical_w
	
	# Right vertical line of W
	li $t2, 28  # X position
	li $t3, 30  # Starting Y position
	
right_vertical_w:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, right_vertical_w
	
	# Left diagonal (down-right)
	li $t2, 20  # Starting X position
	li $t3, 36  # Starting Y position
	li $t9, 24  # Ending X position
	
left_diagonal_w:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1  # Increment X
	addi $t3, $t3, -1  # Decrement Y
	ble $t2, $t9, left_diagonal_w
	
	# Right diagonal (down-left)
	li $t2, 28  # Starting X position
	li $t3, 36  # Starting Y position
	li $t9, 24  # Ending X position
	
right_diagonal_w:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	subi $t2, $t2, 1  # Decrement X
	addi $t3, $t3, -1  # Decrement Y
	bge $t2, $t9, right_diagonal_w
	
	# Now draw "I" (5 pixels to the right of W)
	li $t2, 32  # X position for I
	li $t3, 30  # Starting Y position
	li $t4, 36  # Ending Y position
	
vertical_i:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, vertical_i
	
	# Top bar of I
	li $t2, 30  # Left X for top bar
	li $t3, 30  # Y position
	li $t4, 34  # Right X for top bar
	
top_bar_i:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t4, top_bar_i
	
	# Bottom bar of I
	li $t2, 30  # Left X for bottom bar
	li $t3, 36  # Y position
	li $t4, 34  # Right X for bottom bar
	
bottom_bar_i:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t4, bottom_bar_i
	
	# Now draw "N" (5 pixels to the right of I)
	li $t2, 38  # Left X for N
	li $t3, 30  # Starting Y position
	li $t4, 36  # Ending Y position
	
left_vertical_n:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, left_vertical_n
	
	# Right vertical line of N
	li $t2, 44  # Right X for N
	li $t3, 30  # Starting Y position
	
right_vertical_n:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, right_vertical_n
	
	# Diagonal of N
	li $t2, 38  # Starting X position
	li $t3, 30  # Starting Y position
	li $t9, 44  # Ending X position
	
diagonal_n:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1  # Increment X
	addi $t3, $t3, 1  # Increment Y
	ble $t2, $t9, diagonal_n
	
	pop_ra
	jr $ra
############# END OF DRAW WIN MESSAGE ###########################################

############# DRAW LOSE MESSAGE ###########################################
draw_lose_message:
	push_ra
	
	li $t0, BASE_ADDRESS
	li $t1, RED  # Red color for the lose message
	
	# Draw "LOSE" text
	# First, draw "L"
	li $t2, 16  # X position for L
	li $t3, 30  # Starting Y position
	li $t4, 36  # Ending Y position
	
vertical_l:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, vertical_l
	
	# Bottom bar of L
	li $t2, 16  # Starting X position
	li $t3, 36  # Y position
	li $t4, 22  # Ending X position
	
horizontal_l:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t4, horizontal_l
	
	# Now draw "O" (5 pixels to the right of L)
	# Top bar of O
	li $t2, 24  # Left X for O
	li $t3, 30  # Top Y for O
	li $t4, 30  # Right X for O
	
top_bar_o:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t4, top_bar_o
	
	# Bottom bar of O
	li $t2, 24  # Left X for O
	li $t3, 36  # Bottom Y for O
	li $t4, 30  # Right X for O
	
bottom_bar_o:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t4, bottom_bar_o
	
	# Left bar of O
	li $t2, 24  # X position for left bar
	li $t3, 30  # Starting Y position
	li $t4, 36  # Ending Y position
	
left_bar_o:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, left_bar_o
	
	# Right bar of O
	li $t2, 30  # X position for right bar
	li $t3, 30  # Starting Y position
	li $t4, 36  # Ending Y position
	
right_bar_o:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, right_bar_o
	
	# Now draw "S" (5 pixels to the right of O)
	# Top bar of S
	li $t2, 32  # Left X for S
	li $t3, 30  # Top Y for S
	li $t4, 38  # Right X for S
	
top_bar_s:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t4, top_bar_s
	
	# Middle bar of S
	li $t2, 32  # Left X for S
	li $t3, 33  # Middle Y for S
	li $t4, 38  # Right X for S
	
middle_bar_s:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t4, middle_bar_s
	
	# Bottom bar of S
	li $t2, 32  # Left X for S
	li $t3, 36  # Bottom Y for S
	li $t4, 38  # Right X for S
	
bottom_bar_s:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t4, bottom_bar_s
	
	# Left vertical bar of S (top half)
	li $t2, 32  # X position
	li $t3, 30  # Starting Y
	li $t4, 33  # Ending Y
	
left_top_s:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, left_top_s
	
	# Right vertical bar of S (bottom half)
	li $t2, 38  # X position
	li $t3, 33  # Starting Y
	li $t4, 36  # Ending Y
	
right_bottom_s:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, right_bottom_s
	
	# Now draw "E" (5 pixels to the right of S)
	# Vertical bar of E
	li $t2, 40  # X position
	li $t3, 30  # Starting Y
	li $t4, 36  # Ending Y
	
vertical_e:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t4, vertical_e
	
	# Top bar of E
	li $t2, 40  # Left X
	li $t3, 30  # Y position
	li $t4, 46  # Right X
	
top_bar_e:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t4, top_bar_e
	
	# Middle bar of E
	li $t2, 40  # Left X
	li $t3, 33  # Y position
	li $t4, 44  # Right X (slightly shorter than top)
	
middle_bar_e:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t4, middle_bar_e
	
	# Bottom bar of E
	li $t2, 40  # Left X
	li $t3, 36  # Y position
	li $t4, 46  # Right X
	
bottom_bar_e:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t4, bottom_bar_e
	
	# Now draw progress bar below the LOSE text
	# The L ends at y=36, so we'll start at y=40
	li $t0, BASE_ADDRESS
	li $t1, YELLOW  # Yellow/gold color for progress bar
	
	# We'll draw the progress bar centered below the LOSE text
	# Start at x=28 (roughly centered), y=40 (below the text)
	li $t3, 40  # Y position for progress bar
	
	# Get the number of collected coins
	lw $t2, coins_collected
	beqz $t2, draw_lose_end  # If no coins collected, we're done
	
	# Draw bars for collected coins (with 1 pixel separation)
	li $t4, 0  # Counter for bars
	li $t5, 28  # Starting X position (centered)
	
draw_lose_bar_loop:
	beq $t4, $t2, draw_lose_end  # If drawn bars for all collected coins, exit
	
	# Calculate position for current bar
	li $t6, DISPLAY_WIDTH
	mul $t7, $t3, $t6        # y * width
	add $t7, $t7, $t5        # y * width + x_start
	sll $t7, $t7, 2          # Multiply by 4 (bytes per pixel)
	add $t8, $t0, $t7        # Add base address
	
	# Draw 3 pixels vertically (1px wide x 3px high)
	sw $t1, 0($t8)           # Top pixel
	
	# Move down one row
	li $t6, DISPLAY_WIDTH
	sll $t6, $t6, 2          # Convert width to bytes
	add $t9, $t8, $t6        # Move down one row
	sw $t1, 0($t9)           # Middle pixel
	
	# Move down another row
	add $t9, $t9, $t6        # Move down another row
	sw $t1, 0($t9)           # Bottom pixel
	
	addi $t4, $t4, 1         # Increment counter
	addi $t5, $t5, 2         # Increment x position by 2 (1px bar + 1px space)
	j draw_lose_bar_loop

draw_lose_end:
	
	pop_ra
	jr $ra
############# END OF DRAW LOSE MESSAGE ###########################################

############## DRAW PROGRESS BAR ###########################################
draw_progress_bar:
	push_ra
	
	li $t0, BASE_ADDRESS     # Base display address
	li $t1, YELLOW           # Yellow/gold color for progress bar (same as coins)
	li $t2, BLACK            # Black color to erase previous progress
	
	# First, clear the progress bar area (4 slots, 1px wide x 3px high each)
	li $t3, 0                # Start x position (left edge)
	li $t4, 1                # Start y position (near top)
	
	# Clear all 4 potential bar positions
	li $t5, 0                # Counter for positions
	
clear_progress_loop:
	beq $t5, 4, clear_progress_end  # If cleared all 4 positions, continue
	
	# Calculate position for pixel: BASE + (y * WIDTH + x) * 4
	li $t6, DISPLAY_WIDTH
	mul $t7, $t4, $t6        # y * width
	add $t7, $t7, $t3        # y * width + x
	add $t7, $t7, $t5        # Add position offset (0-3)
	sll $t7, $t7, 2          # Multiply by 4 (bytes per pixel)
	add $t8, $t0, $t7        # Add base address
	
	# Clear 3 pixels vertically (1px wide x 3px high)
	sw $t2, 0($t8)           # Top pixel
	
	# Move down one row
	li $t6, DISPLAY_WIDTH
	sll $t6, $t6, 2          # Convert width to bytes
	add $t9, $t8, $t6        # Move down one row
	sw $t2, 0($t9)           # Middle pixel
	
	# Move down another row
	add $t9, $t9, $t6        # Move down another row
	sw $t2, 0($t9)           # Bottom pixel
	
	addi $t5, $t5, 1         # Increment position counter
	j clear_progress_loop
	
clear_progress_end:
	# Now draw the filled bars based on coins_collected
	lw $t3, coins_collected  # Number of coins collected
	beqz $t3, draw_progress_end  # If no coins collected, we're done
	
	li $t4, 0                # Counter for bars to draw
	li $t5, 0                # X position offset
	
draw_bar_loop:
	beq $t4, $t3, draw_progress_end  # If drawn all bars for collected coins, exit
	
	# Calculate position for first pixel of bar
	li $t6, DISPLAY_WIDTH
	li $t7, 1                # Y position (near top)
	mul $t7, $t7, $t6        # y * width
	add $t7, $t7, $t5        # y * width + x_offset
	sll $t7, $t7, 2          # Multiply by 4 (bytes per pixel)
	add $t8, $t0, $t7        # Add base address
	
	# Draw 3 pixels vertically (1px wide x 3px high)
	sw $t1, 0($t8)           # Top pixel
	
	# Move down one row
	li $t6, DISPLAY_WIDTH
	sll $t6, $t6, 2          # Convert width to bytes
	add $t9, $t8, $t6        # Move down one row
	sw $t1, 0($t9)           # Middle pixel
	
	# Move down another row
	add $t9, $t9, $t6        # Move down another row
	sw $t1, 0($t9)           # Bottom pixel
	
	addi $t4, $t4, 1         # Increment counter
	addi $t5, $t5, 1         # Increment x offset for next bar
	j draw_bar_loop
	
draw_progress_end:
	pop_ra
	jr $ra
########### END OF DRAW PROGRESS BAR #######################################

# Draw the entire game state
draw_game:
	# Save return address
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal draw_platforms	# Draw platforms
	jal draw_coins
	jal draw_player		# Draw player at current position
	jal draw_enemy
	jal draw_progress_bar
	jal draw_bullets
	
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
	# First pixel (bottom-left)
	li $t8, DISPLAY_WIDTH
	mul $t9, $t7, $t8        # y * width
	add $t9, $t9, $t6        # y * width + x
	sll $t9, $t9, 2          # Multiply by 4 (bytes per pixel)
	add $t9, $t0, $t9        # Add base address
	sw $t1, 0($t9)           # Draw first pixel
	
	# Second pixel (bottom-right)
	addi $t9, $t9, 4         # Move one pixel right
	sw $t1, 0($t9)           # Draw second pixel
	
	# Third pixel (top-left)
	li $t8, DISPLAY_WIDTH
	sll $t8, $t8, 2          # Convert width to bytes
	sub $t9, $t9, 4          # Move back to first column
	sub $t9, $t9, $t8        # Move down one row
	sw $t1, 0($t9)           # Draw third pixel
	
	# Fourth pixel (top-right)
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

draw_enemy:
	push_ra
	li $t0, BASE_ADDRESS
	li $t9, RED         # Enemy color is red
	
	# Get enemy position
	lw $t1, enemy_x
	lw $t2, enemy_y
	
	# Draw the enemy (similar to player, 1px wide x 3px high)
	subi $t2, $t2, 1    # Adjust to draw slightly above the platform
	li $t7, OBJ_HEIGHT  # Use same height as player
	li $t3, 0
	draw_enemy_loop:
	sub $t4, $t2, $t3
	li $t5, DISPLAY_WIDTH
	mul $t4, $t4, $t5
	sll $t4, $t4, 2
	add $t4, $t0, $t4
	move $t5, $t1       # Use enemy_x
	sll $t5, $t5, 2
	add $t6, $t4, $t5
	sw $t9, 0($t6)      # Draw enemy pixel
	add $t3, $t3, 1
	bne $t3, $t7, draw_enemy_loop
	
	pop_ra
	jr $ra

erase_enemy:
    push_ra
    
    li $t0, BASE_ADDRESS
    li $t9, BLACK        # Color to erase with
    
    # Get current enemy position
    lw $t1, enemy_x
    lw $t2, enemy_y    
    # Erase enemy

    subi $t2, $t2, 1
    li $t7, OBJ_HEIGHT
    li $t3, 0
erase_enemy_loop:
    sub $t4, $t2, $t3
    li $t5, DISPLAY_WIDTH
    mul $t4, $t4, $t5
    sll $t4, $t4, 2
    add $t4, $t0, $t4
    move $t5, $t1        # Use enemy_x
    sll $t5, $t5, 2
    add $t6, $t4, $t5
    sw $t9, 0($t6)
    add $t3, $t3, 1
    bne $t3, $t7, erase_enemy_loop
    
    pop_ra
    jr $ra

update_enemy:
	# First check if enemy is active
	push_ra
	lw $t0, enemy_active
	beqz $t0, update_enemy_return  # If enemy is dead, skip update

    
    # Check the counter to see if it's time to move
    lw $t8, enemy_move_counter
    lw $t9, enemy_move_delay
    
    addi $t8, $t8, 1          # Increment counter
    blt $t8, $t9, skip_enemy_move  # If counter < delay, skip movement
    
    # Reset counter when it's time to move
    li $t8, 0
    
    # First erase the enemy at current position
    jal erase_enemy
    
    # Get current position and direction
    lw $t0, enemy_x
    lw $t1, enemy_direction
    
    # Move enemy in current direction
    add $t0, $t0, $t1
    sw $t0, enemy_x
    
    # Check if enemy reached platform boundaries
    blt $t0, PLATFORM_START, change_enemy_direction
    bge $t0, PLATFORM_END, change_enemy_direction
    j update_enemy_end
    
change_enemy_direction:
    # First adjust position to stay within bounds
    blt $t0, PLATFORM_START, adjust_enemy_left
    bge $t0, PLATFORM_END, adjust_enemy_right
    j change_dir
    
adjust_enemy_left:
    li $t0, PLATFORM_START
    sw $t0, enemy_x
    j change_dir
    
adjust_enemy_right:
    li $t0, PLATFORM_END
    subi $t0, $t0, 1  # Subtract 1 to stay within bounds
    sw $t0, enemy_x
    
change_dir:
    # Flip the direction (-1 becomes 1, 1 becomes -1)
    lw $t1, enemy_direction
    neg $t1, $t1
    sw $t1, enemy_direction
    
update_enemy_end:
    # Save the updated counter
    sw $t8, enemy_move_counter
    
    # Draw enemy at new position
    jal draw_enemy
    j update_enemy_return
    
skip_enemy_move:
    # Just update the counter without moving
    sw $t8, enemy_move_counter
    
update_enemy_return:
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

# Function to create a new bullet when player shoots
create_bullet:
	push_ra
	addi $sp, $sp, -44
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	sw $t5, 20($sp)
	sw $t6, 24($sp)
	sw $t7, 28($sp)
	sw $t9, 32($sp)
	sw $t9, 36($sp)
	sw $a0, 40($sp)  # Also save argument registers in case they're used
    
    # Find an inactive bullet slot
    li $t0, 0                   # Counter
    la $t1, bullets_active      # Address of bullets_active array
find_inactive_bullet:
    beq $t0, MAX_BULLETS, create_bullet_end  # If no available slots, exit
    sll $t2, $t0, 2             # Multiply by 4 to get offset
    add $t3, $t1, $t2           # Add offset to array address
    lw $t4, 0($t3)              # Load active status
    beqz $t4, found_inactive_bullet  # If inactive, use this slot
    addi $t0, $t0, 1            # Increment counter
    j find_inactive_bullet      # Continue searching
    
found_inactive_bullet:
    # Set bullet as active
    li $t4, BULLET_ACTIVE
    sw $t4, 0($t3)              # Mark bullet as active
    
    # Set bullet position to player position
    lw $t4, player_x            # Load player x
    lw $t5, player_y            # Load player y
    subi $t5, $t5, 2            # Bullet appears slightly above player
    
    la $t6, bullets_x
    la $t7, bullets_y
    sll $t2, $t0, 2             # Recalculate offset
    add $t6, $t6, $t2           # Add offset to bullets_x
    add $t7, $t7, $t2           # Add offset to bullets_y
    sw $t4, 0($t6)              # Set x position
    sw $t5, 0($t7)              # Set y position
    
    # Set bullet direction based on player's last direction
    la $t6, bullets_dir
    add $t6, $t6, $t2           # Add offset to bullets_dir
    lw $t4, last_direction      # Get player's direction
    sw $t4, 0($t6)              # Set bullet direction
    
    # Draw the newly created bullet
    jal draw_bullet
    
create_bullet_end:
# Restore all saved registers
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    lw $t3, 12($sp)
    lw $t4, 16($sp)
    lw $t5, 20($sp)
    lw $t6, 24($sp)
    lw $t7, 28($sp)
    lw $t9, 32($sp)
    lw $t9, 36($sp)
    lw $a0, 40($sp)
    addi $sp, $sp, 44
    pop_ra
    jr $ra

# Function to update all bullets' positions
update_bullets:
    push_ra
    
    li $t0, 0                   # Counter
    la $t1, bullets_active      # Address of bullets_active array
update_bullets_loop:
    beq $t0, MAX_BULLETS, update_bullets_end  # If processed all bullets, exit
    
    # Check if bullet is active
    sll $t2, $t0, 2             # Multiply by 4 to get offset
    add $t3, $t1, $t2           # Add offset to bullets_active
    lw $t4, 0($t3)              # Load active status
    beqz $t4, update_next_bullet  # Skip inactive bullets
    
    # Erase the bullet at current position
    jal erase_bullet
    
    # Update bullet position
    la $t3, bullets_x
    la $t4, bullets_dir
    sll $t2, $t0, 2             # Recalculate offset
    add $t3, $t3, $t2           # Add offset to bullets_x
    add $t4, $t4, $t2           # Add offset to bullets_dir
    
    lw $t5, 0($t3)              # Load bullet x
    lw $t6, 0($t4)              # Load bullet direction
    
    # Calculate new position
    li $t7, BULLET_SPEED
    mul $t7, $t7, $t6           # Speed * direction
    add $t5, $t5, $t7           # New x = old x + speed*direction
    sw $t5, 0($t3)              # Store new x position
    
    # Check if bullet is out of bounds
    blt $t5, 0, deactivate_bullet
    bge $t5, DISPLAY_WIDTH, deactivate_bullet
    
    # Draw the bullet at new position
    jal draw_bullet
    j update_next_bullet
    
deactivate_bullet:
    # Set bullet to inactive
    la $t3, bullets_active
    sll $t2, $t0, 2             # Recalculate offset
    add $t3, $t3, $t2           # Add offset to bullets_active
    sw $zero, 0($t3)            # Set to inactive
    
update_next_bullet:
    addi $t0, $t0, 1            # Increment counter
    j update_bullets_loop       # Continue loop
    
update_bullets_end:
    pop_ra
    jr $ra

# Function to erase a bullet
erase_bullet:
    # Note: $t0 contains the bullet index
    push_ra
    
    # Get bullet position
    la $t3, bullets_x
    la $t4, bullets_y
    sll $t2, $t0, 2             # Calculate offset
    add $t3, $t3, $t2           # Add offset to bullets_x
    add $t4, $t4, $t2           # Add offset to bullets_y
    lw $t5, 0($t3)              # Load x position
    lw $t6, 0($t4)              # Load y position
    
    # Erase bullet pixel
    li $a0, BASE_ADDRESS
    li $a1, BLACK               # Erase with black
    
    # Calculate pixel address
    li $a2, DISPLAY_WIDTH
    mul $a3, $t6, $a2           # y * width
    add $a3, $a3, $t5           # y * width + x
    sll $a3, $a3, 2             # Multiply by 4 (bytes per pixel)
    add $a3, $a0, $a3           # Add base address
    sw $a1, 0($a3)              # Erase pixel
    
    # Erase second pixel to the right
    addi $a3, $a3, 4            # Move one pixel right (4 bytes)
    sw $a1, 0($a3)              # Erase second pixel
    
    pop_ra
    jr $ra

# Function to draw a bullet
draw_bullet:
    # Note: $t0 contains the bullet index
    push_ra
    
    # Get bullet position
    la $t3, bullets_x
    la $t4, bullets_y
    sll $t2, $t0, 2             # Calculate offset
    add $t3, $t3, $t2           # Add offset to bullets_x
    add $t4, $t4, $t2           # Add offset to bullets_y
    lw $t5, 0($t3)              # Load x position
    lw $t6, 0($t4)              # Load y position
    
    # Draw bullet pixel
    li $a0, BASE_ADDRESS
    li $a1, LIGHT_BLUE               # Bullets are blue
    
    # Calculate pixel address
    li $a2, DISPLAY_WIDTH
    mul $a3, $t6, $a2           # y * width
    add $a3, $a3, $t5           # y * width + x
    sll $a3, $a3, 2             # Multiply by 4 (bytes per pixel)
    add $a3, $a0, $a3           # Add base address
    sw $a1, 0($a3)              # Draw pixel
    
    # Draw second pixel to the right
    addi $a3, $a3, 4            # Move one pixel right (4 bytes)
    sw $a1, 0($a3)              # Draw second pixel
    
    pop_ra
    jr $ra

# Function to draw all active bullets
draw_bullets:
    push_ra
    
    li $t0, 0                   # Counter
    la $t1, bullets_active      # Address of bullets_active array
draw_bullets_loop:
    beq $t0, MAX_BULLETS, draw_bullets_end  # If processed all bullets, exit
    
    # Check if bullet is active
    sll $t2, $t0, 2             # Multiply by 4 to get offset
    add $t3, $t1, $t2           # Add offset to bullets_active
    lw $t4, 0($t3)              # Load active status
    beqz $t4, draw_next_bullet  # Skip inactive bullets
    
    # Draw this bullet
    jal draw_bullet
    
draw_next_bullet:
    addi $t0, $t0, 1            # Increment counter
    j draw_bullets_loop         # Continue loop
    
draw_bullets_end:
    pop_ra
    jr $ra

# Function to check for collisions between bullets and enemies
check_bullet_enemy_collision:
    push_ra
    
    # Check if enemy is active
    lw $t9, enemy_active
    beqz $t9, bullet_collision_end  # If enemy is already dead, skip
    
    # Get enemy position
    lw $t7, enemy_x
    lw $t8, enemy_y
    
    # Check each bullet
    li $t0, 0                   # Counter
    la $t1, bullets_active      # Address of bullets_active array
check_bullet_loop:
    beq $t0, MAX_BULLETS, bullet_collision_end  # If checked all bullets, exit
    
    # Check if bullet is active
    sll $t2, $t0, 2             # Calculate offset
    add $t3, $t1, $t2           # Add offset to bullets_active
    lw $t4, 0($t3)              # Load active status
    beqz $t4, check_next_bullet # Skip inactive bullets
    
    # Get bullet position
    la $t3, bullets_x
    la $t4, bullets_y
    sll $t2, $t0, 2             # Recalculate offset
    add $t3, $t3, $t2           # Add offset to bullets_x
    add $t4, $t4, $t2           # Add offset to bullets_y
    lw $t5, 0($t3)              # Load bullet x
    lw $t6, 0($t4)              # Load bullet y
    
    # IMPROVED COLLISION DETECTION - Less strict x matching to improve hit detection
    sub $t9, $t5, $t7           # Calculate x distance between bullet and enemy
    abs $t9, $t9                # Get absolute value
    bgt $t9, 1, check_next_bullet  # Allow for 1 pixel difference in x position
    
    # Check y proximity (within 3 pixels)
    sub $t9, $t6, $t8
    abs $t9, $t9
    bgt $t9, OBJ_HEIGHT, check_next_bullet  # If y difference > 3, no collision
    
    # Bullet hit enemy!
    # First, erase the bullet at current position
    jal erase_bullet
    
    # Deactivate bullet
    la $t3, bullets_active
    sll $t2, $t0, 2             # Recalculate offset
    add $t3, $t3, $t2           # Add offset to bullets_active
    sw $zero, 0($t3)            # Set to inactive
    
    # Deactivate enemy - MORE EXPLICIT HANDLING
    li $t9, 0                   # Make sure we set to 0
    sw $t9, enemy_active        # Store 0 to enemy_active
    
    # Explicitly erase enemy
    jal erase_enemy
    
    j bullet_collision_end      # Exit loop after hit
    
check_next_bullet:
    addi $t0, $t0, 1            # Increment counter
    j check_bullet_loop         # Continue loop
    
bullet_collision_end:
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
	
	# Check if game is won or lost
	lw $t0, game_won
	bnez $t0, check_restart_quit_keys  # If game is won, only process restart and quit
	lw $t0, game_lost
	bnez $t0, check_restart_quit_keys  # If game is lost, only process restart and quit
	
	beq $t1, KEY_SPACE, shoot_bullet
	beq $t1, KEY_A, update_direction_left
	beq $t1, KEY_D, update_direction_right
	beq $t1, KEY_W, jump_up
	beq $t1, KEY_S, drop_down
	# Quit if 'q' is pressed
	beq $t1, KEY_Q, exit_game
	beq $t1, KEY_R, restart_game
	
	check_restart_quit_keys: 
	# Quit if 'q' is pressed
	beq $t1, KEY_Q, exit_game
	# Restart if 'r' is pressed
	beq $t1, KEY_R, restart_game
	
	j check_keyboard_end

shoot_bullet:
    addi $sp, $sp, -4     # Properly allocate space on stack
    sw $ra, 0($sp)        # Store at proper stack location
    
    # Create the bullet
    jal create_bullet
    
    # Redraw the player to ensure it's fully visible
    # First erase the player
    jal erase_player
    jal draw_player
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    j check_keyboard_end
    
update_direction_left:
    li $t9, BULLET_DIRECTION_LEFT
    sw $t9, last_direction
    j move_left
    
update_direction_right:
    li $t9, BULLET_DIRECTION_RIGHT
    sw $t9, last_direction
    j move_right

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
	bgt $t0, PLATFORM_END, adjust_to_platform_end
	j check_platform_end

adjust_to_platform_start:
	li $t0, PLATFORM_START
	sw $t0, player_x
	j check_platform_end

	
adjust_to_platform_end:
	li $t0, PLATFORM_END
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
	blt $t0, FLOOR12_START, skip_jump
	bgt $t0, FLOOR12_END, skip_jump
	# Can jump to floor12
	li $t2, FLOOR12_Y
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
	
####### CLASS OF FUNCTIONS TO HANDLE FALLING DOWN #########################
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

####### END OF FALLING DOWN ###############################################
	
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
    
    # Bottom-left pixel
    sw $a1, 0($s6)
    
    # Bottom-right pixel
    addi $s6, $s6, 4
    sw $a1, 0($s6)
    
    # Top-left pixel
    li $s5, DISPLAY_WIDTH
    sll $s5, $s5, 2
    sub $s6, $s6, 4
    sub $s6, $s6, $s5
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
    
next_coin:
    addi $t2, $t2, 1
    j check_coin_loop
	
check_coins_end:
	jal draw_progress_bar
	# Restore return address and return
	pop_ra
	jr $ra

########### Collide with an enemy, we lose #######
check_enemy_collision:
    push_ra
    
    lw $t9, enemy_active
    beqz $t9, collision_end  # If enemy is already dead, skip collision check
    
    # Get player and enemy positions
    lw $t0, player_x
    lw $t1, player_y
    lw $t2, enemy_x
    lw $t3, enemy_y
    
    # Check if player and enemy are on the same level
    bne $t1, $t3, collision_end
    
    # Check if player and enemy X positions are close (within 0 units)
    # This is a simple collision - only exact overlap counts
    bne $t0, $t2, collision_end
    
    # Player collided with enemy, game over
    li $t0, 1
    sw $t0, game_lost
    
    # Draw lose message
    jal draw_lose_message
    
collision_end:
    pop_ra
    jr $ra
   
######################### Function to restart the game ######################################
restart_game:
    push_ra
    
    # Clear the entire screen
    li $t0, BASE_ADDRESS
    li $t1, BLACK
    li $t2, 0  # X counter
    li $t3, 0  # Y counter
    
clear_screen_loop_y:
    li $t2, 0  # Reset X counter
    
clear_screen_loop_x:
    # Calculate address: BASE + (y * WIDTH + x) * 4
    li $t4, DISPLAY_WIDTH
    mul $t5, $t3, $t4
    add $t5, $t5, $t2
    sll $t5, $t5, 2
    add $t5, $t0, $t5
    sw $t1, 0($t5)  # Draw black pixel
    
    addi $t2, $t2, 1
    blt $t2, DISPLAY_WIDTH, clear_screen_loop_x
    
    addi $t3, $t3, 1
    blt $t3, DISPLAY_HEIGHT, clear_screen_loop_y
    
    # Reset player position
    li $t0, 10
    sw $t0, player_x
    li $t0, 63
    sw $t0, player_y
    
    # Reset enemy
    li $t0, 50
    sw $t0, enemy_x
    li $t0, 63
    sw $t0, enemy_y
    li $t0, 1
    sw $t0, enemy_direction
    li $t0, 0
    sw $t0, enemy_move_counter
    li $t0, 1
    sw $t0, enemy_active
    
    # Reset coins
    li $t0, 0
    sw $t0, coins_collected
    li $t0, 1
    la $t1, coins_active
    sw $t0, 0($t1)
    sw $t0, 4($t1)
    sw $t0, 8($t1)
    sw $t0, 12($t1)
    
    # Reset game states
    li $t0, 0
    sw $t0, game_won
    sw $t0, game_lost
    sw $t0, coin_just_collected
    
    # Reset bullets
    li $t0, 0
    la $t1, bullets_active
    sw $t0, 0($t1)
    sw $t0, 4($t1)
    sw $t0, 8($t1)
    
    # Reset player direction
    li $t0, 1
    sw $t0, last_direction
    
    # Re-initialize coin hitboxes
    li $t0, 0  # Counter for coins
restart_coin_hitboxes:
    beq $t0, 4, restart_coin_end
    
    # Get coin coordinates
    la $t1, coins_y
    la $t2, coins_adj_y
    sll $t3, $t0, 2
    add $t1, $t1, $t3
    add $t2, $t2, $t3
    
    lw $t4, 0($t1)
    addi $t4, $t4, 1
    sw $t4, 0($t2)
    
    addi $t0, $t0, 1
    j restart_coin_hitboxes
    
restart_coin_end:
    # Redraw the game
    jal draw_game
    
    pop_ra
    jr $ra
    
#######################################################################    
draw_menu:
	push_ra
	
	# Clear screen first
	li $t0, BASE_ADDRESS
	li $t1, BLACK
	li $t2, 0  # X counter
	li $t3, 0  # Y counter
	
clear_menu_screen_y:
	li $t2, 0  # Reset X counter
	
clear_menu_screen_x:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t4, DISPLAY_WIDTH
	mul $t5, $t3, $t4
	add $t5, $t5, $t2
	sll $t5, $t5, 2
	add $t5, $t0, $t5
	sw $t1, 0($t5)  # Draw black pixel
	
	addi $t2, $t2, 1
	blt $t2, DISPLAY_WIDTH, clear_menu_screen_x
	
	addi $t3, $t3, 1
	blt $t3, DISPLAY_HEIGHT, clear_menu_screen_y
	
	# Draw the title "GAME" at the top
	li $t0, BASE_ADDRESS
	li $t1, WHITE  # Title color
	
	# Now draw menu options
	# Draw "START" option
	li $t0, BASE_ADDRESS
	li $t1, GREEN  # Option color
	
	# Check if Start is selected
	lw $t9, selected_option
	bnez $t9, start_not_selected
	
	# If selected, draw ">" cursor
li $t2, 22  # X position for cursor
li $t3, 30  # Y position for START option

# Draw ">" character
# First diagonal line (top part of >)
li $t5, DISPLAY_WIDTH
mul $t6, $t3, $t5
add $t6, $t6, $t2
sll $t6, $t6, 2
add $t6, $t0, $t6
li $t7, GREEN  # Cursor color
sw $t7, 0($t6)  # Top-left pixel

# Second diagonal line (bottom part of >)
addi $t3, $t3, 1  # Move down one pixel
li $t5, DISPLAY_WIDTH
mul $t6, $t3, $t5
add $t6, $t6, $t2
sll $t6, $t6, 2
add $t6, $t0, $t6
sw $t7, 0($t6)  # Bottom-left pixel

# Horizontal line (top part of >)
subi $t3, $t3, 1  # Move back up
addi $t2, $t2, 1  # Move right one pixel
li $t5, DISPLAY_WIDTH
mul $t6, $t3, $t5
add $t6, $t6, $t2
sll $t6, $t6, 2
add $t6, $t0, $t6
sw $t7, 0($t6)  # Top-right pixel

# Horizontal line (bottom part of >)
addi $t3, $t3, 1  # Move down one pixel
li $t5, DISPLAY_WIDTH
mul $t6, $t3, $t5
add $t6, $t6, $t2
sll $t6, $t6, 2
add $t6, $t0, $t6
sw $t7, 0($t6)  # Bottom-right pixel

# Reset positions for drawing text
li $t2, 25  # X position for START text
	
	# Make START text brighter if selected
	li $t1, WHITE

start_not_selected:
	# Draw "START" text 
	li $t2, 25  # X position for START
	li $t3, 30  # Y position for START
	
	# "S"
	jal draw_s_letter
	
	# "T"
	addi $t2, $t2, 5  # Move X position
	jal draw_t_letter
	
	# "A"
	addi $t2, $t2, 5  # Move X position
	jal draw_a_letter
	
	# "R"
	addi $t2, $t2, 5  # Move X position
	jal draw_r_letter
	
	# "T"
	addi $t2, $t2, 5  # Move X position
	jal draw_t_letter
	
	# Draw "QUIT" option
	li $t0, BASE_ADDRESS
	li $t1, GREEN  # Option color
	
	# Check if Quit is selected
	lw $t9, selected_option
	beqz $t9, quit_not_selected
	
	# If selected, draw ">" cursor
	li $t2, 22  # X position for cursor
	li $t3, 40  # Y position for START option (or 40 for QUIT)
	
	# Draw ">" character
	# First diagonal line (top part of >)
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	li $t7, GREEN  # Cursor color
	sw $t7, 0($t6)  # Top-left pixel
	
	# Second diagonal line (bottom part of >)
	addi $t3, $t3, 1  # Move down one pixel
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t7, 0($t6)  # Bottom-left pixel
	
	# Horizontal line (top part of >)
	subi $t3, $t3, 1  # Move back up
	addi $t2, $t2, 1  # Move right one pixel
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t7, 0($t6)  # Top-right pixel
	
	# Horizontal line (bottom part of >)
	addi $t3, $t3, 1  # Move down one pixel
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t7, 0($t6)  # Bottom-right pixel
	
	# Reset positions
	li $t2, 25  # X position for text (same as it was before)
	
	# Make QUIT text brighter if selected
	li $t1, WHITE

quit_not_selected:
	# Draw "QUIT" text 
	li $t2, 25  # X position for QUIT
	li $t3, 40  # Y position for QUIT
	
	# "Q"
	jal draw_q_letter
	
	# "U"
	addi $t2, $t2, 5  # Move X position
	jal draw_u_letter
	
	# "I"
	addi $t2, $t2, 5  # Move X position
	jal draw_i_letter
	
	# "T"
	addi $t2, $t2, 5  # Move X position
	jal draw_t_letter
	
	# Add instructions at bottom
	li $t0, BASE_ADDRESS
	li $t1, YELLOW  # Instructions color
	
	li $t2, 10  # X position for instructions
	li $t3, 55  # Y position for instructions
	
	# Use W/S to navigate text
	# This would be too detailed to draw, so we'll just draw a hint
	
	# Calculate address to draw hint pixel
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw first hint pixel
	
	addi $t2, $t2, 45  # Move right for second hint
	
	# Calculate address for second hint
	li $t5, DISPLAY_WIDTH
	mul $t6, $t3, $t5
	add $t6, $t6, $t2
	sll $t6, $t6, 2
	add $t6, $t0, $t6
	sw $t1, 0($t6)  # Draw second hint pixel
	
	pop_ra
	jr $ra

# Helper functions to draw letters
draw_s_letter:
	push_ra
	
	# Save original X position
	move $t4, $t2  # Save starting X
	
	# Top horizontal line
	addi $t5, $t2, 3  # End X
	
s_top:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t7, DISPLAY_WIDTH
	mul $t8, $t3, $t7
	add $t8, $t8, $t2
	sll $t8, $t8, 2
	add $t8, $t0, $t8
	sw $t1, 0($t8)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t5, s_top
	
	# Left vertical line (top half)
	move $t2, $t4  # Reset X to start
	move $t7, $t3  # Save starting Y
	addi $t5, $t3, 2  # End Y
	
s_left_top:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t5, s_left_top
	
	# Middle horizontal line
	move $t3, $t7  # Reset Y to start
	addi $t3, $t3, 2  # Middle Y
	move $t2, $t4  # Reset X to start
	addi $t5, $t2, 3  # End X
	
s_middle:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t5, s_middle
	
	# Right vertical line (bottom half)
	move $t2, $t4  # Reset X to start
	addi $t2, $t2, 3  # Right side X
	move $t3, $t7  # Reset Y to start
	addi $t3, $t3, 2  # Middle Y
	addi $t5, $t3, 2  # End Y
	
s_right_bottom:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t5, s_right_bottom
	
	# Bottom horizontal line
	move $t3, $t7  # Reset Y to start
	addi $t3, $t3, 4  # Bottom Y
	move $t2, $t4  # Reset X to start
	addi $t5, $t2, 3  # End X
	
s_bottom:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t5, s_bottom
	
	# Restore X and Y for the next letter
	move $t2, $t4  # Restore X
	move $t3, $t7  # Restore Y
	
	pop_ra
	jr $ra

draw_t_letter:
	push_ra
	
	# Save original positions
	move $t4, $t2  # Save starting X
	move $t7, $t3  # Save starting Y
	
	# Top horizontal line of T
	addi $t5, $t2, 3  # End X
	
t_top:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t5, t_top
	
	# Vertical line of T
	move $t2, $t4  # Reset X to start
	addi $t2, $t2, 1  # Center X
	move $t3, $t7    # Reset Y to start
	addi $t5, $t3, 4  # End Y
	
t_vertical:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t5, t_vertical
	
	# Restore X and Y for the next letter
	move $t2, $t4  # Restore X
	move $t3, $t7  # Restore Y
	
	pop_ra
	jr $ra

draw_a_letter:
	push_ra
	
	# Remember original position
	move $t4, $t2  # Save starting X
	move $t7, $t3  # Save starting Y
	
	# Left diagonal of A
	move $t2, $t4  # Reset X
	move $t3, $t7  # Reset Y
	addi $t3, $t3, 4  # Bottom Y
	
a_left_diag:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1  # Move right
	subi $t3, $t3, 1  # Move up
	bge $t3, $t7, a_left_diag
	
	# Right diagonal of A
	move $t2, $t4  # Reset X
	addi $t2, $t2, 3  # Right side X
	move $t3, $t7  # Reset Y
	addi $t3, $t3, 4  # Bottom Y
	
a_right_diag:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	subi $t2, $t2, 1  # Move left
	subi $t3, $t3, 1  # Move up
	bge $t3, $t7, a_right_diag
	
	# Middle horizontal line of A
	move $t2, $t4  # Reset X
	addi $t2, $t2, 1  # Middle left X
	move $t3, $t7  # Reset Y
	addi $t3, $t3, 2  # Middle Y
	addi $t5, $t2, 1  # Middle right X
	
a_middle:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t5, a_middle
	
	# Restore X and Y for the next letter
	move $t2, $t4  # Restore X
	move $t3, $t7  # Restore Y
	
	pop_ra
	jr $ra

draw_r_letter:
	push_ra
	
	# Remember original position
	move $t4, $t2  # Save starting X
	move $t7, $t3  # Save starting Y
	
	# Left vertical line of R
	move $t2, $t4  # Reset X
	move $t3, $t7  # Reset Y
	addi $t5, $t3, 4  # End Y
	
r_left_vertical:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t5, r_left_vertical
	
	# Top horizontal line of R
	move $t2, $t4  # Reset X
	move $t3, $t7  # Reset Y
	addi $t5, $t2, 2  # End X
	
r_top:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t5, r_top
	
	# Right vertical line (top half) of R
	move $t2, $t4  # Reset X
	addi $t2, $t2, 2  # Right side X
	move $t3, $t7  # Reset Y
	addi $t3, $t3, 1  # Start Y for vertical
	addi $t5, $t3, 1  # End Y
	
r_right_vertical:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t5, r_right_vertical
	
	# Middle horizontal line of R
	move $t2, $t4  # Reset X
	move $t3, $t7  # Reset Y
	addi $t3, $t3, 2  # Middle Y
	addi $t5, $t2, 2  # End X
	
r_middle:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t5, r_middle
	
	# Diagonal leg of R
	move $t2, $t4  # Reset X
	addi $t2, $t2, 1  # Start X for diagonal
	move $t3, $t7  # Reset Y
	addi $t3, $t3, 2  # Start Y for diagonal
	addi $t5, $t3, 2  # End Y
	
r_diagonal:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1  # Move right
	addi $t3, $t3, 1  # Move down
	ble $t3, $t5, r_diagonal
	
	# Restore X and Y for the next letter
	move $t2, $t4  # Restore X
	move $t3, $t7  # Restore Y
	
	pop_ra
	jr $ra

draw_q_letter:
	push_ra
	
	# Remember original position
	move $t4, $t2  # Save starting X
	move $t7, $t3  # Save starting Y
	
	# Draw circle part of Q
	# Top horizontal line of Q
	move $t2, $t4  # Reset X
	move $t3, $t7  # Reset Y
	addi $t5, $t2, 3  # End X
	
q_top:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t5, q_top
	
	# Left vertical line of Q
	move $t2, $t4  # Reset X
	move $t3, $t7  # Reset Y
	addi $t3, $t3, 1  # Start Y
	addi $t5, $t3, 2  # End Y
	
q_left_vertical:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t5, q_left_vertical
	
	# Right vertical line of Q
	move $t2, $t4  # Reset X
	addi $t2, $t2, 3  # Right side X
	move $t3, $t7  # Reset Y
	addi $t3, $t3, 1  # Start Y
	addi $t5, $t3, 2  # End Y
	
q_right_vertical:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t5, q_right_vertical
	
	# Bottom horizontal line of Q
	move $t2, $t4  # Reset X
	move $t3, $t7  # Reset Y
	addi $t3, $t3, 3  # Bottom Y
	addi $t5, $t2, 3  # End X
	
q_bottom:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t5, q_bottom
	
	# Diagonal tail of Q
	move $t2, $t4  # Reset X
	addi $t2, $t2, 2  # Start X for diagonal
	move $t3, $t7  # Reset Y
	addi $t3, $t3, 3  # Start Y for diagonal
	addi $t5, $t3, 1  # End Y
	
q_diagonal:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1  # Move right
	addi $t3, $t3, 1  # Move down
	ble $t3, $t5, q_diagonal
	
	# Restore X and Y for the next letter
	move $t2, $t4  # Restore X
	move $t3, $t7  # Restore Y
	
	pop_ra
	jr $ra

draw_u_letter:
	push_ra
	
	# Remember original position
	move $t4, $t2  # Save starting X
	move $t7, $t3  # Save starting Y
	
	# Left vertical line of U
	move $t2, $t4  # Reset X
	move $t3, $t7  # Reset Y
	addi $t5, $t3, 3  # End Y
	
u_left_vertical:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t5, u_left_vertical
	
	# Right vertical line of U
	move $t2, $t4  # Reset X
	addi $t2, $t2, 3  # Right side X
	move $t3, $t7  # Reset Y
	addi $t5, $t3, 3  # End Y
	
u_right_vertical:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t5, u_right_vertical
	
	# Bottom horizontal line of U
	move $t2, $t4  # Reset X
	move $t3, $t7  # Reset Y
	addi $t3, $t3, 4  # Bottom Y
	addi $t5, $t2, 3  # End X
	
u_bottom:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t5, u_bottom
	
	# Restore X and Y for the next letter
	move $t2, $t4  # Restore X
	move $t3, $t7  # Restore Y
	
	pop_ra
	jr $ra
	
draw_i_letter:
	push_ra
	
	# Remember original position
	move $t4, $t2  # Save starting X
	move $t7, $t3  # Save starting Y
	
	# Middle vertical line of I
	move $t2, $t4  # Reset X
	addi $t2, $t2, 1  # Center X
	move $t3, $t7  # Reset Y
	addi $t5, $t3, 4  # End Y
	
i_vertical:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t3, $t3, 1
	ble $t3, $t5, i_vertical
	
	# Top horizontal line of I
	move $t2, $t4  # Reset X
	move $t3, $t7  # Reset Y
	addi $t5, $t2, 3  # End X
	
i_top:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t5, i_top
	
	# Bottom horizontal line of I
	move $t2, $t4  # Reset X
	move $t3, $t7  # Reset Y
	addi $t3, $t3, 4  # Bottom Y
	addi $t5, $t2, 3  # End X
	
i_bottom:
	# Calculate address: BASE + (y * WIDTH + x) * 4
	li $t8, DISPLAY_WIDTH
	mul $t9, $t3, $t8
	add $t9, $t9, $t2
	sll $t9, $t9, 2
	add $t9, $t0, $t9
	sw $t1, 0($t9)  # Draw pixel
	
	addi $t2, $t2, 1
	ble $t2, $t5, i_bottom
	
	# Restore X and Y for the next letter
	move $t2, $t4  # Restore X
	move $t3, $t7  # Restore Y
	
	pop_ra
	jr $ra

# Function to handle menu input
handle_menu_input:
	push_ra
	
	# Check if key pressed
	lw $t0, KEYBOARD_CONTROL
	andi $t0, $t0, 1
	beqz $t0, menu_input_end   # No key pressed
	
	# Key was pressed, get the value
	lw $t1, KEYBOARD_DATA
	
	# Check for navigation keys
	beq $t1, KEY_W, menu_up     # W key - move up
	beq $t1, KEY_S, menu_down   # S key - move down
	beq $t1, KEY_SPACE, menu_select  # Space - select option
	beq $t1, KEY_ENTER, menu_select  # Enter - select option
	j menu_input_end
	
menu_up:
	# Move the selection up
	lw $t0, selected_option
	beqz $t0, menu_input_end  # Already at top option
	li $t0, MENU_START_OPTION
	sw $t0, selected_option
	j redraw_menu
	
menu_down:
	# Move the selection down
	lw $t0, selected_option
	bnez $t0, menu_input_end  # Already at bottom option
	li $t0, MENU_QUIT_OPTION
	sw $t0, selected_option
	j redraw_menu
	
menu_select:
	# Process the selected option
	lw $t0, selected_option
	beqz $t0, start_game    # Start option
	# Otherwise, quit
	j exit_game
	
start_game:
	# Change state to game
	li $t0, GAME_STATE
	sw $t0, game_state
	j menu_input_end
	
redraw_menu:
	# Redraw the menu with updated selection
	jal draw_menu
	
menu_input_end:
	pop_ra
	jr $ra
