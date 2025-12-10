----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date      : 10:20:44 05/19/2011
-- Design Name      : CHAN
-- Module Name      : CHAN - Behavioral
-- Project Name     : CHIME
-- Target Devices   : Kintex 7
-- Tool versions    : Vivado 2013.3 - 2016.2
-- Description      : Channelizer block
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
--      2011-07-11 JFC - Moved ADCDAQ here
--      2012-09-04 JFC: Properly terminated all control streams when IMPLEMENT=FALSE using a for loop
--      2012-09-28 JFC: Added in_reset_reg to isolate the rest lines for this module and facilitate timing closure.
--      2013-02-04 JFC: Removed reset from most of the TIMING_REG registers
--      2013-02-25 JFC: Moved ADCDAQ/SCALER output pipelining within the IF IMPLEMENT block because that caused conflicting assignments to OUT_DAT and crashed the simulator.
--      See Git repository for further logs
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.chFPGA_package.all; -- Get all component definitions

-- Uncomment the following library declaration if instantiating any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;


-- Block diagram wrapper for the channelizer
entity chan_array is
    GENERIC (
        NUMBER_OF_CHANNELIZERS : integer := 16
    --    -- Indicates if the channelizer is implemented. If not, a dummy module will be put in its place.
    --    -- In this case, an dummy ADCDAQ module is still instantiated to ensure that the LVDS receivers are instantiated
    --    -- (which would otherwise cause errors unless they were removed from the UCF file)
    --    IMPLEMENT_CHAN  : BOOLEAN :=TRUE; -- (and that woul dbe bad)
    --    IMPLEMENT_FFT   : BOOLEAN :=GLOBAL_IMPLEMENT_FFT;
    --    SIM             : BOOLEAN :=GLOBAL_SIM
        );

    PORT (

        -- Input Interface from ADC
        -- 32-bit wide, using the AXI4-Streaming Prototol

        in_dat_tdata    : in slv32_array(0 to NUMBER_OF_CHANNELIZERS-1);
        in_dat_tvalid   : in std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1);
        in_dat_tlast    : in std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1);
        in_dat_tuser    : in slv4_array(0 to NUMBER_OF_CHANNELIZERS-1);
        in_clk          : in std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1); -- Input and signal processing clock
        in_reset        : in std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1); -- Resets all the channelizer modules,
                                        -- except ADCDAQ. Must be synchronous to in_clk.

        ---- Output Interface
        ---- Output Data Stream in 32bit AXI4-Streaming

        out_dat_tdata   : out slv32_array(0 to NUMBER_OF_CHANNELIZERS-1);
        out_dat_tvalid  : out std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1);
        out_dat_tlast   : out std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1);
        out_dat_tuser   : out slv4_array(0 to NUMBER_OF_CHANNELIZERS-1);
        out_clk         : in  std_logic;
        out_reset       : in  std_logic;

        ---- Common data interface signals
        ---- Global trigger/capture signal.
        ---- Indicates to SRCSEL when to start flagging the incoming frames the data capture.

        --trig            : in  std_logic;
        --lane_monitor    : out std_logic_vector(3 downto 0);

        ---- UDP Command Control Interface (command and reply stream buses)

        ctrl_cmd_tdata  : in  std_logic_vector(7 downto 0);
        ctrl_cmd_tvalid : in  std_logic;
        ctrl_cmd_tlast  : in  std_logic;
        ctrl_cmd_tready : out std_logic;

        ctrl_rply_tdata : out std_logic_vector(7 downto 0);
        ctrl_rply_tvalid: out std_logic;
        ctrl_rply_tlast : out std_logic;
        ctrl_rply_tready: in  std_logic;
        ctrl_clk        : in  std_logic;
        ctrl_rst        : in  std_logic;

        ---- Control Interface to be hooked-up  to the corresponding ADCDAQ module

        --adc_cmd_tdata   : out std_logic_vector(7 downto 0);
        --adc_cmd_tvalid  : out std_logic;
        --adc_cmd_tlast   : out std_logic;
        --adc_cmd_tready  : in  std_logic;

        --adc_rply_tdata  : in  std_logic_vector(7 downto 0);
        --adc_rply_tvalid : in  std_logic;
        --adc_rply_tlast  : in  std_logic;
        --adc_rply_tready : out std_logic;

        -- Data Probe Interface

        prb_tdata       : out slv8_array(0 to NUMBER_OF_CHANNELIZERS-1);
        prb_tvalid      : out std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1);
        prb_tlast       : out std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1);
        prb_tready      : in  std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1);
        prb_clk         : in  std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1) -- Data capture clock
        );
