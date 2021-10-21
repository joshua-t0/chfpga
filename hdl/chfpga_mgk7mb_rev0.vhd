----------------------------------------------------------------------------------
--! @file
--! @brief Top-level file to implement chFPGA on the Kintex 7-based MGK7MB (ICEboard) platform
-- Company: McGill University 
-- Engineer: JF Cliche
-- 
-- Create Date:    2013-07-29 
-- Design Name:    chFPGA_MGK7MB
-- Module Name:    top - Behavioral 
-- Project Name: CHIME
-- Target Devices: Kintex 7 on MGK7MB/ICE board 
-- Tool versions: Vivado 2013.2

-- Dependencies: 
--
-- Revision: 
-- 2013-07-29 JFC: File Created as a wrapper to chFPGA.vhdl 

---  LIBRARY DECLARATIONS -------------------------------------------------------------------------------
--! Standard libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;
--! Project libraries
use work.chFPGA_Package.all; --! Get all component definitions
        
----ENTITY DECLARATION ------------------------------------------------------------------------------
--! @brief This is the _top level_ entity of the CHIME ICEboard-based data acquisition/channelizer/correlator.  
--! The ports of this top-level entity correspond to physical pins on the Kintex 7 FPGA on that board. The location of these pins are defined in the constraint file. 
entity chFPGA_MGK7MB_Rev0 is
	 generic (
		PLATFORM_ID: INTEGER:= PLATFORM_ID_MGK7MB; --! identifies the type of platform on which the firmware is running. 0=ML605, 1=KC705
		UDP_MAC_PRESENT: BOOLEAN :=TRUE; --! Indicates if the Ethernet interface is to be implemented (sets the DYMMY flag on the MAC). Used for debugging only.
		BLINKER_PRESENT: BOOLEAN :=TRUE; --! Indicates if the LED flasher is to be implemented by setting the DUMMY flag of the BLINKER module
		SYSTEM_CLOCK_SOURCE: string := "SFP_REFCLK"; --!"SYSCLK": the 200 MHz clock will be taken from sysclk_p/n (CC pins) or "SFP_REFCLK": the system clock is 125 MHz from the GTX reference clock
		PHY_TYPE: string := "SGMII"; -- "GMII" or "SGMII"
		SGMII_CLOCK_SOURCE: string :="REFCLK"; --! Selects the 125MHz clock source for the SGMII interface; "CLK125": uses the 125 MHz clock (clk125) from the main MMCM, "REFCLK": uses the GTX Reference clock (gtrefclk)
		NUMBER_OF_ADCS: INTEGER := 16; --! Number of ADC Data acquisition blocks to implement 
		NUMBER_OF_CHANNELIZERS:INTEGER := 16; --! (0-NUMBER_OF_ADCS) Number of antenna processing blocks to be implemented 
		NUMBER_OF_CROSSBAR_INPUTS: integer := 16; --! (0-NUMBER_OF_CHANNELIZERS): Number of channelizers output that are being aligned, filtered and repacked for the corrleator or GPU links
--		NUMBER_OF_CROSSBAR_OUTPUTS: integer := 2; --! (0- ... ): Number of repacked data streams to feed to the corrleator or GPU links
		NUMBER_OF_CORRELATORS: INTEGER :=0; --! (0-NUMBER_OF_REORDER_OUTPUTS) Number of correlator blocks (CH_DIST+CORR+ACC) to be implemented if IMPLEMENT_CORR=TRUE
		NUMBER_OF_CHANNELIZERS_TO_CORRELATE: INTEGER :=GLOBAL_NUMBER_OF_CHANNELIZERS_TO_CORRELATE; --! (3 - NUMBER_OF_CHANNELIZERS) Number of channelizers outputs to be correlated for each frequency channel. This is hard coded for now. Determines how many antenna streams are fed to the CORR_BLOCK modules, and how many multipliers to implement in parallel in the CORR module.
		NUMBER_OF_GPU_LINKS: integer := GLOBAL_NUMBER_OF_GPU_LINKS; --! (0- NUMBER_OF_REORDER_OUTPUTS) Number of 10Gb Ethernet links to connecto to the GPUs
		NUMBER_OF_GPU_REFCLKS: integer := GLOBAL_NUMBER_OF_GPU_REFCLKS; --! Number of Reference clocks provided for the 10GE links to the GPU
		NUMBER_OF_I2C_PORTS: integer := 1;
		NUMBER_OF_SPI_PORTS: integer := 2; -- One port for each FMC
		NUMBER_OF_ADC_BOARDS: integer := 2; -- One SYNC for each FMC
		-- IMPLEMENT_ANT: BoolArray(0 to NUMBER_OF_CHANNELIZERS_MAX-1):=(others=>TRUE); --! Selects for which antenna a processing pipeline is implemented
		-- IMPLEMENT_FFT: BoolArray(0 to NUMBER_OF_CHANNELIZERS_MAX-1):=(others=>TRUE); --! Selects if the FFT block is implemented for each antenna (otherwise the timestream go through directly)
		-- IMPLEMENT_CORR: BoolArray(0 to NUMBER_OF_CORRELATORS_MAX-1):=(0 to 7=>TRUE, others=>FALSE); --! Indicates if the correlator blocks are to be implemented

		--! ADC_IS_DIFFERNTIAL indicates whether each ADC data and clock inputs are single-ended (zero value) or differential (non-zero value).  
		-- For Rev0 board
		ADC_IS_DIFFERENTIAL: BUFMRIndexArrayArray := (
			(0,1,1,1,1,1,1,1,  1), -- CH0 - Data bit 0 is on a single-ended FPGA pin. We have to make sure no IOP is inferred for the 'N' side of that line.
			(1,1,1,1,1,1,1,1,  0), -- CH1 - Clock is on a single ended FPGA pin. We have to make sure no IOP is inferred for the 'N' side of that line.
			(1,1,1,1,1,1,1,1,  1), -- CH2
			(1,1,1,1,1,1,1,1,  1), -- CH3
			(1,1,1,1,1,1,1,1,  1), -- CH4
			(1,1,1,1,1,1,1,1,  1), -- CH5
			(1,1,1,1,1,1,1,1,  1), -- CH6
			(1,1,1,1,1,1,1,1,  1),  -- CH7

			(0,1,1,1,1,1,1,1,  1),  -- CH8
			(1,1,1,1,1,1,1,1,  0),  -- CH9
			(1,1,1,1,1,1,1,1,  1),  -- CH10
			(1,1,1,1,1,1,1,1,  1),  -- CH11
			(1,1,1,1,1,1,1,1,  1),  -- CH12
			(1,1,1,1,1,1,1,1,  1),  -- CH13
			(1,1,1,1,1,1,1,1,  1),  -- CH14
			(1,1,1,1,1,1,1,1,  1)  -- CH15
			);

		--! ADC_INSTANTIATE_PLL determines which ADCDAQ need to instantiate a PLL to provide IOCLK and DIVCLK to ISERDES that are in non-adjacent banks, and to provide a BUFG-buffered global word clock.
		--! NOTE: A PLL (MMCM) could be used in theory for all data buses, but in practice we would run out of PLLs (there are only 2 per clock region).
		--! NOTE: On the Virtex 6, there is no fast clock routing for the outer IO pads to the PLL. So the use of a PLL is preferably limited to the center IO pads 
		ADC_PROVIDE_BUFFERED_DIVCLK: BoolArray( 0 to NUMBER_OF_ADCS_MAX-1):=( 0 => TRUE, others=>FALSE); --! ADC 0 will be used to provide the clock to generate the signal processing clocks for all antennas
		ADC_INSTANTIATE_PLL: BoolArray(0 to NUMBER_OF_ADCS_MAX-1):=(others=>FALSE); -- Need no PLL on this board. All deserialisers are acessible directly by the BUFRs and BUFIOs when using BUFMRs if necessary
		--! ADC_USE_EXT_DATA_CLK determines which ADC use the external (PLL-generated) IOCLK and DIVCLK. This is needed if the data bus lines end up in non-adjacent banks reachable by the IOBUF or BUFR.
		--! If FALSE, the clocks generated by IOCLK and BUFR will be used.
		--! NOTE: using a single PLL output for multiple ADC data buses is allowed, but that assumes that all data buses are relatively well in phase to be realigned with the IDELAY. This is reasonable assumption if all data buses come from the same ADC chip. It is not clear if this work well across multiple ADC chips.  
		ADC_USE_EXT_DATA_CLK: BoolArray(0 to NUMBER_OF_ADCS_MAX-1):=(others=>FALSE); -- On Rev0 board, the clock buffer fot CHAN1 is bad
		ADC_INSTANTIATE_BUFMR: BUFMRIndexArrayArray(0 to NUMBER_OF_ADCS_MAX-1):=(
			-- FMC A
			(others => 0), -- CH0: Data and clock in bank 14. We use a BUFMR to equalize delays with other channels. We have only one BUFR/BUFIO.
			(others => -1), -- CH1: Data and clock in bank 14. Clock is on SRCC. Cannot use BUFMR to equalize delays with other channels. We have only one BUFR/BUFIO.
			(1,1,0,0,0,0,0,0, 0), -- CH2: Clock in bank 13, Data in banks 12 and 13. We have a BUFR/BUFIO in each bank.
			(1,1,1,0,0,0,0,0, 0), -- CH3: Clock in bank 13, Data in banks 12 and 13. We have a BUFR/BUFIO in each bank.
			(others => 0), -- CH4: Data and clock in bank 11. We use a BUFMR to equalize delays with other channels. We have only one BUFR/BUFIO.
			(others => 0), -- CH5: Data and clock in bank 11. We use a BUFMR to equalize delays with other channels. We have only one BUFR/BUFIO.
			(others => 0), -- CH6: Data and clock in bank 12. We use a BUFMR to equalize delays with other channels. We have only one BUFR/BUFIO.
			(others => -1), -- CH7: Data and clock in bank 12. Clock is on SRCC. Cannot use BUFMR to equalize delays with other channels. We have only one BUFR/BUFIO.
			-- FMC B
			(others => 0), -- CH8: Clock in bank 16 (MRCC), data  in bank 16
			(others => -1), -- CH9: Clock in bank 16 (SRCC), data in bank 16. Cannot use BUFMR to equalize delays. 
			(1,1,2,2,2,0,2,0, 0), -- CH10: Clock in bank 17 (MRCC), Data in banks 16,17 and 18. 
			(1,1,1,0,0,0,0,0, 0), -- CH11: Clock in Bank 17 (MRCC), Dana in banks 17 and 18. 
			(others => 0), -- CH12: Clock in Bank 15 (MRCC), data in bank 15
			(others => 0), -- CH13: Clock in Bank 15 (MRCC), data in bank 15
			(0,0,0,1,0,0,0,0, 0), -- CH14: Clock in bank 18 (MRCC), data in banks 17 and 18
			(1,1,1,1,1,1,1,1, 0) -- CH15: Clock in bank 18 (MRCC), Data in Bank 17

			); --! For 7-Series only. Determines which BUFMR to use for each ADC bit (indices 0-7) and clock (index 8) , to allow access to BUFIOs and BUFRs in adjacent clocking regions. No BUFMR is instantiated if any index is negative. If all indices are 0 or more, one BUFMR is instantiated, and the corresponding BUFR/BUFIO will be used for each data/clock line
			--! NOTES on BUFMR/BUFIO/BUFIO assignments
			--! CH0: Data and clock in the same bank. We use a BUFMR to equalize delays on the word counter logic. 
			--! CH1: Used as the PLL clock source. We need a BUFMR. One BUFR is used for the clock IDELAY in Bank 17 . The other is used for the word counter logic in Bank 16 and the PLL. The BUFMR here equalize the delays caused by BUFMRs inother channels  
			--! CH2: Cannot use a BUFMR because clock is on a SRCC pin. Data lines and clock are NOT in same bank. This is why we use the PLL because we cannot do direct clocking.
			--! CH3: Data and clock lines spread between banks 17 and 18. Clock and logic is in Bank 17 . No need of a separate BUFR/BUFIO for data lines in bank 18. 
			--! CH4: Data and clock not in the same bank. We use one BUFMR,  and BUFR and BUFIO in banks 17 and 18 each.
			--! CH5: Data and clock all in same bank 12. We use one BUFMR to equalize delays only.
			--! CH6: Data and clock not in same bank. We use one BUFMR,  and BUFR and BUFIOs in banks 12 and 13 each.
			--! CH7: Data and clock all in same bank 18. Clock is on a SRCC pin, so we cannot use BUFMR to equalize delays.
		ANT_CLK_SOURCE: integer :=0; -- Indicate which ADC is the source of the antenna processing clock. Must be one that has ADC_INSTANTIATE_PLL=TRUE so we have a BUFG that can clock the logic across the chip
        
		GPU_CHANNEL_QUAD: IntegerArray := GLOBAL_GPU_CHANNEL_QUAD; -- Channels 0-3 use QUAD0, Channels 4-7 use QUAD1 
		GPU_QUAD_REFCLK: IntegerArray := GLOBAL_GPU_QUAD_REFCLK; -- Both QUAD0 and QUAD1 use refclk(0)
		SIM: BOOLEAN := GLOBAL_SIM--! Indicates this is running as a simulation. Used to accelerate simulations

	);
    PORT ( 
			------------------------------------
			-- SYSTEM
			------------------------------------

			-- Reset line
			cpu_reset_n: in STD_LOGIC; --! Hardware reset generated by the board
--			bp_io: out  STD_LOGIC_VECTOR(8 downto 0); --! Backplane IO
			bp_io0: out std_logic;
			bp_io1: inout std_logic;
			bp_io2: out std_logic;
			bp_io3: out std_logic;
			bp_io4: out std_logic;
			bp_io5: out std_logic;
			bp_io6: out std_logic;
			bp_io7: out std_logic;
			bp_io8: out std_logic;

			------------------------------------
			--  IIC/PMBus
			------------------------------------
			i2c_scl: inout STD_LOGIC; --!   (I2C) clock (bidirectional)
            i2c_sda: inout STD_LOGIC; --!   (I2C) data (bidirectional)

			------------------------------------
			-- SFP Module (Gbit Ethernet)
			------------------------------------

			-- SFP_LOS: out STD_LOGIC; --! SFP Loss of Signal flag

			sfp_clk_p: in STD_LOGIC; --! SFP reference clock, generated on-board using a high qualyty oscillator and used to synchronize the MGT used to communicate to the SFP. 
			sfp_clk_n: in STD_LOGIC;
			sfp_tx_p: out STD_LOGIC; --! Serialized data from the FPGA MGT to the SFP
			sfp_tx_n: out STD_LOGIC;
			sfp_rx_p: in STD_LOGIC; --! Serialized data from the SFP to the FPGA MGT 
			sfp_rx_n: in STD_LOGIC;

			xge_tx_p: out std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
			xge_tx_n: out std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
			xge_rx_p: in std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
			xge_rx_n: in std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
			xge_refclk_p: in std_logic_vector(0 to NUMBER_OF_GPU_REFCLKS-1);
			xge_refclk_n: in std_logic_vector(0 to NUMBER_OF_GPU_REFCLKS-1);

			sync_1v0_gtx: out std_logic;
			sync_3v3: out std_logic;
			sync_12v0: out std_logic;
			sync_5v0: out std_logic;
			sync_1v0: out std_logic;
			sync_vadj: out std_logic;
			sync_1v5: out std_logic;
			sync_1v8: out std_logic;
			sync_1v2: out std_logic;
			------------------------------------
			-- FMC
			------------------------------------

			-- ADC0 AH signals
			fmca_adc0_ahdp : in  STD_LOGIC_VECTOR (7 downto 0); --! AH data bus from the ADC chip 0 on the ADC board. This is DDR. The AL bus and overrange lines are not used.
			fmca_adc0_ahdn : in  STD_LOGIC_VECTOR (7 downto 0);
			fmca_adc0_adrp : in  STD_LOGIC; --! Data Ready line that clocks the AH data on each rising and falling edge (DDR)
			fmca_adc0_adrn : in  STD_LOGIC;

			-- ADC0 BH signals
			fmca_adc0_bhdp : in  STD_LOGIC_VECTOR (7 downto 0);--! BH data bus from the ADC chip 0 on the ADC board. This is DDR. The BL bus and overrange lines are not used.
			fmca_adc0_bhdn : in  STD_LOGIC_VECTOR (7 downto 0);
            fmca_adc0_bdrp : in  STD_LOGIC;  --! Data Ready line that clocks the BH data on each rising and falling edge (DDR)
--            fmca_adc0_bdrn : in  STD_LOGIC;

			-- ADC0 CH signals. Only 6 bits are available on the LPC FMC connector
			fmca_adc0_chdp : in  STD_LOGIC_VECTOR (7 downto 0); --! CH data bus from the ADC chip 0 on the ADC board. This is DDR. The CL bus and overrange lines are not used.
			fmca_adc0_chdn : in  STD_LOGIC_VECTOR (7 downto 0);
			fmca_adc0_cdrp : in  STD_LOGIC; --! Data Ready line that clocks the CH data on each rising and falling edge (DDR)
			fmca_adc0_cdrn : in  STD_LOGIC;

			-- ADC0 DH or CL  Only 5 bits are available on the FMC LPC connector.
			fmca_adc0_dhdp : in  STD_LOGIC_VECTOR (7 downto 0); --! DH data bus from the ADC chip 0 on the ADC board. This is DDR. The DL bus and overrange lines are not used.
			fmca_adc0_dhdn : in  STD_LOGIC_VECTOR (7 downto 0);
            fmca_adc0_ddrp : in  STD_LOGIC;  --! Data Ready line that clocks the DH data on each rising and falling edge (DDR)
            fmca_adc0_ddrn : in  STD_LOGIC;

			-- ADC1 port AH signals - Available on KC705 with FMC700 adapter
            fmca_adc1_ahdp : in  STD_LOGIC_VECTOR (7 downto 0); --! AH data bus from the ADC chip 1 on the ADC board. This is DDR. The AL bus and overrange lines are not used.
			fmca_adc1_ahdn : in  STD_LOGIC_VECTOR (7 downto 0);
			fmca_adc1_adrp : in  STD_LOGIC; --! Data Ready line that clocks the AH data on each rising and falling edge (DDR)
			fmca_adc1_adrn : in  STD_LOGIC;

			-- ADC1 port BH signals - Available on KC705 with FMC700 adapter
			fmca_adc1_bhdp : in  STD_LOGIC_VECTOR (7 downto 0); --! BH data bus from the ADC chip 1 on the ADC board. This is DDR. The BL bus and overrange lines are not used.
			fmca_adc1_bhdn : in  STD_LOGIC_VECTOR (7 downto 0);
			fmca_adc1_bdrp : in  STD_LOGIC; --! Data Ready line that clocks the BH data on each rising and falling edge (DDR)
			fmca_adc1_bdrn : in  STD_LOGIC;

			-- ADC1 port CH signals
			fmca_adc1_chdp : in  STD_LOGIC_VECTOR (7 downto 0); --! CH data bus from the ADC chip 1 on the ADC board. This is DDR. The CL bus and overrange lines are not used.
			fmca_adc1_chdn : in  STD_LOGIC_VECTOR (7 downto 0);
			fmca_adc1_cdrp : in  STD_LOGIC; --! Data Ready line that clocks the CH data on each rising and falling edge (DDR)
			fmca_adc1_cdrn : in  STD_LOGIC;

			-- ADC1 port DH signals
			fmca_adc1_dhdp : in STD_LOGIC_VECTOR (7 downto 0); --! DH data bus from the ADC chip 1 on the ADC board. This is DDR. The DL bus and overrange lines are not used.
			fmca_adc1_dhdn : in STD_LOGIC_VECTOR (7 downto 0);
			fmca_adc1_ddrp : in STD_LOGIC; --! Data Ready line that clocks the DH data on each rising and falling edge (DDR)
			fmca_adc1_ddrn : in STD_LOGIC;

			-- ADC RESET and SYNC signals
			fmca_adc_sync_p: out STD_LOGIC; --! SYNC signal to the ADC (or the recynchronization circuit that drives the ADC SYNC)
			fmca_adc_sync_n: out STD_LOGIC;
			fmca_adc_rst_n: out STD_LOGIC; --! Active LOW ADC reset line, common to both ADC chips. 
			
			--SPI signals
			fmca_spi_sck: out STD_LOGIC; --! SPI clock to the FPC. Typically 1 MHz.
			fmca_spi_miso: in STD_LOGIC; --! SPI data from the FMC
			fmca_spi_mosi: out STD_LOGIC; --! SPI data to the FMC
			fmca_spi_addr: out STD_LOGIC_VECTOR(2 downto 0); --! Address bus that selects which SPI device is enabled. Up to 8 devices are possible)
			fmca_spi_cs_n: out STD_LOGIC; --! On Rev0 MGADC08, it is the ADC PLL Latch Enable. On Rev2, is is an active LOW SPI_CS that enables the device selected by the address. 
			-- fmca_spi_rst_n: out STD_LOGIC; --! Active LOW reset for the SPI devices, namely the IO Expander. This line is used by REV0 boards, and is left floating by REV2 boards. Note that this LPC pinn is normally used by the PRSNT signal, which should normally be grounded by a FMC board when it is installed. 
			fmca_spi_rst_n_alt: out STD_LOGIC; --! Active LOW reset for the SPI devices, namely the IO Expander. This line is used by REV2 boards, and is left floating by REV0 boards.

			-- Buck control signals - Available on KC705 with FMC700 adapter
			fmca_buck1v8_sync: out STD_LOGIC; --! Clock used to synchronize the 3.3V Buck switching regulator
			fmca_buck3v3_sync: out STD_LOGIC; --! Clock used to synchronize the 1.8V Buck switching regulator

			-- FMC I2C signals: accessed through the IIC hub on KC705
