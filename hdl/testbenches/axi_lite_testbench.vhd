----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Testbench for axi_lite: 16-bit RAM port to AXI4-Lite master (PG203 byte map).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use std.env.finish;

library work;

entity axi_lite_testbench is
	generic (
		RAM_ADDR_WIDTH  : positive := 14;
		AXI_ADDR_WIDTH  : positive := 32;
		AXI_DATA_WIDTH  : positive := 32;
		TEST_FABRIC_CFG : boolean  := TRUE
	);
end entity axi_lite_testbench;

architecture sim of axi_lite_testbench is

	constant CLK_PERIOD : time := 10 ns;
	constant TEST_ADDR   : natural := 16#000C#;

	signal clk : std_logic := '0';
	signal rst : std_logic := '1';

	signal ram_din      : std_logic_vector(15 downto 0);
	signal ram_dout     : std_logic_vector(15 downto 0);
	signal ram_addr     : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
	signal ram_wr_en    : std_logic := '0';
	signal ram_rd_en    : std_logic := '0';
	signal ram_en       : std_logic := '0';
	signal ram_dout_rdy : std_logic;

	signal fabric_cfg_wr    : std_logic := '0';
	signal fabric_cfg_addr  : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0) := (others => '0');
	signal fabric_cfg_wdata : std_logic_vector(AXI_DATA_WIDTH - 1 downto 0) := (others => '0');
	signal fabric_cfg_done  : std_logic;

	signal m_axi_awaddr  : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
	signal m_axi_awvalid : std_logic;
	signal m_axi_awready : std_logic := '1';
	signal m_axi_wdata   : std_logic_vector(AXI_DATA_WIDTH - 1 downto 0);
	signal m_axi_wstrb   : std_logic_vector(AXI_DATA_WIDTH / 8 - 1 downto 0);
	signal m_axi_wvalid  : std_logic;
	signal m_axi_wready  : std_logic := '1';
	signal m_axi_bresp   : std_logic_vector(1 downto 0) := "00";
	signal m_axi_bvalid  : std_logic := '0';
	signal m_axi_bready  : std_logic;

	signal m_axi_araddr  : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
	signal m_axi_arvalid : std_logic;
	signal m_axi_arready : std_logic := '1';
	signal m_axi_rdata   : std_logic_vector(AXI_DATA_WIDTH - 1 downto 0) := (others => '0');
	signal m_axi_rresp   : std_logic_vector(1 downto 0) := "00";
	signal m_axi_rvalid  : std_logic := '0';
	signal m_axi_rready  : std_logic;

	signal slave_mem : std_logic_vector(AXI_DATA_WIDTH - 1 downto 0) := (others => '0');

	----------------------------------------------------------------------------
	procedure ram_write_halfword(
		signal p_clk       : in  std_logic;
		signal p_ram_en    : out std_logic;
		signal p_ram_wr_en : out std_logic;
		signal p_ram_rd_en : out std_logic;
		signal p_ram_addr  : out std_logic_vector;
		signal p_ram_din   : out std_logic_vector(15 downto 0);
		signal p_ram_rdy   : in  std_logic;
		constant byte_addr : in  natural;
		constant hw        : in  std_logic_vector(15 downto 0)
	) is
	begin
		p_ram_addr  <= std_logic_vector(to_unsigned(byte_addr, p_ram_addr'length));
		p_ram_din   <= hw;
		p_ram_wr_en <= '1';
		p_ram_rd_en <= '0';
		p_ram_en    <= '1';
		wait until rising_edge(p_clk);
		p_ram_en    <= '0';
		p_ram_wr_en <= '0';
		wait until p_ram_rdy = '1';
	end procedure ram_write_halfword;

	procedure ram_read_halfword(
		signal p_clk       : in  std_logic;
		signal p_ram_en    : out std_logic;
		signal p_ram_wr_en : out std_logic;
		signal p_ram_rd_en : out std_logic;
		signal p_ram_addr  : out std_logic_vector;
		signal p_ram_dout  : in  std_logic_vector(15 downto 0);
		signal p_ram_rdy   : in  std_logic;
		variable hw        : out std_logic_vector(15 downto 0);
		constant byte_addr : in  natural
	) is
	begin
		p_ram_addr  <= std_logic_vector(to_unsigned(byte_addr, p_ram_addr'length));
		p_ram_wr_en <= '0';
		p_ram_rd_en <= '1';
		p_ram_en    <= '1';
		wait until rising_edge(p_clk);
		p_ram_en    <= '0';
		p_ram_rd_en <= '0';
		wait until p_ram_rdy = '1';
		hw := p_ram_dout;
	end procedure ram_read_halfword;

	procedure write_word_be(
		signal p_clk       : in  std_logic;
		signal p_ram_en    : out std_logic;
		signal p_ram_wr_en : out std_logic;
		signal p_ram_rd_en : out std_logic;
		signal p_ram_addr  : out std_logic_vector;
		signal p_ram_din   : out std_logic_vector(15 downto 0);
		signal p_ram_rdy   : in  std_logic;
		constant base      : in  natural;
		constant value    : in  std_logic_vector(31 downto 0)
	) is
	begin
		ram_write_halfword(p_clk, p_ram_en, p_ram_wr_en, p_ram_rd_en, p_ram_addr, p_ram_din, p_ram_rdy, base + 0, value(31 downto 16));
		ram_write_halfword(p_clk, p_ram_en, p_ram_wr_en, p_ram_rd_en, p_ram_addr, p_ram_din, p_ram_rdy, base + 2, value(15 downto 0));
	end procedure write_word_be;

	procedure read_word_be(
		signal p_clk       : in  std_logic;
		signal p_ram_en    : out std_logic;
		signal p_ram_wr_en : out std_logic;
		signal p_ram_rd_en : out std_logic;
		signal p_ram_addr  : out std_logic_vector;
		signal p_ram_dout  : in  std_logic_vector(15 downto 0);
		signal p_ram_rdy   : in  std_logic;
		constant base      : in  natural;
		variable word      : out std_logic_vector(31 downto 0)
	) is
		variable hi, lo : std_logic_vector(15 downto 0);
	begin
		ram_read_halfword(p_clk, p_ram_en, p_ram_wr_en, p_ram_rd_en, p_ram_addr, p_ram_dout, p_ram_rdy, hi, base + 0);
		ram_read_halfword(p_clk, p_ram_en, p_ram_wr_en, p_ram_rd_en, p_ram_addr, p_ram_dout, p_ram_rdy, lo, base + 2);
		word := hi & lo;
	end procedure read_word_be;

	procedure sleep(signal p_clk : in std_logic; delay : in integer := 1) is
	begin
		for i in 1 to delay loop
			wait until rising_edge(p_clk);
		end loop;
	end procedure sleep;

	procedure check_eq(
		constant got  : in std_logic_vector;
		constant exp  : in std_logic_vector;
		constant name : in string
	) is
	begin
		if got /= exp then
			report name & ": expected " & to_hstring(exp) & ", got " & to_hstring(got) severity failure;
		end if;
	end procedure check_eq;

begin

	clk <= not clk after CLK_PERIOD / 2;

	dut : entity work.axi_lite
		generic map (
			RAM_ADDR_WIDTH => RAM_ADDR_WIDTH,
			AXI_ADDR_WIDTH => AXI_ADDR_WIDTH,
			AXI_DATA_WIDTH => AXI_DATA_WIDTH
		)
		port map (
			clk => clk,
			rst => rst,
			RAM_DIN      => ram_din,
			RAM_DOUT     => ram_dout,
			RAM_ADDR     => ram_addr,
			RAM_WR_EN    => ram_wr_en,
			RAM_RD_EN    => ram_rd_en,
			RAM_EN       => ram_en,
			RAM_DOUT_RDY => ram_dout_rdy,
			fabric_cfg_wr    => fabric_cfg_wr,
			fabric_cfg_addr  => fabric_cfg_addr,
			fabric_cfg_wdata => fabric_cfg_wdata,
			fabric_cfg_done  => fabric_cfg_done,
			m_axi_awaddr  => m_axi_awaddr,
			m_axi_awvalid => m_axi_awvalid,
			m_axi_awready => m_axi_awready,
			m_axi_wdata   => m_axi_wdata,
			m_axi_wstrb   => m_axi_wstrb,
			m_axi_wvalid  => m_axi_wvalid,
			m_axi_wready  => m_axi_wready,
			m_axi_bresp   => m_axi_bresp,
			m_axi_bvalid  => m_axi_bvalid,
			m_axi_bready  => m_axi_bready,
			m_axi_araddr  => m_axi_araddr,
			m_axi_arvalid => m_axi_arvalid,
			m_axi_arready => m_axi_arready,
			m_axi_rdata   => m_axi_rdata,
			m_axi_rresp   => m_axi_rresp,
			m_axi_rvalid  => m_axi_rvalid,
			m_axi_rready  => m_axi_rready
		);

	axi_slave : process(clk) is
		variable awaddr_v   : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
		variable aw_pending : boolean := false;
		variable w_pending  : boolean := false;
		variable b_pending  : boolean := false;
		variable rdata_reg  : std_logic_vector(AXI_DATA_WIDTH - 1 downto 0);
		variable r_armed    : boolean := false;
		variable r_resp     : boolean := false;
	begin
		if rising_edge(clk) then
			m_axi_bvalid <= '0';
			m_axi_rvalid <= '0';
			if rst = '0' then
				if m_axi_awvalid = '1' then
					awaddr_v   := m_axi_awaddr;
					aw_pending := true;
				end if;
				if m_axi_wvalid = '1' then
					w_pending := true;
				end if;
				if aw_pending and w_pending then
					if awaddr_v = std_logic_vector(to_unsigned(TEST_ADDR, AXI_ADDR_WIDTH)) then
						slave_mem <= m_axi_wdata;
					end if;
					aw_pending := false;
					w_pending  := false;
					b_pending  := true;
				end if;
				if b_pending then
					m_axi_bvalid <= '1';
					if m_axi_bready = '1' then
						b_pending := false;
					end if;
				end if;
				if m_axi_arvalid = '1' and not r_armed then
					if m_axi_araddr = std_logic_vector(to_unsigned(TEST_ADDR, AXI_ADDR_WIDTH)) then
						rdata_reg := slave_mem;
					else
						rdata_reg := (others => '0');
					end if;
					m_axi_rdata <= rdata_reg;
					r_armed     := true;
					r_resp      := false;
				elsif r_armed and not r_resp then
					m_axi_rdata <= rdata_reg;
					r_resp      := true;
				elsif r_armed and r_resp then
					m_axi_rdata  <= rdata_reg;
					m_axi_rvalid <= '1';
					if m_axi_rready = '1' then
						r_armed := false;
						r_resp  := false;
					end if;
				end if;
			else
				aw_pending := false;
				w_pending  := false;
				b_pending  := false;
				r_armed    := false;
				r_resp     := false;
			end if;
		end if;
	end process axi_slave;

	rst_proc : process
	begin
		rst <= '1';
		sleep(clk, 5);
		rst <= '0';
		sleep(clk, 2);
		wait;
	end process rst_proc;

	stim_proc : process
		variable rd_word : std_logic_vector(31 downto 0);
	begin
		wait until rst = '0';
		sleep(clk, 2);

		write_word_be(clk, ram_en, ram_wr_en, ram_rd_en, ram_addr, ram_din, ram_dout_rdy, TEST_ADDR, x"AABBCCDD");
		sleep(clk, 4);
		read_word_be(clk, ram_en, ram_wr_en, ram_rd_en, ram_addr, ram_dout, ram_dout_rdy, TEST_ADDR, rd_word);
		check_eq(rd_word, x"AABBCCDD", "RD_WORD");

		if TEST_FABRIC_CFG then
			fabric_cfg_addr  <= std_logic_vector(to_unsigned(TEST_ADDR, AXI_ADDR_WIDTH));
			fabric_cfg_wdata <= x"00000001";
			fabric_cfg_wr    <= '1';
			wait until rising_edge(clk);
			fabric_cfg_wr <= '0';
			wait until fabric_cfg_done = '1';
			check_eq(slave_mem, x"00000001", "FABRIC_WDATA");
		end if;

		report "axi_lite_testbench: all tests passed" severity note;
		sleep(clk, 4);
		finish;
	end process stim_proc;

end architecture sim;
