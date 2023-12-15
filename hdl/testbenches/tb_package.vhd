----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:   2013-05-22
-- Design Name:  chFPGA
-- Module Name:    testbench package
-- Project Name: CHIME
-- Target Devices: Kintex 7, Ultrascale+
-- Tool versions: Vivado 2013+
-- Description: provides helper functions needed for testbenches
--
-- Dependencies:
--
-- Revision: see GIT repo
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.chfpga_package.all;


-------- tb_package ------------
-- Provides helper functions needed for DFMUX testbenches
package tb_package is


	subtype OPCODE_TYPE is slv3;
	constant WRITE_CONTROL: OPCODE_TYPE        := "100";
	constant WRITE_CONTROL_MASK: OPCODE_TYPE   := "101";
	constant NOP: OPCODE_TYPE                  := "110";
	constant WRITE_RAM: OPCODE_TYPE            := "111";
	constant READ_CONTROL: OPCODE_TYPE         := "000";
	constant READ_STATUS: OPCODE_TYPE          := "010";
	constant READ_RAM: OPCODE_TYPE             := "011";

	procedure send_buffer( signal CLK : IN STD_LOGIC; signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0); signal tvalid: OUT STD_LOGIC; signal tlast: OUT STD_LOGIC; signal tready: in std_logic; data: IN slv8_array);
	function to_command_bytes( opcode: slv3; increment: integer:=1; log2_length: integer :=0; addr: integer) return slv8_array;
	procedure fpga_read(  signal CLK : IN STD_LOGIC;  signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0); signal tvalid: OUT STD_LOGIC; signal tlast: OUT STD_LOGIC; signal tready: in std_logic;  addr: integer; log2_length: integer := 0);
	procedure fpga_write_control(  signal CLK : IN STD_LOGIC;  signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0); signal tvalid: OUT STD_LOGIC; signal tlast: OUT STD_LOGIC;  signal tready: in std_logic; addr: integer; data: integer; nbytes: integer:=1);
	procedure fpga_write_control(  signal CLK : IN STD_LOGIC;  signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0); signal tvalid: OUT STD_LOGIC; signal tlast: OUT STD_LOGIC;  signal tready: in std_logic; addr: integer; data: std_logic_vector(7 downto 0));
	procedure fpga_write_mask(  signal CLK : IN STD_LOGIC;  signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0); signal tvalid: OUT STD_LOGIC; signal tlast: OUT STD_LOGIC;  signal tready: in std_logic; addr: integer; data: integer; mask:integer );
	procedure fpga_write_ram(  signal CLK : IN STD_LOGIC;  signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0); signal tvalid: OUT STD_LOGIC; signal tlast: OUT STD_LOGIC;  signal tready: in std_logic; addr: integer; data: slv8_array );
	procedure fpga_write_ram(  signal CLK : IN STD_LOGIC;  signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0); signal tvalid: OUT STD_LOGIC; signal tlast: OUT STD_LOGIC;  signal tready: in std_logic; addr: integer; data: slv_array);
	procedure fpga_select_bins( signal clk : in STD_LOGIC;  signal tdata: out STD_LOGIC_VECTOR(7 downto 0); signal tvalid: out std_logic; signal tlast: out STD_LOGIC;   signal tready: in std_logic; addr: integer;  first_bin: integer; bin_step: integer; number_of_bins: integer);
	procedure send_axis32_packet(signal clk: IN std_logic; signal m_axis_tdata: OUT slv32; signal m_axis_tvalid: out std_logic; signal m_axis_tlast: OUT std_logic; signal m_axis_tready: IN std_logic;data: IN slv32_array; period: in integer := 0);
	procedure send_axis_packet(signal clk: IN std_logic; signal m_axis_tdata: OUT std_logic_vector; signal m_axis_tvalid: out std_logic; signal m_axis_tlast: OUT std_logic; signal m_axis_tready: IN std_logic;data: IN slv_array; period: in integer := 0);
	procedure sleep (signal clk: IN std_logic; delay: IN integer:= 1);
	function create_packet(lane,packet,count: in integer) return slv32_array;




end tb_package;

package body tb_package is

