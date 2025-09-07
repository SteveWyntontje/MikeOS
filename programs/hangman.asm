; ------------------------------------------------------------------
; Geography-based hangman game for MikeOS
;
; At the end of this file you'll see a list of 256 words (in
; lower-case to make the game code simpler). We get one word at
; random from the list and store it in a string.
;
; Next, we create another string of the same size, but with underscore
; characters instead of the real ones. We display this 'work' string to
; the player, who tries to guess characters. If he/she gets a char right,
; it is revealed in the work string.
;
; If he/she gets gets a char wrong, we add it to a list of misses, and
; draw more of the hanging man. Poor bloke.
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "mikedev.inc"
	ORG 32768


start:
	call os_hide_cursor


	; First, reset values in case user is playing multiple games

	mov di, real_string			; Full city name
	mov al, 0
	mov cx, 50
	rep stosb

	mov di, work_string			; String that starts as '_' characters
	mov al, 0
	mov cx, 50
	rep stosb

	mov di, tried_chars			; Chars the user has tried, but aren't in the real string
	mov al, 0
	mov cx, 255
	rep stosb

	mov byte [tried_chars_pos], 0
	mov byte [misses], 1			; First miss is to show the platform


	mov ax, title_msg			; Set up the screen
	mov bx, footer_msg
	mov cx, 01100000b
	call os_draw_background

	mov ax, 0
	mov bx, 255
	call os_get_random			; Get a random number

	mov bl, cl				; Store in BL


	mov si, words				; Skip number of lines stored in BL
skip_loop:
	cmp bl, 0
	je skip_finished
	dec bl
.inner:
	lodsb					; Find a zero to denote end of line
	cmp al, 0
	jne .inner
	jmp skip_loop


skip_finished:
	mov di, real_string			; Store the string from the city list
	call os_string_copy

	mov ax, si
	call os_string_length

	mov dx, ax				; DX = number of '_' characters to show

	call add_underscores


	cmp dx, 5				; Give first char if it's a short string
	ja no_hint

	mov ax, hint_msg_1			; Tell player about the hint
	mov bx, hint_msg_2
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	call os_hide_cursor

	mov ax, title_msg			; Redraw screen
	mov bx, footer_msg
	mov cx, 01100000b
	call os_draw_background

	mov byte al, [real_string]		; Copy first letter over
	mov byte [work_string], al


no_hint:
	call fix_spaces				; Add spaces to working string if necessary

main_loop:
	call show_tried_chars			; Update screen areas
	call show_hangman
	call show_main_box

	cmp byte [misses], 16			; See if the player has lost
	je lost_game

	call os_wait_for_key			; Get input

	cmp al, KEY_ESC
	je finish

	cmp al, 122				; Work with just "a" to "z" keys
	ja main_loop

	cmp al, 97
	jb main_loop

	mov bl, al				; Store character temporarily

	mov cx, 0				; Counter into string
	mov dl, 0				; Flag whether char was found
	mov si, real_string
find_loop:
	lodsb
	cmp al, 0				; End of string?
	je done_find
	cmp al, bl				; Find char entered in string
	je found_char
	inc cx					; Move on to next character
	jmp find_loop



found_char:
	inc dl					; Note that at least one char match was found
	mov di, work_string
	add di, cx				; Update our underscore string with char found
	mov byte [di], bl
	inc cx
	jmp find_loop


done_find:
	mov si, real_string			; If the strings match, the player has won!
	mov di, work_string
	call os_string_compare
	jc won_game

	cmp dl, 0				; If char was found, skip next bit
	jne main_loop

	call update_tried_chars			; Otherwise add char to list of misses

	jmp main_loop


won_game:
	call show_win_msg
.loop:
	call os_wait_for_key			; Wait for keypress
	cmp al, KEY_ESC
	je finish
	cmp al, KEY_ENTER
	jne .loop
	jmp start


lost_game:					; After too many misses...
	call show_lose_msg
.loop:						; Wait for keypress
	call os_wait_for_key
	cmp al, KEY_ESC
	je finish
	cmp al, KEY_ENTER
	jne .loop
	jmp start


finish:
	call os_show_cursor
	call os_clear_screen

	ret




add_underscores:				; Create string of underscores
	mov di, work_string
	mov al, '_'
	mov cx, dx				; Size of string
	rep stosb
	ret



	; Copy any spaces from the real string into the work string

