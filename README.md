# ZXSpeccy-z80-projects
You can consider this repository as being an ongoing collection of code examples, small game projects and more, primarily developed in Z80 assembler language.  Developed as both an educational and personal resource and released here on github for public consumption.

# FILES
The following is an index of the files in this repository and will be updated as new files are added.
## Centipede source code (main project file (ie. the one you should read))
- **centipede_complete_game.asm** : WIP game code (updated 16-05-2018, sna and video added to github (see below))
## Utilities and tools
Non-spectrum tools, written to assist the development process and shave off some time.  These can be found under the **_tools_** subfolder.
- **centipede_PNG_to_bytes.py** : Python script to read UDG data from a PNG file, creates defb text for use in assembler.
## General code examples
Various small snippets of code to demonstrate various techniques and approaches to a variety of tasks on the ZX spectrum.  These can be found under the **_samples_** folder.
- **GENERAL_8x8Char_draw.asm** : How to calculate the screen address of a X,Y location and then draw a 8x8 pixel character
## Centipede programming example
A start on development of an old 1986 notebook plan for a centipede clone for the ZX Spectrum.  A scanned copy of the notebook is provided.  This initial set of files demonstrate how to code a simple working centipede control routine.
## Centiblock (Centi(pede) with block (attribute) graphics) sample files
Each of the different parts of a typical centipede game are demonstrated individually as example code to show how to approach each detail. Found under the **_centiblock_** subfolder
- **centipede_example_code.asm** : Assembler code for creating a moving 'centipede' routine (initial)
- **CENTIBLOCK_centipede.asm** : Moving centipede with collision as well as kamikaze (poison mushroom) mode (updated from example code).
- **CENTIBLOCK_spider.asm** : A bouncing spider with appearance timer and some pseudo-randomness to its movement.
- **CENTIBLOCK_player.asm** : User controlled player and bullet, with basic bullet-mushroom collision. (Q,A,O,P,M)
- **CENTIBLOCK_flea.asm** : A flea drops down above the player, leaving random mushrooms in its path.
- **CENTIBLOCK_scorpion.asm** : A scorpion travels left-to-right, poisoning mushrooms it passes over
## Miscellaneous files
The following files are examples, snapshots or other non-code files.  These are in the root of the respository as they require commandline (local machine) to move them to a subfolder.
- **centipede.png** : Example UDG graphic PNG file (see Tools for the script to read and process this)
- _Note that each of the snapshot files also have short screen recording videos associated with them._
### Playable updates (snap shots) and gameplay video samples
- **centipede_WIP_200418.sna** : WIP - ZX Spectrum snapshot (.sna) (20-04-18). Player/Centipede/Score/Bullet functionality.
- **centipede_WIP_230418.sna** : WIP - ZX Spectrum snapshot (.sna) (23-04-18). Dropping 'flea' added.
- **centipede_WIP_240418.sna** : WIP - ZX Spectrum snapshot (.sna) (23-04-18). Scorpion added.
- **centipede_WIP_010518.sna** : WIP - ZX Spectrum snapshot (.sna) (01-05-18). Spider added. Mostly ready to go! (exciting)
- **centipede_WIP_080518.sna** : WIP - ZX Spectrum snapshot (.sna) (08-05-18). Various game speed controls added. More playable.
- **centipede_WIP_090518.sna** : WIP - ZX Spectrum snapshot (.sna) (09-05-18). Full player and creature collision - now a GAME!
- **centipede_WIP_110518.sna** : WIP - ZX Spectrum snapshot (.sna) (11-05-18). Centipede generator! Ready to add 'levels'.
- _(Note : 11-05-18 has **no** accompanying video - need to optimise screen draw when lots of centipedes(flickering))_
- **centipede_WIP_160518.sna** : WIP - ZX Spectrum snapshot (.sna) (16-05-18). Added non-flickering screen draw
### Various other misc files
- **1986_KP_Centipede_design.pdf** : Scanned hand-written notebook plan
- **centipede_example_demo.sna** : ZX Spectrum snapshot (.sna) that can be loaded in an emulator and run for _centiblock_ demo.
- **spiderDemo_centiblock_test.sna** : ZX Spectrum snapshot (.sna) to load and run the _centiblock_ spider code.
- **centipedeDemo_centiblock_test.sna** : ZX Spectrum snapshot (.sna) to load and run the _centiblock_ centipede code.
- **playerdemo_centiblock.sna** : ZX Spectrum snapshot (.sna) to load and run the _centiblock_ player code.
- **fleaDemo_centiblock.sna** : ZX Spectrum snapshot (.sna) to load and run the _centiblock_ flea code.
- **scorpionDemo_centiblock.sna** : ZX Spectrum snapshot (.sna) to load and run the _centiblock_ scorpion code
# Tools
To work with assembler code, especially when developing for the ZX Spectrum, I made use of the following:
## ZEUS Windows IDE (DesignDesign).
Excellent development tool, and well worth grabbing.  It offers a broad range of tools, including emulation and other more advanced functions such as the ability to write out emulator file formats (.tzx, etc) within the assembler tool itself.

http://www.desdes.com/products/oldfiles/

Note that I used the actual ZX Spectrum version of the ZEUS assembler back in the 1980's.  It was an excellent tool back then as well...
## ZXSpin
ZXSpin is a nice Spectrum emulator, though sadly is no longer supported or developed.  Fairly feature packed, it also includes an assembler that can be used to develop and work with code.  I used this emulator a few times to compile and run the code I was testing directly 'in' the ZX Spectrum without having to transfer files or launch other applications to do so.

ZXSpin : https://www.zophar.net/sinclair/zx-spin.html

## Notepad++
Most people prefer proper development IDE's, however I make heavy use of the excellent Notepad++ editor for code editing.  Primarily I use this for most of my python work (there is a plugin called pyNPP that can launch and run the script).  Its an option worth considering for those who have no other editing tools (sublime, etc).

https://notepad-plus-plus.org/

## Other development resources
There are many ZX spectrum emulators, some have built in debuggers, editors and tools.  For more options, here are some additional links that you can look at to some great tools.
### Emulators/dev tools
- **CSpect** : https://dailly.blogspot.com/
- **Zesarux** : https://github.com/chernandezba/zesarux
- **Z88dk** : https://github.com/z88dk/z88dk

### Documentation and information (Z80 programming)
- http://z80-heaven.wikidot.com/
- http://clrhome.org/table/

### ZX Spectrum Next 
There are a few development resources listed on the official website:
https://www.specnext.com/category/resources/resources_coding/

Note that you can also check out the forum on the official website, as well as the facebook page.
