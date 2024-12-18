----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    2012-06-12
-- Design Name: 	  chFPGA
-- Module Name:    UCORR44_ARRAY - Behavioral
-- Project Name: 	CHIME
-- Target Devices: Ultrascale+
-- Tool versions: Vivado 2022.2 
-- Description: Implement an array of UCORR44
-- Dependencies:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions

library UNISIM;
use UNISIM.VComponents.all;

entity UCORR44_ARRAY is
	GENERIC (
		PLATFORM_ID: integer;
		NCORR: integer; -- number of correlators
		NCHAN: integer -- number of channels to correlate per correlator
	);

	PORT (

		-- Input data AXI-S bus , non-blocking
		-- Data ordering: 0 to K-1 => (Corr0Chan0, Corr0Chan1, ... Corr0 ChanNCHAN-1, Corr1Chan0 ...)
		-- Re in MSB of byte  
		s_axis_data_tdata : in  slv_array(0 to NCHAN-1)(31 downto 0); --! input data stream containing the channelized data from every antenna processor. Each frame must contain up to 512 words each containing four (4+4) bit signed complex values.
		s_axis_data_tvalid : in  std_logic; --
		s_axis_data_tlast : in  std_logic; --

		clk : in std_logic; -- Input clock channelized data.
		rst: in std_logic; -- Reset synchronous to the input clock


		-- Integrated product output
		-- AXI4-Streaming, blocking, 8-bit wide

		m_axis_data_tdata: out std_logic_vector(7 downto 0);
		m_axis_data_tvalid: out std_logic;
		m_axis_data_tlast: out std_logic;
		m_axis_data_tready: in std_logic;


		-- Control and reply streams
		s_axis_bsb_dat:  in AXIS8_DAT_STRUCT := (TDATA => X"00", TVALID => '0', TLAST =>'0');
		s_axis_bsb_rdy:  out AXIS8_RDY_STRUCT := (TREADY => '1');
		m_axis_bsb_dat: out AXIS8_DAT_STRUCT := (TDATA => X"00", TVALID => '0', TLAST =>'0');
		m_axis_bsb_rdy: in AXIS8_RDY_STRUCT := (TREADY => '1');
		ctrl_clk: in std_logic; -- control clock
		ctrl_rst: in std_logic
		);

end UCORR44_ARRAY;

architecture Behavioral of UCORR44_ARRAY is

    -- Attributes used in this design
    attribute equivalent_register_removal: string;
    attribute shreg_extract: string;
    attribute DONT_TOUCH: string;
    --attribute RLOC_ORIGIN : string;
    
    constant N: integer := NCHAN; 
    
    signal rst_reg: slv(0 to NCORR-1);
    attribute DONT_TOUCH of rst_reg: signal is "true";
    
    -- Control signals
    signal control_bytes: slv8_array(0 to 2);
    signal status_bytes: slv8_array(0 to 0);
    signal user_reset: std_logic;
    signal autocorr_only: std_logic;
    signal no_accum: std_logic; -- when '1', there is no accumulation: only th elast product of the accumulation period is kept.
    signal integ_period: std_logic_vector(15 downto 0);

    type slv_2darray is array (natural range <>) of slv_array(0 to NCHAN-1)(7 downto 0);
    signal axis_corr_in_tdata: slv_2darray(0 to NCORR-1);    
    signal axis_corr_in_tlast: std_logic_vector(0 to NCORR-1);
    signal axis_corr_in_tvalid: std_logic_vector(0 to NCORR-1);
    
    signal z_tdata: slv_array(0 to NCORR)(7 downto 0);
    signal z_tlast: std_logic_vector(0 to NCORR);
    signal z_tvalid: std_logic_vector(0 to NCORR);
    signal z_send: std_logic_vector(0 to NCORR);
    
    signal overrun:std_logic_vector(0 to NCORR-1);
