--Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2021.1 (lin64) Build 3247384 Thu Jun 10 19:36:07 MDT 2021
--Date        : Wed Oct 13 01:16:01 2021
--Host        : lbcontrol running 64-bit Ubuntu 20.04.3 LTS
--Command     : generate_target sifpga_zcu111_wrapper.bd
--Design      : sifpga_zcu111_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity sifpga_zcu111_wrapper is
  port (
    CLK_125_clk_n : in STD_LOGIC;
    CLK_125_clk_p : in STD_LOGIC;
    FPGA_REFCLK_OUT_C_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    FPGA_REFCLK_OUT_C_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    SYSREF_FPGA_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    SYSREF_FPGA_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    adc0_clk_clk_n : in STD_LOGIC;
    adc0_clk_clk_p : in STD_LOGIC;
    adc1_clk_clk_n : in STD_LOGIC;
    adc1_clk_clk_p : in STD_LOGIC;
    adc2_clk_clk_n : in STD_LOGIC;
    adc2_clk_clk_p : in STD_LOGIC;
    adc3_clk_clk_n : in STD_LOGIC;
    adc3_clk_clk_p : in STD_LOGIC;
    led_8bits_tri_o : out STD_LOGIC_VECTOR ( 7 downto 0 );
    vin0_01_v_n : in STD_LOGIC;
    vin0_01_v_p : in STD_LOGIC;
    vin0_23_v_n : in STD_LOGIC;
    vin0_23_v_p : in STD_LOGIC;
    vin1_01_v_n : in STD_LOGIC;
    vin1_01_v_p : in STD_LOGIC;
    vin1_23_v_n : in STD_LOGIC;
    vin1_23_v_p : in STD_LOGIC;
    vin2_01_v_n : in STD_LOGIC;
    vin2_01_v_p : in STD_LOGIC;
    vin2_23_v_n : in STD_LOGIC;
    vin2_23_v_p : in STD_LOGIC;
    vin3_01_v_n : in STD_LOGIC;
    vin3_01_v_p : in STD_LOGIC;
    vin3_23_v_n : in STD_LOGIC;
    vin3_23_v_p : in STD_LOGIC
  );
end sifpga_zcu111_wrapper;

architecture STRUCTURE of sifpga_zcu111_wrapper is
  component sifpga_zcu111 is
  port (
    CLK_125_clk_p : in STD_LOGIC;
    CLK_125_clk_n : in STD_LOGIC;
    adc0_clk_clk_n : in STD_LOGIC;
    adc0_clk_clk_p : in STD_LOGIC;
    adc1_clk_clk_n : in STD_LOGIC;
    adc1_clk_clk_p : in STD_LOGIC;
    adc2_clk_clk_n : in STD_LOGIC;
    adc2_clk_clk_p : in STD_LOGIC;
    adc3_clk_clk_n : in STD_LOGIC;
    adc3_clk_clk_p : in STD_LOGIC;
    led_8bits_tri_o : out STD_LOGIC_VECTOR ( 7 downto 0 );
    SYSREF_FPGA_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    SYSREF_FPGA_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    FPGA_REFCLK_OUT_C_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    FPGA_REFCLK_OUT_C_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    vin0_01_v_n : in STD_LOGIC;
    vin0_01_v_p : in STD_LOGIC;
    vin0_23_v_n : in STD_LOGIC;
    vin0_23_v_p : in STD_LOGIC;
    vin1_01_v_n : in STD_LOGIC;
    vin1_01_v_p : in STD_LOGIC;
    vin1_23_v_n : in STD_LOGIC;
    vin1_23_v_p : in STD_LOGIC;
    vin2_01_v_n : in STD_LOGIC;
    vin2_01_v_p : in STD_LOGIC;
    vin2_23_v_n : in STD_LOGIC;
    vin2_23_v_p : in STD_LOGIC;
    vin3_01_v_n : in STD_LOGIC;
    vin3_01_v_p : in STD_LOGIC;
    vin3_23_v_n : in STD_LOGIC;
    vin3_23_v_p : in STD_LOGIC
  );
  end component sifpga_zcu111;
begin
sifpga_zcu111_i: component sifpga_zcu111
     port map (
      CLK_125_clk_n => CLK_125_clk_n,
      CLK_125_clk_p => CLK_125_clk_p,
      FPGA_REFCLK_OUT_C_clk_n(0) => FPGA_REFCLK_OUT_C_clk_n(0),
      FPGA_REFCLK_OUT_C_clk_p(0) => FPGA_REFCLK_OUT_C_clk_p(0),
      SYSREF_FPGA_clk_n(0) => SYSREF_FPGA_clk_n(0),
      SYSREF_FPGA_clk_p(0) => SYSREF_FPGA_clk_p(0),
      adc0_clk_clk_n => adc0_clk_clk_n,
      adc0_clk_clk_p => adc0_clk_clk_p,
      adc1_clk_clk_n => adc1_clk_clk_n,
      adc1_clk_clk_p => adc1_clk_clk_p,
      adc2_clk_clk_n => adc2_clk_clk_n,
      adc2_clk_clk_p => adc2_clk_clk_p,
      adc3_clk_clk_n => adc3_clk_clk_n,
      adc3_clk_clk_p => adc3_clk_clk_p,
      led_8bits_tri_o(7 downto 0) => led_8bits_tri_o(7 downto 0),
      vin0_01_v_n => vin0_01_v_n,
      vin0_01_v_p => vin0_01_v_p,
      vin0_23_v_n => vin0_23_v_n,
      vin0_23_v_p => vin0_23_v_p,
      vin1_01_v_n => vin1_01_v_n,
      vin1_01_v_p => vin1_01_v_p,
      vin1_23_v_n => vin1_23_v_n,
      vin1_23_v_p => vin1_23_v_p,
      vin2_01_v_n => vin2_01_v_n,
      vin2_01_v_p => vin2_01_v_p,
      vin2_23_v_n => vin2_23_v_n,
      vin2_23_v_p => vin2_23_v_p,
      vin3_01_v_n => vin3_01_v_n,
      vin3_01_v_p => vin3_01_v_p,
      vin3_23_v_n => vin3_23_v_n,
      vin3_23_v_p => vin3_23_v_p
    );
end STRUCTURE;