end chan_array;


architecture impl of chan_array is


signal TOP_CHAN_CMD_DAT: AXIS8_DAT_STRUCT;
signal TOP_CHAN_RPLY_DAT: AXIS8_DAT_STRUCT;
signal TOP_CHAN_CMD_RDY:  AXIS8_RDY_STRUCT;
signal TOP_CHAN_RPLY_RDY: AXIS8_RDY_STRUCT;

signal CHAN_CMD_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_CHANNELIZERS-1 downto 0); -- We need to use max because the channelizer and ADCDAQ comamnd buses are linked.
signal CHAN_CMD_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_CHANNELIZERS-1 downto 0);
signal CHAN_RPLY_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_CHANNELIZERS-1 downto 0);
signal CHAN_RPLY_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_CHANNELIZERS-1 downto 0);

signal chan_reset_reg: std_logic_vector (NUMBER_OF_CHANNELIZERS-1 downto 0);

begin


--------------------------------------------------
-- CHAN COMMAND ROUTER
--------------------------------------------------
-- Channel Memoy Map/ Base addresses
-- Offset = Channel # x 0x02000
-- ==============================
-- |#   | Base Addr       | Subaddresses | Description |
-- |----|-----------------|------------- |-------------|
-- | 0  | Base + 0x00000  | CHAN 0       |             |
-- | 1  | Base + 0x02000  | CHAN 1       |             |
-- | 2  | Base + 0x04000  | CHAN 2       |             |
-- | 3  | Base + 0x06000  | CHAN 3       |             |
-- | 4  | Base + 0x08000  | CHAN 4       |             |
-- | 5  | Base + 0x0A000  | CHAN 5       |             |
-- | 6  | Base + 0x0C000  | CHAN 6       |             |
-- | 7  | Base + 0x0E000  | CHAN 7       |             |
-- | 8  | Base + 0x10000  | CHAN 8       |             |
-- | 9  | Base + 0x12000  | CHAN 9       |             |
-- | 10 | Base + 0x14000  | CHAN 10      |             |
-- | 11 | Base + 0x16000  | CHAN 11      |             |
-- | 12 | Base + 0x18000  | CHAN 12      |             |
-- | 13 | Base + 0x1A000  | CHAN 13      |             |
-- | 14 | Base + 0x1C000  | CHAN 14      |             |
-- | 15 | Base + 0x1E000  | CHAN 15      |             |



-- Merge the AXIS signals into the structure. Vivado 2021.1 crashes if we do it on the instantiation
TOP_CHAN_CMD_DAT.TDATA <= ctrl_cmd_tdata(7 downto 0);
TOP_CHAN_CMD_DAT.TLAST <= ctrl_cmd_tlast;
TOP_CHAN_CMD_DAT.TVALID <= ctrl_cmd_tvalid;
ctrl_cmd_tready <= TOP_CHAN_RPLY_RDY.TREADY;

ctrl_rply_tdata(7 downto 0) <= TOP_CHAN_RPLY_DAT.TDATA;
ctrl_rply_tlast <= TOP_CHAN_RPLY_DAT.TLAST;
ctrl_rply_tvalid <= TOP_CHAN_RPLY_DAT.TVALID;
TOP_CHAN_RPLY_RDY.TREADY<= ctrl_rply_tready;

