----------------------------------------------------------------------------------
-- Company: McGill University 
-- Engineer: JF Cliche
-- 
-- Create Date:    2011-05-19 
-- Design Name:    chFPGA_PoC
-- Module Name:    top - Behavioral 
-- Project Name: CHIME
-- Target Devices: Virtex6 on ML605 Evaluation board 
-- Tool versions: ISE 13.1
-- Description: Top level implementation of chFPGA Proof of Concept (PoC) the ML605-based system
--
-- Dependencies: 
--
-- Revision: 
-- 2010-10-31 JFC: SP605 File Created
-- 2011-03-12 JFC: SP605 COmplete makeover to generalize the module: make the system more modular
-- 2011-05-19 JFC: Copied from SP605 and modified for ML605
-- 2011-07-12 JFC: New structure: ADCDAQ is now within the antenna processors
 



-- Additional Comments: 
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


library UNISIM;
use UNISIM.VComponents.all;

use work.chFPGA_Package.all; -- Get all component definitions

entity ADCDAQ_TEST_TOP is

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
end chFPGA_V6;



architecture Behavioral of ADCDAQ_TEST_TOP is

-- ==================================================
-- ========== SIGNALS ==============================
-- ==================================================


-- Clocks & global reset
signal CLK125: std_logic; -- 125 MHz clock  
signal CLK200: std_logic; -- 200 MHz clock  
signal CLK25: std_logic; -- 25 MHz clock  
signal RESET: std_logic; -- Internal RESET after the clocks are stable  
signal USER_RESET: std_logic:='0'; -- User-controlled global reset



signal CTRL_CLK:   STD_LOGIC;

-- ADC Sync
signal ADC_READY:   STD_LOGIC; 


  

begin




-- Assign the ADC bytes to an array for easier indexing

--ADC_DATA_P<=(ADC0_AHDP , ADC0_BHDP_ALDP,  ADC0_CHDP , ADC0_DHDP_CLDP , ADC1_AHDP , ADC1_BHDP_ALDP , ADC1_CHDP , ADC1_DHDP_CLDP);
--ADC_DATA_N<=(ADC0_AHDN ,ADC0_BHDN_ALDN,  ADC0_CHDN , ADC0_DHDN_CLDN , ADC1_AHDN , ADC1_BHDN_ALDN , ADC1_CHDN , ADC1_DHDN_CLDN);

--ADC_CLK_P <= (ADC0_ADRP & ADC0_BDRP & ADC0_CDRP &  ADC0_DDRP & ADC1_ADRP & ADC1_BDRP & ADC1_CDRP & ADC1_DDRP);
--ADC_CLK_N <= (ADC0_ADRN & ADC0_BDRN & ADC0_CDRN &  ADC0_DDRN & ADC1_ADRN & ADC1_BDRN & ADC1_CDRN & ADC1_DDRN);

-------------------------------------------------------------------
-- Instantiate System clocks
-------------------------------------------------------------------

  
CLK0: CLOCKS_V6
	port map
		(
		-- System clock input
		SYSCLK_P=>SYSCLK_P,
		SYSCLK_N=>SYSCLK_N,
		-- Clocks using the internal clock manager
		CLK125 => CLK125,
		CLK200 => CLK200,
		CLK25=>CLK25, -- generate 25 MHz clock for FMC board PLL reference
		-- Reset
		RST_IN=>CPU_RESET or USER_RESET,
		RST_OUT=>RESET
		);

ADCDAQ0: ADC_DAQ_V6 
		GENERIC MAP(
			USE_DMUX =>FALSE,
			USE_PLL=>FALSE, -- Use array to select whether a PLL should be used for this instance.
			USE_BUFG=>FALSE, -- 
			INSTANTIATE_IDELAYCTRL=>TRUE
			)
	    PORT MAP(
            ADC_DATA_H_P => ADC1_DHDP_CLDP,
            ADC_DATA_H_N => ADC1_DHDN_CLDN,
            ADC_CLK_H_P => ADC1_DDRP, 
            ADC_CLK_H_N => ADC1_DDRN, 
 
			ADC_DATA_L_P => (others=>'0'), -- not used if DMUX=FALSE
            ADC_DATA_L_N => (others=>'0'),
            ADC_CLK_L_P => '0', -- not used if DMUX=FALSE
            ADC_CLK_L_N => '0', 
 
			ADC_START=>'1',
			ADC_READY=>ADC_READY,
			ADC_RD_EN=>ADC_READY,

			ADC_DOUT => ADC_DATA,
            ADC_OR => open,
            ADC_CLK =>CLK200,
			ADC_CLK_OUT => open,

			BUFR_SYNC=>'0',
			SERDES_SYNC=>'0',
			
			-- Control lines
			CTRL_DIN => (others=>'0'),
			CTRL_DOUT_RDY => open,
			CTRL_DOUT => open,
			CTRL_WR_EN => '0',
			CTRL_RD_EN => '0',
			CTRL_ADDR => (others=>'0'),
			CTRL_CLK => CTRL_CLK,

			CLK200=>CLK200,
            RST => RESET
        	);
end Behavioral;

