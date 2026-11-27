.. title:: Testbenches

Testbenches
===========

This section documents the VHDL testbenches used to verify the functionality of chFPGA modules. Testbenches are located in ``hdl/testbenches/``.

Channelizer Testbenches
-----------------------

ADCDAQ_timing_test
~~~~~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/ADCDAQ_timing_test/ADCDAQ_timing_test_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/`` (project folder not found)

Tests the timing characteristics of the ADCDAQ module, including clock domain crossing and data acquisition timing.

align
~~~~~

**File:** ``hdl/testbenches/align_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/shuffle_crossbar_testbench/`` (contains align testbench)

Tests the frame alignment module that synchronizes data streams from multiple channelizers. Verifies alignment logic, missing frame handling, and frame synchronization across multiple lanes.

align64
~~~~~~~

**File:** ``hdl/testbenches/align64_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/align64_testbench/``

Tests the 64-bit wide frame alignment module. Verifies packet alignment, lane error detection, and handling of missing frames, short frames, and timing delays.

chan_bin_sel
~~~~~~~~~~~~

**File:** ``hdl/testbenches/chan_bin_sel_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/chan_testbenches/`` or ``xilinx_projects/testbenches/chan_tests/``

Tests the first-stage corner-turn bin selector module. Verifies frequency bin selection, data filtering, packet header generation, and flag handling.

chan_crossbar
~~~~~~~~~~~~~

**File:** ``hdl/testbenches/chan_crossbar_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/chan_testbenches/`` or ``xilinx_projects/testbenches/chan_tests/``

Tests the first-stage corner-turn crossbar module. Verifies data routing, bin selection across multiple channelizers, and packet formatting.

chan_crossbar_shuffle_align
~~~~~~~~~~~~~~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/chan_crossbar_shuffle_align_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/chan_testbenches/`` or ``xilinx_projects/testbenches/chan_tests/``

Tests the integration of the channelizer crossbar with shuffle alignment logic. Verifies end-to-end data flow through the first-stage corner-turn.

chan_fifo
~~~~~~~~~

**File:** ``hdl/testbenches/chan_fifo_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/chan_fifo_testbench/``

Tests the channelizer FIFO module that handles clock domain crossing between the channelizer clock and output clock domains.

funcgen
~~~~~~~

**File:** ``hdl/testbenches/funcgen_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/funcgen_testbench/`` or ``xilinx_projects/testbenches/chan_testbenches/``

Tests the function generator module that provides test waveforms and data sources. Verifies waveform generation, LFSR functionality, and data source selection.

funcgen_clip_width
~~~~~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/funcgen_clip_width_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/chan_testbenches/`` or ``xilinx_projects/testbenches/chan_tests/``

Tests clipping and bit-width handling in the function generator module.

funcgen_lfsr
~~~~~~~~~~~~

**File:** ``hdl/testbenches/funcgen_lfsr_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/chan_testbenches/`` or ``xilinx_projects/testbenches/chan_tests/``

Tests the Linear Feedback Shift Register (LFSR) functionality within the function generator module.

prober
~~~~~~

**File:** ``hdl/testbenches/prober_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/prober_testbench/``

Tests the data capture (prober) module. Verifies data capture functionality, FIFO operation, and packet generation for debugging and monitoring.

scaler
~~~~~~

**File:** ``hdl/testbenches/scaler_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/scaler/``

Tests the scaler module that applies gain coefficients to FFT output data. Verifies scaling operations, quantization, overflow handling, and both real and complex gain modes.

scaler_mul
~~~~~~~~~~

**File:** ``hdl/testbenches/scaler_mul_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/scaler_mul/``

Tests the scaler multiplier core. Verifies signed/unsigned multiplication operations used in the scaling process.

ucap
~~~~

**File:** ``hdl/testbenches/ucap_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/UCAP/``

Tests the UltraRAM-based data capture module. Verifies UltraRAM write/read operations, frame capture, and data retrieval functionality.

Corner-Turn Testbenches
-----------------------

bp_shuffle_align
~~~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/bp_shuffle_align_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/`` (project folder not found)

Tests the backplane shuffle alignment module. Verifies data alignment across backplane links and handling of network delays and errors.

bp_sync
~~~~~~~

**File:** ``hdl/testbenches/bp_sync_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/`` (project folder not found)

Tests the backplane synchronization module. Verifies synchronization logic for multi-board systems.

cge
~~~

