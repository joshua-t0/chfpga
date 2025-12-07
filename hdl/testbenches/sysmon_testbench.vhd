--------------------------------------------------------------------------------
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

ENTITY sysmon_testbench IS
	generic (
		USE_CHAN_DATA: boolean := TRUE -- minimum to fit bits on lane monitor source 0
		);
END sysmon_testbench;



ARCHITECTURE behavior OF sysmon_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

constant CLK_PERIOD : time := 16 ns; -- 62.5 MHz
constant CTRL_CLK_PERIOD : time := 10 ns; --


	--Inputs
	--signal reset : std_logic := '0';


	signal clk, ctrl_clk: std_logic := '0'; 
	signal rst, ctrl_rst: std_logic := '1';

	signal tlast_in, tlast_out, tvalid_in, tvalid_out: std_logic;
	signal tdata_in, tdata_out: std_logic_vector(255 downto 0);

    signal cmd_dat: axis8_dat_struct := (TDATA=>(others=>'0'), TVALID=>'0', TLAST=>'0');
    signal cmd_rdy: axis8_rdy_struct;
    signal rply_dat: axis8_dat_struct;
    signal rply_rdy: axis8_rdy_struct := (TREADY=>'0');

    signal a: std_logic_vector(7 downto 0) := X"AA";
    signal b: std_logic_vector(0 to 7) := X"BB";
    signal c: std_logic_vector(0 to 7) := X"BB";
    
    subtype slv8i is std_logic_vector(0 to 7);
    signal d: slv8 := X"12";
    signal e: slv8i;
    
begin

    clk <= not clk after CLK_PERIOD/2;
    ctrl_clk <= not ctrl_clk after CTRL_CLK_PERIOD/2; 
    
    b <= a;
    c <= a(a'right downto a'left);
    
    e <= d;
    
    SYSMON0: entity work.sysmon
        GENERIC MAP (
            PLATFORM_ID => PLATFORM_ID_ZCU111
            )
        PORT MAP(
            -- Control interface
            CTRL_CMD_IN_DAT => CMD_DAT,
            CTRL_CMD_IN_RDY => CMD_RDY,
            CTRL_RPLY_OUT_DAT => RPLY_DAT,
            CTRL_RPLY_OUT_RDY => RPLY_RDY,
            CTRL_CLK => CTRL_CLK,
            CTRL_RST => ctrl_rst, -- pipelined synchronous reset
    
            -- Analog inputs
            VAUX_CURR_N => '0',
            VAUX_CURR_P => '0',
            VAUX_VOLT_N => '0',
            VAUX_VOLT_P => '0',
            VP => '0',
            VN => '0',
    
    --		debug_out => debug_out,
            sysmon_clk => clk,
            SYSMON_RST => rst 
        );
    
    
    rply_rdy.TREADY <= '1';

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


        for i in 0 to 1000 loop
        fpga_read_ram(clk=> ctrl_CLK , tdata => cmd_dat.TDATA, tvalid=>cmd_dat.TVALID, tlast => cmd_dat.TLAST, tready=>cmd_rdy.TREADY, 
                           addr=> 0, log2_length=>1);
        end loop;
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
