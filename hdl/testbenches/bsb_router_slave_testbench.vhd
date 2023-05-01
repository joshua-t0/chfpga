--------------------------------------------------------------------------------
-- @file
-- Company:
-- Engineer:
--
-- Create Date:  2023-02
-- Project Name:  CHORD
-- Target Device: Ultrascale+
-- Tool versions:
-- Description: testbench for the UltraRAM-based, 8 channel, 8k bins, 16 frames corner-turn engine.
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY router_slave_testbench IS
	generic (
		USE_CHAN_DATA: boolean := TRUE -- minimum to fit bits on lane monitor source 0
		);
END router_slave_testbench;



ARCHITECTURE behavior OF router_slave_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

constant CLK_PERIOD : time := 16 ns; -- 62.5 MHz
constant CTRL_CLK_PERIOD : time := 10 ns; --


	--Inputs
	--signal reset : std_logic := '0';


	signal clk: std_logic; -- 200 MHz
	signal rst, ctrl_rst: std_logic := '1';
	signal ctrl_clk: std_logic; -- 200 MHz

	signal tlast_in, tlast_out, tvalid_in, tvalid_out: std_logic;
	signal tdata_in, tdata_out: std_logic_vector(255 downto 0);

    signal cmd_dat: axis8_dat_struct := (TDATA=>(others=>'0'), TVALID=>'0', TLAST=>'0');
    signal cmd_rdy: axis8_rdy_struct;
    signal rply_dat: axis8_dat_struct;
    signal rply_rdy: axis8_rdy_struct := (TREADY=>'0');

    constant NUMBER_OF_PORTS: integer :=4;

    signal top_cmd_dat: axis8_dat_struct_array(NUMBER_OF_PORTS-1 downto 0);
    signal top_cmd_rdy: axis8_rdy_struct_array(NUMBER_OF_PORTS-1 downto 0):= (others=> (TREADY=> '1')) ;
    signal top_rply_dat: axis8_dat_struct_array(NUMBER_OF_PORTS-1 downto 0):=(others=>(TVALID=>'0', TDATA=>X"00", TLAST=>'0'));
    signal top_rply_rdy: axis8_rdy_struct_array(NUMBER_OF_PORTS-1 downto 0);

	constant NUMBER_OF_PACKETS : integer :=500;

    signal control_bytes: slv8_array(0 to 5); -- default value set in the CMD_SLAVE
    signal status_bytes: slv8_array(0 to 4);
        
    signal ram_ctrl_addr: std_logic_vector(11 downto 0); -- 2048 bytes x 2
    signal ram_ctrl_addr_paged: std_logic_vector(11 downto 0); -- 2048 bytes x 2
    signal ram_ctrl_wr_en: std_logic;
    signal ram_ctrl_din: std_logic_vector(7 downto 0);
    signal ram_ctrl_dout: std_logic_vector(7 downto 0);
    
    signal cmd_overflow: std_logic;
    
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


	--dut_inst: entity work.cge_test
	--	port map (
	--		tx_p=> txp,
	--		tx_n=> txn,
	--		gt_ref_clk_p => clk,
	--		gt_ref_clk_n => not clk
	--	);


	refclk_process: process
	   begin
	       wait for 1 us;
           while  True loop
			clk <= '0';
			wait for CLK_PERIOD/2;
			clk <= '1';
			wait for CLK_PERIOD/2;
        end loop;
	   end process;

    bsbclk_process: process
	   begin
			ctrl_clk <= '0';
			wait for CTRL_CLK_PERIOD/2;
			ctrl_clk <= '1';
			wait for CTRL_CLK_PERIOD/2;
	   end process;

	router0: entity work.CTRL_ROUTER
		generic map (
			TARGET_PBLOCK => "SYSTEM",
			NUMBER_OF_PORTS => NUMBER_OF_PORTS,
			ADDRESS_MASK => "-111----------------" --'1': used to generate port index, '-' = don't care,
		)
		port map(
			-- Root interface

			CMD_IN_DAT =>  CMD_DAT,
			CMD_IN_RDY =>  CMD_RDY,
			RPLY_OUT_DAT => RPLY_DAT,
			RPLY_OUT_RDY => RPLY_RDY,

			-- Downstream interface

			CMD_OUT_DAT => top_cmd_dat,
			CMD_OUT_RDY => top_cmd_rdy,
			RPLY_IN_DAT => top_rply_dat,
			RPLY_IN_RDY => top_rply_rdy,

			cmd_overflow => cmd_overflow,

			CLK => ctrl_clk,
			RST => ctrl_rst
		);

CTRL_SLAVE0: entity work.CTRL_SLAVE
    GENERIC MAP (
        NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), --
        NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1), --
        DEFAULT_CONTROL_BYTES   => X"40_0101_00_FF_00", -- No reset
        ADDR_WIDTH              => 9, -- We have 9 bits of data left after routing
        RAM_DATA_WIDTH          => 8, -- 8 or 16 bits
        RAM_ADDR_WIDTH          => 12, -- Cannot exceed 9 bits with 8-bit data width because higher bits are used for routing
        RAM_LATENCY             => 2
        )
    PORT MAP(
        -- Control interface (command and reply stream buses)
        CTRL_CMD_IN_DAT   => top_cmd_dat(0),
        CTRL_CMD_IN_RDY   => top_cmd_rdy(0),
        CTRL_RPLY_OUT_DAT => top_rply_dat(0),
        CTRL_RPLY_OUT_RDY => top_rply_rdy(0),
        CTRL_CLK          => ctrl_clk,
        CTRL_RST          => ctrl_rst,

        control_bytes     => control_bytes,
        status_bytes      => status_bytes,

        RAM_DIN   => ram_ctrl_din,
        RAM_DOUT  => ram_ctrl_dout,
        RAM_ADDR  => ram_ctrl_addr,
        RAM_WR_EN => ram_ctrl_wr_en,
        RAM_RD_EN => open -- the ram is always reading
        );


    rply_rdy.TREADY <= '1';
    --	rst_proc: process(clk)
    --	begin
    --		if rising_edge(clk) then
    --		end if;
    --	end process;
    

sim_proc: process

        variable data: std_logic_vector(255 downto 0);
        variable addr, eop, eot: integer;
	begin

		-- wait for init and synchronize to clock
		rst <= '0';
		ctrl_rst <= '1';
		-- wait a bit
		sleep(ctrl_clk, 10);
		ctrl_rst <= '0';
		sleep(ctrl_clk, 10);


        -- Enable playlist write
        fpga_write_control(clk=> ctrl_CLK , tdata => cmd_dat.TDATA, tvalid=>cmd_dat.TVALID, tlast => cmd_dat.TLAST, tready=>cmd_rdy.TREADY, 
                           addr=> 0, data => 66);

        fpga_write_ram(clk=> ctrl_CLK , tdata => cmd_dat.TDATA, tvalid=>cmd_dat.TVALID, tlast => cmd_dat.TLAST, tready=>cmd_rdy.TREADY, 
                           addr=> 0, data => (0 to 100=> X"55"));
        fpga_read(clk=> ctrl_CLK , tdata => cmd_dat.TDATA, tvalid=>cmd_dat.TVALID, tlast => cmd_dat.TLAST, tready=>cmd_rdy.TREADY, 
                           addr=> 16#23E#, log2_length=>3);

		wait;
	end process;




--rst_proc : process
--	begin
--		reset <= '1';
--		sleep(out_clk, 10);
--		reset <= '0';
--		sleep(out_clk, 257);


--		wait; -- comment out to implement periodic resets


END;
