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
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY cmd_slave_testbench IS
	-- generic (
	-- 	);
END cmd_slave_testbench;


ARCHITECTURE behavior OF cmd_slave_testbench IS

   -- Clock period definitions

-- constant IN_CLK_PERIOD : time := 5 ns; -- 200 MHz
constant SYSMON_CLK_PERIOD : time := 17 ns; --
constant CLK125_period : time := 8 ns;

--Inputs
signal reset : std_logic := '0';


-- signal in_clk: std_logic; --
signal sysmon_clk: std_logic; --
signal clk125: std_logic; --

signal cmd_tdata: slv8;
signal cmd_tvalid: std_logic;
signal cmd_tlast: std_logic;
signal cmd_tready: std_logic;

signal CONTROL_BYTES: slv8_array(0 to 7); --
signal STATUS_BYTES: slv8_array(0 to 7);
signal RPLY_OUT_DAT: AXIS8_DAT_STRUCT;

-- SYSMON signals
signal SYSMON_DOUT: STD_LOGIC_VECTOR(15 downto 0);
signal SYSMON_DIN: STD_LOGIC_VECTOR(15 downto 0);
--signal SYSMON_DADDR: STD_LOGIC_VECTOR(6 downto 0);
signal SYSMON_DRDY: STD_LOGIC;
signal SYSMON_DEN: STD_LOGIC;
signal SYSMON_WR_EN: STD_LOGIC;
signal rdy_dly1,rdy_dly2, rdy_dly3: std_logic := '0';

signal SYSMON_ADDR: STD_LOGIC_VECTOR(6 downto 0);


begin

SYSMON_DOUT <= X"1234";

bsb_regs0: entity work.bsb_regs
	GENERIC MAP (
        DEFAULT_CONTROL_BYTES=> X"00000000_00000000",
		USE_RAM_DOUT_RDY => TRUE, -- need to wait for the RDY signal on RAM read accesses
		RAM_DATA_WIDTH => 16,
		RAM_ADDR_WIDTH => 7, -- SYSMON DRP Address bus width is 7 bits
		NUMBER_OF_CONTROL_BYTES=>CONTROL_BYTES'Length(1), -- Number of bits in the control word
		NUMBER_OF_STATUS_BYTES=>STATUS_BYTES'Length(1) -- Number of bits in the status word.
		)

	PORT MAP(

		-- Control interface (command and reply stream buses)
		s_axis_bsb_tdata => cmd_tdata,
		s_axis_bsb_tvalid => cmd_tvalid,
		s_axis_bsb_tlast => cmd_tlast,
		s_axis_bsb_tready => cmd_tready,
		m_axis_bsb_tdata => RPLY_OUT_DAT.TDATA,
		m_axis_bsb_tvalid => RPLY_OUT_DAT.TVALID,
		m_axis_bsb_tlast => RPLY_OUT_DAT.TLAST,
		m_axis_bsb_tready => '1',
		CTRL_CLK => clk125,
		CTRL_RST => reset,

		CONTROL_BYTES => CONTROL_BYTES,
		STATUS_BYTES => STATUS_BYTES,

		RAM_DIN => SYSMON_DIN,
		RAM_DOUT => SYSMON_DOUT,
		RAM_DOUT_RDY => SYSMON_DRDY,
		RAM_WR_EN => SYSMON_WR_EN,
		RAM_EN => SYSMON_DEN,
		RAM_ADDR => SYSMON_ADDR

	);

-- sysmon_clk_process :process
--    begin
-- 		sysmon_clk <= '0';
-- 		wait for SYSMON_CLK_PERIOD/2;
-- 		sysmon_clk <= '1';
-- 		wait for SYSMON_CLK_PERIOD/2;
--    end process;

clk125_process :process
   begin
		clk125 <= '0';
		wait for clk125_period/2;
		clk125 <= '1';
		wait for clk125_period/2;
   end process;


-- proc :process(clk125)
--    begin
--    		if rising_edge(clk125) then
--    			SYSMON_DRDY <= SYSMON_DEN;
--    		end if;
--    end process;

stim_proc : process
	begin
		reset <= '1';
		sleep(clk125, 2);
		reset <= '0';
		sleep(clk125, 2); -- make sure we start command transmission on a CLK125 edge or we will lose some data
		fpga_write_mask(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, 255,0); --
        sleep(clk125, 10);
		fpga_write_mask(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 
		  addr => 0, 
		  data => slv8_array'(X"01",X"02",X"03",X"04",X"05",X"06",X"07",X"08"),
		  mask => slv8_array'(X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF"));  --
        
		-- fpga_write(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, 13); --
		-- fpga_read(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, 0); --
		-- fpga_read(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 16#80#+13, 3); --STATUS READ
		-- for i in 0 to 10 loop
		-- 	fpga_read(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 16#238#, 1); -- Re-read the first 8 bytes of the map for debugging
		-- end loop;
		-- fpga_read(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, 0); --
		-- fpga_write(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, 22); --
		wait;
	end process ; -- lane0_proc

END;
