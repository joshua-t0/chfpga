----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:05:15 03/26/2011 
-- Design Name: 
-- Module Name:    SYNC - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: This block performs two functions
--  1) Measure the latency of a CASPER signal processing block (the FPB/FFT) 
--		The block starts counting clocks after a RESET event until a SYNC oulse is seen at the output of the FFT block.
--		This assumes that the FFT input SYNC and clock enable is held high during reset.
--		It seems that holding the SYNC input for more than one clock cycle only generates a single output sync when it is released. We use that to our advantage.
--		The block assumes there are no other SYNC pulses in the FFT pipeline, otherwise that would confuse the readout. RESET does not clear the FFT registers. 
-- 	If we perform multiple resets in succession or just after a input SYNC signal was received we would get a wrong readout.
--  2) Implement a delay line to pass control signals with with the specified delay. This is used to pass VALID/OVERFLOW/etc signals around the FFT block and reassociate them with the corresponding samples at the output of the FFT.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
-- 2012-05-31 JFC: Added Clock Enable (CE)
--		2012-08-28: Separated delay measurment from the delay line process

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity FFT_DELAY is
	generic (
		CTR_WIDTH: INTEGER := 12; -- number of bits of the delay line. Max delay = 2^CTR_WIDTH
		DATA_WIDTH: INTEGER := 4 -- number of flag bits to propagate through the delay line.
		);
   port (
		SYNC_IN : in  STD_LOGIC;
		SYNC_OUT: in  STD_LOGIC;
		MEASURED_DELAY: out STD_LOGIC_VECTOR(CTR_WIDTH-1 downto 0);

		DATA_IN : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
		DATA_OUT: out  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
		DELAY: in STD_LOGIC_VECTOR(CTR_WIDTH-1 downto 0);
		VALID: out std_logic:='0';
		
		CLK : in  STD_LOGIC;
		CE : in  STD_LOGIC;
		RST : in  STD_LOGIC
		);
			  
end FFT_DELAY;

architecture Behavioral of FFT_DELAY is


signal DELAY_CTR: UNSIGNED(CTR_WIDTH-1 downto 0) := (others=>'0');
signal MEASURED_DELAY_CTR: UNSIGNED(CTR_WIDTH-1 downto 0) := (others=>'0'); --needed
signal WAIT_FOR_SYNC: std_logic:='1'; -- needed to start looking for SYNC without a reset
signal COUNTING_DELAY: std_logic:='0'; -- needed
signal VALID_INT: std_logic;

type ram_type is array (0 to 2**CTR_WIDTH) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal RAM : ram_type :=(others=>(others=>'0'));

begin

-- Generate RAM address. The address has to be zero at the same time an SYNC pulse is detected before or after the FFT (when in training mode). This is accomplished by muxing the counter with zero combinatorially so this is done without delay.
--ADDR<=(others=>'0') when (TRAIN='1' and (DSP_SYNC_IN='1' or DSP_SYNC_OUT='1')) else CTR;
--DELAY<=STD_LOGIC_VECTOR(DLY);

-------------------------------------------------------------
-- Measure the propagation delay of a CASPER block
-------------------------------------------------------------

meas_dly: process(CLK)
	begin
		if rising_edge(CLK) then
			if RST='1' then
				MEASURED_DELAY_CTR<=(others=>'0');
				WAIT_FOR_SYNC<='0';
				COUNTING_DELAY<='1';
			elsif CE='1' then
				-- Measure pipelining delay between input and output SYNC
				if SYNC_IN='1' and WAIT_FOR_SYNC='1' then
					WAIT_FOR_SYNC<='0';
					COUNTING_DELAY<='1';
				end if;
				
				if COUNTING_DELAY='1' then
					MEASURED_DELAY_CTR<=MEASURED_DELAY_CTR+1;
				end if;
				
				if SYNC_OUT='1' and COUNTING_DELAY='1' then
					MEASURED_DELAY<=std_logic_vector(MEASURED_DELAY_CTR+1); -- the +1 migh generate unnecessary logic. Refactor to optimize (i.e reuse counter adder or delay SYNC_OUT).
					COUNTING_DELAY<='0';
				end if;
			end if; -- if RST or CE
		end if; -- if CLK
	end process;


-------------------------------------------------------------
-- Implement a delay line with specified delay
-------------------------------------------------------------

dly_line: process(CLK)
	begin
		if rising_edge(CLK) then
			if RST='1' then
				DELAY_CTR<=(others=>'0'); 
				VALID<='0';
				VALID_INT<='0';
			else
--				VALID<='0';
				if CE='1' then
					-- Implement a delay line with specified delay
					if DELAY_CTR=unsigned(DELAY)-2 then -- -1 to account for the output register implicit to the synchronous RAM, and -1 because we count from zero (not efficient in logic, may need to be refactored)
						DELAY_CTR<=(others=>'0');
						VALID_INT<='1';
					else
						DELAY_CTR<=DELAY_CTR+1;
					end if;
					
					-- the VALID flag turns on after we read the data at address zero
					
					DATA_OUT<=RAM(TO_INTEGER(DELAY_CTR));
					VALID<=VALID_INT;
					RAM(TO_INTEGER(DELAY_CTR))<=DATA_IN;
				end if; --CE
			end if; -- RST
		end if; -- CLK
	end process;
	

end Behavioral;