--			FMC_I2C_SCK: inout STD_LOGIC; --! FMC I2C clock (bidirectional). Used to talk to the on-board EEPROM.
--			FMC_I2C_SDA: inout STD_LOGIC; --! FMC I2C data (bidirectional). Used to talk to the on-board EEPROM.
			-- FMC Reference clock -- Available on KC705 with FMC700 adapter

			fmca_refclk_m2c_p: in STD_LOGIC; --! copy of the 10 MHz reference clock received by the FMC board (through its SMA connector )and forwarded to the FPGA as a LVDS signal. May contain encoded SYNC information. 
			fmca_refclk_m2c_n: in STD_LOGIC;


			-- ADC0 AH signals
			fmcb_adc0_ahdp : in  STD_LOGIC_VECTOR (7 downto 0); --! AH data bus from the ADC chip 0 on the ADC board. This is DDR. The AL bus and overrange lines are not used.
			fmcb_adc0_ahdn : in  STD_LOGIC_VECTOR (7 downto 0);
			fmcb_adc0_adrp : in  STD_LOGIC; --! Data Ready line that clocks the AH data on each rising and falling edge (DDR)
			fmcb_adc0_adrn : in  STD_LOGIC;

			-- ADC0 BH signals
			fmcb_adc0_bhdp : in  STD_LOGIC_VECTOR (7 downto 0);--! BH data bus from the ADC chip 0 on the ADC board. This is DDR. The BL bus and overrange lines are not used.
			fmcb_adc0_bhdn : in  STD_LOGIC_VECTOR (7 downto 0);
            fmcb_adc0_bdrp : in  STD_LOGIC;  --! Data Ready line that clocks the BH data on each rising and falling edge (DDR)
            -- fmcb_adc0_bdrn : in  STD_LOGIC;

			-- ADC0 CH signals. Only 6 bits are available on the LPC FMC connector
			fmcb_adc0_chdp : in  STD_LOGIC_VECTOR (7 downto 0); --! CH data bus from the ADC chip 0 on the ADC board. This is DDR. The CL bus and overrange lines are not used.
			fmcb_adc0_chdn : in  STD_LOGIC_VECTOR (7 downto 0);
			fmcb_adc0_cdrp : in  STD_LOGIC; --! Data Ready line that clocks the CH data on each rising and falling edge (DDR)
			fmcb_adc0_cdrn : in  STD_LOGIC;

			-- ADC0 DH or CL  Only 5 bits are available on the FMC LPC connector.
			fmcb_adc0_dhdp : in  STD_LOGIC_VECTOR (7 downto 0); --! DH data bus from the ADC chip 0 on the ADC board. This is DDR. The DL bus and overrange lines are not used.
			fmcb_adc0_dhdn : in  STD_LOGIC_VECTOR (7 downto 0);
            fmcb_adc0_ddrp : in  STD_LOGIC;  --! Data Ready line that clocks the DH data on each rising and falling edge (DDR)
            fmcb_adc0_ddrn : in  STD_LOGIC;

			-- ADC1 port AH signals - Available on KC705 with FMC700 adapter
            fmcb_adc1_ahdp : in  STD_LOGIC_VECTOR (7 downto 0); --! AH data bus from the ADC chip 1 on the ADC board. This is DDR. The AL bus and overrange lines are not used.
			fmcb_adc1_ahdn : in  STD_LOGIC_VECTOR (7 downto 0);
			fmcb_adc1_adrp : in  STD_LOGIC; --! Data Ready line that clocks the AH data on each rising and falling edge (DDR)
			fmcb_adc1_adrn : in  STD_LOGIC;

			-- ADC1 port BH signals - Available on KC705 with FMC700 adapter
			fmcb_adc1_bhdp : in  STD_LOGIC_VECTOR (7 downto 0); --! BH data bus from the ADC chip 1 on the ADC board. This is DDR. The BL bus and overrange lines are not used.
			fmcb_adc1_bhdn : in  STD_LOGIC_VECTOR (7 downto 0);
			fmcb_adc1_bdrp : in  STD_LOGIC; --! Data Ready line that clocks the BH data on each rising and falling edge (DDR)
			fmcb_adc1_bdrn : in  STD_LOGIC;

			-- ADC1 port CH signals
			fmcb_adc1_chdp : in  STD_LOGIC_VECTOR (7 downto 0); --! CH data bus from the ADC chip 1 on the ADC board. This is DDR. The CL bus and overrange lines are not used.
			fmcb_adc1_chdn : in  STD_LOGIC_VECTOR (7 downto 0);
			fmcb_adc1_cdrp : in  STD_LOGIC; --! Data Ready line that clocks the CH data on each rising and falling edge (DDR)
			fmcb_adc1_cdrn : in  STD_LOGIC;

			-- ADC1 port DH signals
			fmcb_adc1_dhdp : in STD_LOGIC_VECTOR (7 downto 0); --! DH data bus from the ADC chip 1 on the ADC board. This is DDR. The DL bus and overrange lines are not used.
			fmcb_adc1_dhdn : in STD_LOGIC_VECTOR (7 downto 0);
			fmcb_adc1_ddrp : in STD_LOGIC; --! Data Ready line that clocks the DH data on each rising and falling edge (DDR)
			fmcb_adc1_ddrn : in STD_LOGIC;

			-- ADC RESET and SYNC signals
			fmcb_adc_sync_p: out STD_LOGIC; --! SYNC signal to the ADC (or the recynchronization circuit that drives the ADC SYNC)
			fmcb_adc_sync_n: out STD_LOGIC;
			fmcb_adc_rst_n: out STD_LOGIC; --! Active LOW ADC reset line, common to both ADC chips. 
			
			--SPI signals
			fmcb_spi_sck: out STD_LOGIC; --! SPI clock to the FPC. Typically 1 MHz.
			fmcb_spi_miso: in STD_LOGIC; --! SPI data from the FMC
			fmcb_spi_mosi: out STD_LOGIC; --! SPI data to the FMC
			fmcb_spi_addr: out STD_LOGIC_VECTOR(2 downto 0); --! Address bus that selects which SPI device is enabled. Up to 8 devices are possible)
			fmcb_spi_cs_n: out STD_LOGIC; --! On Rev0 MGADC08, it is the ADC PLL Latch Enable. On Rev2, is is an active LOW SPI_CS that enables the device selected by the address. 
			-- fmcb_spi_rst_n: out STD_LOGIC; --! Active LOW reset for the SPI devices, namely the IO Expander. This line is used by REV0 boards, and is left floating by REV2 boards. Note that this LPC pinn is normally used by the PRSNT signal, which should normally be grounded by a FMC board when it is installed. 
			fmcb_spi_rst_n_alt: out STD_LOGIC; --! Active LOW reset for the SPI devices, namely the IO Expander. This line is used by REV2 boards, and is left floating by REV0 boards.

			-- Buck control signals - Available on KC705 with FMC700 adapter
            fmcb_buck1v8_sync: out STD_LOGIC; --! Clock used to synchronize the 3.3V Buck switching regulator
            fmcb_buck3v3_sync: out STD_LOGIC; --! Clock used to synchronize the 1.8V Buck switching regulator
            			
			-- FMC I2C signals: accessed through the IIC hub on KC705
