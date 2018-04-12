# --------------------------------------------------------------------------------
# Extract UDG data from a PNG, write text data 'defb' info for use in my Z80 projects.
# Kevin Phillips, 2018. 
#
# v1.0	12-04-2018	KP	* Created simple tool.  Set up data for creating
#						  centipede (ie. what I needed it for)
#
# Feel free to modify this code for your own use if you need it.  Its all about
# making life easier... :)
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Import the PIL module (If needed, install using python -m pip install pillow)
# --------------------------------------------------------------------------------
from PIL import Image

# --------------------------------------------------------------------------------
# Define the pixel (ink) colour to check for when compiling bits.  Any other
# colours just get treated as 0's (makes colour-coding the BG so we can visually
# see the graphics easy)
# --------------------------------------------------------------------------------
pxCol = (0,0,0)

# --------------------------------------------------------------------------------
# Load the image to use here.  Currently hard coded - Change as needed.
# --------------------------------------------------------------------------------
gfxImg = Image.open("D:\\centipede.png")

# Use load function to create a pixel access object into our image.
# This allows us to access pixel data as a 2D array
pixData = gfxImg.load()

# Get the height.
height = gfxImg.size[1]

# --------------------------------------------------------------------------------
# Lets collect the asm text into a list that we'll write out at the end
# --------------------------------------------------------------------------------
gfxList = []

# --------------------------------------------------------------------------------
# For the centipede game, I'm building a custom list for the text file
# --------------------------------------------------------------------------------
sprList = ['mushroom','flea','player','bullet','centU','spider','scorpion','centL',
			'centD','centR']
sprEntry = 0		# Index into this named list
byteCount = 0		# Count that keeps track of every 8 bytes (in the graphic)
gfxBytes = ""		# String where we compile our 8 bytes as comma-sep'd values

# --------------------------------------------------------------------------------
# LOOP : Lets walk through every 8-pixel row in our image and compile all
#        that juicy data (and save us using a calculator and a lot of patience)
# --------------------------------------------------------------------------------
for eachByte in xrange(height):

	# Set value for bit (right back to left).  First bit of course = 1
	bitCount = 1
	# Byte value (our compiled 8 bits)
	byteValue = 0
	
	# Loop through the 8 pixels in the line
	for bits in range(8):
		# Bits start from right to left
		bitPos = 7 - bits
		# Check for the pixel existing
		if pixData[bitPos,eachByte] == pxCol:
			byteValue += bitCount
		# Increase the bit value (ie. 1,2,4,8,16,32,64,128)
		bitCount += bitCount

	# Once finished compiling the byte.  Increase the byte count - this loops from
	# 0 - 7 to make sure we keep only 8 bytes per character.
	byteCount+=1
	
	# If we haven't read our 8 bytes yet
	if byteCount < 8:
		# Add it to our text string that keeps track of our compiled defb values
		gfxBytes += (str(byteValue)+",")
	else:
		# Otherwise we've got the 8 bytes...  Reset our counter to start again
		byteCount = 0

		# Clean up our defb string by removing the trailing comma at the end
		gfxBytes = gfxBytes[:-1]
		
		# Store the details in the right format for the asm.  In this case
		# We have a comment about what graphic it is for first,
		gfxList.append("; Graphic for %s\n" % (sprList[sprEntry]))

		# followed by the defb line, starting with our label we can reference in asm
		# and ending in a clean formatted line (spacing equal, etc)
		dataLine = ("gfx%s"%sprList[sprEntry]).ljust(16)+"defb    "+gfxBytes
		gfxList.append(dataLine+"\n")

		
		# Increase the index for that list of names we're tracking through
		sprEntry += 1
		# and clear the defb text string, ready for the next 8 bytes of data
		gfxBytes = ""

# --------------------------------------------------------------------------------
# COMPLETED : Write out the list we compiled to a text file.  Note that this is
#             hardcoded here.  Change is needed
# --------------------------------------------------------------------------------
asmOutputFile = open("D:\\bytesGFX.txt","w")
asmOutputFile.writelines(gfxList)
asmOutputFile.close()

print "Completed writing the data to our text file.  Copy-paste and make that game!"
