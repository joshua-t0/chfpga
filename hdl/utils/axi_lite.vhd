----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2026-05-28
-- Module Name:    axi_lite
-- Target Devices: Ultrascale+
-- Tool versions:  Vivado 2022.2
-- Description:    16-bit bsb_regs RAM port to AXI4-Lite master (CMAC US+ PG203).
--
-- One 16-bit RAM beat per access; two halfwords per 32-bit AXI register.
-- RAM_ADDR is a byte address. Halfword lane = RAM_ADDR(1):
--   lane 0 (addr bit1='0') -> AXI [31:16]; lane 1 -> AXI [15:0].
--
-- fabric_cfg_*: one-shot full-word AXI write (cge CONFIGURATION_TX_REG1).
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi_lite is
	generic (
		RAM_ADDR_WIDTH : positive := 14;
		AXI_ADDR_WIDTH : positive := 32;
		AXI_DATA_WIDTH : positive := 32
	);
	port (
		clk   : in  std_logic;
		rst   : in  std_logic;

		RAM_DIN      : in  std_logic_vector(15 downto 0);
		RAM_DOUT     : out std_logic_vector(15 downto 0);
		RAM_ADDR     : in  std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
		RAM_WR_EN    : in  std_logic;
		RAM_RD_EN    : in  std_logic;
		RAM_EN       : in  std_logic;
		RAM_DOUT_RDY : out std_logic;

		fabric_cfg_wr    : in  std_logic := '0';
		fabric_cfg_addr  : in  std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0) := (others => '0');
		fabric_cfg_wdata : in  std_logic_vector(AXI_DATA_WIDTH - 1 downto 0) := (others => '0');
		fabric_cfg_done  : out std_logic;

		m_axi_awaddr  : out std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
		m_axi_awvalid : out std_logic;
		m_axi_awready : in  std_logic;

		m_axi_wdata  : out std_logic_vector(AXI_DATA_WIDTH - 1 downto 0);
		m_axi_wstrb  : out std_logic_vector(AXI_DATA_WIDTH / 8 - 1 downto 0);
		m_axi_wvalid : out std_logic;
		m_axi_wready : in  std_logic;

		m_axi_bresp  : in  std_logic_vector(1 downto 0);
		m_axi_bvalid : in  std_logic;
		m_axi_bready : out std_logic;

		m_axi_araddr  : out std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
		m_axi_arvalid : out std_logic;
		m_axi_arready : in  std_logic;

		m_axi_rdata  : in  std_logic_vector(AXI_DATA_WIDTH - 1 downto 0);
		m_axi_rresp  : in  std_logic_vector(1 downto 0);
		m_axi_rvalid : in  std_logic;
		m_axi_rready : out std_logic
	);
end entity axi_lite;