--			FMC_I2C_SCK: inout STD_LOGIC; --! FMC I2C clock (bidirectional). Used to talk to the on-board EEPROM.
--			FMC_I2C_SDA: inout STD_LOGIC; --! FMC I2C data (bidirectional). Used to talk to the on-board EEPROM.
			-- FMC Reference clock -- Available on KC705 with FMC700 adapter

			fmcb_refclk_m2c_p: in STD_LOGIC; --! copy of the 10 MHz reference clock received by the FMC board (through its SMA connector )and forwarded to the FPGA as a LVDS signal. May contain encoded SYNC information. 
			fmcb_refclk_m2c_n: in STD_LOGIC

			
			 );
end chFPGA_MGK7MB_Rev0;

---------- chFPGA implementaPLATFORM_ID_MGK7MBion ------
--! Implements the chFPGA CHIME PoC Data acquisition/channelizer/corrrlator for the KC705 evaluation board (equipped with a Kintex 7 7K355 FPGA). 
--! This simply instantiate the generic chFPGA code with the appropriate generics for that hardware platform.
--!
--! ADC1A and ADC1 B are accessed through the FMC700 adapter that combined the KC705 HPC and LPC connector to provide a full HPC port.
--! ADC1B (ANT[5]) uses  a BUFMR because the clock is in a different (but adjacent) bank than the data lines.

