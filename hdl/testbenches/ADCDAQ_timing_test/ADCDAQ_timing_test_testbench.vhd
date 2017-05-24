--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:23:04 11/17/2010
-- Design Name:   
-- Module Name:   C:/Xilinx/work/CHIME/SP605_test2/ADCDAQ/ADC_IOSERDES_testbench.vhd
-- Project Name:  ADCDAQ
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ADC_IOSERDES
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

--library work;
--USE work.chFPGA_Package.all;
 
ENTITY chFPGA_ML605_testbench IS
	 GENERIC (
		ADC_DMUX: BOOLEAN :=FALSE; -- set to TRUE if ports A and C are used in DMUX1:2 mode.
		FFT_PRESENT: BOOLEAN :=FALSE -- set to TRUE if ADCDAQ module is instantiated. Otherwise dummy instances of the differential port receivers will be instantiated to prevent errors
		);


END chFPGA_ML605_testbench;


ARCHITECTURE behavior OF chFPGA_ML605_testbench IS 

component ADCDAQ_TEST_TOP is

    PORT ( 

			-- Reset line
			CPU_RESET: in  STD_LOGIC;

			-- 200 MHz system clock
			SYSCLK_P : in  STD_LOGIC;
			SYSCLK_N : in  STD_LOGIC;


			-- ADC1 port BH or AL (in case DMUX mode is used. Jumpers select which bus is routed)
			ADC1_DHDP_CLDP : in  STD_LOGIC_VECTOR (7 downto 0);
			ADC1_DHDN_CLDN : in  STD_LOGIC_VECTOR (7 downto 0);
			ADC1_DDRP : in  STD_LOGIC;
			ADC1_DDRN : in  STD_LOGIC;

			ADC_DATA: out STD_LOGIC_VECTOR(31 downto 0)
			 );
end component;
COMPONENT EV8AQ160 is
	 GENERIC (
			DMUX :boolean :=FALSE; -- Is the output Demuxed between the High and Low bytes? (TRUE or FALSE)
			CHANNELS : INTEGER := 4 -- Number of output channels (1, 2 or 4)
	);
	 
    Port ( CLK : in  STD_LOGIC; -- Clock privided at the input of the ADC. The internal sampling clocks are half that rate (although they operate in DDR)

           AHP : out  STD_LOGIC_VECTOR (7 downto 0); -- A Data
           AHN : out  STD_LOGIC_VECTOR (7 downto 0); -- A Data
           ALP : out  STD_LOGIC_VECTOR (7 downto 0); -- A Data (DMUX Mode only)
           ALN : out  STD_LOGIC_VECTOR (7 downto 0); -- A Data (DMUX Mode only)

           BHP : out  STD_LOGIC_VECTOR (7 downto 0);
           BHN : out  STD_LOGIC_VECTOR (7 downto 0);
           BLP : out  STD_LOGIC_VECTOR (7 downto 0);
           BLN : out  STD_LOGIC_VECTOR (7 downto 0);

           CHP : out  STD_LOGIC_VECTOR (7 downto 0);
           CHN : out  STD_LOGIC_VECTOR (7 downto 0);
           CLP : out  STD_LOGIC_VECTOR (7 downto 0);
           CLN : out  STD_LOGIC_VECTOR (7 downto 0);

           DHP : out  STD_LOGIC_VECTOR (7 downto 0);
           DHN : out  STD_LOGIC_VECTOR (7 downto 0);
           DLP : out  STD_LOGIC_VECTOR (7 downto 0);
           DLN : out  STD_LOGIC_VECTOR (7 downto 0);

           AAI : in  REAL;
           BAI : in  REAL;
          CAI : in  REAL;
         DAI : in  REAL;

           ADRP : out  STD_LOGIC;	-- DDR Output clock for AH Data (and AL Data if DMUS mode is used)
           ADRN : out  STD_LOGIC;	-- DDR Output clock for AH Data (and AL Data if DMUS mode is used)

           BDRP : out  STD_LOGIC;
           BDRN : out  STD_LOGIC;

           CDRP : out  STD_LOGIC;
           CDRN : out  STD_LOGIC;

           DDRP : out  STD_LOGIC;
           DDRN : out  STD_LOGIC;

           SYNCP : in  STD_LOGIC;
           SYNCN : in  STD_LOGIC
			  
			  );