architecture impl of axi_lite is

	constant WORD_BASE_HI : positive := RAM_ADDR_WIDTH - 2;

	type axi_state_type is (idle, w_aw, w_w, w_b, r_ar, r_r);
	type pending_kind_type is (pending_none, pending_wr, pending_rd);

	signal axi_state       : axi_state_type := idle;
	signal pending_kind    : pending_kind_type := pending_none;
	signal pending_addr    : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
	signal pending_wdata   : std_logic_vector(AXI_DATA_WIDTH - 1 downto 0);
	signal pending_lane_hi : std_logic;

	signal buf             : std_logic_vector(AXI_DATA_WIDTH - 1 downto 0);
	signal cache           : std_logic_vector(AXI_DATA_WIDTH - 1 downto 0);
	signal cache_valid     : std_logic := '0';
	signal cache_word_base : std_logic_vector(WORD_BASE_HI - 1 downto 0);

	signal ram_en_d1         : std_logic := '0';
	signal ram_wr_en_d1      : std_logic := '0';
	signal ram_rd_en_d1      : std_logic := '0';
	signal ram_addr_d1        : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
	signal ram_din_d1         : std_logic_vector(15 downto 0);
	signal wr_commit_pending  : std_logic := '0';

	signal fabric_pending   : std_logic := '0';
	signal fabric_addr_lat  : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
	signal fabric_wdata_lat : std_logic_vector(AXI_DATA_WIDTH - 1 downto 0);
	signal fabric_wr_active : std_logic := '0';
	signal fabric_done_int  : std_logic := '0';

	signal wr_commit_rdy : std_logic := '0';

	----------------------------------------------------------------------------
	function word_addr(
		base : std_logic_vector(WORD_BASE_HI - 1 downto 0)
	) return std_logic_vector is
	begin
		return std_logic_vector(resize(unsigned(base), AXI_ADDR_WIDTH) sll 2);
	end function word_addr;

	function word_base_from_addr(
		addr : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0)
	) return std_logic_vector is
	begin
		return std_logic_vector(resize(unsigned(addr) srl 2, WORD_BASE_HI));
	end function word_base_from_addr;

	function word_base_from_axi(
		ax_addr : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0)
	) return std_logic_vector is
	begin
		return std_logic_vector(resize(unsigned(ax_addr) srl 2, WORD_BASE_HI));
	end function word_base_from_axi;

	function slice_halfword(
		word   : std_logic_vector(AXI_DATA_WIDTH - 1 downto 0);
		lane_hi : std_logic
	) return std_logic_vector is
	begin
		if lane_hi = '1' then
			return word(15 downto 0);
		else
			return word(31 downto 16);
		end if;
	end function slice_halfword;

	procedure insert_halfword(
		variable word    : inout std_logic_vector(AXI_DATA_WIDTH - 1 downto 0);
		lane_hi         :       std_logic;
		data            :       std_logic_vector(15 downto 0)
	) is
	begin
		if lane_hi = '1' then
			word(15 downto 0) := data;
		else
			word(31 downto 16) := data;
		end if;
	end procedure insert_halfword;