architecture Behavioral of chFPGA_MGK7MB_Rev0 is
	-- SIGNALS 

	attribute IOB: string;
	attribute DONT_TOUCH: string;

	-- Make sure IO buffers are not inferred for the 'N' signals of ADC lines that are connected to single-ended FPGA input pins (On the ICEBoard, a couple of FMC lines pass through a LVDS-to-single-ended receiver before going into the FPGA) 
	attribute IOB of fmca_adc0_ahdn : signal is "false";
	attribute IOB of fmcb_adc0_ahdn : signal is "false";
--	attribute IOB of fmca_adc0_bdrn : signal is "false";

	signal cpu_reset: std_logic;
	signal clk10_from_fpga: std_logic;
	signal USER_SMA_CLOCK_P: std_logic;
	signal USER_SMA_CLOCK_N: std_logic;
	signal USER_SMA_GPIO_N: std_logic;  

	signal sfp_status_vector: std_logic_vector(15 downto 0); -- Core status.
	signal sfp_mmcm_locked : std_logic;
	signal sfp_reset_done: std_logic;

	signal adc_data_p: SLV8_ARRAY(0 to NUMBER_OF_ADCS-1);
	signal adc_data_n: SLV8_ARRAY(0 to NUMBER_OF_ADCS-1);
	signal adc_clk_p: std_logic_vector(0 to NUMBER_OF_ADCS-1);
	signal adc_clk_n: std_logic_vector(0 to NUMBER_OF_ADCS-1);
	signal tx_ready: std_logic;

	signal adc_sync_p: std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1);
	signal adc_sync_n: std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1);
	signal fmcb_refclk_m2c: std_logic;
	signal buck_sync: std_logic_vector(0 to 15);
	signal adc_rst_n: std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1);

	signal spi_miso: std_logic_vector(0 to NUMBER_OF_SPI_PORTS-1);
	signal spi_mosi: std_logic;
	signal spi_addr: std_logic_vector(2 downto 0);
	signal spi_sck: std_logic;
	signal spi_cs_n: std_logic_vector(0 to NUMBER_OF_SPI_PORTS-1);
	signal spi_rst_n: std_logic;

	attribute DONT_TOUCH of fmcb_refclk_m2c : signal is "true";

