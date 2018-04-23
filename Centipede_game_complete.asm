; -------------------------------------------------------------------------------------------------------
; SIMPLE CENTIPEDE, written by Kevin Phillips, 1986 - 2018.
; a very simple version of the arcade game centipede written in Z80 assembler.  Source code has been
; heavily commented to help explain how it works.  This was written as a personal 'refresher' some 35+
; years after last touching Z80, and inspired by the upcoming ZX Spectrum Next community to return to
; my roots as the saying goes. And as a resource for the ZX Spectrum enthusiasts looking for sample code
; to learn from.
;
; -------------------------------------------------------------------------------------------------------

; Defined labels to make things more 'readable' in our code, and also easy to tweak globally of course
; Attribute colour codes
bgclr           equ 7   ; Blank square, colour white
mushclr         equ 4   ; Colour green
fleaclr         equ 6   ; Colour yellow
playerclr       equ 71  ; Colour bright white
bulletclr       equ 7   ; Colour white
centclr         equ 2   ; Colour red
spiderclr       equ 5   ; Colour cyan
scorpionclr     equ 67  ; Colour bright magenta
poisonclr       equ 3   ; Colour magenta101

; general 'switch' codes for various/common flags
swOff           equ 0   ; generic off
swOn            equ 255 ; generic on
swKamikaze      equ 64  ; centipede kamikaze
movRight        equ 1   ; generic move right value
screenH         equ 24  ; Screen height (max Y + 1)
screenW         equ 32  ; Screen Width (max X + 1)
screenT         equ 1   ; Min screen value (ie. for game chars)
screenB         equ 1   ; Screen border gutter (sides)
playerMin       equ 18  ; Highest the player ship can go

; -------------------------------------------------------------------------------------------------------
; DEFINE ADDRESS TO ASSEMBLE TO
; -------------------------------------------------------------------------------------------------------

org 40000

; -------------------------------------------------------------------------------------------------------
; GAME CHARACTER ROUTINES
; The following routines are all used to clear, move and draw the characters in our game.  All code is
; collected from a variety of example pieces of code found on github below
; https://github.com/kevman3d/ZXSpeccy-z80-projects
; -------------------------------------------------------------------------------------------------------

; -------------------------------------------------------------------------------------------------------
;                                T  H  E    C  E  N  T  I  P  E  D  E
; -------------------------------------------------------------------------------------------------------
; CENTIPEDE SEGMENT : Calculates the movement of a single centipede segment.  This is called from a 
; following routine called 'movecentipede'
; -------------------------------------------------------------------------------------------------------
; Important : load address for a single segment's data into ix *before* calling this...

centsegment     ld a,(ix+0)             ; Check to make sure the segment is actually 'alive'
                cp swOff                ; Was it off?
                ret z                   ; If so, we can safely return and do nothing
                
                ; Firstly, lets backup the X and Y location
                ld a,(ix+1)             ; Read the segment's X location into the 'a' register
                ld (tempX),a            ; Store the X location temporarily into a memory location
                ld a,(ix+2)             ; Read the segment's Y location
                ld (tempY),a            ; Store the Y location temporarily

                ; Check if its in Kamikaze mode.  If so, we're just moving straight down.
                ld a,(ix+0)             ; Get the segment's active flag
                cp swKamikaze           ; A setting of 64 means its in Kamikaze mode
                jr nz, centhorz         ; If its not, just skip over and do the usual movement
                
kamikaze        ld a,(ix+2)             ; Get the Y location
                inc a                   ; Move down
                ld (ix+2),a             ; Store this updated value back into Y
                cp screenH              ; Is it at the bottom of the screen?
                ret nz                  ; Nope - so we can now exit - we've moved the segment...
                
                ld (ix+2),screenT       ; Otherwise lets reset the centipede back to the top
                ld (ix+0),255           ; Reset the active flag to normal
                ret                     ; and we're done.
                
centhorz        ld a,(ix+3)             ; read the X move direction
                cp movRight             ; check to see if was 1 (right).
                jr z,centright          ; If true, skip down to move right

centleft        ld a,(ix+1)             ; Get the X coordinate
                dec a                   ; Move it left one
                ld (ix+1),a             ; update the X coordinate
                
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                
                call getattr            ; We now need to check and see if this new location is a mushroom
                cp mushclr              ; The result was returned in the 'a' register.  See if it was a mushroom
                jr z, centdown          ; and if true, jump to the down label
                call getattr
                cp poisonclr            ; Check to see if it was a poison mushroom.
                jr nz, centlChk         ; No - probably was something else...  Lets jump to the down label
                ld (ix+0),swKamikaze    ; Set the segment to kamikaze mode
                jr kamikaze             ; and jump back up to the kamikaze code to finish the move

