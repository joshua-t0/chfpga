Firmware features
=================



Before we dig into a detailed description of each main modules of the chFPGA firmware, here is a list of the main features it supports:

	•	The firmware can acquire the data and channelize N antenna signals coming from the ADC board through the FMC connector. The number of supported antennas is set by a variable in the firmware. The channelization is performed by a CASPER Polyphase filter bank (PFB)/FFT. A scaler module brings the frequency samples into a (8+8) bit complex number format. The FFT and the scaler modules can be bypassed for debugging purposed.
	•	The channelizer can be set to use data from three sources: the ADC chip, from a firmware-based function generator that can generate various patterns or from a injection buffer that allows the user to send data patters to be processed.
	•	The data at the output of the channelizer can be captured and streamed over the Ethernet interface. If the FFT is bypassed, the timestream is captured instead. The number of frames to capture and the frequency of the captures can be set by software.
	•	The firmware can implement M streaming correlators that correlate the (8+8) bits complex frequency samples from the N antennas. Each correlator is programmed to process a fraction of the frequency bins grabbed from each antenna data streams. Multiple correlators are used to cover all designed frequency bins. The correlators operate on a separate clock from the data acquistion. The number of frequency channels that can be processed (and there the total number of correlators needed) depends on the correlator speed and the maximum accumulator depth.  The integration time and the data capture time can be set independently by software.
	•	All data processing modules and the control interfaces are interconnected through a standard AXI4 Streaming bus. This makes system interconnections and scaling easy.
	•	The design contains no processor or associated firmware. A simple UDP packet receiver/transmitter implemented as a state machine receives simple command frames and returns data. Every module in the system is mapped to a specific memory space in which control and status registers can be read or written.


