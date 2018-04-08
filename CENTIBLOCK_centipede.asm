; "CENTIBLOCK" - CENTIPEDE CLONE for ZX Spectrum.  Kevin Phillips, 1986-2018.
; Centipede control functions.  This file contains the routines used to move the centipede
; in the game.  This code is an update on the example code developed as a simple demo, but now
; has the addition of collision tests for downward mushrooms, as well as a downward motion to
; add the 'poison mushroom' kamikaze feature (Centipede hits a poison mushroom, centipede goes
; directly down to bottom of screen (invincible))

; Colour attribute constants
mushroom        equ 96          ; Bright green for mushrooms
centsegment     equ 80          ; Bright red for centipede
bgcolor         equ 7           ; Background colour to clear centipede from screen
poisonmushy     equ 95          ; Poison mushroom value  - Bright purple

; -------------------------------------------------------------------------------------------------
; CODE STARTS HERE
; -------------------------------------------------------------------------------------------------
                org 40000
; -------------------------------------------------------------------------------------------------
; MOVESEGMENT : Calculates the movement of a single centipede segment
; -------------------------------------------------------------------------------------------------
; Important : load address for a single segment's data into ix *before* calling this...

movesegment     ld a,(ix+0)             ; Check to make sure the segment is actually 'alive'
                cp 0                    ; Was it off?
                ret z                   ; If so, we can safely return and do nothing
                
                ; Firstly, lets backup the X and Y location
                ld a,(ix+1)             ; Read the segment's X location into the 'a' register
                ld (tempX),a            ; Store the X location temporarily into a memory location
                ld a,(ix+2)             ; Read the segment's Y location
                ld (tempY),a            ; Store the Y location temporarily

                ; Check if its in Kamikaze mode.  If so, we're just moving straight down.
                ld a,(ix+0)             ; Get the segment's active flag
                cp 64                   ; A setting of 64 means its in Kamikaze mode
                jr nz, horizontal       ; If its not, just skip over and do the usual movement
                
kamikaze        ld a,(ix+2)             ; Get the Y location
                inc a                   ; Move down
                ld (ix+2),a             ; Store this updated value back into Y
                cp 24                   ; Is it at 24 (the bottom of the screen)?
                ret nz                  ; Nope - so we can now exit - we've moved the segment...
                
                ld (ix+2),0             ; Otherwise lets reset the centipede back to the top
                ld (ix+0),255           ; Reset the active flag to normal
                ret                     ; and we're done.
                
horizontal      ld a,(ix+3)             ; read the X move direction
                cp 1                    ; check to see if was 1 (right).
                jr z,moveright          ; If true, skip down to moveright

moveleft        ld a,(ix+1)             ; Get the X coordinate
                dec a                   ; Move it left one
                ld (ix+1),a             ; update the X coordinate
                call checkseg           ; We now need to check and see if this new location is a mushroom
                cp mushroom             ; The result was returned in the 'a' register.  See if it was a mushroom
                jr z, down              ; and if true, jump to the down label
                call checkseg
                cp poisonmushy          ; Check to see if it was a poison mushroom.
                jr nz, leftChk          ; No - probably was something else...  Lets jump to the down label
                ld (ix+0),64            ; Set the segment to kamikaze mode
                jr kamikaze             ; and jump back up to the kamikaze code to finish the move

