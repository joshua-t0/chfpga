----------------------------------------------------------------------------------
-- Company: JFCInc
-- Engineer: JF CLiche
-- 
-- Create Date:    04:20:25 03/27/2010 
-- Design Name: 
-- Module Name:    ADC - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: E2V QUAD ADC simple simulation Model
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--    Simulates the ADC in Dual channel, 1:2 DMUX mode
--    Minimal signals are implemented
--    Not for synthesis

-- 111004 JFC: Added SYNC

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;


---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity EV8AQ160 is
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

           ADRP : out  STD_LOGIC;	-- DDR Output clock for AH Data (and AL Data if DMUX mode is used)
           ADRN : out  STD_LOGIC;	-- DDR Output clock for AH Data (and AL Data if DMUX mode is used)

           BDRP : out  STD_LOGIC;
           BDRN : out  STD_LOGIC;

           CDRP : out  STD_LOGIC;
           CDRN : out  STD_LOGIC;

           DDRP : out  STD_LOGIC;
           DDRN : out  STD_LOGIC;

           SYNCP : in  STD_LOGIC;
           SYNCN : in  STD_LOGIC

			  
			  );
end EV8AQ160;

architecture Behavioral of EV8AQ160 is


-- Constants
--constant TA : TIME :=5 ns; -- Aperture delay after clock
constant TA : TIME :=0 ns; -- Aperture delay after clock
--constant T: TIME :=
--constant TD1 : TIME := T/2 +(|TOD-TDR|) 
--constant TD2 : TIME := T/2 +(|TOD-TDR|)



-- Signals

signal sample_clk: STD_LOGIC_VECTOR (3 downto 0) := "0000"; -- Sample clocks for up to 4 channels 
signal sample_clk_div2: STD_LOGIC :='0';  
signal sample_clk_dly: STD_LOGIC_VECTOR (3 downto 0); -- actual time of sampling (aperture delay) 
signal dr_clk,dr_clk_dly: STD_LOGIC :='0'; -- Data Ready clock for DMUX=TRUE and DMUX=FALSE
signal data_clk: STD_LOGIC :='0'; -- Data clock (data is put on bus on rising edge, whether in DMUX mode or not)

type sample_array_type is array (integer range 0 to 3, integer range 0 to 1) of STD_LOGIC_VECTOR (7 downto 0);
signal sample: sample_array_type;

signal AH,BH,CH,DH,AL,BL,CL,DL: std_logic_vector(7 downto 0); -- output data pipeline 
 
--signal sample_A: STD_LOGIC_VECTOR;
--signal sample_C: STD_LOGIC_VECTOR;
--signal sampled_signal_A: STD_LOGIC;
--signal sampled_signal_C: STD_LOGIC;

signal SYNC: STD_LOGIC;



begin

-- Define the actual sampling clock (a small time after the actual input clock due to aperture delay)
sample_clk_dly<=sample_clk after TA;

-- Assign data clock to all outputs
ADRP<=dr_clk;
ADRN<=not dr_clk;
BDRP<=dr_clk;
BDRN<=not dr_clk;
CDRP<=dr_clk;
CDRN<=not dr_clk;
DDRP<=dr_clk;
DDRN<=not dr_clk;

AHP<=AH;
AHN<=not AH;
ALP<=AL;
ALN<=not AL;
BHP<=BH;
BHN<=not BH;
BLP<=BL;
BLN<=not BL;
CHP<=CH;
CHN<=not CH;
CLP<=CL;
CLN<=not CL;
DHP<=DH;
DHN<=not DH;
DLP<=DL;
DLN<=not DL;

SYNC<=SYNCP;



-- Generate an internal 4-phase sampling clock
-- CLK:           _-_-_-_-_-_-
-- sample_clk(0): 011001100110
-- sample_clk(1):  01100110011
-- sample_clk(2):   0110011001
-- sample_clk(3):    011001100

sample_clk_proc: process(CLK,SYNC)
		begin
			if SYNC='1' then
				sample_clk<=(others=>'0');
			else
				IF rising_edge(CLK) THEN
					sample_clk(0) <= not sample_clk(0);
					sample_clk(2) <= sample_clk(0);
				END IF;
				IF falling_edge(CLK) THEN
					sample_clk(1) <= not sample_clk(1);
					sample_clk(3) <= sample_clk(1);
				END IF;
			end if;
		end process sample_clk_proc;

sample_clk_div2_proc: process(sample_clk,SYNC)
		begin
			if SYNC='1' then
				sample_clk_div2<='0';
				
			ELSIF rising_edge(sample_clk(0)) THEN
				sample_clk_div2<=not sample_clk_div2;
			END IF;					
		end process sample_clk_div2_proc;