begin

	-- cpu_reset <= not cpu_reset_n; --! Reset is active LOW on the ICEBoard
	cpu_reset <= '0'; --! ICEBoard reset held low when ARM is not clocked. We thereofre ignore it.
	bp_io0 <= clk10_from_fpga; -- BP_IO5/SMA-A Read: 
	bp_io1 <= USER_SMA_GPIO_N; -- BP_IO4/SMA-B/SW8 0
	bp_io2 <= USER_SMA_CLOCK_P; --BP_IO0_P/SW1 0
	bp_io3 <= USER_SMA_CLOCK_N; -- BP_IO0_N/SW2 1
	bp_io4 <= sfp_status_vector(0);-- Link status (active high), BP_IO1_P/SW3 1
	bp_io5 <= sfp_status_vector(1);-- Link sync'ed (active high), BP_IO1_N/SW4 1
	bp_io6 <= tx_ready; -- Rx IDLE, BP_IO2_P/SW5 1
	bp_io7 <= sfp_mmcm_locked; -- RXNOTINTABLE, BP_IO2_N/SW6 0
	bp_io8 <= sfp_reset_done; -- BP_IO3/SW7 1


--! Buck phase schedule
--! |  0 | 5V0      | Supply |
--! |  1 | 1V0_GTX  | 5V0    | GTX |
--! |  2 | 1V2      | 5V0    |
--! |  3 | 1V5      | 5V0    |
--! |  4 | 3V3      | Supply |
--! |  5 | 1V0      | 5V0    | FPGA Core logic |
--! |  6 | 1V8      | 5V0    |
--! |  7 | VADJ     | 5V0    |
--! |  8 | FMCA_1V8 | 5V0    |
--! |  9 | (unused) |        |
--! | 10 | FMCB_1V8 | 5V0    |
--! | 11 | (unused) |        |
--! | 12 | FMCA_3V3 | 5V0    |
--! | 13 | (unused) |        |
--! | 14 | FMCB_3V3 | 5V0    |
--! | 15 | (unused) |        |


	-- Assign motherboard buck sync
	-- These are held at '0' during reset and until the sync signals are explicitely enabled by software to allow the bucks to free-run.
	sync_12v0    <= '0';
	sync_5v0     <= buck_sync(0); -- large current
	sync_1v0_gtx <= buck_sync(1);
	sync_1v0     <= buck_sync(5);
	sync_1v2     <= buck_sync(2);
	sync_1v5     <= buck_sync(3);
	sync_1v8     <= buck_sync(6);
	sync_vadj    <= buck_sync(7);
	sync_3v3     <= buck_sync(4); -- large current

	-- bp_io(0) <= clk200; -- BP_IO5/SMA-A Read: 
	-- bp_io(1) <= sfp_refclk; -- BP_IO4/SMA-B/SW8 0
	-- bp_io(2) <= mmcm_locked; --BP_IO0_P/SW1 0
	-- bp_io(3) <= reset_done; -- BP_IO0_N/SW2 1
	-- bp_io(4) <= status_vector(0);-- Link status (active high), BP_IO1_P/SW3 1
	-- bp_io(5) <= status_vector(1);-- Link sync'ed (active high), BP_IO1_N/SW4 1
	-- bp_io(6) <= status_vector(3); -- Rx IDLE, BP_IO2_P/SW5 1
	-- bp_io(7) <= status_vector(6); -- RXNOTINTABLE, BP_IO2_N/SW6 0
	-- bp_io(8) <= reset; -- BP_IO3/SW7 1


	IBUFGDS1 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair   
		generic map( 
			DIFF_TERM => TRUE
		)
		port map (
			I=>fmcb_refclk_m2c_p,
			IB=>fmcb_refclk_m2c_n,
			O=>fmcb_refclk_m2c
		);

