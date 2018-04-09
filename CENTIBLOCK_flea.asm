; "CENTIBLOCK" - CENTIPEDE CLONE for ZX Spectrum.  Kevin Phillips, 1986-2018.
; Flea control functions.  A flea character is super-simple.  It drops down the screen above the
; player and deposits random mushrooms (and deletes others).  Like the spider example, the flea
; will only appear every 'tick'.  The flea is also impervious to bullets, and should (as in will
; need to be added to other player/bullet code) just kill any bullet fired at it.
;
; Like the spider, a pseudo-buffer of values is created to trigger when a mushroom should appear
;

; Colour attribute constants
mushroom        equ 96          ; Bright green for mushrooms
bgcolour        equ 7           ; Background colour to clear centipede from screen
flea            equ 48          ; Flea colour value    - yellow

; -------------------------------------------------------------------------------------------------
; CODE STARTS HERE
; -------------------------------------------------------------------------------------------------
                org 40000
; -------------------------------------------------------------------------------------------------
; DROPFLEA : Calculate and drop the flea
; -------------------------------------------------------------------------------------------------
; 
dropflea		ld ix,fleaData          ; Lets point IX at the flea data
				ld a,(ix+0)				; First check if the flea is actually active
				cp 0
				ret z					; Nope, we can just exit
				
				; Check on our 'pseudo-random' mushroom drop
				ld hl,(randM)			; Get location
				ld a,(hl)				; Grab the value of the random drop
				cp 128					; Are we at the end of the data yet?
				jr nz, selectDrop		; No, then lets determine if we drop a mushroom
				
				ld hl,randDrop			; Reset the loop
				ld (randM),hl
				ld a,(hl)				; and grab the first value again

selectDrop		cp 0
				jr z, setBG				; If it was 0, we use the bgcolour

				inc hl
				ld(randM),hl
				
				ld hl,whatDropC		; Set the colour to a mushroom
				ld (hl),mushroom
				jr goflea

setBG			inc hl
				ld(randM),hl

			    ld hl,whatDropC
				ld (hl),bgcolour
				
goflea			; Erase flea
				call clearscn

				; move flea
				ld a,(ix+2)				; Select Y
				inc a					; Move it down
				ld (ix+2),a
				cp 24					; Is it at the bottom?
				jr nz, drawFlea			; Nope, we're safe to draw the flea
				
				ld (ix+0),0				; disable the flea
				ret						; and exit
				
drawFlea		; Draw flea
                call drawscn
				ret

; -------------------------------------------------------------------------------------------------
; SCREEN FUNCTIONS
; Technically we should turn these into more of a function given that the other game characters
; will all do the same thing.  We can tidy up the complete code once we have the game working...
; -------------------------------------------------------------------------------------------------

