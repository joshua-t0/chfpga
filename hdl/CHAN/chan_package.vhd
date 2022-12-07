----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.chfpga_package.all;

-------- udp_mac package ------------
--! Defines the chan entity as a component so we can  defer binding in conditional if-generate blocks and prevent elaboration errors
package chan_package is

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- CHAN: Channelizer module
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
COMPONENT CHAN is
  GENERIC (
        PLATFORM_ID : integer
        );

  PORT (

    in_dat_tdata: in slv32;
    in_dat_tvalid: in std_logic;
    in_dat_tlast: in std_logic;
    in_dat_tuser: in slv4;
    in_reset: in std_logic; --! Resets all the antenna processor modules, except ADCDAQ. Must be synchronous to ANT_CLK.
    in_clk : in  STD_LOGIC; --! Data processing clock for all the Antenna processing pipeline

    -- Data processing clock

    -- Output interface
--    OUT_DAT : out  AXIS32_DAT_STRUCT; --! Output data stream
    out_dat_tdata: out slv32;
    out_dat_tvalid: out std_logic;
    out_dat_tlast: out std_logic;
    out_dat_tuser: out slv4;
    out_clk: in std_logic;
    out_reset: in std_logic;

    -- System level signals
    TRIG : in  STD_LOGIC; --! Global trigger/capture signal. Indicates to SRCSEL when to start flagging the incoming frames the data capture.
--    ADC_DAQ_BUFR_SYNC: in STD_LOGIC;
--    ADC_DAQ_SERDES_SYNC: in STD_LOGIC;
    lane_monitor: out std_logic_vector(3 downto 0);

    -- Control interface (command and reply stream buses)
--    CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT;
--    CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT;
    ctrl_cmd_tdata: in std_logic_vector(7 downto 0);
    ctrl_cmd_tvalid: in std_logic;
    ctrl_cmd_tlast: in std_logic;
    ctrl_cmd_tready: out std_logic;

--    CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
--    CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;
    ctrl_rply_tdata: out std_logic_vector(7 downto 0);
    ctrl_rply_tvalid: out std_logic;
    ctrl_rply_tlast: out std_logic;
    ctrl_rply_tready: in std_logic;

    CTRL_CLK : in  STD_LOGIC;
    CTRL_RST : in  STD_LOGIC; --! Global asynchronous RESET, activated at power-up.

    -- Control interface to be hooked-up  to the corresponding ADCDAQ module
    -- ADC_CMD_DAT: out AXIS8_DAT_STRUCT;
    -- ADC_CMD_RDY: in AXIS8_RDY_STRUCT;
    -- ADC_RPLY_DAT: in AXIS8_DAT_STRUCT;
    -- ADC_RPLY_RDY: out AXIS8_RDY_STRUCT;
    adc_cmd_tdata: out std_logic_vector(7 downto 0);
    adc_cmd_tvalid: out std_logic;
    adc_cmd_tlast: out std_logic;
    adc_cmd_tready: in std_logic;

--    adc_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
--    adc_RPLY_OUT_RDY: out AXIS8_RDY_STRUCT;
    adc_rply_tdata: in std_logic_vector(7 downto 0);
    adc_rply_tvalid: in std_logic;
    adc_rply_tlast: in std_logic;
    adc_rply_tready: out std_logic;

    -- Data Probe interface
    -- PRB_DAT: out AXIS8_DAT_STRUCT; --! Data capture bus (AXI4 Streaming)
    -- PRB_RDY: in AXIS8_RDY_STRUCT;
    prb_tdata: out std_logic_vector(7 downto 0);
    prb_tvalid: out std_logic;
    prb_tlast: out std_logic;
    prb_tready: in std_logic;


    PRB_CLK : in  STD_LOGIC  --! Data capture clock

    -- System
    );
end COMPONENT;



--COMPONENT simple_pfb_v2
--  port (
--    ce_1: in std_logic;
--    clk_1: in std_logic;
--    in0: in std_logic_vector(7 downto 0);
--    in1: in std_logic_vector(7 downto 0);
--    in2: in std_logic_vector(7 downto 0);
--    in3: in std_logic_vector(7 downto 0);
--    shift: in std_logic_vector(10 downto 0);
--    sync_in: in std_logic;
--    out1: out std_logic_vector(35 downto 0);
--    out2: out std_logic_vector(35 downto 0);
--    overflow: out std_logic;
--    sync_out: out std_logic
--  );
--END COMPONENT;




end chan_package;

--package body chan_package is
--end chan_package;
