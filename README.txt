----------
HOW TO USE
----------

-------------
MARS Settings
---------------------------------------------------------------------------------------------------
For the program to assemble correctly, ensure the following settings are enabled in MARS:

	1) Permit extended (Pseudo) instructions and formats

---------------------------------------------------------------------------------------------------

---------------
Bitmap Settings
---------------------------------------------------------------------------------------------------
In order for the board to display properly, open the bitmap display in the tools section, connect it to MIPS, and apply the following settings need to the bitmap display:

	Unit Width in Pixels: 1	
	Unit Height in Pixels: 1
	Display Width in Pixels: 512
	Display Height in Pixels: 512
	Base Address for display: 0x10040000 (heap)

---------------------------------------------------------------------------------------------------

-------------
Player Inputs
---------------------------------------------------------------------------------------------------
When playing the game, follow these 3 rules to avoid having to re-input your move or crashing the 
program:

	1) Y coordinate must always be in the range of [1, 6]
	2) X coordinate must be non-negative and be less than or equal to your Y coordinate
	3) Avoid entering any non-numeric values, or the program will most likely crash

---------------------------------------------------------------------------------------------------

-------------------
Running the Program
---------------------------------------------------------------------------------------------------
To run the game, follow these steps:

	1) Open the main.asm file in MARS
	2) Assemble the file
	3) Run the current program
	4) Enjoy!

---------------------------------------------------------------------------------------------------