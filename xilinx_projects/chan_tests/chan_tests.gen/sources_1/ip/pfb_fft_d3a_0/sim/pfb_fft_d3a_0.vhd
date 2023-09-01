-- (c) Copyright 1995-2023 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: CASPER:user:pfb_fft_d3a:1.0
-- IP Revision: 1

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pfb_fft_d3a_0 IS
  PORT (
    in0 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    in1 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    in2 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    in3 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    in4 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    in5 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    in6 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    in7 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    shift : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    sync_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    clk : IN STD_LOGIC;
    of_x0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    out0 : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    out1 : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    out2 : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    out3 : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    sync_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END pfb_fft_d3a_0;

ARCHITECTURE pfb_fft_d3a_0_arch OF pfb_fft_d3a_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : STRING;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF pfb_fft_d3a_0_arch: ARCHITECTURE IS "yes";
  COMPONENT fft_pfb IS
    PORT (
      in0 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      in1 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      in2 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      in3 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      in4 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      in5 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      in6 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      in7 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      shift : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      sync_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      clk : IN STD_LOGIC;
      of_x0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      out0 : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
      out1 : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
      out2 : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
      out3 : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
      sync_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
  END COMPONENT fft_pfb;
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER OF clk: SIGNAL IS "XIL_INTERFACENAME clk, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF clk: SIGNAL IS "xilinx.com:signal:clock:1.0 clk CLK";
BEGIN
  U0 : fft_pfb
    PORT MAP (
      in0 => in0,
      in1 => in1,
      in2 => in2,
      in3 => in3,
      in4 => in4,
      in5 => in5,
      in6 => in6,
      in7 => in7,
      shift => shift,
      sync_in => sync_in,
      clk => clk,
      of_x0 => of_x0,
      out0 => out0,
      out1 => out1,
      out2 => out2,
      out3 => out3,
      sync_out => sync_out
    );
END pfb_fft_d3a_0_arch;