adc_data_p <= (fmca_adc0_ahdp , fmca_adc0_bhdp,  fmca_adc0_chdp , fmca_adc0_dhdp , fmca_adc1_ahdp , fmca_adc1_bhdp , fmca_adc1_chdp , fmca_adc1_dhdp, fmcb_adc0_ahdp , fmcb_adc0_bhdp,  fmcb_adc0_chdp , fmcb_adc0_dhdp , fmcb_adc1_ahdp , fmcb_adc1_bhdp , fmcb_adc1_chdp , fmcb_adc1_dhdp);
adc_data_n <= (fmca_adc0_ahdn , fmca_adc0_bhdn,  fmca_adc0_chdn , fmca_adc0_dhdn , fmca_adc1_ahdn , fmca_adc1_bhdn , fmca_adc1_chdn , fmca_adc1_dhdn, fmcb_adc0_ahdn , fmcb_adc0_bhdn,  fmcb_adc0_chdn , fmcb_adc0_dhdn , fmcb_adc1_ahdn , fmcb_adc1_bhdn , fmcb_adc1_chdn , fmcb_adc1_dhdn);
adc_clk_p <=  (fmca_adc0_adrp & fmca_adc0_bdrp & fmca_adc0_cdrp &  fmca_adc0_ddrp & fmca_adc1_adrp & fmca_adc1_bdrp & fmca_adc1_cdrp & fmca_adc1_ddrp & fmcb_adc0_adrp & fmcb_adc0_bdrp & fmcb_adc0_cdrp &  fmcb_adc0_ddrp & fmcb_adc1_adrp & fmcb_adc1_bdrp & fmcb_adc1_cdrp & fmcb_adc1_ddrp);
adc_clk_n <=  (fmca_adc0_adrn & '0'            & fmca_adc0_cdrn &  fmca_adc0_ddrn & fmca_adc1_adrn & fmca_adc1_bdrn & fmca_adc1_cdrn & fmca_adc1_ddrn & fmcb_adc0_adrn & '0'            & fmcb_adc0_cdrn &  fmcb_adc0_ddrn & fmcb_adc1_adrn & fmcb_adc1_bdrn & fmcb_adc1_cdrn & fmcb_adc1_ddrn);

