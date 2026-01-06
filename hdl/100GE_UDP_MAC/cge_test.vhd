
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
		clk100_p: in std_logic;
		clk100_n: in std_logic;
		pl_clk_p, pl_clk_n: in std_logic


	);
end entity;


architecture impl of cge_test is
	signal refclk: std_logic;
	signal rst, ctrl_rst: std_logic := '1';
	signal uram_tdata: std_logic_vector(255 downto 0); 
    signal uram_tvalid: std_logic := '0';
    signal uram_tlast: std_logic := '0';
    signal ctrl_clk: std_logic;
    signal clk: std_logic;
    signal clk_rst_ctr, rst_ctr: unsigned(7 downto 0) := (others => '0');
	signal tlast_in, tlast_out, tvalid_in, tvalid_out: std_logic;
	signal tdata_in, tdata_out: std_logic_vector(255 downto 0);

begin


   clk100_buf0 : IBUFDS
   generic map (
      CCIO_EN_M => "TRUE",
      CCIO_EN_S => "TRUE" 
   )
   port map (
      O => ctrl_clk,   -- 1-bit output: Buffer output
      I => clk100_p,   -- 1-bit input: Diff_p buffer input (connect directly to top-level port)
      IB => clk100_n  -- 1-bit input: Diff_n buffer input (connect directly to top-level port)
   );

   plclk_buf0 : IBUFDS
   generic map (
      CCIO_EN_M => "TRUE",
      CCIO_EN_S => "TRUE" 
   )
   port map (
      O => clk,   -- 1-bit output: Buffer output
      I => pl_clk_p,   -- 1-bit input: Diff_p buffer input (connect directly to top-level port)
      IB => pl_clk_n  -- 1-bit input: Diff_n buffer input (connect directly to top-level port)
   );

	ct0: entity work.uram_ct
		--generic map (
		--	IMPLEMENT_PACKET_GENERATOR => TRUE
		-- 	)
		port map (
			s_axis_in_tdata => tdata_in, -- First byte to transmit is in in most significant byte
			s_axis_in_tvalid => tvalid_in,
			s_axis_in_tlast => tlast_in,

			m_axis_out_tdata => tdata_out,
			m_axis_out_tvalid => tvalid_out,
			m_axis_out_tlast => tlast_out,

--            cmd_dat => cmd_dat,
--            cmd_rdy => cmd_rdy,
--            rply_dat => rply_dat,
--            rply_rdy => rply_rdy,
    

			clk=> clk,
			rst => rst,
			ctrl_clk => ctrl_clk, -- used as init_clk
			ctrl_rst => ctrl_rst
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


            s_axis_tx_tdata => tdata_out,
            s_axis_tx_tvalid => tvalid_out,
            s_axis_tx_tlast=> tlast_out,
            clk => clk,
 
			rst => rst,
			bsb_clk => ctrl_clk, -- used as init_clk
			bsb_rst => ctrl_rst
		 );


		ctrlrst_proc: process(ctrl_clk)
		begin
			if rising_edge(ctrl_clk) then
				ctrl_rst <= '0';
			end if;
		end process;


		rst_proc: process(clk)
		begin
			if rising_edge(clk) then
				rst <= '0';
			end if;
		end process;


end architecture impl;



