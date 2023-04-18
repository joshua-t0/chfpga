--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
--Date        : Mon Apr 17 18:03:57 2023
--Host        : twiddlebug running 64-bit Ubuntu 22.04.2 LTS
--Command     : generate_target sifpga_crs_wrapper.bd
--Design      : sifpga_crs_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity sifpga_crs_wrapper is
  port (
    adc0_clk_clk_n : in STD_LOGIC;
    adc0_clk_clk_p : in STD_LOGIC;
    adc1_clk_clk_n : in STD_LOGIC;
    adc1_clk_clk_p : in STD_LOGIC;
    adc2_clk_clk_n : in STD_LOGIC;
    adc2_clk_clk_p : in STD_LOGIC;
    adc3_clk_clk_n : in STD_LOGIC;
    adc3_clk_clk_p : in STD_LOGIC;
    buck_sync_0v85 : out STD_LOGIC;
    buck_sync_1v2a : out STD_LOGIC;
    buck_sync_1v2b : out STD_LOGIC;
    buck_sync_1v4 : out STD_LOGIC;
    buck_sync_1v8 : out STD_LOGIC;
    buck_sync_2v5 : out STD_LOGIC;
    buck_sync_3v3 : out STD_LOGIC;
    buck_sync_5v0 : out STD_LOGIC;
    buck_sync_bp : out STD_LOGIC;
    clk10_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk10_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk156_n : in STD_LOGIC;
    clk156_p : in STD_LOGIC;
    clk200_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk200_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    led7b : out STD_LOGIC_VECTOR ( 7 downto 0 );
    pl_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    pl_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    qsfp_txn : out STD_LOGIC_VECTOR ( 0 to 3 );
    qsfp_txp : out STD_LOGIC_VECTOR ( 0 to 3 );
    smp : out STD_LOGIC_VECTOR ( 0 to 3 );
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
end sifpga_crs_wrapper;

architecture STRUCTURE of sifpga_crs_wrapper is
  component sifpga_crs is
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
    clk200_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk200_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk10_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk10_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    pl_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    pl_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    smp : out STD_LOGIC_VECTOR ( 0 to 3 );
    buck_sync_5v0 : out STD_LOGIC;
    buck_sync_3v3 : out STD_LOGIC;
    buck_sync_0v85 : out STD_LOGIC;
    buck_sync_2v5 : out STD_LOGIC;
    buck_sync_1v8 : out STD_LOGIC;
    buck_sync_1v2b : out STD_LOGIC;
    buck_sync_1v2a : out STD_LOGIC;
    buck_sync_1v4 : out STD_LOGIC;
    buck_sync_bp : out STD_LOGIC;
    clk156_p : in STD_LOGIC;
    clk156_n : in STD_LOGIC;
    qsfp_txp : out STD_LOGIC_VECTOR ( 0 to 3 );
    qsfp_txn : out STD_LOGIC_VECTOR ( 0 to 3 );
    led7b : out STD_LOGIC_VECTOR ( 7 downto 0 )
  );
  end component sifpga_crs;
begin
sifpga_crs_i: component sifpga_crs
     port map (
      adc0_clk_clk_n => adc0_clk_clk_n,
      adc0_clk_clk_p => adc0_clk_clk_p,
      adc1_clk_clk_n => adc1_clk_clk_n,
      adc1_clk_clk_p => adc1_clk_clk_p,
      adc2_clk_clk_n => adc2_clk_clk_n,
      adc2_clk_clk_p => adc2_clk_clk_p,
      adc3_clk_clk_n => adc3_clk_clk_n,
      adc3_clk_clk_p => adc3_clk_clk_p,
      buck_sync_0v85 => buck_sync_0v85,
      buck_sync_1v2a => buck_sync_1v2a,
      buck_sync_1v2b => buck_sync_1v2b,
      buck_sync_1v4 => buck_sync_1v4,
      buck_sync_1v8 => buck_sync_1v8,
      buck_sync_2v5 => buck_sync_2v5,
      buck_sync_3v3 => buck_sync_3v3,
      buck_sync_5v0 => buck_sync_5v0,
      buck_sync_bp => buck_sync_bp,
      clk10_clk_n(0) => clk10_clk_n(0),
      clk10_clk_p(0) => clk10_clk_p(0),
      clk156_n => clk156_n,
      clk156_p => clk156_p,
      clk200_clk_n(0) => clk200_clk_n(0),
      clk200_clk_p(0) => clk200_clk_p(0),
      led7b(7 downto 0) => led7b(7 downto 0),
      pl_clk_n(0) => pl_clk_n(0),
      pl_clk_p(0) => pl_clk_p(0),
      qsfp_txn(0 to 3) => qsfp_txn(0 to 3),
      qsfp_txp(0 to 3) => qsfp_txp(0 to 3),
      smp(0 to 3) => smp(0 to 3),
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