leftChk         ld a,(ix+1)             ; Get the X coordinate into the 'a' register
                and 224                 ; See if X is in the range 0-31 (the 'and' operator will mask and see if
                                        ; any values in 128-32 exist (ie > 31) using 11100000)
                ret z                   ; If all good, we're done and can exit...

                jr down                 ; and then jump to the down calculation (ie. the centipede can't move horiz.)

moveright       ld a,(ix+1)             ; Get the X coordinate into the 'a' register
                inc a                   ; Move it right one
                ld (ix+1),a             ; Update the X coordinate
                call checkseg           ; We now need to check and see if this new location is a mushroom
                cp mushroom             ; The result was returned in the a register.  See if it was a mushroom
                jr z, down              ; and if true, jump to the down label
                call checkseg
                cp poisonmushy          ; Check to see if it was a poison mushroom.
                jr nz, rightChk         ; No - probably was something else... Lets just check X is ok
                ld (ix+0),64            ; Set the segment to kamikaze mode
                jp kamikaze             ; and jump back up to the kamikaze code to finish the move

rightChk        ld a,(ix+1)             ; Get the X coordinate into the 'a' register
                and 224                 ; See if X is in the range 0-31 (the 'and' operator will mask and see if
                                        ; any values in 128-32 exist (ie > 31) using 11100000)
                ret z                   ; If all good, we're done and can exit...
                
down            ld a,(tempX)            ; Get the previous X location and set the segment X to this value.
                ld (ix+1),a             
                
                ld a,(ix+3)             ; Load the X move direction as collision means switching its direction
                cp 1                    ; Is it going right (ie. = 1)
                jr z, switchLeft        ; if true, jump to switch to left
                
                ld (ix+3),1             ; else obviously it was likely going left - switch to go right
                jr godown
                
switchLeft      ld (ix+3),0             ; Left movement is any value that is *not* 1. Here I used 0

godown          ld a,(ix+2)             ; Load the Y value into the 'a' register
                inc a                   ; move it down by 1
                ld (ix+2),a             ; Update the Y value
                cp 24                   ; is Y outside the bottom of the screen?
                jr nz, oktomovedown     ; no, we're all good to try and move down
                xor a                   ; otherwise lets use a bitwise xor to make a = 0 and set it
                                        ; back to the top of the screen again.
                ld (ix+2),a             
                ret                     ; and we're done
                
oktomovedown    ld a,(ix+2)
                call checkseg           ; But first test to make sure that we can move down
                cp mushroom             ; Check to see if its a mushroom...
                jr z, nopedown          ; If it is, we should reset the Y location
                call checkseg
                cp poisonmushy          ; Check to see if it was a poison mushroom.
                ret nz                  ; No - we're done...  Exit

                ld (ix+0),64            ; Set the segment to kamikaze mode
                jp kamikaze             ; and jump back up to the kamikaze code to finish the move
                
nopedown        ld a,(tempY)            ; Otherwise lets reset the Y location (essentially don't
                                        ; move down cause we can't)
                ld (ix+2),a             ; update the Y location...
                ret                     ; and we're done...

; -------------------------------------------------------------------------------------------------
; SCREEN FUNCTIONS
; Technically we should turn these into more of a function given that the other game characters
; will all do the same thing.  We can tidy up the complete code once we have the game working...
; -------------------------------------------------------------------------------------------------

; Check the screen location (ie. read the attribute at X,Y
checkseg        ld a,(ix+1)
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

; Draw the segment
drawseg         ld a,(ix+1)             ; grab the X location
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
                ld (hl),centsegment     ; Set the block with red
                ret

; Clears the segment by drawing a black attribute
clearseg        ld a,(ix+1)             ; grab the X location
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
; MAIN CODE FOLLOWS BELOW
; -------------------------------------------------------------------------------------------------

; MOVE CENTIPEDE (this is the main procedure we will be calling for our game)
; Clears the centipede from screen, moves it, redraws to screen
centipede       ld de,segData           ; set up the pointer to the centipede data
                push de                 ; store this in the stack so we can retrieve it
                ld ixh,d
                ld ixl,e
clearloop       ld a,(ix+0)             ; test to see if we've reached the end of the data
                cp 128
                jr z, movecentipede     ; If true, we can go down to move the segments
                call clearseg           ; Clear the segment
                inc ix                  ; go to the next segment
                inc ix
                inc ix
                inc ix
                jr clearloop
movecentipede   pop de                  ; Retrieve the address back into de
                push de                 ; and repush de to store it again
                ld ixh,d
                ld ixl,e
moveloop        ld a,(ix+0)             ; test to see if we've reached the end of the data
                cp 128
                jr z, drawcentipede     ; If true, we can go down to draw the segments
                call movesegment        ; Move the segments
                inc ix                  ; go to the next segment
                inc ix
                inc ix
                inc ix
                jr moveloop
drawcentipede   pop de                  ; Retrieve the address back into de
                ld ixh,d
                ld ixl,e
drawloop        ld a,(ix+0)             ; test to see if we've reached the end of the data
                cp 128
                ret z                   ; If true, we're all done!  We can exit back to wherever this was called from.
                call drawseg            ; draw the segments
                inc ix                  ; go to the next segment
                inc ix
                inc ix
                inc ix
                jr drawloop


; -------------------------------------------------------------------------------------------------
; DATA FOLLOWS BELOW
; -------------------------------------------------------------------------------------------------
; Segment data for centipede has Active flag (0-off, 64-kamikaze, 255-on), x, y and x direction
; 128 marks the end of the centipede data (8 segments for testing)
segData         defb    255,10,0,1
                defb    255,11,0,1
                defb    255,12,0,1
                defb    255,13,0,1
                defb    255,14,0,1
                defb    255,15,0,1
                defb    255,16,0,1
                defb    255,17,0,1
                defb    128
; Temp storage of X and Y location
tempX           defb    0
tempY           defb    0
