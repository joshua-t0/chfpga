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
package ct_package is

COMPONENT shuffle_crossbar is
  GENERIC (
    PLATFORM_ID: integer; -- necessary to select the proper FIFOs
    NUMBER_OF_INPUT_LANES: integer := 16; -- Number of input streams
    NUMBER_OF_OUTPUT_LANES: integer := 8; -- Number of output streams
    NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL: integer := 1;
    EIGHT_BIT_SUPPORT: boolean := FALSE; --
    COMBINE_DATA_FLAGS: boolean := TRUE;
    WORDS_PER_BIN_MAX: integer :=4; --! Maximum number of words that can be present in a bin on one input lane. The 2nd crossbar receives up to 4 words. The 3rd crossbar will can have up to 16 words.
    BINS_PER_FRAME_MAX: integer :=64; --! Maximum number of bins per frame
    BIN_SEL_FIFO_TYPE_MAP: integer_16xN_array := (0 to 15 => (0 to 3=>0, others=>0)); -- 0= Block RAM., 1=Dist RAM. By default, for every BIN_SEL, 10 FIFOS are made of BRAM and the rest is made of distributed RAM to maximize area utilization efficiency
    SHUFFLE_FLAGS_MASK: slv32 -- Mask to apply to the shuffle flags to count packet errors
    );
  PORT(

    -- Non-blocking input stream from the backplane shuffle receiver
    s_axis_tvalid: in slv(0 to NUMBER_OF_INPUT_LANES-1);
    s_axis_tdata: in slv32_array(0 to NUMBER_OF_INPUT_LANES-1);
    s_axis_tlast: in slv(0 to NUMBER_OF_INPUT_LANES-1);
    -- s_axis_tready: out slv(0 to NUMBER_OF_INPUT_LANES-1);
    -- s_axis_clk: in std_logic_vector(0 to NUMBER_OF_INPUT_LANES-1); -- clock from each channelizer

    -- Non-blocking output stream
    m_axis_tvalid: out slv(0 to NUMBER_OF_OUTPUT_LANES-1);
    m_axis_tdata: out slv32_array(0 to NUMBER_OF_OUTPUT_LANES-1);
    m_axis_tlast: out slv(0 to NUMBER_OF_OUTPUT_LANES-1);
    -- m_axis_tready: in slv(0 to NUMBER_OF_OUTPUT_LANES-1);

    -- frame_clk_in: in std_logic;
    clk: in  std_logic; -- clocks all align, remap and bin selection and output bus logic.
    rst: in std_logic;

    align_pulse: out std_logic;

    -- Control interface (command and reply stream buses)
    ctrl_cmd_dat: in AXIS8_DAT_STRUCT;
    ctrl_cmd_rdy: out AXIS8_RDY_STRUCT;
    ctrl_rply_dat: out AXIS8_DAT_STRUCT;
    ctrl_rply_rdy: in AXIS8_RDY_STRUCT;
    ctrl_clk: in  std_logic;
    ctrl_rst : in  std_logic
    );

  end COMPONENT;
end ct_package;

