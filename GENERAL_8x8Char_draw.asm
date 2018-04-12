; -------------------------------------------------------------------------------------------------------
; HOW-TO : Writing an 8-byte character to the ZX Spectrum graphics memory - Kevin Phillips, 1986-2018.
; This snippet of code demonstrates how to write to the spectrum's graphics memory.  The routine here
; can be used to draw 8x8 (characters) to the screen.
;
; Part of the example here is to give a break down of how to calculate the physical address of the
; screen, which in turn can then be applied to sprite-drawing or other functions on the classic ZX spec.
; -------------------------------------------------------------------------------------------------------

; Define some constants
attMem      equ 22528       ; Address of the spectrums colour attrib memory
xval        equ 10          ; Dummy value for X location (column)
yval        equ 10          ; Dummy value for Y location (row)

org 40000

; -------------------------------------------------------------------------------------------------------
; CALCULATE SCREEN ADDRESS
; -------------------------------------------------------------------------------------------------------
; The speccy's screen address (16384) is 64 x 256.  In binary looks like this:
; 0 1 0 0 0 0 0 0  ,  0 0 0 0 0 0 0 0
;
; -------------------------------------------------------------------------------------------------------
; The way that the screen is structured is in 3 blocks of 8 character lines each.  Memory is ordered
; so that the first pixel line for all 8 lines (32 characters wide) is drawn, then the second and so
; forth.  Once all 8 pixel lines are done, the next block of 8 lines begins.
;
; On completion, then the attribute data is written sequentually from left to right, line by line.
;
; Its easier to show then explain in words.  If you are familiar with watching loading screens on speccy's
; then you are watching the screen memory being populated...
;
; Some 'more visual' examples showing screens loading (and hence showing structure) from Youtube:
; https://youtu.be/MtBoRp_cSxQ
; https://youtu.be/O6uwfM8F5uU
; -------------------------------------------------------------------------------------------------------
; So, how do we translate a value X and Y into a physical address?  We get their 'bits' and then
; structure them into our screen memory address.  I hope you know your binary, cause here we go...
;
; X (column).  0 - 31.  This range of values is stored in the first 5 bits.
; ("x#" indicate the bits that are used, and help make it clear further down)
; 0 0 0 x4 x3 x2 x1 x0
;
; Y (row).  0 - 23.  This range of values is also stored in the first 5 bits.
; ("y#" indicate the bits that are used, and help make it clear further down)
; 0 0 0 y4 y3 y2 y1 y0
;
; Each character is comprised of 8 pixel lines.  These require just the lower 3 bits (value 0-7)
; ("p#" indicate the bits that are used, and help make it clear further down)
; 0 0 0 0 0 p2 p1 p0
;
; Knowing these particular values, lets look at how they are used in the address:
;
; High byte.  Bit 6 (64) is set as the base value, then top two bits of Y, and pixel line (0-7)
; 0  1  0  y4 y3  p2 p1 p0
;
; Low byte.  The lower 3 bits of Y are used at the start, followed by the 5 bits of X.
; y2 y1 y0 x4 x3 x2 x1 x0
;
; Our final address structure looks like this:
; 0  1  0  y4 y3  p2 p1 p0  ,  y2 y1 y0 x4 x3 x2 x1 x0
;
; Sounds complicated?  Once you've got your values X and Y, this short snippet of assembler will
; construct the address for us.  Set the BC with the values.  B = Y,  C = X
;
calcScreen  ld a,b          ; Get the Y value into the a register
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
; This is much simpler, as attributes are organised sequentially from top to bottom.  Basically its a case
; of 22528 (the base address) + (32 * Y) + X
;
; Calculating that is as straight forward as this.  Again, pass the location into BC (B = Y, C = X)
calcAttrib  ld l,b          ; Load the Y into the l register
            xor a           ; Zero out a register (xor quickest way to set the value to 0)
            ld b,a          ; Zero out b.  This will leave bc = X
            ld h,a          ; Zero out h.  This leaves hl = Y
            
            add hl,hl       ; Adding hl to itself 5 times performs a multiplication by 32 (its a binary
            add hl,hl       ; thing.)
            add hl,hl
            add hl,hl
            add hl,hl
            
            ld de,attMem    ; Load the base address into de
            add hl,de       ; Add the address to hl (the 32 * Y).
            add hl,bc       ; then add bc (the X)
            ret             ; When we return, HL = attribute address
        
; -------------------------------------------------------------------------------------------------------
; HOW TO USE IT
; -------------------------------------------------------------------------------------------------------       
; This example shows how we can draw a character + attributes to screen at a position.  Store the screen
; X and Y in memory (see below) and then call the drawChar routine.  Note that there is a dummy graphic
; stored at the end in the charData...

; Note the order (Y first, X second) is important.  Store them here.
charPos     defb yval,xval

; Take data and draw the graphic to screen
drawChar    ld bc,(charPos) ; Grab the X and Y into bc
            call calcScreen ; Get the screen address into hl
            
            ; Read the 8 bytes of the character graphic
            ld ix,charData
            ld b,8
drawbyte    ld a,(ix+0)     ; Grab the pixel data
            ld (hl),a       ; Poke byte to screen
            inc h           ; We can simply inc the high byte for each pixel line
            inc ix          ; Jump to next graphic byte
            djnz drawbyte   ; decrement b and repeat loop
            
            ld bc,(charPos) ; Get the X and Y again
            call calcAttrib ; Get the attribute address into hl
            
            ld de,charAtt  ; Grab the attribute
            ld a,(de)         
            ld (hl),a       ; and poke it onto the screen
            
            ret             ; We're done!

; -------------------------------------------------------------------------------------------------------
; DATA FOLLOWS
; -------------------------------------------------------------------------------------------------------           
; Define a simple UDG style graphic (basically a rectangle)
charData    defb 0,255,129,129,129,129,255,0

; Define the character attribute colour (7 = black BG and white ink)
charAtt     defb 7
