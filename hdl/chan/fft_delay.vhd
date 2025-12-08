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
--  2) Implement a delay line to pass control signals with with the specified delay. This is used to pass valid/OVERFLOW/etc signals around the FFT block and reassociate them with the corresponding samples at the output of the FFT.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 2012-05-31 JFC: Added Clock Enable (ce)
--		2012-08-28: Separated delay measurment from the delay line process

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.chFPGA_config.all; -- get platform-specific configurations

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity fft_delay is
	generic (
		CTR_WIDTH: INTEGER; -- number of bits of the delay line. Max delay = 2^CTR_WIDTH
		DATA_WIDTH: INTEGER := 4 -- number of flag bits to propagate through the delay line.
		);
   port (
		sync_in : in  STD_LOGIC;
		sync_out: in  STD_LOGIC;
		measured_delay: out STD_LOGIC_VECTOR(CTR_WIDTH-1 downto 0);

		data_in : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
		data_out: out  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
		delay: in STD_LOGIC_VECTOR(CTR_WIDTH-1 downto 0);
		valid: out std_logic:='0';

		clk : in  STD_LOGIC;
		ce : in  STD_LOGIC;
		rst : in  STD_LOGIC
		);

end fft_delay;

architecture Behavioral of FFT_DELAY is


signal delay_ctr, delay_ctr_max: unsigned(CTR_WIDTH-1 downto 0) := (others=>'0');
signal measured_delay_ctr: unsigned(CTR_WIDTH-1 downto 0) := (others=>'0'); --needed
signal wait_for_sync: std_logic:='1'; -- needed to start looking for SYNC without a reset
signal counting_delay: std_logic:='0'; -- needed
signal valid_pre, valid_pre2: std_logic;
signal data_out_pre:  std_logic_vector(DATA_WIDTH-1 downto 0);
type ram_type is array (0 to 2**CTR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal ram : ram_type :=(others=>(others=>'0'));

begin

-- Generate RAM address. The address has to be zero at the same time an SYNC pulse is detected before or after the FFT (when in training mode). This is accomplished by muxing the counter with zero combinatorially so this is done without delay.
--ADDR<=(others=>'0') when (TRAIN='1' and (DSP_SYNC_IN='1' or DSP_SYNC_OUT='1')) else CTR;
--delay<=STD_LOGIC_VECTOR(DLY);

-------------------------------------------------------------
-- Measure the propagation delay of a CASPER block
-------------------------------------------------------------
meas_dly: process(clk)
	begin
		if rising_edge(clk) then
			if rst='1' then
				measured_delay_ctr <= (others=>'0');
				wait_for_sync <= '0';
				counting_delay <= '1';
			elsif ce='1' then
				-- Measure pipelining delay between input and output SYNC
				if sync_in='1' and wait_for_sync='1' then
					wait_for_sync <= '0';
					counting_delay <= '1';
				end if;

				if counting_delay='1' then
					measured_delay_ctr <= measured_delay_ctr + 1;
				end if;

				if sync_out='1' and counting_delay='1' then
					measured_delay <= std_logic_vector(measured_delay_ctr + 1); -- the +1 might generate unnecessary logic. Refactor to optimize (i.e reuse counter adder or delay sync_out).
					counting_delay <= '0';
				end if;
			end if; -- if rst or ce
		end if; -- if clk
	end process;


-------------------------------------------------------------
-- Implement a delay line with specified delay
-------------------------------------------------------------

dly_line: process(clk)
	begin
		if rising_edge(clk) then
			if ce='1' then
				-- precompute the maximum counter value to avoid a "large" combinatorial adder in the counter enable logic.
				-- We stop the counter in advance to take into account the logic latencies
				--    -1 because we count delays from zero, not one
				--    -1 because this is a synchronous RAM: data comes one clock after address
				--    -1 to account for the pipeline output register we add after the RAM
				delay_ctr_max <= unsigned(delay)-3;
				-- Implement a delay line with specified delay
				if delay_ctr = delay_ctr_max then --
					delay_ctr <= (others=>'0');
					valid_pre2 <= '1';
				else
					delay_ctr <= delay_ctr + 1;
				end if;

				-- the valid flag turns on after we read the data at address zero

				-- RAM read
				data_out_pre <= ram(to_integer(delay_ctr));
				valid_pre <= valid_pre2;
				-- We add an output pipeline register to mitigte the large
				-- clk-to-output delay of the inferred block RAM.
				-- Hopefully this extra register will be absorbed in the BRAM.
				data_out <= data_out_pre;
				valid <= valid_pre;

				-- RAM write
				ram(to_integer(delay_ctr)) <= data_in;
			end if; --ce
			-- Synchronous resets - overides signals above
			if rst='1' then
				delay_ctr <= (others=>'0');
				valid <= '0';
				valid_pre2 <= '0';
				valid_pre <= '0';
			end if; -- rst
		end if; -- clk
	end process;


end Behavioral;