end COMPONENT;



 
   --Inputs
   signal CPU_RESET : std_logic := '0';
   signal SYSCLK_P : std_logic := '0';
   signal SYSCLK_N : std_logic := '0';


 
--   signal ADC0_AHDP,ADC0_AHDN, ADC0_BHDP_ALDP, ADC0_BHDN_ALDN: std_logic_vector(7 downto 0) := (others => '0');
--   signal ADC0_CHDP,ADC0_CHDN, ADC0_DHDP_CLDP, ADC0_DHDN_CLDN: std_logic_vector(7 downto 0) := (others => '0');
--   signal ADC1_AHDP,ADC1_AHDN, ADC1_BHDP_ALDP, ADC1_BHDN_ALDN: std_logic_vector(7 downto 0) := (others => '0');
   signal  ADC1_DHDP_CLDP, ADC1_DHDN_CLDN: std_logic_vector(7 downto 0) := (others => '0');
 
   signal ADC1_DDRP : std_logic := '0';
   signal ADC1_DDRN : std_logic := '1';

	signal ADC_SYNC_P : STD_LOGIC :='0';
	signal ADC_SYNC_N : STD_LOGIC :='1';
	


   -- Clock period definitions
   constant CLK125_period : time := 8 ns;
   constant SYSCLK_period : time := 5 ns;
   constant FMC_REFCLK_period : time := 100 ns;

signal CLK125:   STD_LOGIC;

--   signal SUM_OUT : std_logic_vector(63 downto 0);
 signal ADC_CLK : std_logic;
constant adc_clk_period : TIME := 0.625 ns; -- 1.6 GHz, which will generate a 800 MHz sampling rate and 400 MHz DDR clock in 4 channel non-DMUX mode


BEGIN

--	-- Instantiate the Unit Under Test (UUT)
CHFPGA0: ADCDAQ_TEST_TOP 
	PORT MAP(
		-- System
		 CPU_RESET => CPU_RESET,
		 SYSCLK_P => SYSCLK_P,
		 SYSCLK_N => SYSCLK_N,

		ADC1_DHDP_CLDP => ADC1_DHDP_CLDP,
		ADC1_DHDN_CLDN => ADC1_DHDN_CLDN,
		ADC1_DDRP => ADC1_DDRP,
		ADC1_DDRN => ADC1_DDRN


		
		);
 

 adc_clk_process :process
   begin
		ADC_CLK <= '0';
		wait for adc_clk_period/2;
		ADC_CLK<= '1';
		wait for adc_clk_period/2;
   end process;

SYSCLK_process :process
   begin
		SYSCLK_P <= '0';
		SYSCLK_N <= '1';
		wait for SYSCLK_period/2;
		SYSCLK_P <= '1';
		SYSCLK_N <= '0';
		wait for SYSCLK_period/2;
   end process;

 ADC0: EV8AQ160
			GENERIC MAP
				( DMUX => FALSE, CHANNELS => 4)
			PORT MAP (
          CLK => ADC_CLK,

          AHP => open,
          AHN => open,
          ALP => open,
          ALN => open,
          ADRP => open,
          ADRN => open,
			 
          BHP => open,
          BHN => open,
          BLP => open,
          BLN => open,
          BDRP => open,
          BDRN => open,
			 
          CHP => open,
          CHN => open,
          CLP => open,
          CLN => open,
          CDRP => open,
          CDRN => open,

          DHP =>   ADC1_DHDP_CLDP,
          DHN =>   ADC1_DHDN_CLDN,
          DLP => open,
          DLN => open,
          DDRP => ADC1_DDRP,
          DDRN => ADC1_DDRN,

			SYNCP=>'0',
			SYNCN=>'1',
			
			 AAI => 0.0,
			 BAI => 0.0,
			 CAI => 0.0,
			 DAI => 0.0
        );


   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		CPU_RESET<='1';
		wait for 10*SYSCLK_period;	
		CPU_RESET<='0';
		wait for 10*SYSCLK_period;	      -- insert stimulus here 

      wait;
   end process;


---------------------------------------------------------------------
-- Instantiate UDP / IP / Ethernet interface to talk to the PHY 
---------------------------------------------------------------------


phy_process: process
	begin
	wait for 250 ns;  -- make sure the clocks are stabilized
	
	end process;
	
END;