fix_spaces:
	mov si, real_string
	mov di, work_string
.loop:
	lodsb
	cmp al, 0
	je .done
	cmp al, ' '
	jne .no_space
	mov byte [di], ' '
.no_space:
	inc di
	jmp .loop
.done:
	ret



	; Here we check the list of wrong chars that the player entered previously,
	; and see if the latest addition is already in there...

update_tried_chars:
	mov si, tried_chars
	mov al, bl
	call os_find_char_in_string
	cmp ax, 0
	jne .nothing_to_add			; Skip next bit if char was already in list

	mov si, tried_chars
	mov ax, 0
	mov byte al, [tried_chars_pos]		; Move into the list
	add si, ax
	mov byte [si], bl
	inc byte [tried_chars_pos]

	inc byte [misses]			; Knock up the score
.nothing_to_add:
	ret


show_main_box:
	pusha
	mov bl, BLACK_ON_WHITE
	mov dh, 5
	mov dl, 2
	mov si, 36
	mov di, 21
	call os_draw_block

	mov dh, 7
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_1
	call os_print_string

	mov dh, 8
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_2
	call os_print_string

	mov dh, 17
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_3
	call os_print_string

	mov dh, 18
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_4
	call os_print_string

	mov dh, 12
	mov dl, 6
	call os_move_cursor
	mov si, work_string
	call os_print_string

	popa
	ret


show_tried_chars:
	pusha
	mov bl, BLACK_ON_WHITE
	mov dh, 18
	mov dl, 40
	mov si, 39
	mov di, 23
	call os_draw_block

	mov dh, 19
	mov dl, 41
	call os_move_cursor

	mov si, tried_chars_msg
	call os_print_string

	mov dh, 21
	mov dl, 41
	call os_move_cursor

	mov si, tried_chars
	call os_print_string

	popa
	ret



show_win_msg:
	mov bl, WHITE_ON_GREEN
	mov dh, 14
	mov dl, 5
	mov si, 30
	mov di, 15
	call os_draw_block

	mov dh, 14
	mov dl, 6
	call os_move_cursor

	mov si, .win_msg
	call os_print_string

	mov dh, 12
	mov dl, 6
	call os_move_cursor
	mov si, real_string
	call os_print_string

	ret


	.win_msg	db 'Yes! Hit enter to play again', 0



show_lose_msg:
	mov bl, WHITE_ON_LIGHT_RED
	mov dh, 14
	mov dl, 5
	mov si, 30
	mov di, 15
	call os_draw_block

	mov dh, 14
	mov dl, 6
	call os_move_cursor

	mov si, .lose_msg
	call os_print_string

	mov dh, 12
	mov dl, 6
	call os_move_cursor
	mov si, real_string
	call os_print_string

	ret


	.lose_msg	db 'Nope! Hit enter to play again', 0



	; Draw the hangman box and appropriate bits depending on the number of misses

show_hangman:
	pusha

	mov bl, BLACK_ON_WHITE
	mov dh, 2
	mov dl, 42
	mov si, 35
	mov di, 17
	call os_draw_block


	cmp byte [misses], 0
	je near .0
	cmp byte [misses], 1
	je near .1
	cmp byte [misses], 2
	je near .2
	cmp byte [misses], 3
	je near .3
	cmp byte [misses], 4
	je near .4
	cmp byte [misses], 5
	je near .5
	cmp byte [misses], 6
	je near .6
	cmp byte [misses], 7
	je near .7
	cmp byte [misses], 8
	je near .8
	cmp byte [misses], 9
	je near .9
	cmp byte [misses], 10
	je near .10
	cmp byte [misses], 11
	je near .11

.11:					; Right leg
	mov dh, 10
	mov dl, 64
	call os_move_cursor
	mov si, .11_t
	call os_print_string

.10:					; Left leg
	mov dh, 10
	mov dl, 62
	call os_move_cursor
	mov si, .10_t
	call os_print_string

.9:					; Torso
	mov dh, 9
	mov dl, 63
	call os_move_cursor
	mov si, .9_t
	call os_print_string

.8:					; Arms
	mov dh, 8
	mov dl, 62
	call os_move_cursor
	mov si, .8_t
	call os_print_string

