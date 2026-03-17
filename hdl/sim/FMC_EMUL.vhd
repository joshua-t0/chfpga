----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:32:13 03/12/2011 
-- Design Name: 
-- Module Name:    FMC_EMUL - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
-- 111004 JFC: Added SYNC

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--library work;
--use work.chFPGA_Package.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FMC_EMUL is
		 GENERIC (
			PRESENT: BOOLEAN := TRUE;
			SAMPLING_FREQUENCY: real
		);

	PORT(
		ADC_RESET : IN std_logic;

		ADC0_AHDP : OUT std_logic_vector(7 downto 0);
		ADC0_AHDN : OUT std_logic_vector(7 downto 0);
		ADC0_ADRP : OUT std_logic;
		ADC0_ADRN : OUT std_logic;

		ADC0_BHDP_ALDP : OUT std_logic_vector(7 downto 0);
		ADC0_BHDN_ALDN : OUT std_logic_vector(7 downto 0);
		ADC0_BDRP : OUT std_logic;
		ADC0_BDRN : OUT std_logic;

		ADC0_CHDP : OUT std_logic_vector(7 downto 0);
		ADC0_CHDN : OUT std_logic_vector(7 downto 0);
		ADC0_CDRP : OUT std_logic;
		ADC0_CDRN : OUT std_logic;

		ADC0_DHDP_CLDP : OUT std_logic_vector(7 downto 0);
		ADC0_DHDN_CLDN : OUT std_logic_vector(7 downto 0);
		ADC0_DDRP : OUT std_logic;
		ADC0_DDRN : OUT std_logic;

		ADC1_AHDP : OUT std_logic_vector(7 downto 0);
		ADC1_AHDN : OUT std_logic_vector(7 downto 0);
		ADC1_ADRP : OUT std_logic;
		ADC1_ADRN : OUT std_logic;

		ADC1_BHDP_ALDP : OUT std_logic_vector(7 downto 0);
		ADC1_BHDN_ALDN : OUT std_logic_vector(7 downto 0);
		ADC1_BDRP : OUT std_logic;
		ADC1_BDRN : OUT std_logic;
		ADC1_CHDP : OUT std_logic_vector(7 downto 0);
		ADC1_CHDN : OUT std_logic_vector(7 downto 0);
		ADC1_CDRP : OUT std_logic;
		ADC1_CDRN : OUT std_logic;
		ADC1_DHDP_CLDP : OUT std_logic_vector(7 downto 0);
		ADC1_DHDN_CLDN : OUT std_logic_vector(7 downto 0);
		ADC1_DDRP : OUT std_logic;
		ADC1_DDRN : OUT std_logic;          

		ADC_SYNCP : IN std_logic;
		ADC_SYNCN : IN std_logic;

		-----------------------
		-- SPI Interface ------
		-----------------------

		SPI_MISO : OUT std_logic;          
		SPI_MOSI : IN std_logic:='0';          
		SPI_ADDR : IN std_logic_vector (2 downto 0):="000";
		SPI_SCK : IN std_logic:='0';
		

		-----------------------
		-- PLL Interface ------
		-----------------------

		PLL_LE: IN std_logic:='0';


		-----------------------
		-- I2C Interface ------
		-----------------------

		I2C_SDI: INOUT std_logic:='0';
		I2C_SCK: IN std_logic:='0';

		--------------------------------
		-- 10 MHz reference clock ------
		--------------------------------

		REFCLK_C2M_P: IN std_logic:='0';
		REFCLK_C2M_N: IN std_logic:='1';

		REFCLK_M2C_P: OUT std_logic;
		REFCLK_M2C_N: OUT std_logic
		
		);

end FMC_EMUL;

architecture Behavioral of FMC_EMUL is



-- ADC Clock
signal ADC_CLK : std_logic;
--constant adc_clk_period : TIME := 0.625 ns; -- 1.6 GHz, which will generate a 800 MHz sampling rate and 400 MHz DDR clock in 4 channel non-DMUX mode
--constant adc_clk_period : TIME := 0.588235294 ns; -- 1.7 GHz, which will generate a 850 MHz sampling rate and 425 MHz DDR clock in 4 channel non-DMUX mode
constant adc_clk_period : TIME := 1.0/SAMPLING_FREQUENCY/2.0 * 1 sec; 

