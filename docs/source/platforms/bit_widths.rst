Overview
========

This document outlines the differences in precisions and bit widths between the ICE (Kintex) and CRS (Zynq Ultrascale+) platforms, which are due to fundamental differences in hardware capacity between the two.

All of the widths are on a per-channel basis unless otherwise stated.



Bit widths
==========

------------------------------------------------------------------------------------------------------------------------------------------
| Signal                                |             ICE                 |             CRS               |                  Notes
------------------------------------------------------------------------------------------------------------------------------------------
| ADC output                            | 4 samples *      8  bits/sample | 8 samples * 14 bits/sample    | Same as output width of FUNCGEN
| FFT output                            | 2 bins    * (18+18) bits/bin    | 4 samples * (18+18) bits/bin  | 
| FFT output (CHORD)                    |            N/A                  | 4 samples * (32+32) bits/bin  | 
| gains                                 | 2 gains   *     16  bits/gain   | 4 gains   *     16  bits/gain | Bin # of gain from MSB to LSB is reversed wrt to word from fft 
| raw SCALER output                     | 2 bins    * (35+35) bits/bin    | 4 bins    * (35+35) bits/bin  | gain width + fft width + 1 for complex gains 
| raw SCALER output (CHORD)             |            N/A                  | 4 bins    * (48+48) bits/bin  | 
| SCALER  output                        | 2 bins    *   (4+4) bits/bin    | 4 bins    *   (4+4) bits/bin  | 
| CAPTURE output                        | 32 bits                         | 128 bits                      | The format of this signal depends on the capture mode selected
| bin width in full capture mode        | 16 bits                         | 32 bits                       | capture width / number of bins
| bin width in even or odd capture mode | 32 bits                         | 64 bits                       | as above * 2
------------------------------------------------------------------------------------------------------------------------------------------


Other parameters
================

A couple of other parameters of the system are affected by changing these bit widths, as outlined below.
------------------------------------------------------------------------------------------------------------------------------------------
| Parameter                                   | ICE | CRS |                  Notes
------------------------------------------------------------------------------------------------------------------------------------------
| implicit shift on FFT bypass                |  10  |  4  | the width of either component of a single freqency bin - the width of a single sample
| shift to recover captured adc data          |   0  |  2  | capture width / number of samples - sample width 
| shift to recover top 4 upper bits of scaler |  31  | 31  | scaler output - 4 
------------------------------------------------------------------------------------------------------------------------------------------
