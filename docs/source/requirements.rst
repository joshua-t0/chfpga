=====================
Firmware Requirements
=====================


Source requirments
==================

The firmware was based on the following main requirements that flow from the science, system engineering and project logistics requirements:

	- Science-related requirements:
		-	Acquire the data in a nominal 400-800 MHz range (can be extended up to 850 MHz)
		-	Channelize the data into 1 MHz frequency bins or less
		-	The channelizing must have a good rejection of adjacent interference tones
		-	Channelizer data has a resolution of (4+4) bits (real + imaginary parts)
	-	Systems engineering requirements
		-	Operate on the FPGAs new hardware platforms (Virtex 6, Kintex 7 and Virtex 7 if needed) and efficiently use the resources on those chips to maximize the amount of processing per board
		-	Support the data acquisition from the 8-channel McGill MGADC08 FMC-based ADC board with proper synchronization
		-	Provide the data formatting and firmware to shuffle the data between a large number of boards using the multi-gigabit serial links
	-	Project management requirements
		-	Re-use CASPER signal processing blocks as much as possible to minimize development costs, delays and risks
		-	Provides the tools to allow easy debugging and validation of the signal processing path

Derived requirements
====================

The analysis of the source requirements and preliminary design allowed us to identify a basic architecture with the following constraints:

	- Channelizer

		- Will be implemented using the CASPER PFB/FFT
		- Will use the same configuration as the CASPER pocket configuration in order to allow easy comparison of the results
		- Channelizing will be performed on non-overlapping,  2048-sample frames (bin resolution of 800 MHz sampling / 2048 = 0.4 MHz bins)
		- A 4 tap PFB is used at the input
