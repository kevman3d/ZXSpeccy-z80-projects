; "CENTIBLOCK" - CENTIPEDE CLONE for ZX Spectrum.  Kevin Phillips, 1986-2018.
; Player and Bullet control functions.  Code that reads the keyboard, moves the player and controls
; firing of the bullet.  Note that the bullet function will test for collisions and update relevant
; flags of other elements in game.  This example simply checks for mushrooms, but will be expanded
; later when integrated into the entire game.
;
; Techniques in this code to note:
; * Key reading using ULA port 254 (pass address lines to A and then IN A,(254))

; Colour attribute constants
mushroom        equ 96          ; Bright green for mushrooms
bgcolor         equ 7           ; Background colour to clear centipede from screen
poisonmushy     equ 95          ; Poison mushroom value  - Bright purple
playership      equ 104         ; player colour value    - Cyan
bullet          equ 56          ; bullet colour value    - white

; -------------------------------------------------------------------------------------------------
; CODE STARTS HERE
; -------------------------------------------------------------------------------------------------
                org 40000
; -------------------------------------------------------------------------------------------------
; MOVEPLAYER : Calculate and move the player ship.
; -------------------------------------------------------------------------------------------------
; Note that as this is a single entity, all processing is done in the one function.

moveplayer      ; BULLET : Erase the bullet if active5
                ld ix,bulletData        ; Set to bulletData quickly
                ld a,(ix+0)             ; Is the bullet actually active?
                cp 0
                jr z, goplayer          ; Yup, well, just skip over and do the player
                call clearscn           ; otherwise erase the bullet from screen

goplayer        ld ix,playerData        ; Lets point IX at the player data
                
                ; Firstly, lets backup the X and Y location
                ld a,(ix+1)             ; Read the segment's X location into the 'a' register
                ld (tempX),a            ; Store the X location temporarily into a memory location
                ld a,(ix+2)             ; Read the segment's Y location
                ld (tempY),a            ; Store the Y location temporarily
                
                ; Erase the player ship first
                call clearscn

                ; Read the keys.  The key details will be returned in d (bits 7-3)
                call readKeys
                
                ; Now move and update the players position
pressedup       bit 7,d                 ; Was up pressed?
                jr z, presseddn         ; No, lets go test down
                
                ld a,(ix+2)             ; Get Y
                dec a                   ; Move up
                ld (ix+2),a             ; Update the Y value
                
                ; Did we hit a mushroom?  We can't move through these
                call checkscn
                cp mushroom
                jr z, stopYu            ; Yup, lets reset the Y value
                
                ; Did we hit a poison muchroom?
                call checkscn
                cp poisonmushy
                jr nz, okcheckup        ; Nope, we can skip over
                
stopYu          ld a,(tempY)            ; If we hit mushroom, lets reset the position
                ld (ix+2),a
okcheckup       ld a,(ix+2)
                cp 18                   ; Is the Y at the top max for the player
                jr nz, pressedlt        ; No, we're all good - jump to left press...
                
                ld a,(tempY)            ; Otherwise just reset the Y value
                ld (ix+2),a
                jr pressedlt
                
                ; Check for player moving down.
presseddn       call readKeys           ; Call the readKeys fucntion (checkscn screws d register)
                bit 6,d
                jr z, pressedlt         ; No, lets go test left
                
                ld a,(ix+2)             ; Get Y
                inc a                   ; Move down
                ld (ix+2),a             ; Update the Y value
                
                ; Did we hit a mushroom?  We can't move through these
                call checkscn
                cp mushroom
                jr z, stopYd                ; Yup, lets reset the Y value
                
                ; Did we hit a poison mushroom?
                call checkscn
                cp poisonmushy
                jr nz, okcheckdn        ; Nope, we can skip over
                
stopYd          ld a,(tempY)            ; If we hit mushroom, lets reset the position
                ld (ix+2),a
okcheckdn       ld a,(ix+2)
                cp 24                   ; Is the Y at the bottom of the screen
                jr nz, pressedlt        ; No, we're all good - jump to left press...
                
                ld a,(tempY)            ; Otherwise just reset the Y value
                ld (ix+2),a
                