.7:					; Head
	mov dh, 7
	mov dl, 63
	call os_move_cursor
	mov si, .7_t
	call os_print_string

.6:					; Rope
	mov dh, 6
	mov dl, 63
	call os_move_cursor
	mov si, .6_t
	call os_print_string

.5:					; Beam
	mov dh, 5
	mov dl, 56
	call os_move_cursor
	mov si, .5_t
	call os_print_string

.4:					; Support for beam
	mov dh, 6
	mov dl, 57
	call os_move_cursor
	mov si, .4_t
	call os_print_string

.3:					; Pole
	mov dh, 12
	mov dl, 56
	call os_move_cursor
	mov si, .3_t
	call os_print_string
	mov dh, 11
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 10
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 9
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 8
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 7
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 6
	mov dl, 56
	call os_move_cursor
	call os_print_string

.2:					; Support for pole
	mov dh, 13
	mov dl, 55
	call os_move_cursor
	mov si, .2_t
	call os_print_string

.1:					; Ground
	mov dh, 14
	mov dl, 53
	call os_move_cursor
	mov si, .1_t
	call os_print_string
	

.0:
	popa
	ret


	.1_t		db '-------------', 0
	.2_t		db '/|\', 0
	.3_t		db '|', 0
	.4_t		db '/', 0
	.5_t		db '________', 0
	.6_t		db '|', 0
	.7_t		db 'O', 0
	.8_t		db '---', 0
	.9_t		db '|', 0
	.10_t		db '/', 0
	.11_t		db '\', 0



	title_msg	db 'MikeOS Hangman', 0
	footer_msg	db 'Press Esc to exit', 0

	hint_msg_1	db 'Short word this time, so you', 0
	hint_msg_2	db 'get the first letter for free!', 0

	help_msg_1	db 'Can you guess the word', 0
	help_msg_2	db 'that fits the spaces beneath?', 0
	help_msg_3	db 'Press keys to guess letters,', 0
	help_msg_4	db 'but you only have 15 chances!', 0

	real_string	times 50 db 0
	work_string	times 50 db 0

	tried_chars_msg	db 'Tried characters...', 0
	tried_chars_pos	db 0
	tried_chars	times 255 db 0

	misses		db 1



words:

