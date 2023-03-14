--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
--Date        : Mon Mar 13 01:29:56 2023
--Host        : twiddlebug running 64-bit Ubuntu 22.04.1 LTS
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
    clk156_n : in STD_LOGIC;
    clk156_p : in STD_LOGIC;
    gpio_led : out STD_LOGIC_VECTOR ( 7 downto 0 );
    qsfp_txn : out STD_LOGIC_VECTOR ( 0 to 3 );
    qsfp_txp : out STD_LOGIC_VECTOR ( 0 to 3 );
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
    adc0_clk_clk_n : in STD_LOGIC;
    adc0_clk_clk_p : in STD_LOGIC;
    adc1_clk_clk_n : in STD_LOGIC;
    adc1_clk_clk_p : in STD_LOGIC;
    adc2_clk_clk_n : in STD_LOGIC;
    adc2_clk_clk_p : in STD_LOGIC;
    adc3_clk_clk_n : in STD_LOGIC;
    adc3_clk_clk_p : in STD_LOGIC;
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
    vin3_23_v_p : in STD_LOGIC;
    FPGA_REFCLK_OUT_C_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    FPGA_REFCLK_OUT_C_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    SYSREF_FPGA_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    SYSREF_FPGA_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    gpio_led : out STD_LOGIC_VECTOR ( 7 downto 0 );
    qsfp_txp : out STD_LOGIC_VECTOR ( 0 to 3 );
    qsfp_txn : out STD_LOGIC_VECTOR ( 0 to 3 );
    clk156_p : in STD_LOGIC;
    clk156_n : in STD_LOGIC
  );
  end component sifpga_zcu111;
begin
sifpga_zcu111_i: component sifpga_zcu111
     port map (
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
      clk156_n => clk156_n,
      clk156_p => clk156_p,
      gpio_led(7 downto 0) => gpio_led(7 downto 0),
      qsfp_txn(0 to 3) => qsfp_txn(0 to 3),
      qsfp_txp(0 to 3) => qsfp_txp(0 to 3),
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