centlChk        ld a,(ix+1)             ; Get the X coordinate into the 'a' register
                and 224                 ; See if X is in the range 0-31 (the 'and' operator will mask and see if
                                        ; any values in 128-32 exist (ie > 31) using 11100000)
                ret z                   ; If all good, we're done and can exit...
                jr centdown             ; Otherwise jump to the down calculation (ie. the centipede can't move horiz.)

centright       ld a,(ix+1)             ; Get the X coordinate into the 'a' register
                inc a                   ; Move it right one
                ld (ix+1),a             ; Update the X coordinate
                
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc

                call getattr            ; We now need to check and see if this new location is a mushroom
                cp mushclr              ; The result was returned in the a register.  See if it was a mushroom
                jr z, centdown          ; and if true, jump to the down label
                call getattr
                cp poisonclr            ; Check to see if it was a poison mushroom.
                jr nz, centrChk         ; No - probably was something else... Lets just check X is ok
                ld (ix+0),swKamikaze            ; Set the segment to kamikaze mode
                jp kamikaze             ; and jump back up to the kamikaze code to finish the move

centrChk        ld a,(ix+1)             ; Get the X coordinate into the 'a' register
                and 224                 ; See if X is in the range 0-31 (the 'and' operator will mask and see if
                                        ; any values in 128-32 exist (ie > 31) using 11100000)
                ret z                   ; If all good, we're done and can exit...
                
centdown        ld a,(tempX)            ; Get the previous X location and set the segment X to this value.
                ld (ix+1),a             
                
                ld a,(ix+3)             ; Load the X move direction as collision means switching its direction
                cp movRight             ; Is it going right (ie. = 1)
                jr z, centswL           ; if true, jump to switch to left
                
                ld (ix+3),movRight      ; else obviously it was likely going left - switch to go right
                jr centgodown
                
centswL         ld (ix+3),0             ; Left movement is any value that is *not* 1. Here I used 0

centgodown      ld a,(ix+2)             ; Load the Y value into the 'a' register
                inc a                   ; move it down by 1
                ld (ix+2),a             ; Update the Y value
                cp screenH              ; is Y outside the bottom of the screen?
                jr nz, centokdown       ; no, we're all good to try and move down
                xor a                   ; otherwise lets use a bitwise xor to make a = 0 and set it
                                        ; back to the top of the screen again.
                ld (ix+2),a             
                ret                     ; and we're done
                
centokdown      ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                
                call getattr            ; But first test to make sure that we can move down
                cp mushclr              ; Check to see if its a mushroom...
                jr z, centnodown        ; If it is, we should reset the Y location
                call getattr
                cp poisonclr            ; Check to see if it was a poison mushroom.
                ret nz                  ; No - we're done...  Exit

                ld (ix+0),swKamikaze    ; Set the segment to kamikaze mode
                jp kamikaze             ; and jump back up to the kamikaze code to finish the move
                
centnodown      ld a,(tempY)            ; Otherwise lets reset the Y location (essentially don't
                                        ; move down cause we can't)
                ld (ix+2),a             ; update the Y location...
                ret                     ; and we're done...

; -------------------------------------------------------------------------------------------------------
; MOVECENTIPEDE : This routine clears, moves and redraws the centipede.  Relies on the centsegment
; routine to move and update each segments positions.
; -------------------------------------------------------------------------------------------------------

movecentipede   ld de,centipede         ; set up the pointer to the centipede data
                push de                 ; store this in the stack so we can retrieve it
                ld ixh,d
                ld ixl,e
clearloop       ld a,(ix+0)             ; test to see if we've reached the end of the data
                cp 128
                jr z, updateSegment     ; go down to move the segments
        
                cp swOff        ; Is the segment deactive?
                jr z,nxtSegmentC    ; Yup, we can skip over this segment            
                
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                
                push ix                 ; Store the IX (pointing to centipede)
                call eraseChar          ; Clear the segment
                pop ix                  ; Restore IX
nxtSegmentC     inc ix                  ; go to the next segment
                inc ix
                inc ix
                inc ix
                jr clearloop
updateSegment   pop de                  ; Retrieve the address back into de
                push de                 ; and repush de to store it again
                ld ixh,d
                ld ixl,e
moveloop        ld a,(ix+0)             ; test to see if we've reached the end of the data
                cp 128
                jr z, drawcentipede     ; go down to move the segments

                cp swOff                ; Is the segment deactive?
                jr z,nxtSegmentM        ; Yup, we can skip over this segment            

                call centsegment        ; Move the segments
nxtSegmentM     inc ix                  ; go to the next segment
                inc ix
                inc ix
                inc ix
                jr moveloop
drawcentipede   pop de                  ; Retrieve the address back into de
                ld ixh,d
                ld ixl,e
drawloop        ld a,(ix+0)             ; test to see if we've reached the end of the data
                cp 128
                ret z                   ; We're all done!  We can exit

                cp swOff                ; Is the segment deactive?
                jr z,nxtSegmentD        ; Yup, we can skip over this segment            
 

                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                
                push ix                 ; push ix to store it
                
                ld a,(ix+0)             ; Determine which way we're facing and set appropriate gfx
                cp swKamikaze           ; is it down?
                jr nz, centHGfx         ; No, jump down to work out if left or right
                ld ix,gfxcentD          ; else lets set the ix and jump to draw and continue
                jr drawSegment
                
centHGfx        ld a,(ix+3)             ; Read the direction
                cp movRight             ; is it moving right?
                jr nz, centLGfx         ; Nope, its left...
                
                ld ix,gfxcentR          ; Set the graphics to right
                jr drawSegment          ; draw segment continue
                
centLGfx        ld ix,gfxcentL          ; Set the graphics to left
                
drawSegment     call drawChar           ; draw the segments

                pop ix                  ; Restore the ix back to the centipede data
nxtSegmentD     inc ix                  ; go to the next segment
                inc ix
                inc ix
                inc ix
                jr drawloop


; -------------------------------------------------------------------------------------------------------
; KILLCENTIPEDE : Checks the centipede segments against the charPos values.  Once found, disable the 
; segment
; -------------------------------------------------------------------------------------------------------

killcentipede   ld ix,centipede         ; set up the pointer to the centipede data
killloop        ld a,(ix+0)             ; test to see if we've reached the end of the data
                cp 128
                ret z                   ; If yes, exit

                ld e,(ix+2)             ; Get the X/Y values into de
                ld d,(ix+1)
                ld bc,(charPos)         ; Get the X/Y position
                
                ld a,e                  ; Get the Y
                cp b                    ; Compare it with the charPos Y
                jr nz, nextSeg          ; Nope, just check the next segment
                
                ld a,d                  ; Get the X
                cp c                    ; Compare it with charPos X
                jr nz, nextSeg          ; Nope, just check the next segment
                
                ; Otherwise - its a MATCH!
                ld (ix+0),swOff         ; Deactivate the segment
                ret                     ; and exit
                
nextSeg         inc ix                  ; go to the next segment
                inc ix
                inc ix
                inc ix
                jr killloop
                
; -------------------------------------------------------------------------------------------------------
;                                    T  H  E    P  L  A  Y  E  R
; -------------------------------------------------------------------------------------------------------
; -------------------------------------------------------------------------------------------------
; MOVEPLAYER : Calculate and move the player ship.
; -------------------------------------------------------------------------------------------------
; Note that as this is a single entity, all processing is done in the one function.

moveplayer      ; BULLET : Erase the bullet if active
                ld ix,bullet            ; Set to bulletData quickly
                ld a,(ix+0)             ; Is the bullet actually active?
                cp swOff
                jr z, goplayer          ; Yup, well, just skip over and do the player
                
                ; Otherwise, clear the bullet from the screen
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                call eraseChar          ; Clear the bullet

goplayer        ld ix,player            ; Lets point IX at the player data
                
                ; Firstly, lets backup the X and Y location
                ld a,(ix+1)             ; Read the segment's X location into the 'a' register
                ld (tempX),a            ; Store the X location temporarily into a memory location
                ld a,(ix+2)             ; Read the segment's Y location
                ld (tempY),a            ; Store the Y location temporarily
                
                ; Otherwise, clear the player from the screen first
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                push ix                 ; back up ix (erasechar will change it)
                call eraseChar          ; Clear the player
                pop ix                  ; restore ix

                ; Read the keys.  The key details will be returned in d (bits 7-3)
                call readKeys
                
                ; Now move and update the players position
pressedup       bit 7,d                 ; Was up pressed?
                jr z, presseddn         ; No, lets go test down
                
                ld a,(ix+2)             ; Get Y
                dec a                   ; Move up
                ld (ix+2),a             ; Update the Y value
                
                ; Did we hit a mushroom?  We can't move through these
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                
                push ix
                call getattr            ; But first test to make sure that we can move down
                pop ix
                cp mushclr              ; Check to see if its a mushroom...
                jr z, stopYu            ; Yup, lets reset the Y value
                
                ; Did we hit a poison mushroom?
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                
                push ix
                call getattr            ; But first test to make sure that we can move down
                pop ix
                cp poisonclr
                jr nz, okcheckup        ; Nope, we can skip over
                
stopYu          ld a,(tempY)            ; If we hit mushroom, lets reset the position
                ld (ix+2),a
okcheckup       ld a,(ix+2)
                cp playerMin            ; Is the Y at the top max for the player
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
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                
                push ix
                call getattr            ; But first test to make sure that we can move down
                pop ix
                cp mushclr              ; Check to see if its a mushroom...
                jr z, stopYd            ; Yup, lets reset the Y value
                
                ; Did we hit a poison mushroom?
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                
                push ix
                call getattr            ; But first test to make sure that we can move down
                pop ix
                cp poisonclr
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
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                
                push ix
                call getattr            ; But first test to make sure that we can move down
                pop ix
                cp mushclr              ; Check to see if its a mushroom...
                jr z, stopXl            ; Yup, lets reset the X value
                
                ; Did we hit a poison mushroom?
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                
                push ix
                call getattr            ; But first test to make sure that we can move down
                pop ix
                cp poisonclr
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
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                
                push ix
                call getattr            ; But first test to make sure that we can move down
                pop ix
                cp mushclr              ; Check to see if its a mushroom...
                jr z, stopXr            ; Yup, lets reset the X value
                
                ; Did we hit a poison mushroom?
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                
                push ix
                call getattr            ; But first test to make sure that we can move down
                pop ix
                cp poisonclr
                jr nz, okcheckrt        ; Nope, we can skip over
                
stopXr          ld a,(tempX)            ; If we hit mushroom, lets reset the position
                ld (ix+1),a
                
okcheckrt       ld a,(ix+1)
                cp screenW              ; Is the X at the edge of the screen
                jr nz, pressedfire      ; No, we're all good - jump to fire press check
                
                ld a,(tempX)            ; Otherwise just reset the X value
                ld (ix+1),a
                
pressedfire     ld ix,bullet            ; First, point ix to the bulletdata
                call readKeys           ; Call the readKeys fucntion (checkscn screws d register)
                bit 3,d
                jr z, movebullet        ; Nope, just skip over and check if we can move the bullet.
                
                ; Check bullet status
                ld a,(ix+0)             ; Check if bullet is active already
                cp swOff
                jr nz, movebullet       ; if yes, just go move it
                
                ; Set up a new bullet
                ld (ix+0),swOn          ; Activate the bullet
                ld hl,player            ; Get the players details and set bullet
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
                
                ld (ix+0),swOff         ; Disable bullet (out of top of screen)
                
                ; DRAW PLAYER SHIP
notfired        ld ix,player
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                ld ix,gfxplayer        ; Set IX to the graphic
                call drawChar          ; draw ship
                
                ; DRAW BULLET - finish up with checking for bullet hits, either drawing the bullet or
                ; drawing an explosion/fx instead and deactivating the bullet.
                ld ix,bullet            ; Set to bulletData quickly
                ld a,(ix+0)             ; Is the bullet actually active?
                cp swOff
                ret z                   ; Nope - safe to exit
                
                ; Did we hit a mushroom?  If so, we just need to destroy it
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                push ix
                call getattr            ; grab the screen colour
                pop ix
                cp mushclr              ; Was it a mushroom?
                jr z, goBoomM           ; Yup, go boomM (mushroom gets erased)
                
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                push ix
                call getattr            ; grab the screen colour
                pop ix
                cp poisonclr            ; Was it a poison mushroom?
                jr z, goBoomP           ; Yup, go boomP (poison gets hit, changes to mushroom colour)
                
                ; Did we hit the centipede?  If so, little more complex - disable centipede
                ; segment, replacing it with a mushroom.
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                push ix
                call getattr            ; grab the screen colour
                pop ix
                cp centclr              ; Was it the centipede
                jr nz, drawBullet       ; Nope, just redraw the bullet
                
                ; Detect which segment was hit and disable it
                push ix
                call killcentipede      ; Routine takes care of this
                pop ix
                
                ; Replace location with mushroom and add ten to the score
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                push ix
                ld ix,gfxmushroom       ; Draw a mushroom
                call drawchar
                call incScoreT          ; Add 10 to the score
                pop ix
                jr endBullet            ; We're done... Disable bullet and exit
                
                ; Draw the bullet to screen
drawBullet      ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                ld ix,gfxbullet         ; Set IX to the bullet graphic
                call drawChar           ; And draw the bullet
                ret
                
                ; Draw a boom FX and then kill the bullet.
                ; At this stage, we're gonna just erase the mushroom/etc.  Poison mushrooms
                ; will simply swap to normal attributes when hit.  They take 2 shots.
goBoomM         ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                push ix
                call eraseChar          ; Clear the mushroom - we can replace this at a later
                                        ; time with an 'explosion' effect of some kind.
                call incScore
                pop ix
                jr endBullet
                
goBoomP         ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                ld a,mushclr            ; Store update attribute into location tempA (used by setattr)
                ld (tempA),a
                call setAttr            ; Turn poison into normal mushroom (recoloured)
                ; No score for hitting a poison mushroom (since it doesn't die)
                
endBullet       ld (ix+0),swOff         ; Deactivate the bullet
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
;
; There is a redefine keys routine later down in the code that can be used

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


; -------------------------------------------------------------------------------------------------------
;                                       T  H  E    F  L  E  A
; -------------------------------------------------------------------------------------------------------
; -------------------------------------------------------------------------------------------------
; DROPFLEA : Move the flea down, leave either a mushroom or eat (wipe) any mushroom in the way
; -------------------------------------------------------------------------------------------------
; Note that this is a single entity. We erase, more and draw the flea in the one routine
dropflea        ld ix,flea              ; Lets point IX at the flea data
                ld a,(ix+0)             ; First check if the flea is actually active
                cp swOff
                ret z                   ; Nope, we can just exit
                    
                ; Check on our 'pseudo-random' mushroom drop
                ld hl,(fleadrop)        ; Get location
                ld a,(hl)               ; Grab the value of the random drop
                cp 128                  ; Are we at the end of the data yet?
                jr nz, selectDrop       ; No, then lets determine if we drop a mushroom
                        
                ld hl,randdrop          ; Reset the loop
                ld (fleadrop),hl
                ld a,(hl)               ; and grab the first value again

selectDrop      cp swOff
                jr z, eatBG             ; If it was 0, we wipe the BG (erase the flea)
                
                ; Else we're drawing a mushroom here
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                push ix
                push hl
                ld ix,gfxmushroom
                call drawChar          ; Draw the mushroom
                pop hl
                pop ix
                jr goflea

                ; Erase the flea - leaves empty space (ie. 'eats' mushrooms)
eatBG           ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                push ix
                push hl

                call eraseChar          ; Clear the background/mushroom
                pop hl
                pop ix

goflea          ; Move our 'pseudo random' table pointer
                inc hl
                ld(fleadrop),hl
                
                ; move flea
                ld a,(ix+2)             ; Select Y
                inc a                   ; Move it down
                ld (ix+2),a
                cp 24                   ; Is it at the bottom?
                jr nz, drawFlea         ; Nope, we're safe to draw the flea
                        
                ld (ix+0),0             ; disable the flea
                ld (ix+2),screenT       ; Reset the Y to the top of the screen
                ret                     ; and exit
                
drawFlea        ; Draw flea
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
                ld ix,gfxflea
                call drawChar          ; Draw the flea graphic
                ret

; -------------------------------------------------------------------------------------------------
; THEFLEA : this controls the tick counter, as well as setting up the flea and activating it
; -------------------------------------------------------------------------------------------------
theflea         ld ix,flea
                ld a,(ix+0)             ; Check to see if the flea is currently active.
                cp 0                    
                jr z, fleatickUpd       ; If not, we'll loop through the tick counter code
                call dropflea           ; Call the code to drop the flea
                ret
            
fleatickUpd     ld de,fleatick
                ld a,(de)               ; Get the tick counter
                inc a                   ; and increment it
                ld (de),a               ; update the tick counter
                ld hl,fleatmax
                cp (hl)                 ; Check to see if we need to add a flea
                jr z, addFlea
                ret                     ; Otherwise exit
                
addFlea         ; Lets add a flea
                ld ix,player
                ld a,(ix+1)             ; Get the player X
                
                ; Set the flea info
                ld ix,flea
                ld (ix+0),255           ; Activate flea
                ld (ix+1),a             ; Set the flea above the player location
                ld (ix+2),screenT       ; Set to top of screen
                
                ; Reset the counter
                xor a
                ld (de),a
                ret

; -------------------------------------------------------------------------------------------------------
;                                T  H  E    S  C  O  R  P  I  O  N
; -------------------------------------------------------------------------------------------------------

; -------------------------------------------------------------------------------------------------------
; GRAPHICS ROUTINES
; Routines and data for 8x8 character sized graphics.
; -------------------------------------------------------------------------------------------------------
; -------------------------------------------------------------------------------------------------------
; CALCULATE SCREEN ADDRESS
; -------------------------------------------------------------------------------------------------------
calcScreen  ld bc,(charPos)
            ld a,b          ; Get the Y value into the a register
            and 24          ; Mask the top two bits of the Y (y4,y3)
            or 64           ; and then set bit 6 (which is the base value for 16384)
            ld h,a          ; Store this as our high byte into h
            
            ld a,b          ; Get the Y value again from b
            rrca            ; Shift the bottom three bits into the top 3
            rrca            ; RRCA will rotate all the bits 1 to the right
            rrca
            and 224         ; Clear the bottom 5 bits first
            or c            ; and then insert the X
            ld l,a          ; Store this as our low byte
            ret             ; When we return, HL = screen address

; -------------------------------------------------------------------------------------------------------
; CALCULATE ATTRIBUTE ADDRESS
; -------------------------------------------------------------------------------------------------------
calcAttrib  ld bc,(charPos)
            ld l,b          ; Load the Y into the l register
            xor a           ; Zero out a register (xor quickest way to set the value to 0)
            ld b,a          ; Zero out b.  This will leave bc = X
            ld h,a          ; Zero out h.  This leaves hl = Y
            
            add hl,hl       ; Adding hl to itself 5 times performs a multiplication by 32 (its a binary
            add hl,hl       ; thing.)
            add hl,hl
            add hl,hl
            add hl,hl
            
            ld de,22528     ; Load the Attribute memory address into de
            add hl,de       ; Add the address to hl (the 32 * Y).
            add hl,bc       ; then add bc (the X)
            ret             ; When we return, HL = attribute address

; -------------------------------------------------------------------------------------------------------
; DRAW A CHARACTER
; Make sure that ix = Graphics data address, Y and X are stored in two bytes at address 'charPos' first
; (To erase a graphic, use ix = gfxblank - however 'eraseChar' routine does this for you)
; -------------------------------------------------------------------------------------------------------
drawChar    call calcScreen ; Get the screen address into hl
            
            ld b,8          ; Loop to read the 8 bytes of the character graphic
drawbyte    ld a,(ix+0)     ; Grab the pixel data (ix should have the gfx... address)
            ld (hl),a       ; Poke byte to screen
            inc h           ; We can simply inc the high byte for each pixel line (bits 0-3 = line value)
            inc ix          ; Jump to next graphic byte
            djnz drawbyte   ; decrement b and repeat loop

            call calcAttrib ; Get the attribute address into hl
            ld a,(ix+0)     ; Read the colour attribute
            ld (hl),a       ; and poke it onto the screen
            ret             ; We're done!

; SHORTCUT ROUTINE TO ERASE A CHARACTER
eraseChar   ld ix,gfxblank
            call drawChar
            ret

; -------------------------------------------------------------------------------------------------------
; READ SCREEN ATTRIBUTE
; Store the Y and X at the address 'charPos'.  The routine returns the attribute value in a.
; This routine is used primarily for collision detection.
; -------------------------------------------------------------------------------------------------------
getattr     call calcAttrib         ; Get the memory address into hl
            ld a,(hl)               ; grab the attribute value
            ret                     ; and return

; -------------------------------------------------------------------------------------------------------
; SET SCREEN ATTRIBUTE
; Store the Y and X at the address 'charPos'. Place the attribute value in address 'tempA'
; -------------------------------------------------------------------------------------------------------
setattr     call calcAttrib         ; Get the memory address into hl
            ld de,tempA
            ld a,(de)               ; grab the attribute value
            ld (hl),a
            ret                     ; and return

; -------------------------------------------------------------------------------------------------------
; CLEAR SCREEN
; Wipes the screen, note that using a routine for CLS and not the ROM version means could replace this
; simple blanking routine with other 'effect' style screen clears
; -------------------------------------------------------------------------------------------------------
cls         ld hl, 16384            ; Set HL to graphics location
            ld de, 16385            ; Set DE to next byte
            ld bc, 6143             ; Set BC to the length of the screen memory
            ld (hl),0               ; Set the first byte to 0 (blank)
            ldir                    ; Loop - LDIR ld (HL),(DE), incs both, and loops BC times
            
            ld hl, 22528            ; Same process for the Attributes
            ld de, 22529
            ld bc, 767
            ld (hl),7               ; Set to 7 (white ink, black paper)
            ldir
            ret                     ; and we're finished


; -------------------------------------------------------------------------------------------------------
; VARIOUS GAME ROUTINES
; -------------------------------------------------------------------------------------------------------

; -------------------------------------------------------------------------------------------------------
; PRINT SCORE
; Grabs the text data at txtScore, the values at scoreChar and prints the score
; -------------------------------------------------------------------------------------------------------
printScore  ld a,2
            call 5633               ; Set the print to go to the screen first (channel 2 (a))
                                    ; Note that 1 = lower screen (input area) and 3 = ZX Printer
            
            ; Start by setting ASCII chars into the string
            ld de,scoreChar
            ld hl,txtScString
            ld b,6
setChar     ld a,(de)               ; Get the counter
            add a,48                ; Character = ascii 48+counter
            ld (hl),a               ; Update it
            inc hl
            inc de
            djnz setChar            ; And repeat the process for all 6 digits
            
printChar   ld de,txtScore          ; Point to the string data
            ld bc,13                ; 13 characters long (AT Y,X; INK 7; PAPER 0; "000000")
            call 8252
            ret
            
; -------------------------------------------------------------------------------------------------------
; PRINT "GAME OVER"
; Prints text data at txtGameOver
; -------------------------------------------------------------------------------------------------------
printGO     ld a,2
            call 5633               ; Set the print to go to the screen first (channel 2 (a))
                                    ; Note that 1 = lower screen (input area) and 3 = ZX Printer
            ld de,txtGameOver       ; Point to the string data
            ld bc,16                ; 16 characters long (AT Y,X; INK 6; PAPER 2; "GAME OVER")
            call 8252
            ret
            
; -------------------------------------------------------------------------------------------------------
; INCREASE SCORE
; Increases the 6 digit score stored under scoreChar.  A collection of short routines added for adding
; 1 (incScore),10 (incScoreT),100 (incScoreH) to the score.
; -------------------------------------------------------------------------------------------------------
; Add 100 to score
incScoreH   ld ix,scoreChar
            jr incHunds
            
; Add 10 to score
incScoreT   ld ix,scoreChar
            jr incTens
            
; Add 1 to score
incScore    ld ix,scoreChar         ; Point IX to the score counters
incOnes     ld a,(ix+5)             ; ONES - increase this value
            inc a
            cp 10                   ; Is it 10?
            jr z, rolloverTen       ; Then we need to increase the 10's counter
            ld (ix+5),a             ; Otherwise save it
            ret                     ; and we're done
            
rolloverTen xor a
            ld (ix+5),a             ; Reset the ones counter
            
incTens     ld a,(ix+4)             ; TENS - increase this value
            inc a
            cp 10                   ; Is it 10?
            jr z, rolloverHnd       ; Then we need to increase the 100's counter
            ld (ix+4),a             ; Otherwise save it
            ret                     ; and we're done

rolloverHnd xor a
            ld (ix+4),a             ; Reset the 10 counter
            
incHunds    ld a,(ix+3)             ; HUNDREDS - increase this value
            inc a
            cp 10                   ; Is it 10?
            jr z, rolloverTho       ; Then we need to increase the 1000's counter
            ld (ix+3),a             ; Otherwise save it
            ret                     ; and we're done

rolloverTho xor a
            ld (ix+3),a             ; Reset the 1000 counter
            
incThous    ld a,(ix+2)             ; Thousands - increase this value
            inc a
            cp 10                   ; Is it 10?
            jr z, rolloverTth       ; Then we need to increase the 10000's counter
            ld (ix+2),a             ; Otherwise save it
            ret                     ; and we're done

rolloverTth xor a
            ld (ix+2),a             ; Reset the 1000 counter
            
incTenthou  ld a,(ix+1)             ; 10 Thousands - increase this value
            inc a
            cp 10                   ; Is it 10?
            jr z, rolloverHth       ; Then we need to increase the 100000's counter
            ld (ix+1),a             ; Otherwise save it
            ret                     ; and we're done

rolloverHth xor a
            ld (ix+1),a             ; Reset the 10000 counter
            
incHundthou ld a,(ix+0)             ; 100 Thousands - increase this value
            inc a
            cp 10                   ; Is it 10?
            jr z, resetScore        ; Then we roll over - we've clocked the score!
            ld (ix+0),a             ; Otherwise save it
            ret                     ; and we're done
            
resetScore  ld hl,scoreChar         ; Reset the score...  Set hl to our scoreChar counters
            ld b,6                  ; There are 6 counters
resValue    xor a
            ld (hl),a               ; Zero out the counter
            inc hl
            djnz resValue           ; And loop
            ret
 
; -------------------------------------------------------------------------------------------------------           
; REDEFINE KEYS
; Handy routine to redefine keys for the game.
; -------------------------------------------------------------------------------------------------------
redefKeys   call cls                ; Clear the screen
            ld hl,txtRedefKeys      ; Print the message "redefine keys" to begin
            call printStr           ; (uses our printing routine for a string (255 termination byte))
            call shortBlip          ; Quick beep
            ld ix,keysTable         ; load ix to point to our keys table
            ld hl,txtRedefUP        ; load hl to point to our messages (ie. what key to define)
            ld b,5                  ; There are 5 keys (U,D,L,R,F)
redfLoop    push bc                 ; Quickly push these two registers (they get altered by other code)
            push ix
            call printStr           ; Print out key message
            inc hl                  ; and inc hl to the next key message
waitForKey  ld de,chanTable         ; point de to a channel table used by the keyboard input
            ld b,8                  ; There are 8 channels (in the chanTable) to check
scanKeys    ld a,(de)               ; Read the channel entry from chanTable
            in a,(254)              ; Read the port to see if anything pressed
            cpl                     ; Invert the value returned in a
            and 31                  ; mask the bottom 5 bytes to see if a key was pressed
            cp 0                    ; Was a key pressed? (ie. the value won't be 0)
            jr nz, okRedef          ; Yup, lets redefine that key
            inc de
            djnz scanKeys           ; If not, lets keep scanning the next channel
            jr waitForKey           ; Once done, we just go back and scan again
okRedef     push af                 ; Yup - a key was pressed.  Lets push all our registers to back them up
            push de
            push hl
            call shortBlip          ; Make a short sound.  This gives the user time to release a key
            pop hl                  ; Restore our registers
            pop de
            pop af
            pop ix                  ; And don't forget our first push that we did for the key loop
            pop bc
            ld (ix+1),a             ; Store the bit value for key
            ld a,(de)               ; Get the channel it was read from
            ld (ix+0),a               ; Store this value
            inc ix                  ; and move to next key entry
            inc ix
            inc ix
            djnz redfLoop           ; And go back to loop through the keys
            ret                     ; Once done all 5, exit
            

; This routine prints text data to the screen, byte by byte.  Means we can just print any length without
; calculating bytes, etc.  Text data just has to terminate with a 255 byte value
printStr    push hl                 ; When calling, pass hl = address of text data
            ld a,2
            call 5633               ; Set print area to upper screen
            pop hl                  ; Restore hl pointer
strLoop     ld a,(hl)               ; Loop through each byte
            cp 255                  ; Have we reached the end of the data yet?
            ret Z                   ; Yup, we can exit this routine
            push hl                 ; Otherwise lets quickly push hl
            rst 16                  ; send the print code (in a) to the screen
            pop hl
            inc hl                  ; Go to next byte
            jr strLoop              ; and repeat until done
            
; Simple beep tone used when keys are redefined.  Add's a pause to the code so that it doesn't jump
; quickly to next key (and annoy heavy fingered gamers)
shortBlip   ld hl,1000              ; Load tone into hl
            ld de,60                ; Load length into de
            call 949                ; Call rom routine to 'beep'
            ret
; -------------------------------------------------------------------------------------------------------           
; DATA / INFORMATION
; -------------------------------------------------------------------------------------------------------           

; -------------------------------------------------------------------------------------------------------           
; GRAPHICS DATA
; Individual graphics appear below.  There are 9 bytes per character.  8 pixel lines, one attribute.
; Note that the collision/detection of graphics is done via its colour attribute.  All graphics move
; in character blocks and its much easier to check an attribute then an 8 byte bitmap
; The is the Attribute colour for a poison mushroom. All attribs have a black paper (BG)
;
; Note that graphics are included for the up/down directions for the centipede for future additions
; otherwise this game mainly just makes use of the left and right and down (kamikaze). Up... Maybe.
; -------------------------------------------------------------------------------------------------------           
gfxblank          defb    0,0,0,0,0,0,0,0,bgclr
gfxmushroom       defb    60,106,213,255,36,36,24,0
attmushroom       defb    4
gfxflea           defb    56,126,255,252,42,80,0,0
attflea           defb    6
gfxplayer         defb    24,24,60,126,126,90,60,0
attplayer         defb    71
gfxbullet         defb    16,8,16,8,16,8,16,8
attbullet         defb    7
gfxcentU          defb    0,60,126,90,126,126,153,0
attcentU          defb    2
gfxspider         defb    0,90,189,60,90,165,129,0
attspider         defb    5
gfxscorpionR      defb    0,134,105,162,30,188,96,128
attscorpionR      defb    67
gfxcentL          defb    2,60,108,126,126,108,60,2
attcentL          defb    2
gfxcentD          defb    0,153,126,126,90,126,60,0
attcentD          defb    2
gfxcentR          defb    64,60,54,126,126,54,60,64
attcentR          defb    2
gfxscorpionL      defb    0,97,150,69,120,61,6,1
attscorpionL      defb    67
attPoison         defb    poisonclr

; -------------------------------------------------------------------------------------------------------           
; GAME DATA
; Variables, values and settings for all items within the game.
; -------------------------------------------------------------------------------------------------------           
; -------------------------------------------------------------------------------------------------------
; PLAYER
; -------------------------------------------------------------------------------------------------------           
player          defb    3,16,20                     ; Player (lives, x, y)
bullet          defb    0,16,19                     ; Bulley (active, x, y) 

; Table for keys (port value, bit test, recordBit (to store keypress if true))
; Redefine key function should update these values (if we add one)
keysTable       defb    251,1,128       ; Q key
                defb    253,1,64        ; A key
                defb    223,2,32        ; O key
                defb    223,1,16        ; P key
                defb    127,4,8         ; M Key

; Define a list of all the ports used to read the keyboard - used in redefine keys routines
chanTable       defb    254,253,251,247,239,223,191,127


; -------------------------------------------------------------------------------------------------------
; CENTIPEDE
; Each segment of a centipede contains an active flag (0 dead,128 on,64 kamikaze),x,y and delta x (+/-)
; 128 terminates the list.  This enables the ability to inc or dec the length of the centipede.
; centipedespeed is a tick counter for motion speed - ie. every x ticks, update the movement
; -------------------------------------------------------------------------------------------------------           
centipede       defb    255,10,0,1                  ; A segment (active, x, y, dx)
                defb    255,11,0,1
                defb    255,12,0,1
                defb    255,13,0,1
                defb    255,14,0,1
                defb    255,15,0,1
                defb    255,16,0,1
                defb    255,17,0,1
                defb    128                         ; 128 terminates centipede segment list
centipedespeed  defb    1                           ; Speed of the centipede

; -------------------------------------------------------------------------------------------------------
; SPIDER
; Spider (active, x, y, dx, dy. spiderbg stores the gfx... address so that it does not erase bg elements
; such as mushrooms. spidermove steps through data for a 'change direction' list used to give it more
; interesting movement. 128 terminates. spidertick used to decide when the spider will appear on screen 
; (spidertmax = how frequently). 
; spiderspeed is a tick counter for motion speed - ie. every x ticks, update the movement
; -------------------------------------------------------------------------------------------------------           
spider          defb    255,31,16,128,0
spiderbg        defb    0,0
spidertick      defb    0
spidertmax      defb    64
spiderspeed     defb    1
spidermove      defw    randmotion
randmotion      defb    1,1,0,1,255,255,255,0,1,0,1,1,1,0,0,0,0,255,255,1,1,1,1,255,0,0,1,1,1,0,0,0,0,0
                defb    1,1,1,255,255,255,255,0,1,0,255,255,1,0,1,0,1,0,255,0,255,0,255,0,1,255,255,1,1
                defb    128

; -------------------------------------------------------------------------------------------------------
; FLEA
; flea (active, x, y), fleatick controls when come on (like spider, alfs fleatmax). fleadrop points to
; data that contains a 'pseudo random' list of whether to drop a mushroom or not (128 terminates list)
; fleaspeed is a tick counter for motion speed - ie. every x ticks, update the movement
; -------------------------------------------------------------------------------------------------------           
flea            defb    0,10,0
fleatick        defb    0
fleatmax        defb    64
fleadrop        defw    randdrop
fleaspeed       defb    2
randdrop        defb    1,0,0,0,0,0,0,0,1,0,0,1,0,0,0,1,0,1,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,1,0,0,1,0,0,1
                defb    1,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,1,0,0,0,1,0,1,0,1,0,0
                defb    1,0,1,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,1,0,1,0,0,0
                defb    128

; -------------------------------------------------------------------------------------------------------
; SCORPION
; scorpion (active, x, y, dx). bg is used to determine whether use a mushroom or a blank.
; scorpionspeed is a tick counter for motion speed - ie. every x ticks, update the movement
; -------------------------------------------------------------------------------------------------------           
scorpion        defb    255,0,10,1
scorpionbg      defb    0,0
scorpiontick    defb    0
scorpiontmax    defb    64
scorpionspeed   defb    2

; -------------------------------------------------------------------------------------------------------           
; VARIOUS:
; Data here is used for various parts of the game.
; -------------------------------------------------------------------------------------------------------           
scoreChar       defb    0,0,0,0,0,0                 ; 6 digit score counters
charPos         defb    16,12                       ; Character position (used by drawChar/eraseChar)
tempX           defb    0                           ; Temporary X storage
tempY           defb    0                           ; Temporary Y storage
tempA           defb    0                           ; Temporary attribute used by setattr

; -------------------------------------------------------------------------------------------------------           
; TEXT DATA FOR PRINTING
; Text codes for printing simple text strings in game go here...
; -------------------------------------------------------------------------------------------------------           
; Print Score at top of screen (13 bytes)
txtScore        defb    22,0,13                     ; AT 0,13
                defb    16,7,17,0                   ; Ink 7, Paper 0
txtScString     defb    48,48,48,48,48,48           ; INSERT NUMBER CHAR CODES HERE (48 + val)

; Print Game over at center of screen (16 bytes)
txtGameOver     defb    22,0,0                      ; AT 10,10
                defb    16,6,17,2                   ; Ink 6, Paper 2
                defm    "GAME OVER"                 ; "GAME OVER"

; Title for 'redefine keys' screen (uses 255 to terminate.  See key redefine routine for more...)
txtRedefKeys    defb    22,0,13                     ; AT 0,13
                defb    16,7,17,2                   ; Ink 7, Paper 2
                defm    "DEFINE"                    ; "DEFINE"
                defb    22,1,14                     ; AT 1,14 (next line down)
                defm   "KEYS"                      ; "KEYS"
                defb    255                         

; Individual text per keypress when defining keys.  Note use of 255 to signal end of each line of text
; means we can redefine the keys using a continuous loop without individual need for knowing bytes
txtRedefUP      defb    22,3,14
                defb    16,7,17,0
                defm    "UP"
                defb    255
                
txtRedefDN      defb    22,5,14
                defb    16,7,17,0
                defm    "DOWN"
                defb    255
                
txtRedefLT      defb    22,7,14
                defb    16,7,17,0
                defm    "LEFT"
                defb    255
                
txtRedefRT      defb    22,9,14
                defb    16,7,17,0
                defm    "RIGHT"
                defb    255
                
txtRedefFR      defb    22,11,14
                defb    16,7,17,0
                defm    "FIRE"
                defb    255
                