db 'apple', 0
db 'banana', 0
db 'cherry', 0
db 'grape', 0
db 'orange', 0
db 'peach', 0
db 'pear', 0
db 'plum', 0
db 'mango', 0
db 'melon', 0
db 'kiwi', 0
db 'lemon', 0
db 'lime', 0
db 'berry', 0
db 'coconut', 0
db 'papaya', 0
db 'guava', 0
db 'fig', 0
db 'date', 0
db 'olive', 0
db 'apricot', 0
db 'nectarine', 0
db 'pineapple', 0
db 'pomegranate', 0
db 'raspberry', 0
db 'strawberry', 0
db 'blueberry', 0
db 'blackberry', 0
db 'cranberry', 0
db 'watermelon', 0
db 'cantaloupe', 0
db 'honeydew', 0
db 'dragonfruit', 0
db 'passionfruit', 0
db 'lychee', 0
db 'persimmon', 0
db 'tangerine', 0
db 'kumquat', 0
db 'starfruit', 0
db 'jackfruit', 0
db 'durian', 0
db 'rambutan', 0
db 'sapodilla', 0
db 'longan', 0
db 'mulberry', 0
db 'quince', 0
db 'gooseberry', 0
db 'currant', 0
db 'elderberry', 0
db 'boysenberry', 0
db 'cloudberry', 0
db 'salak', 0
db 'tamarind', 0
db 'soursop', 0
db 'cherimoya', 0
db 'jabuticaba', 0
db 'marionberry', 0
db 'huckleberry', 0
db 'ackee', 0
db 'bilberry', 0
db 'medlar', 0
db 'miraclefruit', 0
db 'naranjilla', 0
db 'pitaya', 0
db 'santol', 0
db 'ugli', 0
db 'yuzu', 0
db 'zucchini', 0
db 'tomato', 0
db 'carrot', 0
db 'potato', 0
db 'onion', 0
db 'garlic', 0
db 'pepper', 0
db 'cucumber', 0
db 'lettuce', 0
db 'spinach', 0
db 'broccoli', 0
db 'cauliflower', 0
db 'cabbage', 0
db 'kale', 0
db 'celery', 0
db 'radish', 0
db 'beet', 0
db 'turnip', 0
db 'parsnip', 0
db 'squash', 0
db 'pumpkin', 0
db 'zucchini', 0
db 'eggplant', 0
db 'okra', 0
db 'artichoke', 0
db 'asparagus', 0
db 'pea', 0
db 'bean', 0
db 'lentil', 0
db 'chickpea', 0
db 'soybean', 0
db 'corn', 0
db 'rice', 0
db 'wheat', 0
db 'barley', 0
db 'oat', 0
db 'rye', 0
db 'quinoa', 0
db 'buckwheat', 0
db 'millet', 0
db 'sorghum', 0
db 'teff', 0
db 'amaranth', 0
db 'spelt', 0
db 'kamut', 0
db 'emmer', 0
db 'einkorn', 0
db 'durum', 0
db 'semolina', 0
db 'bulgur', 0
db 'farro', 0
db 'freekeh', 0
db 'couscous', 0
db 'polenta', 0
db 'grits', 0
db 'porridge', 0
db 'muesli', 0
db 'granola', 0
db 'bread', 0
db 'pasta', 0
db 'noodle', 0
db 'dumpling', 0
db 'tortilla', 0
db 'pancake', 0
db 'waffle', 0
db 'crepe', 0
db 'bagel', 0
db 'croissant', 0
db 'muffin', 0
db 'scone', 0
db 'biscuit', 0
db 'cookie', 0
db 'brownie', 0
db 'cake', 0
db 'pie', 0
db 'tart', 0
db 'pudding', 0
db 'custard', 0
db 'jelly', 0
db 'jam', 0
db 'honey', 0
db 'syrup', 0
db 'sugar', 0
db 'salt', 0
db 'pepper', 0
db 'spice', 0
db 'herb', 0
db 'oil', 0
db 'vinegar', 0
db 'butter', 0
db 'cheese', 0
db 'milk', 0
db 'cream', 0
db 'yogurt', 0
db 'icecream', 0
db 'chocolate', 0
db 'candy', 0
db 'toffee', 0
db 'caramel', 0
db 'fudge', 0
db 'marshmallow', 0
db 'gum', 0
db 'mint', 0
db 'tea', 0
db 'coffee', 0
db 'juice', 0
db 'soda', 0
db 'water', 0
db 'wine', 0
db 'beer', 0
db 'whiskey', 0
db 'vodka', 0
db 'rum', 0
db 'gin', 0
db 'brandy', 0
db 'liqueur', 0
db 'cocktail', 0
db 'smoothie', 0
db 'shake', 0
db 'soup', 0
db 'stew', 0
db 'curry', 0
db 'chili', 0
db 'salad', 0
db 'sandwich', 0
db 'burger', 0
db 'pizza', 0
db 'pasta', 0
db 'noodle', 0
db 'rice', 0
db 'sushi', 0
db 'taco', 0
db 'burrito', 0
db 'quesadilla', 0
db 'nachos', 0
db 'enchilada', 0
db 'fajita', 0
db 'wrap', 0
db 'roll', 0
db 'springroll', 0
db 'dumpling', 0
db 'wonton', 0
db 'bao', 0
db 'gyoza', 0
db 'pierogi', 0
db 'empanada', 0
db 'samosa', 0
db 'pakora', 0
db 'bhaji', 0
db 'kebab', 0
db 'skewer', 0
db 'meatball', 0
db 'sausage', 0
db 'bacon', 0
db 'ham', 0
db 'steak', 0
db 'chop', 0
db 'roast', 0
db 'grill', 0
db 'barbecue', 0
db 'smoke', 0
db 'bake', 0
db 'fry', 0
db 'boil', 0
db 'steam', 0
db 'poach', 0
db 'braise', 0
db 'stew', 0
db 'simmer', 0
db 'reduce', 0
db 'thicken', 0
db 'blend', 0
db 'mix', 0
db 'whisk', 0
db 'knead', 0
db 'roll', 0
db 'cut', 0
db 'chop', 0
db 'slice', 0
db 'dice', 0
db 'mince', 0
db 'grate', 0
db 'peel', 0
db 'core', 0
db 'seed', 0
db 'pit', 0
db 'hull', 0
db 'trim', 0
db 'clean', 0


; ------------------------------------------------------------------