begin

pres: if PRESENT generate

REFCLK_M2C_P <= REFCLK_C2M_P;
REFCLK_M2C_N <= REFCLK_C2M_N;

SPI_SLAVE0: entity work.SPI_SLAVE 
	GENERIC MAP (
		ADDRESS=>4,
		READ_VALUE=>X"A028"
		)
	PORT MAP(
		SPI_SCK => SPI_SCK,
		SPI_MISO => SPI_MISO,
		SPI_MOSI => SPI_MOSI,
		SPI_ADDR => SPI_ADDR,
		SPI_RST_N => '1',
		RST => '0'
	);


--DMUXFALSE: if ADC_DMUX=FALSE generate
    ADC0: entity work.EV8AQ160
			GENERIC MAP
				( DMUX => FALSE, CHANNELS => 4)
			PORT MAP (
          CLK => ADC_CLK,

          AHP => ADC0_AHDP,
          AHN => ADC0_AHDN,
          ALP => open,
          ALN => open,
          ADRP => ADC0_ADRP,
          ADRN => ADC0_ADRN,
			 
          BHP => ADC0_BHDP_ALDP,
          BHN => ADC0_BHDN_ALDN,
          BLP => open,
          BLN => open,
          BDRP => ADC0_BDRP,
          BDRN => ADC0_BDRN,
			 
          CHP => ADC0_CHDP,
          CHN => ADC0_CHDN,
          CLP => open,
          CLN => open,
          CDRP => ADC0_CDRP,
          CDRN => ADC0_CDRN,

          DHP => ADC0_DHDP_CLDP,
          DHN => ADC0_DHDN_CLDN,
          DLP => open,
          DLN => open,
          DDRP => ADC0_DDRP,
          DDRN => ADC0_DDRN,

			SYNCP=>ADC_SYNCP,
			SYNCN=>ADC_SYNCN,
			 
			 AAI => 0.0,
			 BAI => 0.0,
			 CAI => 0.0,
			 DAI => 0.0
        );

    ADC1: entity work.EV8AQ160
			GENERIC MAP
				( DMUX => FALSE, CHANNELS => 4)
			PORT MAP (
          CLK => ADC_CLK,

          AHP => ADC1_AHDP,
          AHN => ADC1_AHDN,
          ALP => open,
          ALN => open,
          ADRP => ADC1_ADRP,
          ADRN => ADC1_ADRN,
			 
          BHP => ADC1_BHDP_ALDP,
          BHN => ADC1_BHDN_ALDN,
          BLP => open,
          BLN => open,
          BDRP => ADC1_BDRP,
          BDRN => ADC1_BDRN,
			 
          CHP => ADC1_CHDP,
          CHN => ADC1_CHDN,
          CLP => open,
          CLN => open,
          CDRP => ADC1_CDRP,
          CDRN => ADC1_CDRN,

          DHP => ADC1_DHDP_CLDP,
          DHN => ADC1_DHDN_CLDN,
          DLP => open,
          DLN => open,
          DDRP => ADC1_DDRP,
          DDRN => ADC1_DDRN,

			SYNCP=>ADC_SYNCP,
			SYNCN=>ADC_SYNCN,
			 
			 AAI => 0.0,
			 BAI => 0.0,
			 CAI => 0.0,
			 DAI => 0.0
        );

   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
    adc_clk_process: process (all)
		begin
			if rising_edge(REFCLK_C2M_P) then
				ADC_CLK <= '1';
				ADC_CLK <= '0' after adc_clk_period/2;
			elsif falling_edge(ADC_CLK) then
				ADC_CLK <= '1' after adc_clk_period/2;
			elsif rising_edge(ADC_CLK) then
				ADC_CLK <= '0' after adc_clk_period/2;
			end if;
--			ADC_CLK <= '0';
--			wait for adc_clk_period/2;
--			ADC_CLK<= '1';
--			wait for adc_clk_period/2;
		end process;

end generate;

GEN0: if not present generate
	REFCLK_M2C_P <= '0';
	REFCLK_M2C_N <= '1';
end generate;

end Behavioral;

