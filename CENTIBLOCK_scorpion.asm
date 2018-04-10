; "CENTIBLOCK" - CENTIPEDE CLONE for ZX Spectrum.  Kevin Phillips, 1986-2018.
; Scorpion control functions.  A scorpion character is super-simple.  It simply travels in from the
; side of the screen in a straight line.  When it travels over a mushroom, it switches it to poison
; which causes the centipede to kamikaze directly down to the bottom of the screen.
;
; Notes : Vertical location of the scorpion will be around the location of the first active centipede
; segment.  If too low, lets position it up towards the top of the screen.  The X direction will flip
; based on the previous direction.
;

; Colour attribute constants
mushroom        equ 96          ; Bright green for mushrooms
poisonmushy     equ 95          ; Bright Magenta for poison mushrooms
bgcolour        equ 7           ; Background colour to clear centipede from screen
scorpion        equ 72          ; Scorpion colour value    - Blue like spider for now

; -------------------------------------------------------------------------------------------------
; CODE STARTS HERE
; -------------------------------------------------------------------------------------------------
                org 40000
; -------------------------------------------------------------------------------------------------
; MOVESCORPION : Move the scorpion, poison any mushrooms it passes over
; -------------------------------------------------------------------------------------------------
; 
movescorpion    ld ix,scorpData         ; Lets point IX at the flea data
                ld a,(ix+0)             ; First check if the scorpion is actually active
                cp 0
                ret z                   ; Nope, we can just exit

erasescorpion   call clearscn           ; Erase the scorpion character

updatescorpion  ld a,(ix+3)             ; Get the X direction
                cp 1                    ; Is it moving right?
                jr z, scorpionR         ; If so, go and move it right
                
                ; The scorpion can only go one of two ways so assume its left
                ld a,(ix+1)
                dec a
                ld (ix+1),a
                and 224                 ; Before we continue, lets see if its exited the screen
                jr nz, flipscorpion     ; If it has, lets disable the scorpion and flip the direction
                
                call checkscn           ; Otherwise quickly check the screen location
                cp mushroom             ; Did we just travel over a mushroom?
                jr z, setpoisonmushy    ; Yes, then lets set the mushroom to poison
                
                call checkscn           ; Otherwise, lets get the colour
                cp poisonmushy          ; was it already a poison mushroom?
                jr z, setpoisonmushy    ; Yup, just set the mushroom as poison (ie no change)
                
                ld hl,scorpbgC
                ld (hl),bgcolour    ; Otherwise we're all good to just paint it out
                jr drawscorpion
                
                ; Set the scorpbgC to be a poison mushroom
setpoisonmushy  ld hl,scorpbgC
                ld (hl),poisonmushy

drawscorpion    call drawscn            ; redraw the scorpion
                ret                     ; and we're done...

                ; Move the scorpion right - basically the same as left (other than just the, eh, right)
scorpionR       ld a,(ix+1)             ; Get the X coordinate
                inc a                   ; Move it right
                ld (ix+1),a
                and 224                 ; Before we continue, lets see if its exited the screen
                jr nz, flipscorpion     ; If it has, lets disable the scorpion and flip the direction
                
                call checkscn           ; Otherwise quickly check the screen location
                cp mushroom             ; Did we just travel over a mushroom?
                jr z, setpoisonmushy    ; Yes, then lets set the mushroom to poison
                
                call checkscn           ; Otherwise, lets get the colour
                cp poisonmushy          ; was it already a poison mushroom?
                jr z, setpoisonmushy    ; Yup, just set the mushroom as poison (ie no change)
                
                ld hl,scorpbgC
                ld (hl),bgcolour    ; Otherwise we're all good to just paint it out
                jr drawscorpion         ; And jump back to draw scorpion

flipscorpion    ld (ix+0),0             ; Disable the scorpion...
                ld a,(ix+3)             ; check the direction we had been travelling previously
                cp 1                    ; Was it to the right
                jr z, flipL             ; Then lets flip it to go left the next time
                
                ; Otherwise lets flip to go right
                ld (ix+1),0             ; Set X to 0 (left side)
                ld (ix+3),1             ; Set X to move to the right
                ret                     ; And exit
                
flipL           ; Flip it to the left
                ld (ix+1),31            ; Set X to 31 (right side)
                ld (ix+3),0             ; Set X to move to the left
                ret

