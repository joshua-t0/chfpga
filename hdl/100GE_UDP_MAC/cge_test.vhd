
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.ALL; -- for reduce functions

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all;

entity cge_test is
	port (
		tx_p: out std_logic_vector(0 to 3);
		tx_n: out std_logic_vector(0 to 3);
		gt_ref_clk_p : in std_logic; --156.250 reference clock input
		gt_ref_clk_n : in std_logic;
		clk_100_p: in std_logic;
		clk_100_n: in std_logic


	);
end entity;


architecture impl of cge_test is
	signal refclk: std_logic;
	signal rst: std_logic := '1';
	signal uram_tdata: std_logic_vector(255 downto 0); 
    signal uram_tvalid: std_logic := '0';
    signal uram_tlast: std_logic := '0';
    signal ctrl_clk: std_logic;
begin


   IBUFDS_inst : IBUFDS
   generic map (
      CCIO_EN_M => "TRUE",
      CCIO_EN_S => "TRUE" 
   )
   port map (
      O => ctrl_clk,   -- 1-bit output: Buffer output
      I => clk_100_p,   -- 1-bit input: Diff_p buffer input (connect directly to top-level port)
      IB => clk_100_n  -- 1-bit input: Diff_n buffer input (connect directly to top-level port)
   );


		cge0: entity work.cge
		 generic map (
			IMPLEMENT_PACKET_GENERATOR => TRUE
		 	)
		port map (
			tx_p => tx_p,
			tx_n => tx_n,
			refclk_p => gt_ref_clk_p,
			refclk_n => gt_ref_clk_n,


--            s_axis_tx_tdata => uram_tdata,
--            s_axis_tx_tvalid => uram_tvalid,
--            s_axis_tx_tlast=> uram_tlast,
 
			refclk_out => refclk,
			rst => rst,
			ctrl_clk => ctrl_clk, -- used as init_clk
			ctrl_rst => rst
		 );

--    uram0: entity work.uram_ct
--        port map (
----            s_axis_in_tdata: in std_logic_vector(255 downto 0) := (others=>'0'); -- First byte to transmit is in in most significant byte
----            s_axis_in_tvalid: in std_logic := '0';
----            s_axis_in_tlast: in std_logic := '0';
    
--            m_axis_out_tdata => uram_tdata,
--            m_axis_out_tvalid => uram_tvalid,
--            m_axis_out_tlast=> uram_tlast,
    
--            clk => refclk, 
--            rst => rst -- synchrounous reset
    
    
--            --init_clk: in std_logic; -- continuous clock
    
--            -- Control and reply streams
----            cmd_dat: in axis8_dat_struct := (TDATA=>(others=>'0'), TVALID=>'0', TLAST=>'0');
----            cmd_rdy: out axis8_rdy_struct;
----            rply_dat: out axis8_dat_struct;
----            rply_rdy: in axis8_rdy_struct := (TREADY=>'0');
----            ctrl_clk : IN std_logic := '0'; -- control clock
----            ctrl_rst : in std_logic := '0'
    
--            --areset: in std_logic --! asynchronous reset
--         );

		rst_proc: process(ctrl_clk)
		begin
			if rising_edge(ctrl_clk) then
				rst <= '0';
			end if;
		end process;


end architecture impl;