fmca_buck1v8_sync <= buck_sync(8);
fmcb_buck1v8_sync <= buck_sync(10);
fmca_buck3v3_sync <= buck_sync(12);
fmcb_buck3v3_sync <= buck_sync(14);

fmca_adc_sync_p <= adc_sync_p(0);
fmca_adc_sync_n <= adc_sync_n(0);
fmcb_adc_sync_p <= adc_sync_p(1);
fmcb_adc_sync_n <= adc_sync_n(1);

fmca_adc_rst_n <= adc_rst_n(0);
fmcb_adc_rst_n <= adc_rst_n(1);

spi_miso(0) <= fmca_spi_miso;
fmca_spi_mosi <= spi_mosi;
fmca_spi_addr <= spi_addr;
fmca_spi_sck <= spi_sck;
fmca_spi_cs_n <= spi_cs_n(0);
fmca_spi_rst_n_alt <= spi_rst_n;

spi_miso(1) <= fmcb_spi_miso;
fmcb_spi_mosi <= spi_mosi;
fmcb_spi_addr <= spi_addr;
fmcb_spi_sck <= spi_sck;
fmcb_spi_cs_n <= spi_cs_n(1);
fmcb_spi_rst_n_alt <= spi_rst_n;

	chfpga0: entity work.chFPGA 
		GENERIC MAP(
			PLATFORM_ID => PLATFORM_ID, 
			BLINKER_PRESENT=>BLINKER_PRESENT,
			SYSTEM_CLOCK_SOURCE => SYSTEM_CLOCK_SOURCE,
			PHY_TYPE => PHY_TYPE,
			SGMII_CLOCK_SOURCE => SGMII_CLOCK_SOURCE,
			NUMBER_OF_ADCS =>NUMBER_OF_ADCS,
			NUMBER_OF_CHANNELIZERS=>NUMBER_OF_CHANNELIZERS,
			NUMBER_OF_CORRELATORS=>NUMBER_OF_CORRELATORS,
			NUMBER_OF_CROSSBAR_INPUTS=>NUMBER_OF_CROSSBAR_INPUTS,
--			NUMBER_OF_CROSSBAR_OUTPUTS=>NUMBER_OF_CROSSBAR_OUTPUTS,
			NUMBER_OF_GPU_LINKS => NUMBER_OF_GPU_LINKS,
			NUMBER_OF_GPU_REFCLKS => NUMBER_OF_GPU_REFCLKS,
			NUMBER_OF_I2C_PORTS => NUMBER_OF_I2C_PORTS,
			NUMBER_OF_SPI_PORTS => NUMBER_OF_SPI_PORTS,
			NUMBER_OF_ADC_BOARDS => NUMBER_OF_ADC_BOARDS,
			-- IMPLEMENT_ANT=>IMPLEMENT_ANT, -- Selects for which antenna a processing pipeline is implemented
			-- IMPLEMENT_FFT=>IMPLEMENT_FFT, -- Selects if the FFT block is implemented for each antenna (otherwise the timestream go through directly)
			-- IMPLEMENT_CORR=>IMPLEMENT_CORR, 
			ADC_IS_DIFFERENTIAL => ADC_IS_DIFFERENTIAL,
			ADC_PROVIDE_BUFFERED_DIVCLK => ADC_PROVIDE_BUFFERED_DIVCLK,
			ADC_INSTANTIATE_PLL=>ADC_INSTANTIATE_PLL,
			ADC_USE_EXT_DATA_CLK=>ADC_USE_EXT_DATA_CLK,
			ADC_INSTANTIATE_BUFMR=>ADC_INSTANTIATE_BUFMR,
			ANT_CLK_SOURCE=>ANT_CLK_SOURCE,
			GPU_CHANNEL_QUAD => GPU_CHANNEL_QUAD,
			GPU_QUAD_REFCLK => GPU_QUAD_REFCLK,
			SIM=>SIM
			)
		PORT MAP(
			-- System
			CPU_RESET    => cpu_reset,
			GPIO_BUTTON0 => '0',
			GPIO_LED     => open,
			
			SYSCLK_P     => '0',
			SYSCLK_N     => '1',
			
			GPIO_DIP_SW  => (others=>'0'), 
			
			-- LCD
			
			LCD_DB       => open, 
			LCD_E        => open,
			LCD_RS       => open,
			LCD_RW       => open,

			-- Fan
			FAN_PWM  => open,
			FAN_TACH => '0',

			-- PHY
			 -- PHY_RXCLK => PHY_RXCLK,
			 -- PHY_TXER => PHY_TXER,
			 -- PHY_RESET_L => PHY_RESET_L,
			 -- PHY_RXCTRL_RXDV => PHY_RXCTRL_RXDV,
			 -- PHY_RXD => PHY_RXD,
			 -- PHY_TXC_GTXCLK => PHY_TXC_GTXCLK,
			 -- PHY_TXCTL_TXEN => PHY_TXCTL_TXEN,
			 -- PHY_TXD => PHY_TXD,
			 -- PHY_TXCLK => PHY_TXCLK,

			-- SFP
			-- sfp_los     => '0',
			sfp_clk_p => sfp_clk_p,
			sfp_clk_n => sfp_clk_n,
			sfp_tx_p    => sfp_tx_p,
			sfp_tx_n    => sfp_tx_n,
			sfp_rx_p    => sfp_rx_p,
			sfp_rx_n    => sfp_rx_n,

			sfp_status_vector => sfp_status_vector,
			sfp_mmcm_locked => sfp_mmcm_locked,
			sfp_reset_done => sfp_reset_done,
			tx_ready => tx_ready,


			xge_tx_p => xge_tx_p,
			xge_tx_n => xge_tx_n,
			xge_rx_p => xge_rx_p,
			xge_rx_n => xge_rx_n,
			xge_refclk_p => xge_refclk_p,
			xge_refclk_n => xge_refclk_n,

	        -- PMBus (I2C) interface
			-- pmbus_sck => fcmb_i2c_scl,
			-- pmbus_sda => fmcb_i2c_sda,

			USER_SMA_GPIO_P  => clk10_from_fpga, -- 10 MHz reference clock generated by FPGA. 
			USER_SMA_GPIO_N  => USER_SMA_GPIO_N, -- SYNC signal input/output. IOBUF is instantiated explicitely. Must be connected to an inout port
			USER_SMA_CLOCK_P => USER_SMA_CLOCK_P,
			USER_SMA_CLOCK_N => USER_SMA_CLOCK_N,

			---------------------------
			-- FMC
			---------------------------
			-- Buck sync
			buck_sync => buck_sync,

			-- FMC Reference clock
			refclk_m2c_p => fmca_refclk_m2c_p,
			refclk_m2c_n => fmca_refclk_m2c_n,

			-- FMC ADCs
			adc_data_p => adc_data_p,
			adc_data_n => adc_data_n,
			adc_clk_p => adc_clk_p,
			adc_clk_n => adc_clk_n,

			adc_sync_p       => adc_sync_p,
			adc_sync_n       => adc_sync_n,
			ADC_RST_N        => adc_rst_n,
			

			-- FMC SPI
			spi_miso      => spi_miso,
			spi_mosi      => spi_mosi,
			spi_addr      => spi_addr,
			spi_sck       => spi_sck,
			spi_cs_n      => spi_cs_n,
			spi_rst_n     => spi_rst_n,
--			spi_rst_n_alt => fmca_spi_rst_n_alt, 
			
			-- I2C signals
			i2c_scl(0) => i2c_scl,
			i2c_sda(0) => i2c_sda
			);

end Behavioral;