**File:** ``hdl/testbenches/cge_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/cge_tests/``

Tests the 100G Ethernet corner-turn engine (CGE). Verifies corner-turn operations, packet handling, and Ethernet interface integration.

gain_switch
~~~~~~~~~~~

**File:** ``hdl/testbenches/gain_switch_testbench.vhd``

**Run with:** ``xilinx_projects/testbenches/gain_switch_testbench/run.sh [GENERIC=value ...]`` (Vivado simulator, no project needed)

Self-checking test of the switch of the scaler gain bank at the end of a correlator integration. Two scalers feed ``UCORR44_ARRAY`` through a delay line that stands for the channelizer FIFO (``DELAY``). The test arms the scalers at many times in an integration, close together around its end, and checks on the input of the multipliers of the correlator that every integration has data of one gain bank only, that the two scalers switch on the same clock, that a gain table written a second time before the switch is the one used, and that the frame-number mode still works. With ``BINS=8192 INTEG=2100`` (the real frame length) it also checks the products in the result packets. ``BREAK=1`` (the signal of the correlator one frame late) and a ``DELAY`` of one frame or more must fail.

sample_split
~~~~~~~~~~~~

**File:** ``hdl/testbenches/sample_split_testbench.vhd``

**Run with:** ``xilinx_projects/testbenches/sample_split_testbench/run.sh``

Self-checking test of the split-sample stage against a model in the testbench, on every clock: the default mode (the values pass with no change), every value from -128 to 127 on every component in the split mode (parts, saturation and its counters), random data with a common signal on four inputs (the products of the parts give the products of the wide values exactly), and mode changes at random times (a frame has one mode only).

scaler_width
~~~~~~~~~~~~

**File:** ``hdl/testbenches/scaler_width_testbench.vhd``

**Run with:** ``xilinx_projects/testbenches/scaler_width_testbench/run.sh``

Gives the same random data, gains and settings to a scaler with (4+4)-bit outputs and to a scaler with (8+8)-bit outputs, and checks that the 4-bit values are the same on every clock in the 4-bit mode, for each rounding mode. This shows that the default mode of the corr8 build, which has scalers with (8+8)-bit outputs for the split-sample mode, gives the correlator the same data as before.

ucorr_acc
~~~~~~~~~

**File:** ``hdl/testbenches/ucorr_acc_testbench.vhd``

**Run with:** ``xilinx_projects/testbenches/ucorr_acc_testbench/run.sh [GENERIC=value ...]`` (15 minutes or more)

Self-checking test of the correlator accumulators with frames of the real length. Three inputs are constant at full scale and five are random. The testbench has the exact sum of the power of each input in each bin and compares it with the 36-bit autocorrelations of the result packets (``WIDE=1``). ``DUMP_FILE`` writes the result records, to compare all the products with those of the design before a change (``CORR_SRC``). ``INTEG=32768 CONSTANT_ONLY=1 INTEGRATIONS=1`` checks one integration of 32768 frames at full scale (3211264).

ucmac88
~~~~~~~

**File:** ``hdl/testbenches/ucmac88_testbench.vhd``

**Run with:** ``xilinx_projects/testbenches/ucmac88_testbench/run.sh [GENERIC=value ...]`` (3 minutes)

Self-checking test of the (8+8)-bit correlator cells (``UCMAC88_ARRAY``, 36 CMACs, short frames). Random values and values at the limits go to all the CMACs for four integrations. A model computes the fields of each sum with the saturation rules of the module, and each result record is compared with the model. Where nothing is saturated, ``RE - IM_HIGH`` is compared with the exact sum of the real parts. The third integration takes the real and imaginary parts of the cross-products past their limits in the two directions. ``AUTO_BITS=20`` also saturates the autocorrelations, and ``CROSS_BITS=22`` tests another width. The test ends with ``UCMAC88 TEST PASSED``.

ucorr88
~~~~~~~

**File:** ``hdl/testbenches/ucorr88_testbench.vhd``

**Run with:** ``xilinx_projects/testbenches/ucorr88_testbench/run.sh [SAMPLE_BITS=8 INTEG=1300]`` (3 minutes), or ``run.sh NCORR=4 PARALLEL=TRUE WORDS=16 INTEG=1050 INTEGRATIONS=2`` for four correlators with the parallel readout (the records come from the correlators in turn, 8 records in a frame, and a record takes no more than its bytes and 16 clocks; without ``PARALLEL=TRUE``: four correlators in the daisy chain)

