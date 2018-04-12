; "CENTIBLOCK" - CENTIPEDE CLONE for ZX Spectrum.  Kevin Phillips, 1986-2018.
; Spider control routines.  At timed intervals, a spider will appear.  This bounces
; across the screen however at top/bottom bounce it may decide to change direction of
; stop moving.  Note that the spider also does not delete BG colours (ie. mushrooms, etc)

; Colour attribute constants
bgcolor         equ 7           ; Generic BG colour
spider          equ 72          ; Spider block - Blue
; -------------------------------------------------------------------------------------------------
; CODE STARTS HERE (for testing)
; -------------------------------------------------------------------------------------------------
                org 40000
; -------------------------------------------------------------------------------------------------
; MOVESPIDER : Calculates the movement of the spider
; -------------------------------------------------------------------------------------------------
; Unlike the centipede, as a single entity the entire process of erase, move, draw is in one routine

movespider      ld ix,sdrData           ; Set IX to the spider data.
                ld a,(ix+0)             ; Check to make sure the spider is active
                cp 0                    ; Was it off?
                ret z                   ; If so, we can safely return and do nothing
                
                ; Start by blanking out the spider location
                call clearspider
                
                ; Move spider - Backup Y - just handy to have when moving down for quick reset
                ld a,(ix+2)             ; Read the spider's Y location
                ld (tempY),a            ; Store the Y location temporarily

                ; Read the movement X value
                ld a,(ix+3)             ; Read the x direction
                cp 1
                jr nz, spiderLN         ; If not right, jump to spiderLN (left/none) label
                
                ld a,(ix+1)             ; Otherwise get spider X
                inc a                   ; Move left
                ld (ix+1),a
                and 224                 ; See if X is in the range 0-31 (the 'and' operator will mask and see if
                                        ; any values in 128-32 exist (ie > 31) using 11100000)
                jr z,spiderBounce       ; If inside bounds, jump to spiderBounce (vertical movement)
                
                ld(ix+0),0              ; Otherwise deactivate the spider (left screen)
                ld (ix+1),0             ; Set the start to the left
                ld (ix+2),16            ; Start at Y 16
                ld (ix+3),1             ; X move right
                ld (ix+4),1             ; Y move down
                ld (ix+5),7             ; BG colour as black
                ld hl,spiderTick
                ld (hl),0               ; Reset counter
                ret                     ; and we can exit.

spiderLN        ld a,(ix+3)             ; Lets check to make sure that we're actually moving
                cp 0
                jr z, spiderBounce      ; if not moving, lets just go bounce
                
                ld a,(ix+1)             ; Otherwise get spider X
                dec a                   ; Move Left
                ld (ix+1),a
                and 224                 ; See if X is in the range 0-31 (the 'and' operator will mask and see if
                                        ; any values in 128-32 exist (ie > 31) using 11100000)
                jr z,spiderBounce       ; If inside bounds, jump to spiderBounce (vertical movement)
                
                ld(ix+0),0              ; Otherwise deactivate the spider (left screen)
                ld (ix+1),31            ; Set the start to the right
                ld (ix+2),16            ; Start at Y 16
                ld (ix+3),255           ; X move left
                ld (ix+4),1             ; Y move down
                ld (ix+5),7             ; BG colour as black
                ld hl,spiderTick
                ld (hl),0       ; Reset counter
                ret                     ; and we can exit.

spiderBounce    ld a,(ix+4)             ; Grab the Y direction
                cp 1                    ; Is it moving down?
                jr nz, spiderU          ; If no, its moving up
                
                ld a,(ix+2)             ; Grab the Y value
                inc a
                ld (ix+2),a             ; Increment and update
                cp 24                   ; Check if its outside the bottom of the screen.
                jr nz, spiderOK         ; No, then we're done and we can jump to the end (spiderOK)
                
                ld a,(tempY)            ; Get previous Y
                ld (ix+2),a             ; Reset Y with this value
                ld (ix+4),255           ; Set the Y move to up
                call chooseDirection    ; And see if we are going to randomly change direction X
                jr spiderOK             ; and then jump to the end (spiderOK) to draw and exit
                