; Check the screen location (ie. read the attribute at X,Y
checkscn        ld a,(ix+1)
                ld c,a                  ; load the X value (stored in 'a') into the c register
                xor a                   ; xor a will effectively 0 out 'a'. xor is often used as a quick
                                        ; way to say, wipe a graphic from screen by xor'ing over itself.
                ld b,a                  ; Load 0 into b register, leaving bc=X
                ld h,a                  ; Also 0 out the h register
                ld l,(ix+2)             ; set the l register to the Y. hl=Y

                ; Adding hl 5 times essentially creates Y * 32(32 being the result of the 5 add's). Explanation below
                add hl,hl               ; If Y was 10, we get 10+10 = 20
                add hl,hl               ; 20+20 = 40
                add hl,hl               ; 40+40 = 80
                add hl,hl               ; 80+80 = 160
                add hl,hl               ; 160+160 = 320... Its all to do with the way binary doubles (1,2,4,8,16 > 32)

                ; Lets get the screen address and the value at that address
                ld de,22528             ; de contains the attribute memory address
                add hl,de               ; add the vertical value
                add hl,bc               ; add the horizontal value
                ld a,(hl)               ; grab the screen contents
                ret                     ; and return (a contains the screen contents)

; Draw attribute to screen (flea)
drawscn         ld a,(ix+1)             ; grab the X location
                ld c,a                  ; load the X value (stored in 'a') into the c register
                xor a                   ; xor a will effectively 0 out 'a'. xor is often used as a quick
                                        ; way to say, wipe a graphic from screen by xor'ing over itself.
                ld b,a                  ; Load 0 into b register, leaving bc=X
                ld h,a                  ; Also 0 out the h register
                ld l,(ix+2)             ; set the l register to the Y. hl=Y

                ; Adding hl 5 times essentially creates Y * 32(32 being the result of the 5 add's). Explanation below
                add hl,hl               ; If Y was 10, we get 10+10 = 20
                add hl,hl               ; 20+20 = 40
                add hl,hl               ; 40+40 = 80
                add hl,hl               ; 80+80 = 160
                add hl,hl               ; 160+160 = 320... Its all to do with the way binary doubles (1,2,4,8,16 > 32)

                ; Lets draw a red character block on screen
                ld de,22528             ; de contains the attribute memory address
                add hl,de               ; add the vertical value
                add hl,bc               ; add the horizontal value
                ld (hl),flea               ; Set the block with the colour
                ret

; Clears the flea by drawing either black or mushroom attribute.  This is similiar to the player code
; where a colour is stored in a temporary memory location.  The value is set by the flea movement loop.
clearscn        ld a,(ix+1)             ; grab the X location
                ld c,a                  ; load the X value (stored in 'a') into the c register
                xor a                   ; xor a will effectively 0 out 'a'. xor is often used as a quick
                                        ; way to say, wipe a graphic from screen by xor'ing over itself.
                ld b,a                  ; Load 0 into b register, leaving bc=X
                ld h,a                  ; Also 0 out the h register
                ld l,(ix+2)             ; set the l register to the Y. hl=Y

                ; Adding hl 5 times essentially creates Y * 32(32 being the result of the 5 add's). Explanation below
                add hl,hl               ; If Y was 10, we get 10+10 = 20
                add hl,hl               ; 20+20 = 40
                add hl,hl               ; 40+40 = 80
                add hl,hl               ; 80+80 = 160
                add hl,hl               ; 160+160 = 320... Its all to do with the way binary doubles (1,2,4,8,16 > 32)

				; 
                ; Lets draw the necessary 'clear' character block on screen
                ld de,22528             ; de contains the attribute memory address
                add hl,de               ; add the vertical value
                add hl,bc               ; add the horizontal value
				ld a,(whatDropC)		; Get the colour to draw
                ld (hl),a				; Set the block with whatever the colour should be
                ret

; -------------------------------------------------------------------------------------------------
; MAIN CODE : this controls the tick counter, as well as setting up the flea and activating it
; -------------------------------------------------------------------------------------------------
theflea			ld ix,fleaData
				ld a,(ix+0)				; Check to see if the flea is currently active.
				cp 0					
				jr z, tickUpdate		; If not, we'll loop through the tick counter code
				
				call dropflea			; Call the code to drop the flea
				ret
tickUpdate		ld hl,fleaTicker
				ld a,(hl)				; Get the tick counter
				inc a					; and increment it
				ld (hl),a				; update the tick counter
				cp 64					; Check to see if we need to add a flea
				jr z, addFlea
				ret						; Otherwise exit
				
addFlea			; Lets add a flea
				ld ix,playerData
				ld a,(ix+1)				; Get the player X
				
				; Set the flea info
				ld ix,fleaData
				ld (ix+0),255			; Activate flea
				ld (ix+1),a				; Set the flea above the player location
				ld (ix+2),0				; Set to top of screen
				
				; Reset the counter
				xor a
				ld (hl),a
				ret
; -------------------------------------------------------------------------------------------------
; DATA FOLLOWS BELOW
; -------------------------------------------------------------------------------------------------
; Player data (Active flag, x, y) - dummy for now so can test code
playerData		defb	0,16,18

; Flea data (active flag,x,y)
fleaData        defb    0,10,0

; Flea tick counter
fleaTicker		defb	0

; Random pointer for the 'pseudo random' values
randM			defw	randDrop

; Random data for mushy drop.  Data ends with 128
randDrop		defb 1,0,0,0,0,0,0,0,1,0,0,1,0,0,0,1,0,1,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,1,0,0,1,0,0,1
				defb 1,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,1,0,0,0,1,0,1,0,1,0,0
				defb 1,0,1,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,1,0,1,0,0,0
				defb 128

; What to clear the flea with (bg or mushroom)
whatDropC		defb	bgcolour