Self-checking test of ``UCORR44_ARRAY`` with (8+8)-bit inputs (one correlator of 8 inputs, short frames). All the inputs are random. A model computes the 36 products of each bin, and all the result records of three integrations are compared with it. With ``SAMPLE_BITS=8`` the same test runs on the (4+4)-bit correlator: this shows that the two correlators have the same order and the same signs of the products. The test ends with ``UCORR88 TEST PASSED``.

ucap_buffers
~~~~~~~~~~~~

**File:** ``hdl/testbenches/ucap_buffers_testbench.vhd``

**Run with:** ``xilinx_projects/testbenches/ucap_buffers_testbench/run.sh [MODE=0..3] [BUFFERS=4 MEMORY=ultra] [ONE_FRAME=true] [BUFFERS=2 MEMORY=block SPACING=4]`` (3 minutes)

Self-checking test of ``ucap`` with memory in some of its buffers only (``BUFFERS_WITH_MEMORY``). The module under test and a reference with 8 UltraRAM buffers get the same data and commands, and their output streams of one capture are compared packet for packet: the headers must be equal, and the data must be equal to those of the reference or all zeros, in the fraction ``BUFFERS / 8`` of the packets. The default is 2 buffers in block RAM (with the register stages in front of the memories). With ``MODE=0 BUFFERS=4 MEMORY=ultra ONE_FRAME=true`` it tests the mode that captures one frame of each of the 8 channels (``MODE0_ONE_FRAME``): the 4 packets of each channel must be equal to the packets of frame 0 of that channel of the reference. ``SPACING`` is ``MEMORY_BUFFER_SPACING`` of the module under test (``BUFFERS=2 MEMORY=block SPACING=4`` is the ``crs_ct_exponent3`` configuration). The test also checks which buffers have the data: the buffers 0, ``SPACING``, ..., or the first ``BUFFERS`` buffers in mode 3 with ``SPACING`` > 1. The test ends with ``UCAP BUFFERS TEST PASSED``.

scaler_exponent
~~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/scaler_exponent_testbench.vhd``

**Run with:** ``xilinx_projects/testbenches/scaler_exponent_testbench/run.sh [FRAMES=30] [EB=3]`` (``EB`` is ``EXPONENT_BITS`` of the scaler under test; the ``ct`` build has 2)

Self-checking test of the exponent mode of the scaler (generic ``EXPONENT_BITS``). It also compares, for each bin, the bit that tells that the bin has an exponent (the MSB of the bin in ``m_axis_out_texp``) with the table, ``exponent_max`` and the mode. With the mode off, a scaler with ``EXPONENT_BITS`` = 3 must give the same data, flags and frame ends as a scaler without the mode, 4 clocks later. With the mode on, a model in the testbench computes the exact product of each FFT value and its gain and, from the definition, the exponent, the two 4-bit values and the overflow flag of each bin; every bin is compared, for the three rounding modes, with and without the symmetric saturation and the zero on saturation, with random integer and floating-point gains, and with a table of values at the limits (7.5 x 2^e, 7 x 2^e, 8 x 2^e, one step above and below, values that no exponent holds) on the real part, on the imaginary part and on the two. The test prints the number of bins checked with each exponent and ends with ``SCALER EXPONENT TEST PASSED``. It takes about 90 seconds. The test then does all the values of ``exponent_max`` from 0 to 7 (with 0, and for each bin in the table of the bins with no exponent, the output must be that of a scaler without the mode), and the table with these patterns: all the bins, one bin, all the bins but one, every second bin (the two cases) and a random pattern. The model has the bin number of each sample.

upack_exponent
~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/upack_exponent_testbench.vhd``

**Run with:** ``xilinx_projects/testbenches/upack_exponent_testbench/run.sh [EB=2] [WORDS=32] [NPKT=4] [NBINS=8] [BLOCKS=3] [SWEEP=16] [SEED=1] [VECTORS=<directory> [VEC_B=2] [VEC_BAND=TRUE] [VEC_FIELD4=TRUE]]``

Self-checking test of the exponent mode of the packetizer (``upack`` with ``EXPONENT_BITS`` = 2, or 3 with ``EB=3``). The input is the stream of the corner-turn engine: random (4+4)-bit samples, each one with its exponent and with the bit of its scaler that tells that the bin has an exponent. Each of the 8 inputs has its own table of bins with an exponent. The testbench writes the mask, the headers and the playlist (the list of the bins of each packet) through the BSB interface as the host does, and compares every byte of every packet with a model of the definition:

- a bin of a packet has exponents if one input or more has the bit at 1 in the last frame of the 16 frames of the packet;
- one exponent for each group of *B* frames: the largest exponent of the group, and the division of the other samples with a tie to the even integer;
- the exponents after the last data bin, with zeros to a multiple of 64 bytes;
- the packet with the timestamp *T* has the frames *T* to *T* + 15, counted from the first frame after the reset.

It also checks that every packet has an even number of 32-byte words, and that the packets of a set of 16 frames come *W* + (*W* - 1) / 32 + 1 clocks apart with ``tx_exponents`` = 1 (*W*: words of the packet).

The phases:

1. ``tx_exponents`` = 0. The packets and their timestamps are equal to those of a packetizer with ``EXPONENT_BITS`` = 0 that gets the same frames and the same reset, 7 clocks later. Three cases: the reset ends before the stream starts (as after a sync), at the end of a frame, and in the middle of a frame.
2. For *B* = 2, 4, 8 and 16: four tables (all the bins have exponents, none, random and not the same for each input, a band of bins). With ``EB=3`` this is done for exponents of 2 bits in the packets (input exponents from 0 to 3) and of 4 bits (input exponents from 0 to 7).
3. ``EB=3`` only: exponents of 2 bits in the packets with input exponents to 7. The exponents above 3 are sent as 3 and the status flag ``exp_field_over`` must be set.
4. ``SWEEP`` resets of the transmitter (``tx_reset`` = 1, then 0, as the host does) at moments that go through two sets of 16 frames, while the frames flow. After each one: the first packet has the timestamp 0 and the set of frames that was complete, the exponents are those of their samples, and the flag ``overrun`` is 0.
5. The header of one packet has wrong bits for the bins with exponents: the flag ``exponent_bins_mismatch`` and its counter.
6. The tables of the inputs change two times while the frames flow.
7. A playlist that is too long for a set of 16 frames: the flag ``overrun`` is set, the packets that are complete are right, the packet in progress ends with an even number of words, and the timestamps go up by 16 for each set.
8. A reset of the packetizer in the middle of the stream and of a readout.

The test fails if a case was not in the run: all the shifts (1 to 3, or 1 to 7 with ``EB=3``) with the ties that are possible, packets with no exponents, packets with and without a word of zeros after the exponents, bins that not all the inputs select, and the pauses between packets.

The firmware size is ``WORDS=2048 NPKT=128 NBINS=48 BLOCKS=2 SWEEP=4``.

With ``VECTORS``, only one setting runs (one exponent for ``VEC_B`` frames; exponents of 4 bits with ``VEC_FIELD4``; all the bins, or with ``VEC_BAND`` a band of 10 % of the data bins), and the test writes two files for the decoder of the host: ``packets.hex`` (the UDP payload of the packets of the first 2 sets of 16 frames, one line for each packet, with the header as the host writes it) and ``samples.txt`` (for each sample: packet, number of the data bin in the packet, frame, input, real part, imaginary part, exponent, and 1 if the bin has exponents).

scaler_gain_switch
~~~~~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/scaler_gain_switch_testbench.vhd``

**Run with:** ``xilinx_projects/testbenches/scaler_gain_switch_testbench/run.sh [WRAP=1]``

Self-checking test of the switch of the scaler gain bank at a frame number: a target that is ahead (the switch is at the end of that frame and not before), a target that is past when the bank is selected (the switch is at the end of the frame in progress, with the late flag), an old target, the unsynchronised mode, and the register that has the frame of the switch. ``WRAP=1`` starts the frame counter 30 frames before its limit with a target after the limit.

rawpack
~~~~~~~

**File:** ``hdl/testbenches/rawpack_testbench.vhd``

**Run with:** ``xilinx_projects/testbenches/rawpack_testbench/run.sh [GENERIC=value ...]`` (Vivado simulator, no project needed)

Self-checking test of the raw ADC sample streamer, with one or two 100G links (``LINKS``) and any set of streams (``STREAM_ENABLE``). Drives a known pattern on the capture bus, enables the stream through the BSB registers and checks every packet: Ethernet/IP/UDP headers, IP checksum, the order of the two streams, the packet counter and the continuity of the timestamps of each stream, and every sample. Also checks the upstream bus of link 0, which carries frames of the length of the ``upack`` frames back to back: it passes through before the streams are enabled and after they are disabled, and every upstream frame that comes out is complete. ``SWEEP=485`` starts and stops the streams at every position of an upstream frame. ``PASS_MUTE=1`` stops the upstream transmitter in the middle of a frame: the module must close that frame. Generics select the channels, the data source, the packet size and gaps in the input (``GAP_PERIOD``). ``DUMP_FILE`` writes the packets to a file for use by host software tests. ``run_all.sh`` runs all the cases.