chan_router0: entity work.bsb_router
    GENERIC MAP (
        NUMBER_OF_PORTS=>NUMBER_OF_CHANNELIZERS,
        ADDRESS_MASK => "----1111------------" --'1': used to generate port index, '-' = don't care,
    )
    PORT MAP(
        -- Master control interface
        CMD_IN_DAT   => TOP_CHAN_CMD_DAT,
        CMD_IN_RDY   => TOP_CHAN_CMD_RDY,
        RPLY_OUT_DAT => TOP_CHAN_RPLY_DAT,
        RPLY_OUT_RDY => TOP_CHAN_RPLY_RDY,

        CMD_OUT_DAT=> CHAN_CMD_DAT,
        CMD_OUT_RDY=> CHAN_CMD_RDY,
        RPLY_IN_DAT=> CHAN_RPLY_DAT,
        RPLY_IN_RDY=> CHAN_RPLY_RDY,

        -- Slave (module) control interface
        CLK => CTRL_CLK,
        RST => ctrl_rst
    );


CHANGEN: for i in 0 to NUMBER_OF_CHANNELIZERS-1 generate

    --PRB_PORT_OFFSET(CHAN_PROBE_BASE_PORT+i) <= DATA_IP_PORT_OFFSET ; -- Assign the IP port number to be used for the returned data

    -- Pipeline the channel synchronous reset line to the channelizers and correlator inputs
    rst_proc: process(in_clk(i))
        begin
            if rising_edge(in_clk(i)) then
                chan_reset_reg(i) <= in_reset(i);
            end if;
        end process;

    CHANi: entity work.CHAN
        PORT MAP(

            -- Channelizer input (on ANT_CLK)
            in_dat_tdata  => in_dat_tdata(i),
            in_dat_tvalid => in_dat_tvalid(i),
            in_dat_tlast  => in_dat_tlast(i),
            in_dat_tuser  => in_dat_tuser(i),
            in_reset => chan_reset_reg(i),
            in_clk => in_clk(i), -- input and signal processing clock

            -- Channelizer output, resynchronized to out_clk
            out_dat_tdata  => out_dat_tdata(i),
            out_dat_tvalid => out_dat_tvalid(i),
            out_dat_tlast  => out_dat_tlast(i),
            out_dat_tuser  => out_dat_tuser(i),
            out_reset      => out_reset,
            out_clk        => out_clk, -- output clock

            -- Misc signals
            TRIG => '0', -- TRIG,
            --lane_monitor => chan_lane_monitor(i),


            -- Control interface

            ctrl_cmd_tdata  => CHAN_CMD_DAT(i).TDATA,
            ctrl_cmd_tvalid => CHAN_CMD_DAT(i).TVALID,
            ctrl_cmd_tlast  => CHAN_CMD_DAT(i).TLAST,
            ctrl_cmd_tready => CHAN_CMD_RDY(i).TREADY,

            ctrl_rply_tdata  => CHAN_RPLY_DAT(i).TDATA,
            ctrl_rply_tvalid => CHAN_RPLY_DAT(i).TVALID,
            ctrl_rply_tlast  => CHAN_RPLY_DAT(i).TLAST,
            ctrl_rply_tready => CHAN_RPLY_RDY(i).TREADY,

            CTRL_CLK => CTRL_CLK,
            CTRL_RST => ctrl_rst, --chan_ctrl_rst_reg(i),

            -- ADCDAQ Control interface

            --adc_cmd_tdata   => ADC_CMD_DAT(i).TDATA,
            --adc_cmd_tvalid  => ADC_CMD_DAT(i).TVALID,
            --adc_cmd_tlast   => ADC_CMD_DAT(i).TLAST,
            adc_cmd_tready  => '1',

            adc_RPLY_tdata  => (others => '0'),
            adc_RPLY_tvalid => '0',
            adc_RPLY_tlast  => '0',
            --adc_RPLY_tready => ADC_RPLY_RDY(i).TREADY,

            -- Data capture interface
            PRB_tdata  => prb_tdata(i),
            PRB_tvalid => prb_tvalid(i),
            PRB_tlast  => prb_tlast(i),
            PRB_tready => prb_tready(i),
            PRB_CLK    => CTRL_CLK
        );
end generate;



    end architecture;

