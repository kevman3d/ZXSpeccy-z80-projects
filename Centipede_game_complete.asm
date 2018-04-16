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
screenH         equ 24  ; Bottom of screen

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
                
                ld (ix+2),0             ; Otherwise lets reset the centipede back to the top
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

centlChk		ld a,(ix+1)             ; Get the X coordinate into the 'a' register
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
                
                ld c,(ix+1)             ; Poke the YX values first
                ld b,(ix+2)
                ld (charPos),bc
				
				push ix					; Store the IX (pointing to centipede)
                call eraseChar          ; Clear the segment
				pop ix					; Restore IX
                inc ix                  ; go to the next segment
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
                call centsegment        ; Move the segments
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
                inc ix                  ; go to the next segment
                inc ix
                inc ix
                inc ix
                jr drawloop

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
; (To erase a graphic, use ix = gfxblank - eraseChar routine does this for you)
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
; GAME DATA:
; Variables, values and settings for all items within the game.
; -------------------------------------------------------------------------------------------------------           
; -------------------------------------------------------------------------------------------------------
; PLAYER
; -------------------------------------------------------------------------------------------------------           
player          defb    3,16,20                     ; Player (lives, x, y)
bullet          defb    0,16,19                     ; Bulley (active, x, y) 

; -------------------------------------------------------------------------------------------------------
; CENTIPEDE
; Each segment of a centipede contains an active flag (0 dead,128 on,64 kamikaze),x,y and delta x (+/-)
; 128 terminates the list.  This enables the ability to inc or dec the length of the centipede.
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

; -------------------------------------------------------------------------------------------------------
; SPIDER
; Spider (active, x, y, dx, dy. spiderbg stores the gfx... address so that it does not erase bg elements
; such as mushrooms. spidermove steps through data for a 'change direction' list used to give it more
; interesting movement. 128 terminates. spidertick used to decide when the spider will appear on screen 
; (spidertmax = how frequently). 
; -------------------------------------------------------------------------------------------------------           
spider          defb    255,31,16,128,0
spiderbg        defb    0,0
spidertick      defb    0
spidertmax      defb    64
spidermove      defw    randmotion
randmotion      defb    1,1,0,1,255,255,255,0,1,0,1,1,1,0,0,0,0,255,255,1,1,1,1,255,0,0,1,1,1,0,0,0,0,0
                defb    1,1,1,255,255,255,255,0,1,0,255,255,1,0,1,0,1,0,255,0,255,0,255,0,1,255,255,1,1
                defb    128

; -------------------------------------------------------------------------------------------------------
; FLEA
; flea (active, x, y), fleatick controls when come on (like spider, alfs fleatmax). fleadrop points to
; data that contains a 'pseudo random' list of whether to drop a mushroom or not (128 terminates list)
; -------------------------------------------------------------------------------------------------------           
flea            defb    0,10,0
fleatick        defb    0
fleatmax        defb    64
fleadrop        defb    0,0
randdrop        defb    1,0,0,0,0,0,0,0,1,0,0,1,0,0,0,1,0,1,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,1,0,0,1,0,0,1
                defb    1,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,1,0,0,0,1,0,1,0,1,0,0
                defb    1,0,1,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,1,0,1,0,0,0
                defb    128

; -------------------------------------------------------------------------------------------------------
; SCORPION
; scorpion (active, x, y, dx). bg is used to determine whether use a mushroom or a blank.
; -------------------------------------------------------------------------------------------------------           
scorpion        defb    255,0,10,1
scorpionbg      defb    0,0
scorpiontick    defb    0
scorpiontmax    defb    64

; -------------------------------------------------------------------------------------------------------           
; VARIOUS:
; Data here is used for various parts of the game.
; -------------------------------------------------------------------------------------------------------           
scoreChar       defb    0,0,0,0,0                   ; 5 digit score counters
charPos         defb    16,12                       ; Character position (used by drawChar/eraseChar)
tempX           defb    0                           ; Temporary X storage
tempY           defb    0                           ; Temporary Y storage