pressedlt       call readKeys           ; Call the readKeys fucntion (checkscn screws d register)
                bit 5,d
                jr z, pressedrt         ; No, lets go test right

                ld a,(ix+1)             ; Get X
                dec a                   ; Move left
                ld (ix+1),a             ; Update the X value
                
                ; Did we hit a mushroom?  We can't move through these
                call checkscn
                cp mushroom
                jr z, stopXl            ; Yup, lets reset the X value
                
                ; Did we hit a poison mushroom?
                call checkscn
                cp poisonmushy
                jr nz, okchecklt        ; Nope, we can skip over
                
stopXl          ld a,(tempX)            ; If we hit mushroom, lets reset the position
                ld (ix+1),a
                
okchecklt       ld a,(ix+1)
                cp 0                    ; Is the X at the edge of the screen
                jr nz, pressedfire      ; No, we're all good - jump to fire press check
                
                ld a,(tempX)            ; Otherwise just reset the X value
                ld (ix+1),a
                
pressedrt       call readKeys           ; Call the readKeys fucntion (checkscn screws d register)
                bit 4,d
                jr z, pressedfire       ; No, we can just jump down to see if fire was pressed.

                ld a,(ix+1)             ; Get X
                inc a                   ; Move right
                ld (ix+1),a             ; Update the X value
                
                ; Did we hit a mushroom?  We can't move through these
                call checkscn
                cp mushroom
                jr z, stopXr            ; Yup, lets reset the X value
                
                ; Did we hit a poison mushroom?
                call checkscn
                cp poisonmushy
                jr nz, okcheckrt        ; Nope, we can skip over
                
stopXr          ld a,(tempX)            ; If we hit mushroom, lets reset the position
                ld (ix+1),a
                
okcheckrt       ld a,(ix+1)
                cp 31                   ; Is the X at the edge of the screen
                jr nz, pressedfire      ; No, we're all good - jump to fire press check
                
                ld a,(tempX)            ; Otherwise just reset the X value
                ld (ix+1),a
                
pressedfire     ld ix,bulletData        ; First, point ix to the bulletdata
                call readKeys           ; Call the readKeys fucntion (checkscn screws d register)
                bit 3,d
                jr z, movebullet        ; Nope, just skip over and check if we can move the bullet.
                
                ; Check bullet status
                ld a,(ix+0)             ; Check if bullet is active already
                cp 0
                jr nz, movebullet       ; if yes, just go move it
                
                ; Set up a new bullet
                ld (ix+0),255           ; Activate the bullet
                ld hl,playerData        ; Get the players details and set bullet
                inc hl
                ld a,(hl)               ; Get the players X
                ld (ix+1),a             ; and set the bullet to the same
                inc hl
                ld a,(hl)               ; Get the players Y
                dec a                   ; Set the bullet to the player Y - 1
                ld (ix+2),a
                jr notfired             ; And we can jump down to draw ship and bullet
                
                ; Move the bullet.  Note the double-check to see if the bullet was active.  This is
                ; to compensate for the keypress not knowing this fact yet...
movebullet      ld a,(ix+0)             ; Check if bullet is active already
                cp 0
                jr z, notfired          ; if not just skip over the move
                ld a,(ix+2)             ; Get the bullets Y
                dec a                   ; move up
                ld (ix+2),a
                cp 0                    ; Top of screen reached?
                jr nz, notfired         ; Nope, we can then skip down to draw ship and bullet
                
                ld (ix+0),0             ; Disable bullet (out of top of screen)
                
notfired        ld ix,playerData        ; Set the IX to the players data
                ld hl,tempC
                ld (hl),playership      ; Set the 'graphic' (colour) to the player ship (this allows
                                        ; this routine to be reused for multiple purposes (kinda))
                call drawscn            ; draw ship
                
                ; DRAW BULLET - finish up with checking for bullet hits, either drawing the bullet or
                ; drawing an explosion/fx instead and deactivating the bullet.
                ld ix,bulletData        ; Set to bulletData quickly
                ld a,(ix+0)             ; Is the bullet actually active?
                cp 0
                ret z                   ; Nope - safe to exit
                
                ; Check for collisions.  If so, we're going to draw FX and kill the bullet
                ; Did we hit a mushroom?  We can't move through these
                call checkscn
                cp mushroom
                jr z, goBoom
                
                call checkscn
                cp poisonmushy
                jr z, goBoom
                
                ; Draw the bullet to screen
                ld hl,tempC
                ld (hl),bullet          ; Set the 'graphic' (colour) to the bullet (this allows
                                        ; this routine to be reused for multiple purposes (kinda))
                call drawscn            ; draw bullet
                ret
                
                ; Draw a boom FX and then kill the bullet.