--! @brief Sends an array of words to the UDP/MAC interface
	procedure send_buffer (
			signal clk : IN STD_LOGIC;
			signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0);
			signal tvalid: out std_logic;
			signal tlast: OUT STD_LOGIC;
			signal tready: in STD_LOGIC;

			data: IN slv8_array
			) is
	variable i: integer;
	variable dly: time := 10 ps;
	begin
		i := 0;
		while i < data'length loop
			if tready='1' then
				tdata <= data(i) after dly;
				tvalid <= '1' after dly;
				tlast <= to_std_logic(i = data'length-1) after dly;
				i := i + 1;
			end if;
			wait until clk='1';
		end loop;
		tvalid <='0' after dly;
		wait until clk='1'; -- wait an extra clock with valid=0 because the router seems to have a bug with consecutive frames
	end procedure send_buffer;



	--! Builds a command word based on its various fields
	function to_command_bytes( opcode: slv3; increment: integer:=1;  log2_length: integer :=0; addr: integer) return slv8_array is
		variable c: slv8_array(0 to 2);
	begin
		c(0)(7 downto 5) := opcode;
		c(0)(4 downto 3) := to_slv(log2_length, 2);
		c(0)(2 downto 0) := to_slv(addr/65536,3);
		c(1) := to_slv((addr/256) mod 256, 8);
		c(2) := to_slv(ADDR mod 256,8);
		return c;
	end to_command_bytes;


	--! Reads a single word from specified address

	procedure fpga_read (
			signal CLK : IN STD_LOGIC;
			signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0);
			signal tvalid: out std_logic;
			signal tlast: OUT STD_LOGIC;
			signal tready: in std_logic;
			-- port_number: in integer;
			-- module_number: in integer;
			addr: IN integer;
			log2_length: integer := 0
			) is
		variable buf: slv8_array(0 to 2);
		variable opcode: slv3;
		variable addr_vect: slv19;
	begin
		addr_vect := to_slv(addr, 19);
		if addr_vect(9)='1' then opcode := READ_RAM;
		elsif addr_vect(7)='1' then opcode := READ_STATUS;
		else opcode:=READ_CONTROL;
		end if;
		buf := to_command_bytes(opcode=>opcode, log2_length => log2_length, addr => addr);
		send_buffer(clk, tdata, tvalid, tlast, tready, buf);
	end procedure fpga_read;


      
    -- Writes one control byte specified as a std_logic_vector(7 downto 0)
	procedure fpga_write_control (
			signal CLK : IN STD_LOGIC;
			signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0);
			signal tvalid: out std_logic;
			signal tlast: OUT STD_LOGIC;
			signal tready: in std_logic;
			addr: IN integer;
			data: in std_logic_vector(7 downto 0)
			) is
		variable buf: slv8_array(0 to 3);
	begin
		buf(0 to 2) := to_command_bytes(opcode=> WRITE_CONTROL, addr=> addr);
		buf(3) := data;
		send_buffer(clk, tdata, tvalid, tlast, tready, buf);
	end procedure fpga_write_control;
	

    -- Writes a n-byte wide integer in the control registers. 
    -- The word is stored in big endian format.
    -- `addr` specifies the address of the first byte (the MSB)
	procedure fpga_write_control (
			signal CLK : IN STD_LOGIC;
			signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0);
			signal tvalid: out std_logic;
			signal tlast: OUT STD_LOGIC;
			signal tready: in std_logic;
			addr: IN integer;
			data: in integer;
			nbytes: in integer := 1
			) is
		variable buf: slv8_array(0 to 2+nbytes);
	begin
		buf(0 to 2) := to_command_bytes(opcode=> WRITE_CONTROL, addr=> addr);
		buf(3 to 3+nbytes-1) := to_slv8_array(to_unsigned(data, 8*nbytes));
		send_buffer(clk, tdata, tvalid, tlast, tready, buf);
	end procedure fpga_write_control;



	procedure fpga_write_ram (
			signal CLK : IN STD_LOGIC;
			signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0);
			signal tvalid: out std_logic;
			signal tlast: OUT STD_LOGIC;
			signal tready: in std_logic;
			addr: IN integer;
			data: in slv8_array
			) is
		variable buf: slv8_array(0 to 2 + data'LENGTH);
	begin
		buf(0 to 2) := to_command_bytes(opcode=> WRITE_RAM, addr=> addr);
		buf(3 to 2 + data'LENGTH) := data;
		send_buffer(clk, tdata, tvalid, tlast, tready, buf);
	end procedure fpga_write_ram;

	procedure fpga_write_ram (
			signal CLK : IN STD_LOGIC;
			signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0);
			signal tvalid: out std_logic;
			signal tlast: OUT STD_LOGIC;
			signal tready: in std_logic;
			addr: IN integer;
			data: in slv_array
			) is
		variable buf: slv8_array(0 to 2 + data'LENGTH);
	begin
		buf(0 to 2) := to_command_bytes(opcode=> WRITE_RAM, addr=> addr);
		buf(3 to 2 + data'LENGTH) := slv8_array(data);
		send_buffer(clk, tdata, tvalid, tlast, tready, buf);
	end procedure fpga_write_ram;

	procedure fpga_write_mask (
			signal CLK : IN STD_LOGIC;
			signal tdata: OUT STD_LOGIC_VECTOR(7 downto 0);
			signal tvalid: out std_logic;
			signal tlast: OUT STD_LOGIC;
			signal tready: in std_logic;
			-- port_number: in integer;
			-- module_number: in integer;
			addr: IN integer;
			data: in integer;
			mask: in integer
			) is
		variable buf: slv8_array(0 to 4);
		variable opcode: slv3;
		variable addr_vect: slv19;
	begin
		addr_vect := to_slv(addr, 19);
		opcode := WRITE_CONTROL_MASK;
		buf(0 to 2) := to_command_bytes(opcode=>opcode, addr => addr);
		buf(3) := to_slv(data,8);
		buf(4) := to_slv(mask,8);
		send_buffer(clk, tdata, tvalid, tlast, tready, buf);
	end procedure fpga_write_mask;



	procedure fpga_select_bins (
			signal clk : in STD_LOGIC;
			signal tdata: out STD_LOGIC_VECTOR(7 downto 0);
			signal tvalid: out std_logic;
			signal tlast: out STD_LOGIC;
			signal tready: in std_logic;
			addr: IN integer;
			first_bin: integer;
			bin_step: integer;
			number_of_bins: integer
			) is
		variable buf: slv8_array(0 to 1024/8-1);
		variable byte_index: integer;
		variable bit_index: integer;
		variable opcode: slv3;
	begin

		-- buf(0 to 2) := to_command_bytes(opcode => WRITE_RAM,  addr => addr);

		-- Clear the buffer
		for i in 0 to buf'LENGTH-1 loop
			buf(i) := to_slv(0,8);
		end loop;
		report "fpga_select_bins(): Selecting words";
		-- select the desired bins
		for i in 0 to number_of_bins-1 loop
			bit_index := first_bin + bin_step * i;
			buf(bit_index/8)(bit_index mod 8) := '1';
		end loop;
		report "fpga_select_bins(): Sending buffer words";
		fpga_write_ram(clk, tdata, tvalid, tlast, tready, addr, buf);
	end procedure fpga_select_bins;



	function create_packet(lane, packet, count: in integer) return slv32_array is
		variable word_array: slv32_array(0 to count-1);
		begin
			for i in 0 to count-1 loop
				word_array(i) := to_slv(lane,8) & to_slv(packet,8) & to_slv(i,16);
			end loop;
			return word_array;
		end function;

    -- Send a AXIS packet
	procedure send_axis_packet (
			signal clk: in std_logic;
			signal m_axis_tdata: out std_logic_vector;
			signal m_axis_tvalid: out std_logic;
			signal m_axis_tlast: out std_logic;
			signal m_axis_tready: in std_logic;
			data: in slv_array;
			period: in integer := 0 -- don't send another packet until `period` clock period from the previous one
			) is

	variable i: integer;
	variable clk_ctr: integer;
	begin
		-- variable tvalid: std_logic :='0';
		i := 0;
		clk_ctr := 0;
		loop
			-- if m_axis_tready='1' then
			-- 	m_axis_tvalid='0';
			-- end if;
			m_axis_tdata <= data(i);
			m_axis_tvalid <= '1';
			if i = data'length-1 then
				m_axis_tlast <= '1';
			else
				m_axis_tlast <= '0';
			end if;
			wait until clk='1';
			clk_ctr := clk_ctr + 1;
			if m_axis_tready='1' then
				if i = data'length-1 then
					exit;
				else
					i := i + 1;
				end if;
			end if;
		end loop;
		m_axis_tvalid <= '0';
		while clk_ctr < period loop
			wait until clk='1';
			clk_ctr := clk_ctr + 1;
		end loop;
	end procedure send_axis_packet;


--! @brief Sends an AXIS32 frame
	procedure send_axis32_packet (
			signal clk: in std_logic;
			signal m_axis_tdata: out slv32;
			signal m_axis_tvalid: out std_logic;
			signal m_axis_tlast: out std_logic;
			signal m_axis_tready: in std_logic;
			data: in slv32_array;
			period: in integer := 0
			) is

	variable i: integer;
	variable clk_ctr: integer;
	begin
		-- variable tvalid: std_logic :='0';
		i := 0;
		clk_ctr := 0;
		loop
			-- if m_axis_tready='1' then
			-- 	m_axis_tvalid='0';
			-- end if;
			m_axis_tdata <= data(i);
			m_axis_tvalid <= '1';
			if i = data'length-1 then
				m_axis_tlast <= '1';
			else
				m_axis_tlast <= '0';
			end if;
			wait until clk='1';
			clk_ctr := clk_ctr + 1;
			if m_axis_tready='1' then
				if i = data'length-1 then
					exit;
				else
					i := i + 1;
				end if;
			end if;
		end loop;
		m_axis_tvalid <= '0';
		while clk_ctr < period loop
			wait until clk='1';
			clk_ctr := clk_ctr + 1;
		end loop;
	end procedure send_axis32_packet;


--! @brief Sends an AXIS32 frame
	procedure sleep (
			signal clk: IN std_logic;
			delay: IN integer := 1
			) is
	begin
		-- variable tvalid: std_logic :='0';
		for i in 0 to delay-1 loop
			wait until CLK='1';
		end loop;
	end procedure sleep;



end tb_package;