begin

	m_axi_bready <= '1';
	m_axi_rready <= '1';
	m_axi_wstrb  <= (others => '1');
	fabric_cfg_done <= fabric_done_int;

	ram_cap: process(clk) is
	begin
		if rising_edge(clk) then
			if rst then
				ram_en_d1    <= '0';
				ram_wr_en_d1 <= '0';
				ram_rd_en_d1 <= '0';
			else
				ram_en_d1 <= RAM_EN;
				if RAM_EN = '1' then
					ram_wr_en_d1 <= RAM_WR_EN;
					ram_rd_en_d1 <= RAM_RD_EN;
					ram_addr_d1  <= RAM_ADDR;
					ram_din_d1   <= RAM_DIN;
				end if;
			end if;
		end if;
	end process ram_cap;

	main_proc: process(clk) is
		variable lane_hi   : std_logic;
		variable wbase     : std_logic_vector(WORD_BASE_HI - 1 downto 0);
		variable ax_addr   : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
		variable assembled : std_logic_vector(AXI_DATA_WIDTH - 1 downto 0);
		variable fabric_arm : boolean;
	begin
		if rising_edge(clk) then
			fabric_arm := false;
			RAM_DOUT_RDY    <= '0';
			wr_commit_rdy   <= '0';
			fabric_done_int <= '0';

			if rst then
				wr_commit_pending <= '0';
				axi_state         <= idle;
				pending_kind      <= pending_none;
				cache_valid       <= '0';
				m_axi_awvalid     <= '0';
				m_axi_wvalid      <= '0';
				m_axi_arvalid     <= '0';
				m_axi_awaddr      <= (others => '0');
				m_axi_wdata       <= (others => '0');
				m_axi_araddr      <= (others => '0');
				RAM_DOUT          <= (others => '0');
				fabric_pending    <= '0';
				fabric_wr_active  <= '0';
			else
				if fabric_cfg_wr = '1' and fabric_pending = '0' then
					fabric_addr_lat  <= fabric_cfg_addr;
					fabric_wdata_lat <= fabric_cfg_wdata;
					fabric_pending   <= '1';
					fabric_arm       := true;
				end if;

				if axi_state = w_b and m_axi_bvalid = '1' then
					axi_state     <= idle;
					m_axi_awvalid <= '0';
					m_axi_wvalid  <= '0';
					pending_kind  <= pending_none;
					wr_commit_rdy <= '1';
					if fabric_wr_active = '1' then
						fabric_done_int  <= '1';
						fabric_wr_active <= '0';
					end if;
				end if;

				if axi_state = w_aw and m_axi_awready = '1' then
					m_axi_awvalid <= '0';
					m_axi_wvalid  <= '1';
					axi_state     <= w_w;
				elsif axi_state = w_w and m_axi_wready = '1' then
					m_axi_wvalid <= '0';
					axi_state    <= w_b;
				end if;

				if (axi_state = r_ar or axi_state = r_r) and m_axi_rvalid = '1' then
					cache           <= m_axi_rdata;
					cache_valid     <= '1';
					cache_word_base <= word_base_from_axi(pending_addr);
					axi_state       <= idle;
					pending_kind    <= pending_none;
					m_axi_arvalid   <= '0';
					RAM_DOUT        <= slice_halfword(m_axi_rdata, pending_lane_hi);
					RAM_DOUT_RDY    <= '1';
				elsif axi_state = r_ar and m_axi_arready = '1' then
					m_axi_arvalid <= '0';
					axi_state     <= r_r;
				end if;

				if axi_state = idle and pending_kind /= pending_none then
					if pending_kind = pending_wr then
						m_axi_awaddr  <= pending_addr;
						m_axi_wdata   <= pending_wdata;
						m_axi_awvalid <= '1';
						m_axi_wvalid  <= '0';
						axi_state     <= w_aw;
						pending_kind  <= pending_none;
						if cache_valid = '1' and cache_word_base = word_base_from_axi(pending_addr) then
							cache_valid <= '0';
						end if;
					else
						m_axi_araddr  <= pending_addr;
						m_axi_arvalid <= '1';
						axi_state     <= r_ar;
						pending_kind  <= pending_none;
					end if;
				end if;

				if (fabric_pending = '1' or fabric_arm) and axi_state = idle and pending_kind = pending_none and ram_en_d1 = '0' then
					pending_kind     <= pending_wr;
					pending_addr     <= fabric_cfg_addr when fabric_arm else fabric_addr_lat;
					pending_wdata    <= fabric_cfg_wdata when fabric_arm else fabric_wdata_lat;
					fabric_pending   <= '0';
					fabric_wr_active <= '1';
				end if;

				if ram_en_d1 = '1' and axi_state = idle and pending_kind = pending_none and fabric_pending = '0' then
					lane_hi := ram_addr_d1(1);
					wbase   := word_base_from_addr(ram_addr_d1);
					ax_addr := word_addr(wbase);

					if ram_rd_en_d1 = '1' then
						if cache_valid = '1' and cache_word_base = wbase then
							RAM_DOUT     <= slice_halfword(cache, lane_hi);
							RAM_DOUT_RDY <= '1';
						else
							pending_kind      <= pending_rd;
							pending_addr      <= ax_addr;
							pending_lane_hi   <= lane_hi;
							pending_wdata     <= (others => '0');
						end if;
					elsif ram_wr_en_d1 = '1' then
						assembled := buf;
						insert_halfword(assembled, lane_hi, ram_din_d1);
						buf <= assembled;
						if lane_hi = '1' then
							pending_kind      <= pending_wr;
							pending_addr      <= ax_addr;
							pending_wdata     <= assembled;
							wr_commit_pending <= '1';
						else
							RAM_DOUT_RDY <= '1';
						end if;
					end if;

				elsif ram_en_d1 = '1' and axi_state /= idle then
					null;
				end if;

				if wr_commit_rdy = '1' and wr_commit_pending = '1' then
					RAM_DOUT_RDY      <= '1';
					wr_commit_pending <= '0';
				end if;

			end if;
		end if;
	end process main_proc;

end architecture impl;
