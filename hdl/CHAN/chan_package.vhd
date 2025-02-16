----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.chfpga_package.all;
use work.chfpga_config.all;

-- Defines the chan entity as a component so we can  defer binding in conditional if-generate blocks and prevent elaboration errors
package chan_package is

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- CHAN: Channelizer module
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
COMPONENT CHAN is
    -- We cannot have GENERICS here if the module is to be used as an Out-Of-Contect (OOC) module.
    -- That is true EVEN IF all the GENERICS have default values and we don't have a GENERICS section in the component
    -- instantiation...

    --GENERIC (
    --    ADC_BITS_PER_SAMPLE: integer := CONFIG_ADC_BITS_PER_SAMPLE;
    --    ADC_SAMPLES_PER_WORD: integer := CONFIG_ADC_SAMPLES_PER_WORD;
    --    ADC_SAMPLES_PER_FRAME: integer := CONFIG_ADC_SAMPLES_PER_FRAME;
    --    ADC_BITS_PER_WORD: integer := ADC_BITS_PER_SAMPLE * ADC_SAMPLES_PER_WORD;
    --    IMPLEMENT_FFT: boolean := TRUE; -- out-of-context block will always have their FFT
    --    NUMBER_OF_CAPTURE_SOURCES: integer := CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES;
    --    CAPTURE_BITS_PER_WORD: integer := CONFIG_CAPTURE_BITS_PER_WORD
    --    );

  PORT (

    in_dat_tdata: in std_logic_vector(CONFIG_ADC_BITS_PER_SAMPLE * CONFIG_ADC_SAMPLES_PER_WORD -1  downto 0);
    in_dat_tuser: in std_logic_vector(CONFIG_ADC_SAMPLES_PER_WORD -1 downto 0);
    in_dat_tvalid: in std_logic;
    in_dat_tlast: in std_logic;
    in_reset: in std_logic; -- Resets all the antenna processor modules, except ADCDAQ. Must be synchronous to ANT_CLK.
    in_clk : in  std_logic; -- input interface clock, also used for data processing


    -- Output interface
    out_dat_tdata: out std_logic_vector(31 downto 0);
    out_dat_tuser: out std_logic_vector(3 downto 0);
    out_dat_tvalid: out std_logic;
    out_dat_tlast: out std_logic;
    out_dat_almost_empty : out std_logic; -- assers about 15 clocks before the FIFO has no more data
    out_dat_send    : in  std_logic := '1'; -- high when output data can be sent. Has a one clock latency.
    out_clk: in std_logic;
    out_reset: in std_logic;

    -- System level signals
    trig : in  std_logic; --! Global trigger/capture signal.
--    lane_monitor: out std_logic_vector(3 downto 0);

    -- Control interface (command and reply stream buses)
    ctrl_cmd_tdata: in std_logic_vector(7 downto 0);
    ctrl_cmd_tvalid: in std_logic;
    ctrl_cmd_tlast: in std_logic;
    ctrl_cmd_tready: out std_logic;
    ctrl_rply_tdata: out std_logic_vector(7 downto 0);
    ctrl_rply_tvalid: out std_logic;
    ctrl_rply_tlast: out std_logic;
    ctrl_rply_tready: in std_logic;

    ctrl_clk : in  STD_LOGIC;
    ctrl_rst : in  STD_LOGIC; --! Global asynchronous RESET, activated at power-up.

    -- Control interface to be hooked-up  to the corresponding ADCDAQ module
    adc_cmd_tdata: out std_logic_vector(7 downto 0);
    adc_cmd_tvalid: out std_logic;
    adc_cmd_tlast: out std_logic;
    adc_cmd_tready: in std_logic;
    adc_rply_tdata: in std_logic_vector(7 downto 0);
    adc_rply_tvalid: in std_logic;
    adc_rply_tlast: in std_logic;
    adc_rply_tready: out std_logic;

    -- packet capture interface
    cap_source_req: in std_logic := '0';
    cap_source_ack: out std_logic := '0';
    m_axis_cap_tdata: out std_logic_vector(CONFIG_CAPTURE_BITS_PER_WORD-1 downto 0);
    m_axis_cap_tvalid: out std_logic_vector(0 to CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES - 1);
    m_axis_cap_tlast: out std_logic_vector(0 to CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES - 1);


    -- Data Capture interface
    prb_tdata: out std_logic_vector(7 downto 0);
    prb_tvalid: out std_logic;
    prb_tlast: out std_logic;
    prb_tready: in std_logic;
    prb_clk : in  STD_LOGIC  --! Data capture clock
    );
end COMPONENT;


end chan_package;

--package body chan_package is
--end chan_package;