spiderU         ld a,(ix+2)             ; Grab the Y value
                dec a
                ld (ix+2),a             ; decrement and update
                cp 16                   ; Check if its outside the top barrier of the screen.
                jr nz, spiderOK         ; No, then we're done and we can jump to the end (spiderOK)
                
                ld a,(tempY)            ; Get previous Y
                ld (ix+2),a             ; Reset Y with this value
                ld (ix+4),1             ; Set the Y move to down
                call chooseDirection    ; And see if we are going to randomly change direction X

spiderOK        call getspiderBG        ; Grab the BGcontents of the spiders new position first
                call drawspider         ; then draw the spider
                ret                     ; and we're done...
                
; -------------------------------------------------------------------------------------------------
; PSEUDO RANDOM - A table of random X direction values used to give the spider a little more 
; of an interesting bounce left, right or up-n-down
; -------------------------------------------------------------------------------------------------
chooseDirection ld hl,(randM)           ; Grab the random value (ie. our rom address)
                ld a,(hl)               ; This value in a will determine if we move or not.
                ld (ix+3),a             ; set movement on X
                cp 128                  ; End of data?  Lets jump back
                jr z, resetMove         ; No, check left
                inc hl                  ; Otherwise inc and move on...
                ld (randM),hl
                ret
resetMove       ld hl,randMotion        ; Reset the table pointer ready to start again
                ld (randM),hl
                ld a,(hl)
                ld (ix+3),a             ; And don't forget to reset the x move...
                ret                     ; We're finished
                
; -------------------------------------------------------------------------------------------------
; SCREEN FUNCTIONS
; Technically we should turn these into more of a function given that the other game characters
; will all do the same thing.  We can tidy up the complete code once we have the game working...
; -------------------------------------------------------------------------------------------------

; Check the screen location (ie. read the attribute at X,Y
getspiderBG     ld a,(ix+1)
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
                ld (ix+5),a             ; and store the BG for the spider
                ret                     ; and return (a contains the screen contents)

; Draw the spider
drawspider      ld a,(ix+1)             ; grab the X location
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

                ; Lets draw a character block on screen
                ld de,22528             ; de contains the attribute memory address
                add hl,de               ; add the vertical value
                add hl,bc               ; add the horizontal value
                ld (hl),spider          ; Set the block with the spider (blue)
                ret

; Clears the spider by drawing the bgcolour (which we grabbed at the start)
clearspider     ld a,(ix+1)             ; grab the X location
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

                ; Lets draw a bg character block on screen
                ld de,22528             ; de contains the attribute memory address
                add hl,de               ; add the vertical value
                add hl,bc               ; add the horizontal value
                ld a,(ix+5)
                ld (hl),a               ; Set the block with the bg colour
                ret
                
; -------------------------------------------------------------------------------------------------
; DATA FOLLOWS BELOW
; -------------------------------------------------------------------------------------------------
; Our pseudo-movement memory address for the data.
randM           defw    randMotion

; SpiderTick as a counter that defines when the spider should appear.  This value increments each
; game loop.  When it reaches the spiderAppear amount, we activate...
spiderTick      defb    0
spiderAppear    defb    128

; Spider details - flag (0-off, 255-on), x, y, x dir, y dir, BGcharacter
; BGcharacter stores the attribute - spider doesn't necessarily blank out mushrooms
sdrData         defb    255,31,16,128,0,0

; Temp storage of X and Y location
tempX           defb    0
tempY           defb    0

; -------------------------------------------------------------------------------------------------
; DEMO SPIDER :  This is usually in the game loop, but this is a test version for now.  Call this
; routine from BASIC in a loop.  It manages the spider, and you can see the example below of how
; to make use of the tick counter...
; -------------------------------------------------------------------------------------------------

gospider        call movespider         ; Call the movespider code first

                ld ix,sdrData           ; Set IX to the spider data.
                ld a,(ix+0)             ; Check to make sure the spider is active
                cp 0                    ; Was it off?
                ret nz                  ; No, well, all good then...
                
                ld hl,spiderTick        ; Lets update the game ticker
                ld a,(hl)
                inc a
                ld (hl),a
                cp 128                  ; Tick count - do we activate the spider again?
                jr z, activateSpider
                ret
                
activateSpider  ld (ix+0),255
                ld (hl),0
                ret
                
; RANDOM MOVE DATA - to give the spider a little less 'left to right' bounce
randMotion  defb    1,1,1,0,0,255,0,1,0,0,0,255,1,0,255,1,1,255,255,255,0,0,1,255,128