; -------------------------------------------------------------------------------------------------
; SCREEN FUNCTIONS
; Technically we should turn these into more of a function given that the other game characters
; will all do the same thing.  We can tidy up the complete code once we have the game working...
; -------------------------------------------------------------------------------------------------

; Check the screen location (ie. read the attribute at X,Y)
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

; Draw attribute to screen (scorpion)
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

                ; Lets draw a scoprion character block on screen
                ld de,22528             ; de contains the attribute memory address
                add hl,de               ; add the vertical value
                add hl,bc               ; add the horizontal value
                ld (hl),scorpion        ; Set the block with the colour
                ret

; Clears the scorpion by drawing either black or poison mushroom attribute.  The colour is stored in
; scorpbgC by the scorpion move routine (which detects it before the scorpion is redrawn).
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
                ld a,(scorpbgC)         ; Get the colour to draw
                ld (hl),a               ; Set the block with whatever the colour should be
                ret

; -------------------------------------------------------------------------------------------------
; MAIN CODE : this controls the tick counter, as well as setting up the scorpion and activating it
; -------------------------------------------------------------------------------------------------
thescorpion     ld ix,scorpData
                ld a,(ix+0)             ; Check to see if the scorpion is currently active.
                cp 0                    
                jr z, tickUpdate        ; If not, we'll loop through the tick counter code
                
                call moveScorpion       ; Call the code to move the scorpion
                ret
                
tickUpdate      ld hl,scorpTicker
                ld a,(hl)               ; Get the tick counter
                inc a                   ; and increment it
                ld (hl),a               ; update the tick counter
                cp 32                   ; Check to see if we need to add the scorpion
                jr z, addScorpion
                ret                     ; Otherwise exit
                
addScorpion     ; Lets add the scorpion
                ld ix,scorpData
                ld (ix+0),255           ; Activate scorpion
                ; X and X direction should already be set up
                ; Set the Y location to be the same as the first live centipede segment
                ld hl,segData
scanYloc        ld a,(hl)               ; Check to make sure that we get an active segment
                cp 128                  ; Was it the last segment?
                jr z, resetTicker       ; Yup, just skip over and reset ticker
            
                ld a,(hl)
                cp 255                  ; Was the segment active?
                jr z, getY              ; Yup, lets get the Y, set the scorpion and exit
                inc hl                  ; Jump down over X...
                inc hl                  ; ...Y...
                inc hl                  ; ...and X direction
                inc hl                  ; To the next segment
                jr scanYloc             ; and go loop for next segment
                
getY            inc hl                  ; So jump to X, Y
                inc hl
                ld a,(hl)               ; Grab the Y value
                ld (ix+2),a             ; and set the scorpion's Y value
                
                ; Check first BG colour, and then reset the tick counter
resetTicker     call checkscn           ; Lets make sure we've grabbed the BG colour
                cp mushroom             ; Did we just travel over a mushroom?
                jr z, bgpoison          ; Yes, then lets set the mushroom to poison
                
                call checkscn           ; Otherwise, lets get the colour
                cp poisonmushy          ; was it already a poison mushroom?
                jr z, bgpoison          ; Yup, just set the mushroom as poison (ie no change)
                
                ld hl,scorpbgC
                ld (hl),bgcolour        ; Otherwise we're all good to just paint it out
                jr setZTicker           ; and go finish up...
                
bgpoison        ld hl,scorpbgC
                ld (hl),poisonmushy     ; Otherwise we're all good to just paint it out

setZTicker      ld hl,scorpTicker
                xor a
                ld (hl),a
                ret
                
; -------------------------------------------------------------------------------------------------
; DATA FOLLOWS BELOW
; -------------------------------------------------------------------------------------------------
; Scorpion data (active flag,x,y,x direction)
scorpData       defb    255,0,10,1
                    

; Flea tick counter
scorpTicker     defb    0

; Colour to paint out the scorpion using (ie. blank, or leave poison mushroom)
scorpbgC        defb    bgcolour

; TEST : Segment data for centipede
; This is a single segment acting as a dummy test value for the scorpion. We should be able to
; POKE a random value into the y from BASIC to change it easily for testing.
segData         defb    255,0,9,1
                defb    128
