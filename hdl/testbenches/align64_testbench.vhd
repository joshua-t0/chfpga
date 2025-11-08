--------------------------------------------------------------------------------
-- Company: McGill University -  Cosmology Instrumentation Lab
-- Engineer:JF CLiche
--
-- Description:
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

use std.env.finish; -- import finish procedure

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY align64_testbench IS
	generic (
		NUMBER_OF_LANES: integer := 2 -- Minimum of one reference lane and one delayed lane
		);
END align64_testbench;


ARCHITECTURE behavior OF align64_testbench IS
    constant CLK_PERIOD : time := 2.5 ns; -- 400 MHz

	signal rst : std_logic := '0';
	signal clk: std_logic := '0'; -- 244 MHz


	signal s_axis_tdata: slv_array(0 to NUMBER_OF_LANES-1)(63 downto 0) := (others=> (others=>'0'));
	signal s_axis_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1) := (others=>'0'); -- needed for sim. If, U, data will not start
	signal s_axis_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1):= (others=>'0');

	signal m_axis_tdata: slv_array(0 to NUMBER_OF_LANES-1)(63 downto 0);
	signal m_axis_tvalid: std_logic;
	signal m_axis_tlast: std_logic;
	signal lane_error: std_logic_vector(0 to NUMBER_OF_LANES-1);

    signal tready: std_logic := '1';
	signal frame_clk: std_logic;
	signal first: std_logic := '1';
	signal timeout_ctr: unsigned(7 downto 0);
	constant NUMBER_OF_PACKETS : integer :=500;

	constant PL: integer := 1984; -- packet length
	constant PP: integer := 2048; -- packet period (packet length + interpacket delay)

    type event_type is (NONE, MISSING, SHORT_FRAME, NO_EOF, ADD_DELAY, EOT);
    type event_type_array is array(natural range <>) of event_type;
    type event_item is RECORD FRAME:integer; EVT:event_type; VALUE: integer; end record;
    type event_array is array(natural range <>) of event_item;

    signal event_ctr: integer; 
    signal current_event: event_type_array(0 to NUMBER_OF_LANES-1);
    constant DELTA: integer := 5;

    constant event_list: event_array := (
        (DELTA, MISSING, 0),
        (DELTA, SHORT_FRAME, 100),
        (DELTA, NO_EOF, 0),
        (DELTA, ADD_DELAY, 10), 
        (DELTA, ADD_DELAY, 10), 
        (DELTA, ADD_DELAY, 10), 
        (DELTA, ADD_DELAY, 10), 
        (DELTA, ADD_DELAY, 10),
        (DELTA, ADD_DELAY, 10),
        (DELTA, ADD_DELAY, 10),
        (DELTA, ADD_DELAY, 10),
        (DELTA, EOT, 0) -- end of test
        ); 
-- Tests
-- Normal mode
-- Borderline delay
-- Missing frame
-- Short frame
-- One lane with bursts on back-to-back 1 word frame
-- All single word, back-to-back packets: cannot work because  too fast for the frame clock processing

	-- signal t1: slv8;
	-- signal t2,t3: std_logic;
begin


clk <= not clk after CLK_PERIOD/2;


-- tests
-- 5 back-to back frames, all same length, aligned: ok
-- 5 frames, 1 clock spacing, same length, aligned: ok
-- 5 frames, same_length, aligned within timeout: ok
-- 5 frames, same_length, lane2 delayed by frame length:

-- data(0) <= (X"A0A0A0A0", X"A1A1A1A1", X"A2A2A2A2", X"A3A3A3A3", X"A4A4A4A4", X"A5A5A5A5", X"A6A6A6A6", X"A7A7A7A7");


-- frame_clk <= s_axis_tvalid and s_axis_tlast;
align0: entity work.align64
	generic map (
		NUMBER_OF_LANES => NUMBER_OF_LANES
		)
	port map (
		s_axis_tdata  => s_axis_tdata,
		s_axis_tvalid => s_axis_tvalid,
		s_axis_tlast  => s_axis_tlast,

		m_axis_tdata  => m_axis_tdata,
		m_axis_tvalid => m_axis_tvalid,
		m_axis_tlast  => m_axis_tlast,

        lane_error => lane_error,
        
    	clk => clk,
		rst => rst
	);

rst_proc : process
	begin
		rst <= '1';
		sleep(clk, 10);
		rst <= '0';
		sleep(clk, 257);
		wait; -- comment out to implement periodic resets
	end process ;

--process(all) begin
--    event_ctr <= 0 when rst else event_ctr +1 when rising_edge(clk);
--end process;

lane_gen: for lane in 0 to NUMBER_OF_LANES-1 generate
	lane_proc : process
        variable data: slv_array(0 to 500-1)(63 downto 0);
        variable event_ctr: integer := 0;
        variable clk_ctr: integer := 0;
        variable frame_length: integer;
        variable is_no_eof, is_missing: boolean;
        variable next_event_frame: integer := 0;
        variable evt: event_type;
        variable value: integer;
		begin
			wait until rst='0';
            for frame in 0 to NUMBER_OF_PACKETS-1 loop
                frame_length := PL;
                is_no_eof := FALSE;
                is_missing := FALSE;
                current_event(lane) <= NONE;
                if lane > 0 and event_ctr < event_list'LENGTH and frame = next_event_frame then
                    evt := event_list(event_ctr).EVT;
                    value := event_list(event_ctr).VALUE;
                    if evt = EOT then
                        finish;
                    end if;
                    is_no_eof := TRUE when evt = NO_EOF;
                    is_missing := TRUE when evt = MISSING;
                    frame_length := value  when evt = SHORT_FRAME;
                    event_ctr := event_ctr + 1;
                    if evt = ADD_DELAY then
                        sleep(clk, value);
                    end if;
                    next_event_frame := next_event_frame + event_list(event_ctr).FRAME; 
                    current_event(lane) <= evt;
                end if;
                for w in 0 to PL-1 loop
                    s_axis_tdata(lane) <= to_slv(lane,64/4) & to_slv(frame,64/4) & to_slv(w,64/2);
                    s_axis_tvalid(lane) <= '1' when w < frame_length and not is_missing else '0';
                    s_axis_tlast(lane) <= '1' when w=frame_length-1 and not is_no_eof else '0';
                    sleep(clk);
                 end loop; -- w
                 s_axis_tvalid(lane) <= '0';
                 s_axis_tlast(lane) <= '0';
                                    
--                sleep(clk, packet_period(lane)(frame) - packet_length(lane)(frame));
                sleep(clk, PP - PL);
            end loop;
        wait;
	end process ; -- lane0_proc

end generate;

-- Check results
process(all) 
constant mask: std_logic_vector := X"0000_FFFF_FFFFFFFF"; -- ignore lane number
begin
	if rising_edge(clk) then
        for lane in 0 to NUMBER_OF_LANES-1 loop
            assert not (lane_error(lane)='0' and m_axis_tvalid='1' and (m_axis_tdata(0) and mask ) /= (m_axis_tdata(lane) and mask))
                report "Align error. Expected " & to_hstring(m_axis_tdata(0)) & " got " & to_hstring(m_axis_tdata(lane))
                severity FAILURE;
        end loop;
	end if; --clk
end process;


END;