-- Assign data clock
data_clk<= sample_clk_div2 when DMUX else sample_clk(0);


-- Data ready clock
dr_clk_proc: process(data_clk,SYNC)
		begin
			if SYNC='1' then
				dr_clk<='0';
				dr_clk_dly<='0';
			else
				if falling_edge(data_clk) THEN -- Make DDR transitions on the falling edge of the data clock (i.e.in middle of data window)
					dr_clk <=not dr_clk;
					dr_clk_dly<=dr_clk;
				END IF;

				IF rising_edge(data_clk)  THEN
					
	--				IF(data_clk='0') THEN -- Register the data out when both samle_clk(0) and data_clk go up at the same time
					AH<=sample(0,0); -- N (N+2 in DMUX mode)
					BH<=sample(2,0); -- N+1 (N+3 in DMUX mode)
					CH<=sample(1,0); -- M (M+2 in DMUX mode)
					DH<=sample(3,0); -- M (M+3 in DMUX mode)
					IF (DMUX=TRUE) THEN
						-- 4 Channels, DMUX=TRUE
							AL<=sample(0,1); -- N 
							BL<=sample(2,1); -- N+1
							CL<=sample(1,1); -- M
							DL<=sample(3,1); -- M+1
					END IF;			
	--				END IF;
				END IF; -- rising_edge (data_clk)
		END IF; -- SYNC=1


		end process dr_clk_proc;

-- Sample the data on their respective clocks
sample_proc: process(sample_clk,SYNC)
	variable ch1_data,ch2_data,ch3_data,ch4_data : STD_LOGIC_VECTOR(7 downto 0) := (others=>'0');
	begin
		if SYNC='1' then
			ch1_data:=X"FD"; -- Not zero, to simulate the effect
			ch2_data:=X"FD";
			ch3_data:=X"FD";
			ch4_data:=X"FD";
			sample<=(others=>(others=>X"FA"));
			
		else
			
			-- Clock data out when it is time
			

			IF(CHANNELS=1) THEN
				IF rising_edge(sample_clk(0))  THEN
					sample(0,1)<=sample(0,0);
					sample(0,0)<=ch1_data;
					ch1_data:=ch1_data+1;
				END IF;

				IF rising_edge(sample_clk(1))  THEN
					sample(1,1)<=sample(1,0);
					sample(1,0)<=ch1_data;
					ch1_data:=ch1_data+1;
				END IF;

				IF rising_edge(sample_clk(2))  THEN
					sample(2,1)<=sample(2,0);
					sample(2,0)<=ch1_data;
					ch1_data:=ch1_data+1;
				END IF;

				IF rising_edge(sample_clk(3))  THEN
					sample(3,1)<=sample(3,0);
					sample(3,0)<=ch1_data;
					ch1_data:=ch1_data+1;
				END IF;


			ELSIF (CHANNELS=2) THEN
				IF rising_edge(sample_clk(0))  THEN
					sample(0,1)<=sample(0,0);
					sample(0,0)<=ch1_data;
					ch1_data:=ch1_data+1;
					
					sample(1,1)<=sample(1,0);
					sample(1,0)<=ch2_data;
					ch2_data:=ch2_data+1;
				END IF;

				IF rising_edge(sample_clk(2))  THEN
					sample(2,1)<=sample(2,0);
					sample(2,0)<=ch1_data;
					ch1_data:=ch1_data+1;
					
					sample(3,1)<=sample(3,0);
					sample(3,0)<=ch2_data;
					ch2_data:=ch2_data+1;
				END IF;
			ELSIF (CHANNELS=4) THEN
				-- Four channel mode: all 4 channels are sampled on the same sample clock

				IF sample_clk(0)'EVENT and sample_clk(0)='1' THEN -- does not work with rising_edge()
					sample(0,1)<=sample(0,0);
					sample(0,0)<=ch1_data;
					ch1_data:=ch1_data+1;
					
					sample(2,1)<=sample(2,0);
					sample(2,0)<=ch3_data;
					ch3_data:=ch3_data+1;

					sample(1,1)<=sample(1,0);
					sample(1,0)<=ch2_data;
					ch2_data:=ch2_data+1;

					sample(3,1)<=sample(3,0);
					sample(3,0)<=ch4_data;
					ch4_data:=ch4_data+1;
				END IF;
			ELSE
			-- need to assert an error here
			END IF;

		end if; -- if SYNC	
	end process sample_proc;
end Behavioral;