goBoom          ld hl,tempC
                ld (hl),80              ; For now, I'm just gonna make the square go red
                call drawscn
                
                ld (ix+0),0
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

; Draw attribute to screen.  Note that I've used a tempC location so I can share this with the bullet
; rather than make a messy multiple-copy thing (like we already do - lol!).  Will obviously be rewritten
; when we compile this into a single game rather that this example code...
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
                ld a,(tempC)            ; Read the colour to paint
                ld (hl),a               ; Set the block with the colour
                ret

; Clears the segment by drawing a black attribute
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

                ; Lets draw a red character block on screen
                ld de,22528             ; de contains the attribute memory address
                add hl,de               ; add the vertical value
                add hl,bc               ; add the horizontal value
                ld (hl),bgcolor         ; Set the block with red
                ret


; -------------------------------------------------------------------------------------------------
; READKEYS : Reads the keyboard, stores all key presses into the d register
; -------------------------------------------------------------------------------------------------
; Reading keys is done by loading the port # into a, then reading the port using in a,(254). Port 254
; accesses info in the ULA.  We pass the address lines we want to request in 'a' first.  In this case
; the ports in the keysTable define the address lines for the various half-keyboard lines.
;
; The key bit (returned byte from 'in a,(254)') is checked and if true, stored into the d register.
;
; d bits    7  6  5  4  3  2  1  0
;           up dn lt rt fr -  -  -

readKeys        ld hl,keysTable         ; Set hl to the key table (which contains port and bits)
                ld d,0                  ; Zero out d.  This will be populated with the keys pressed
                                        ; info.  Each key is stored in bits 7...3 (as per table)
                ld b,5                  ; We're going to read 5 keys. Set the loop in b reg
                ld c,0                  ; Zero out the c register
                
readKeyLoop     ld a,(hl)               ; Read the key port from the table
                in a,(254)              ; Read port 254 (with the a register forming the other
                                        ; part (address lines) for reading key input)
                cpl                     ; cpl (complement) inverts the a register result. Bits are
                                        ; reset when pressed, so invert to make them set.
                                        
                inc hl                  ; Read next piece of data - the bit that we need to test for
                and (hl)                ; 'and(hl)' will mask the value in 'a' (and 0 out the rest)
                inc hl
                cp 0                    ; Was the key not pressed?
                jr z, trynextkey        ; Yup, so we can skip and read next key
                
                ld a,d                  ; Read the d register (where we're storing keys pressed)
                or (hl)                 ; And set the 'pressed' bit in d (which gets passed back
                                        ; when this routine exits)
                ld d,a                  ; And store the updated value back into d
                
trynextkey      inc hl
                djnz readKeyLoop        ; Decrement b and repeat if not zero yet

                ret                     ; and finally return.  d register will contain bit values
                                        ; to indicate what keys had been pressed
                                        
; -------------------------------------------------------------------------------------------------
; DATA FOLLOWS BELOW
; -------------------------------------------------------------------------------------------------
; Player data (Active flag (lives counter), x, y)
playerData      defb    3,15,19

; Bullet data (active flag, x, y)
bulletData      defb    0,15,19

; Temp storage of X and Y location
tempX           defb    0
tempY           defb    0

; In this code, this quicky hack is used to store colour to draw for drawscn function
tempC           defb    7

; Table for keys (port value, bit test, recordBit (to store keypress if true))
keysTable       defb    251,1,128       ; Q key
                defb    253,1,64        ; A key
                defb    223,2,32        ; O key
                defb    223,1,16        ; P key
                defb    127,4,8         ; M Key