begin


    --------------------------------------------
    -- Memory mapped registers
    --------------------------------------------
    
	bsb_regs0: entity work.CTRL_SLAVE
		GENERIC MAP (
			DEFAULT_CONTROL_BYTES=> X"03_3FFF",
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES => status_bytes'Length(1) -- Number of bits in the status word.
		)
		PORT MAP(

			control_bytes => control_bytes,
			status_bytes => status_bytes,

			ctrl_cmd_in_dat=>   s_axis_bsb_dat,
			ctrl_cmd_in_rdy=>   s_axis_bsb_rdy,
			ctrl_rply_out_dat=> m_axis_bsb_dat,
			ctrl_rply_out_rdy=> m_axis_bsb_rdy,
			ctrl_clk => ctrl_clk,
			ctrl_rst => ctrl_rst
		);

	-- CONTROL byte 0
	user_reset            <= control_bytes(0)(7); -- 
    no_accum              <= control_bytes(0)(1);
    autocorr_only         <= control_bytes(0)(0);

    -- control byte 1-2
    integ_period <= to_slv(control_bytes(1 to 2));

    -- Status Byte 0
    status_bytes(0)(0) <= or(overrun);

---------------------------------------------------------------------
-- Correlator input pipelining process
---------------------------------------------------------------------
-- Pipeline the reset and data buses inputs to facilitate routing and timing closure.
	process(clk)
	begin
		if rising_edge(clk) then
			rst_reg <= (others=> rst);

			-- Perform the corner-turn between the inputs by remapping the bytes
			for corr in 0 to NCORR-1 loop
				for chan in 0 to NCHAN-1 loop
					axis_corr_in_tdata(corr)(chan) <= s_axis_data_tdata(chan)(8*(NCORR-1-corr+1)-1 downto 8*(NCORR-1-corr)); 
				end loop;
				axis_corr_in_tvalid(corr) <= s_axis_data_tvalid;
				axis_corr_in_tlast(corr) <= s_axis_data_tlast;
			end loop;

		end if; -- clk
	end process;


-- Connect CORR[0] output stream to the ouput port
z_send(0) <= m_axis_data_tready; -- first corr sends data only if destination is ready
m_axis_data_tdata <= z_tdata(0);
m_axis_data_tvalid <= z_tvalid(0);
m_axis_data_tlast <= z_tlast(0);

-- Connect null stream to the cascade input of CORR[NCORR]
z_tvalid(NCORR) <= '0'; -- no data coming into the last corr
z_tdata(NCORR) <= (others => '0'); -- don't leave floating to prevent warnings
z_tlast(NCORR) <= '0'; -- don't leave floating to prevent warnings

corr_gen: for i in 0 to NCORR-1 generate
	-- set the position of the core44 core
	--attribute RLOC_ORIGIN of corr0: label is rpm_to_string(corr44_rpm(i).loc);
begin
	corr0: entity work.ucorr44
		generic map (
			PLATFORM_ID             => PLATFORM_ID,
			CORR_NUMBER             => i, -- will be used in the packet header and to determine the RPM location of the CORR44 cores
			N => NCHAN,
			N_PER_CLK => NCHAN,
			URAM_MAX => 64/NCORR
			)
		port map(
			s_axis_tvalid           => axis_corr_in_tvalid(i),
			s_axis_tlast            => axis_corr_in_tlast(i),
			s_axis_tdata            => axis_corr_in_tdata(i),

            integ_period => integ_period,
            autocorr_only => autocorr_only,
            no_accum => no_accum,
            overrun => overrun(i),

			z_out_tdata   => z_tdata(i),
			z_out_tvalid  => z_tvalid(i),
			z_out_tlast   => z_tlast(i),
			z_out_send  => z_send(i),

			z_in_tdata   => z_tdata(i+1),
			z_in_tvalid  => z_tvalid(i+1),
--			z_in_tvalid  => '0',
			z_in_tlast   => z_tlast(i+1),
			z_in_send  => z_send(i+1),
   
			clk                  => clk,
			rst                  => rst_reg(i)
			);

end generate;

end Behavioral;