``SAMPLE_BITS`` (12 or 14) is the number of bits of a sample; with 14 the test also checks that each packet has an even number of 256-bit words and the number of blocks that the firmware uses. ``RESTART_TEST=1 RESTART_BITS=12`` (or 14) makes a first run with another number of bits, and ``CHANGE_TEST=1`` also writes another number of bits while the streams run (it must have no effect). The last line of a test gives the largest number of words in the FIFO of a stream. ``run_all.sh`` runs all the cases; ``JOBS=16 run_all.sh`` runs 16 of them at the same time.

**Pass-through test:** ``hdl/testbenches/rawpack_pass_testbench.vhd``, run with ``xilinx_projects/testbenches/rawpack_testbench/run_pass.sh``. No stream is enabled: the output of link 0 must be the upstream bus delayed by one clock, word for word, with random frames and gaps and across resets.

rawpack_cge
~~~~~~~~~~~

**Files:** ``hdl/testbenches/rawpack_cge_testbench.vhd``, ``hdl/testbenches/cmac_usplus_1_sim_model.vhd``

**Run with:** ``xilinx_projects/testbenches/rawpack_testbench/run_chain.sh [GENERIC=value ...]``

``SAMPLE_BITS`` (12 or 14) is the number of bits of a sample. With 14 bits and two streams on a link, the link has 90.7 Gb/s with the default packets.

Full-rate test of the chain capture bus, ``rawpack``, ``cge``, with one ``cge`` and one MAC model for each 100G link (``LINKS``, 2 by default). The Xilinx 100G MAC inside ``cge`` is replaced by a behavioural model that paces the transmit stream at the 100 Gb/s line rate (including preamble, FCS and inter-frame gap), fails on a transmit underflow and writes every frame to a file. Link 0 also gets upstream frames with the timing of ``upack`` (``UPSTREAM``: 0 none, as in corr8; 1 all the time; 2 stopped in the middle of a frame during the runs), and ``RUNS`` sets the number of start and stop cycles. The testbench fails if any FIFO overflows, and ``check_frames.py`` then checks all the frames: headers, no packet lost, every sample, and that every upstream frame out of the MAC model is complete.

cge_test
~~~~~~~~

**File:** ``hdl/testbenches/cge_test_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/cge_tests/``

Additional testbench for the CGE module with different test scenarios. Tests normal mode, borderline delays, missing frames, and short frames.

shuffle_crossbar
~~~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/shuffle_crossbar_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/shuffle_crossbar_testbench/``

Tests the second and third-stage corner-turn crossbar (shuffle crossbar). Verifies align, remap, and shuffle_bin_sel functionality, data combining, and packet routing.

shuffle
~~~~~~~

**File:** ``hdl/testbenches/shuffle_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/shuffle_sim/``

Tests the shuffle network module. Verifies data shuffling operations and network routing.

two_crossbars
~~~~~~~~~~~~~

**File:** ``hdl/testbenches/two_crossbars_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/`` (project folder not found)

Tests the integration of two crossbar stages (channelizer crossbar and shuffle crossbar). Verifies end-to-end data flow through multiple corner-turn stages.

upack
~~~~~

**File:** ``hdl/testbenches/upack_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/upack_testbench/``

Tests the UltraRAM-based packetizer and corner-turn engine (UPACK). Verifies corner-turn operations using UltraRAM for data buffering.

u_ct
~~~~

**File:** ``hdl/testbenches/u_ct_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/uct_engine_level2_testbench/``

Tests the Ultrascale+ corner-turn engine (UCT). Verifies multi-level corner-turn operations (CT_LEVEL 1, 2, and 3) and link management.

uram_ct_cge
~~~~~~~~~~~

**File:** ``hdl/testbenches/uram_ct_cge_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/cge_tests/``

Tests the UltraRAM-based corner-turn engine for CGE. Verifies UltraRAM usage in corner-turn operations with 8 channels, 8k bins, and 16 frames.

Correlator Testbenches
----------------------

