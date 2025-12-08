----------------------------------------------------------------------------------
-- Description: Core firmware registers
-- Company: McGill University
-- Engineers: JF Cliche (JFC Inc) & Graeme Smecher (Three-Speed Logic, Inc)
--
-- Create Date:    2015-01-06
-- Design Name:    ICE development environment
-- Module Name:    icecore
-- Project Name:   Generic
-- Target Devices:  Kintex 7 on IceBoard (McGill Model MGK7MB)
-- Tool versions:  Vivado 2014.4

---  LIBRARY DECLARATIONS ------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all; -- needed for ceil()

library UNISIM;
use UNISIM.VComponents.all;

use work.irigb_package.all;

-- Implements an array of 32-bit core registers accessible via a 32-bit req/ack-type  bus and a 8-bit rd_en/wr_en-type bus.
entity core_registers is
	generic (
		ADDRESS_MASK: std_logic_vector(31 downto 0); -- X"000010--" means that we respond to s_addr(31:16)=x"000010" and that we have 8 bits of local address (i.e. 64 registers or less)
		NUMBER_OF_REGISTERS: integer := 1;
		DEFAULT_REGISTER_VALUES: slv32_array;
		ADDRESS_WIDTH: integer := 32;  -- For the 32-bit interface
		BYTE_ADDRESS_WIDTH: integer := integer(ceil(log2(real(4*NUMBER_OF_REGISTERS)))); -- for the 8-bit interface
		SIM: BOOLEAN:= FALSE -- Indicates this is running as a simulation. Used to accelerate simulations
	);
	port (
		-- 32-bit control interface

		s_addr: in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
		s_wdat: in std_logic_vector(31 downto 0);
		s_rdat: out std_logic_vector(31 downto 0);
		s_wreq: in std_logic;
		s_wack: out std_logic;
		s_rreq: in std_logic;
		s_rack: out std_logic;

		-- Registers

		reg_wr_value : out slv32_array(0 to NUMBER_OF_REGISTERS-1) := DEFAULT_REGISTER_VALUES(0 to NUMBER_OF_REGISTERS-1);
		reg_rd_value : in slv32_array(0 to NUMBER_OF_REGISTERS-1) := (others=> (others=>'0'));

		-- Alternate 8-bit control interface

		din: in std_logic_vector(7 downto 0);
		dout: out std_logic_vector(7 downto 0);
		addr: in std_logic_vector(BYTE_ADDRESS_WIDTH-1 downto 0); -- this is a byte address
		wr_en: in std_logic;
		rd_en: in std_logic;

		clk: in std_logic -- Control interface clock
	);
end core_registers;

architecture IMPL of core_registers is

	constant WORD_ADDRESS_WIDTH: integer := BYTE_ADDRESS_WIDTH - 2; -- word address width. We ignore the address mask

	signal local_addr: unsigned(WORD_ADDRESS_WIDTH-1 downto 0) := (others => '0');
	signal s_wdat_int: std_logic_vector(31 downto 0) := (others => '0');

	-- Masked request signals (zero if outside valid address range)
	signal s_rreq_int: std_logic;
	signal s_wreq_int: std_logic;

begin

	---------------------------------------------------------------------
	-- Register access process
	---------------------------------------------------------------------

	reg_proc: process(all)
		variable reg_number_var: integer range 0 to NUMBER_OF_REGISTERS-1;
		variable byte_number_var: integer range 0 to 3;
	begin
		if rising_edge(clk) then

			local_addr <= unsigned(s_addr(WORD_ADDRESS_WIDTH + 1 downto 2)); -- strip last two bits to convert byte address to word address;
			reg_number_var := to_integer(local_addr); -- To do: add checks against actual number of registers
			s_wdat_int <= s_wdat;
			s_rdat <= (others => '0'); -- This is important to make sure that s_rdat is 0 when we are not accessing this module.

			if s_addr(ADDRESS_WIDTH - 1 downto WORD_ADDRESS_WIDTH + 2) = ADDRESS_MASK(ADDRESS_WIDTH - 1 downto WORD_ADDRESS_WIDTH + 2) then
				s_rreq_int <= s_rreq;
				s_wreq_int <= s_wreq;
			else
				s_rreq_int <= '0';
				s_wreq_int <= '0';
			end if;

			-- 32-bit Writes & ack
			reg_wr_value(reg_number_var) <= s_wdat_int when s_wreq_int;
			s_wack <= s_wreq_int;

			-- 32-bit Reads & ack
			s_rdat <= reg_rd_value(reg_number_var) when s_rreq_int;
			s_rack <= s_rreq_int;



			-- 8-bit interface variables
			reg_number_var := to_integer(unsigned(addr(addr'LEFT downto 2))); --
			byte_number_var := to_integer(unsigned(addr(1 downto 0)));

			-- 8-bit write
			reg_wr_value(reg_number_var)(byte_number_var * 8 + 7 downto byte_number_var * 8) <= din when wr_en;  -- little endian storage

			-- 8-bit read
			dout <= reg_rd_value(reg_number_var)(byte_number_var*8+7 downto byte_number_var*8) when rd_en; -- little endian storage

		end if; -- clk
	end process;

end IMPL;

