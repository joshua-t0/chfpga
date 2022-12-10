--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
--Date        : Sat Dec 10 01:56:56 2022
--Host        : DellMonster running 64-bit major release  (build 9200)
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
    gpio_led : out STD_LOGIC_VECTOR ( 7 downto 0 );
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
    gpio_led : out STD_LOGIC_VECTOR ( 7 downto 0 );
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
      gpio_led(7 downto 0) => gpio_led(7 downto 0),
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