cmac
~~~~

**File:** ``hdl/testbenches/cmac_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/corr_core_testbench/``

Tests the Complex Multiply-and-Accumulate (CMAC) core. Verifies complex multiplication, accumulation, and correlation product calculations.

corr44
~~~~~~

**File:** ``hdl/testbenches/corr44_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/corr_core_testbench/``

Tests the (4+4) bit correlator core. Verifies correlation operations, integration periods, and output formatting.

CORR
~~~~

**File:** ``hdl/testbenches/CORR_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/corr_core_testbench/``

Tests the legacy correlator module. Verifies basic correlation functionality.

ucorr44
~~~~~~~

**File:** ``hdl/testbenches/ucorr44_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/ucorr44/``

Tests the UltraRAM-based (4+4) bit correlator. Verifies correlation operations using UltraRAM for data storage.

ucorr44_array
~~~~~~~~~~~~~

**File:** ``hdl/testbenches/ucorr44_array_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/ucorr44_array/``

Tests the array of UltraRAM-based correlators. Verifies multiple correlator instances working in parallel.

System Testbenches
------------------

axis_sync_fifo
~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/axis_sync_fifo_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/axis_sync_fifo_testbench/``

Tests the AXI4-Streaming synchronous FIFO. Verifies FIFO read/write operations, full/empty flags, and data integrity across clock cycles.

bsb_router_slave
~~~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/bsb_router_slave_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/bsb_regs_testbench/``

Tests the backplane serial bus (BSB) router and slave modules. Verifies command routing, address decoding, and register access.

chFPGA
~~~~~~

**File:** ``hdl/testbenches/chFPGA_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/`` (project folder not found)

Tests the top-level chFPGA module. Verifies system integration, command interface, GPIO, and overall system functionality.

cmd_slave
~~~~~~~~~

**File:** ``hdl/testbenches/cmd_slave_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/`` (project folder not found)

Tests the command slave module that implements memory-mapped registers. Verifies register read/write operations, control and status byte handling.

packetizer
~~~~~~~~~~

**File:** ``hdl/testbenches/packetizer_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/`` (project folder not found)

Tests the packetizer module. Verifies packet formatting, header generation, and data packaging for transmission.

sysmon
~~~~~~

**File:** ``hdl/testbenches/sysmon_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/sysmon_testbench/``

Tests the system monitor (SYSMON/XADC) module. Verifies analog-to-digital conversion, temperature and voltage monitoring.

Ethernet and Network Testbenches
---------------------------------

udp_mac
~~~~~~~

**File:** ``hdl/testbenches/udp_mac_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/`` (project folder not found)

Tests the UDP MAC module for 1G Ethernet. Verifies UDP packet transmission and reception, Ethernet frame handling, and GMII interface.

udp_mac_rx
~~~~~~~~~~

**File:** ``hdl/testbenches/udp_mac_rx_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/udp_mac_rx_testbench/``

Tests the UDP MAC receiver functionality. Verifies packet reception, frame parsing, and data extraction.

xge_udp_mac_tx
~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/xge_udp_mac_tx_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/`` (project folder not found)

Tests the 10G Ethernet UDP MAC transmitter. Verifies 10G packet transmission, XGMII interface, and high-speed data handling.

xge_udp_mac_tx_xglink
~~~~~~~~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/xge_udp_mac_tx_xglink_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/`` (project folder not found)

Tests the integration of 10G Ethernet UDP MAC transmitter with XGLINK serial links. Verifies end-to-end data transmission through Ethernet and serial interfaces.

XGMII_UDP_MAC
~~~~~~~~~~~~~

**File:** ``hdl/testbenches/XGMII_UDP_MAC_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/`` (project folder not found)

Tests the XGMII UDP MAC module. Verifies XGMII interface, 10G Ethernet packet handling, and protocol compliance.

Serial Link Testbenches
-----------------------

xglink_array
~~~~~~~~~~~~

**File:** ``hdl/testbenches/xglink_array_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/shuffle_sim/``

Tests the XGLINK serial link array. Verifies multiple serial link operation, data transmission, and link management.

xxvglink_array
~~~~~~~~~~~~~~

**File:** ``hdl/testbenches/xxvglink_array_testbench.vhd``

**Xilinx Project:** ``xilinx_projects/testbenches/xxvglink_testbench/``

Tests the 25G serial link array (XXVGLINK). Verifies 25Gbps packet transmission, link initialization, and array operation.
