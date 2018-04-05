; CENTIPEDE Z80 FUNCTION - Kevin Phillips, 1986-2018.
; Centipede code - draws a moving 8-segment centipede travelling down the screen using simple
; colour blocks on the ZX spectrum.  Its not perfect (code needs to be tweaked when it moves
; down to prevent it eating the block below it), but it should make for a (hopefully) easy example
; of approaching this type of program.
;
; Originally hand-written in 1986, 2018 is the *first* time I ever sat and typed my code in...
; Amazingly, when I assembled it - it was a complete failure! lol! :D  This instead is the cleaned 
; up and works...  If you are curious about what exactly did a 16 year old write, I've scanned and
; put the whole plan for a centipede game here:
; https://drive.google.com/file/d/0B-yNJZpBnrutdUZCaUluMDhnMzQ/view?usp=sharing
;
; After assembled, this can be tested using a BASIC program.  When assembled, the centipede function is
; called at address 40168...  There is a snapshot (.sna) for those wanting to just run this... Ignore
; the messed up line numbering - was a quick hack... Well, that's MY excuse at least
;
;  10 REM Quick example.  Note that we should initiate the segment data
;  15 GOSUB 100
;  20 PAPER 0 : BORDER 0 : INK 7 : CLS
;  30 REM Create some 'mushrooms' (colour code 96)
;  40 FOR m=0 TO 64 : POKE 22528+(RND*768),96 : NEXT m
;  50 RANDOMISE USR 40168
;  60 REM I'm using the BEEP to control the speed of the game (0.01 of a second per loop)
;  70 BEEP 0.01, 0
;  80 GOTO 50
; 100 REM Initialise
; 105 LET seg=40246
; 106 LET x=8
; 110 REM Loop through data until last segment
; 115 IF PEEK seg=128 THEN GO TO 145
; 120 POKE seg,255 : LET seg=seg+1
; 125 POKE seg,x : LET seg=seg+1 : LET x=x+1
; 130 POKE seg,0 : LET seg=seg+1
; 135 POKE seg,1 : LET seg=seg+1
; 140 GO TO 115
; 145 RETURN
;

; Just define some colour attribute constants
mushroom        equ 96          ; Bright green for mushrooms
centsegment     equ 80          ; Bright red for centipede
blankcolor      equ 0           ; Background colour to clear centipede from screen

; -------------------------------------------------------------------------------------------------
; CODE STARTS HERE
; -------------------------------------------------------------------------------------------------
                org 40000

; -------------------------------------------------------------------------------------------------
; MOVESEGMENT : Calculates the movement of a single centipede segment
; -------------------------------------------------------------------------------------------------
; Important : load address for a single segment's data into ix *before* calling this...

movesegment     ld a,(ix+1)             ; Read the segment's X location into the 'a' register
                ld (tempX),a            ; Store the X location temporarily into a memory location

                ld a,(ix+3)             ; read the X move direction
                cp 1                    ; check to see if was 1 (right).
                jr z,moveright          ; If true, skip down to moveright

moveleft        ld a,(ix+1)             ; Get the X coordinate
                dec a                   ; Move it left one
                ld (ix+1),a             ; update the X coordinate
                call checkscreen        ; We now need to check and see if this new location is a mushroom
                cp mushroom             ; The result was returned in the 'a' register.  See if it was a mushroom
                jr z, down              ; and if true, jump to the down label

leftChk         ld a,(ix+1)             ; Get the X coordinate into the 'a' register
                and 224                 ; See if X is in the range 0-31 (the 'and' operator will mask and see if
                                        ; any values in 128-32 exist (ie > 31) using 11100000)
                ret z                   ; If all good, we're done and can exit...
                
                ld a,(tempX)            ; Otherwise get the previous X coordinate, set segment X back to that one
                ld (ix+1),a
                jr down                 ; and then jump to the down calculation (ie. the centipede can't move horiz.)

moveright       ld a,(ix+1)             ; Get the X coordinate into the 'a' register
                inc a                   ; Move it right one
                ld (ix+1),a             ; Update the X coordinate
                call checkscreen        ; We now need to check and see if this new location is a mushroom
                cp mushroom             ; The result was returned in the a register.  See if it was a mushroom
                jr z, down              ; and if true, jump to the down label

rightChk        ld a,(ix+1)             ; Get the X coordinate into the 'a' register
                and 224                 ; See if X is in the range 0-31 (the 'and' operator will mask and see if
                                        ; any values in 128-32 exist (ie > 31) using 11100000)
                ret z                   ; If all good, we're done and can exit...
                
                ld a,(tempX)            ; Otherwise get the previous X coordinate, set segment X back to that one
                ld (ix+1),a             ; We don't need to jump to down - its the next line of code anyway... :)

down            ld a,(tempX)            ; Get the previous X location and set the segment X to this value.
                ld (ix+1),a             
                
                ld a,(ix+3)             ; Load the X move direction as collision means switching its direction
                cp 1                    ; Is it going right (ie. = 1)
                jr z, switchLeft         ; if true, jump to switch to left
                
                ld (ix+3),1             ; else obviously it was likely going left - switch to go right
                jr godown
                
switchLeft      ld (ix+3),0             ; Left movement is any value that is *not* 1. Here I used 0

godown          ld a,(ix+2)             ; Load the Y value into the 'a' register
                inc a                   ; move it down by 1
                cp 24                   ; is Y outside the bottom of the screen?
                jr nz, oktomovedown     ; no, we're all good to move down
                xor a                   ; otherwise lets use a bitwise xor to make a = 0 and set it back to 
                                        ; the top of the screen again.

oktomovedown    ld (ix+2),a             ; Update the segment's Y value
                ret                     ; and we're done...

; -------------------------------------------------------------------------------------------------
; SCREEN FUNCTIONS
; Note that these are extrapolated out rather than optimised for code size and tidiness.  There are
; a couple of very 1980's reasons to consider whether simplifying duplicate code into one common
; function that is called instead of inline code is a good idea...
;
; (a) YES - if the game takes a lot of RAM, then yes - shorten the code to shave a few bytes off.
; (b) NO  - If the machine is slow, adding an extra call in each function adds a (very, very tiny)
;           amount of extra time (3 * the addition of 'call' to a procedure and its 'ret').
; -------------------------------------------------------------------------------------------------
; The checkscreen code is designed to return the attribute value of a specific location on screen.
checkscreen     ld c,a                  ; load the X value (stored in 'a') into the c register
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

; The drawScreen code is really just to display the segment as a red block.  Literally its the same
; as the code for check screen, except it sets the memory value, not read it.  Note the replication of all
; that screen address calculation code.
drawScreen      ld a,(ix+1)             ; grab the X location
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

; The clearScreen code is really just to display the segment as a black block.  Literally its the same
; as the code for drawscreen, except it sets a different color value.  Note the replication of all
; that screen address calculation code.
clearScreen     ld a,(ix+1)             ; grab the X location
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
                ld (hl),blankcolor      ; Set the block with red
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
                jr z, movecentipede     ; go down to move the segments
                call clearScreen        ; Clear the segment
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
                jr z, drawcentipede     ; go down to move the segments
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
                ret z                   ; We're all done!  We can exit
                call drawScreen         ; draw the segments
                inc ix                  ; go to the next segment
                inc ix
                inc ix
                inc ix
                jr drawloop


; -------------------------------------------------------------------------------------------------
; DATA FOLLOWS BELOW
; -------------------------------------------------------------------------------------------------
; Segment data for centipede has Active flag (0 - off, 255 - on), x, y and x direction
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
; Temp storage of X location
tempX           defb    0


