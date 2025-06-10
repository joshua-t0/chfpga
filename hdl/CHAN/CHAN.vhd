----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date      : 10:20:44 05/19/2011
-- Design Name      : CHAN
-- Module Name      : CHAN - Behavioral
-- Project Name     : CHIME
-- Target Devices   : Kintex 7, UltrascalePlus
-- Tool versions    : Vivado 2013.3 - 2022.2
-- Description      : Channelizer module
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
use work.chFPGA_config.all; -- get platform-specific configurations

-- Uncomment the following library declaration if instantiating any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

-- Implements the chanelizer pipeline, consisting of a function generator (FUNCGEN), FFT module (FFT), scaler (SCALER) and a resynchrozing FIFO (CHAN_FIFO).
entity CHAN is
    GENERIC (
        -- If this module is to be compiled as an Out-of-context module, it
        -- should be instantiated using component instantiation, and
        -- the instanciation and the component definition MUST NOT include the
        -- GENERICS section. In that case, the defaults defined here will be
        -- used.
        --
        -- For non-OOC usage, this entity can be instantiated with entity instantiation with GENERICS

        PLATFORM_ID     : integer          := CONFIG_PLATFORM_ID;-- PLATFORM_ID_MGK7MB; -- This generics is locked to the MGK7MB when using CHAN as an OOC.
        IMPLEMENT_CHAN  : boolean          := TRUE;
        IMPLEMENT_FFT   : boolean          := CONFIG_CHAN_IMPLEMENT_FFT;
        FFT_TYPE        : integer          := CONFIG_CHAN_FFT_TYPE;
        FFT_ROTATE_BINS : boolean          := CONFIG_FFT_ROTATE_BINS; -- enables bin rotation when true
        SCALER_USE_COMPLEX_GAINS: boolean  := CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS;
        OUT_BITS_PER_WORD: integer         := 32; -- Width of the output data bus which feeds the corner-turn engine or correlator.
        NUMBER_OF_CAPTURE_SOURCES: integer := CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES;
        CAPTURE_TYPE: string               := CONFIG_CHAN_CAPTURE_TYPE; -- "URAM" or "BRAM"
        CAPTURE_BITS_PER_WORD: integer     := CONFIG_CAPTURE_BITS_PER_WORD; -- sel(CAPTURE_TYPE="URAM", 128, 32); -- If we use URAM capture (which has a 128-bit bus), have the scaler output be the same width so we can get more FFT resolution when the scaler is bypassed.

        FFT_BITS_PER_BIN: integer          := FFT_INFO(FFT_TYPE).BITS_PER_BIN; -- Re and Im parts combined
        ADC_BITS_PER_SAMPLE: integer       := FFT_INFO(FFT_TYPE).BITS_PER_SAMPLE;
        ADC_SAMPLES_PER_WORD: integer      := FFT_INFO(FFT_TYPE).SAMPLES_PER_WORD;
        ADC_SAMPLES_PER_FRAME: integer     := FFT_INFO(FFT_TYPE).SAMPLES_PER_FRAME;
        ADC_BITS_PER_WORD: integer         := ADC_BITS_PER_SAMPLE * ADC_SAMPLES_PER_WORD;
        SCALER_COEFF_BITS_PER_BIN: integer := sel(SCALER_USE_COMPLEX_GAINS, 16+16, 16); -- use wither 16-bit real gains or (16+16i) bit complex gains
        SIM: boolean                       := GLOBAL_SIM
        );

    PORT (

        -- Input Interface from ADC
        -- Non-blocking AXI4-Streaming bus
        -- Data width: ADC_BITS_PER_WORD = ADC_SAMPLES_PER_WORD * ADC_BITS_PER_SAMPLE (ADC output width)

        in_dat_tdata    : in std_logic_vector(ADC_BITS_PER_WORD-1 downto 0);
        in_dat_tvalid   : in std_logic;
        in_dat_tlast    : in std_logic;
        in_dat_tuser    : in std_logic_vector(ADC_SAMPLES_PER_WORD-1 downto 0);  -- ADC saturation flags (one per sample)
        in_clk          : in std_logic; -- Input and signal processing clock
        in_reset        : in std_logic; -- Resets all the channelizer modules,
                                        -- except ADCDAQ. Must be synchronous to in_clk.

        -- Output Interface
        -- Blocking AXI4-Streaming
        -- Data width: OUT_BITS_PER_WORD (Scaler output width)

        out_dat_tdata   : out std_logic_vector(OUT_BITS_PER_WORD-1 downto 0);
        out_dat_tvalid  : out std_logic;
        out_dat_tlast   : out std_logic;
        out_dat_tuser   : out std_logic_vector(3 downto 0);
        out_dat_almost_empty : out std_logic; -- assers about 15 clocks before the FIFO has no more data
        out_dat_send    : in  std_logic := '1'; -- high when output data can be sent. Has a one clock latency.
        out_clk         : in  std_logic;
        out_reset       : in  std_logic;

        -- Common data interface signals
        -- Global trigger/capture signal.
        -- Indicates to SRCSEL when to start flagging the incoming frames the data capture.

        trig            : in  std_logic; -- For manually triggering packet generation/transmission
        lane_monitor    : out std_logic_vector(3 downto 0);

--        lane_monitor    : out std_logic_vector(3 downto 0);

        -- Byte-Serial-Bus (BSB) interface for control and monitoring of sub-modules

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

        -- BSB bus interface to be hooked-up  to the corresponding ADCDAQ module

        adc_cmd_tdata   : out std_logic_vector(7 downto 0);
        adc_cmd_tvalid  : out std_logic;
        adc_cmd_tlast   : out std_logic;
        adc_cmd_tready  : in  std_logic;

        adc_rply_tdata  : in  std_logic_vector(7 downto 0);
        adc_rply_tvalid : in  std_logic;
        adc_rply_tlast  : in  std_logic;
        adc_rply_tready : out std_logic;

        -- Data capture interface
        cap_source_req: in std_logic := '0'; -- requested data capture source (0 or 1). The actual source switch will happen on a frame boundary and will be reflected by `cap_source_ack`. Default provided in case we don't use an external capture module.
        cap_source_ack: out std_logic := '0'; -- Current source (0 or 1) for the captured data. This is synchronous to the m_axis_cap tdata/tvalud/tlast. Default value needed to avoir 'undriven net' warning when we don't use the external capture module is used.
        m_axis_cap_tdata: out std_logic_vector(CAPTURE_BITS_PER_WORD-1 downto 0);
        m_axis_cap_tvalid: out std_logic_vector(0 to NUMBER_OF_CAPTURE_SOURCES - 1);
        m_axis_cap_tlast: out std_logic_vector(0 to NUMBER_OF_CAPTURE_SOURCES - 1);


        prb_tdata       : out std_logic_vector(7 downto 0);
        prb_tvalid      : out std_logic;
        prb_tlast       : out std_logic;
        prb_tready      : in  std_logic;
        PRB_CLK         : in  std_logic -- Data capture clock
        );
end CHAN;




------ Channelizer implementation
-- Implements the channelizer blocks
architecture impl of CHAN is

--attribute equivalent_register_removal: string;
--attribute shreg_extract: string;
attribute keep: string;
attribute dont_touch: string;

--constant IMPLEMENT_FFT   : BOOLEAN :=GLOBAL_IMPLEMENT_FFT;
--constant SIM             : BOOLEAN :=GLOBAL_SIM;

constant FPGA_SERIES: integer          := FPGA_SERIES_LIST(PLATFORM_ID);
constant FFT_BINS_PER_WORD: integer    := FFT_INFO(FFT_TYPE).BINS_PER_WORD;
constant FFT_BITS_PER_WORD: integer    := FFT_BITS_PER_BIN * FFT_BINS_PER_WORD;
constant FFT_BINS_PER_FRAME :integer   := ADC_SAMPLES_PER_FRAME / 2;
constant SCALER_BITS_PER_WORD: integer := OUT_BITS_PER_WORD;
constant SCALER_BITS_PER_BIN: integer  := SCALER_BITS_PER_WORD / FFT_BINS_PER_WORD; -- Note: scaler output is always 4+4 or 8+8 bits when not bypassed.
constant OUT_BITS_PER_BIN: integer     := SCALER_BITS_PER_BIN;  -- 16 for CHIME, 8 for CHORD

signal axis_funcgen_out_tdata: std_logic_vector(ADC_BITS_PER_WORD-1 downto 0);
signal axis_funcgen_out_tuser: std_logic_vector(3 downto 0);
signal axis_funcgen_out_tvalid: std_logic;
signal axis_funcgen_out_tlast: std_logic;


signal axis_fft_out_tdata: std_logic_vector(FFT_BITS_PER_WORD-1 downto 0);
signal axis_fft_out_tuser: std_logic_vector(3 downto 0);
signal axis_fft_out_tvalid: std_logic;
signal axis_fft_out_tlast: std_logic;

--signal axis_fft_out         : axis72_dat_struct;


signal axis_scaler_out      : axis32_dat_struct;

signal axis_scaler_out_tdata: std_logic_vector(SCALER_BITS_PER_WORD-1 downto 0);
signal axis_scaler_out_tvalid : std_logic;
signal axis_scaler_out_tlast : std_logic;
signal axis_scaler_out_tuser: std_logic_vector(3 downto 0);

signal axis_scaler_cap_tdata: std_logic_vector(CAPTURE_BITS_PER_WORD-1 downto 0);
signal axis_scaler_cap_tvalid : std_logic;
signal axis_scaler_cap_tlast : std_logic;
signal axis_scaler_cap_tuser: std_logic_vector(3 downto 0);

-- Signals monitored by the SCALER module
signal fifo_overflow        : std_logic;


--signal in_reset_prober: std_logic :='1'; -- added =1 to see if it helps the reset problem
-- signal out_reset_reg: std_logic :='1';
-- Make sure the pipeline registers are not simplified by the synthesizer so they can be useful in helping meeting timing
signal funcgen_reset_out: std_logic;
signal fft_reset_out: std_logic;
signal scaler_reset_out: std_logic;

attribute keep of funcgen_reset_out, fft_reset_out, scaler_reset_out: signal is "true";


-- make sure that the ADCDAQ logic is not removed if nothing is connected downstream
-- Make sure the synthesizer does not remove the I/O logic for the unused ADC outputs


--signal ADC_CLK_OUT_PLL_INT : STD_LOGIC;

-- Control bus signals
constant MODULE_ADCDAQ_ADDR : integer := 0; -- Address of the ADC data acquisition module
constant MODULE_FFT_ADDR    : integer := 2; -- Address of the channelizer (FFT) module
constant MODULE_SCALER_ADDR : integer := 3; -- Address of the scaler module
constant MODULE_PROBER_ADDR : integer := 4; -- Address of the data capture module
constant MODULE_FUNCGEN_ADDR: integer := 5; -- Address of the function generator module
constant NUMBER_OF_MODULES  : integer := 7; -- Total number of modules to be implemented. Is used to set the number of ports of the control interface router.

-- UDP Control Command from chfpga
signal CMD_DAT  : AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_MODULES-1 downto 0);
signal CMD_RDY  : AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_MODULES-1 downto 0);
signal RPLY_DAT : AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_MODULES-1 downto 0);
signal RPLY_RDY : AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_MODULES-1 downto 0);

-- Control Command Signals
signal CTRL_CMD_IN_DAT  : AXIS8_DAT_STRUCT;
signal CTRL_CMD_IN_RDY  : AXIS8_RDY_STRUCT;
signal CTRL_RPLY_OUT_DAT: AXIS8_DAT_STRUCT;
signal CTRL_RPLY_OUT_RDY: AXIS8_RDY_STRUCT;

--ADC Command Signals
signal ADC_CMD_DAT  :  AXIS8_DAT_STRUCT;
signal ADC_CMD_RDY  : AXIS8_RDY_STRUCT;
signal ADC_RPLY_DAT : AXIS8_DAT_STRUCT;
signal ADC_RPLY_RDY :  AXIS8_RDY_STRUCT;

--Funcgen Command Signals
signal srcsel_cmd_dat   : AXIS8_DAT_STRUCT;
signal srcsel_cmd_rdy   : AXIS8_RDY_STRUCT;
signal srcsel_rply_dat  : AXIS8_DAT_STRUCT;
signal srcsel_rply_rdy  : AXIS8_RDY_STRUCT;


begin


CTRL_CMD_IN_DAT.TDATA <= ctrl_cmd_tdata;
CTRL_CMD_IN_DAT.TVALID <= ctrl_cmd_tvalid;
CTRL_CMD_IN_DAT.TLAST <= ctrl_cmd_tlast;
ctrl_cmd_tready <= CTRL_CMD_IN_RDY.TREADY;

ctrl_rply_tdata <= CTRL_RPLY_OUT_DAT.TDATA;
ctrl_rply_tvalid <= CTRL_RPLY_OUT_DAT.TVALID;
ctrl_rply_tlast <=  CTRL_RPLY_OUT_DAT.TLAST;
CTRL_RPLY_OUT_RDY.TREADY <= ctrl_rply_tready;


adc_cmd_tdata <= adc_cmd_dat.tdata;
adc_cmd_tvalid <= adc_cmd_dat.tvalid;
adc_cmd_tlast <= adc_cmd_dat.tlast;
ADC_CMD_RDY.tready <= adc_cmd_tready;

adc_rply_dat.tdata <= adc_rply_tdata;
adc_rply_dat.tvalid <= adc_rply_tvalid;
adc_rply_dat.tlast <= adc_rply_tlast;
adc_rply_tready <= ADC_RPLY_RDY.tready;


-- Memory Map
--
-- ---------------------------------------------------------------------
-- |#   |  Addr           | Module                       | Description |
-- |----|-----------------|------------------------------|-------------|
-- | 0  | Base + 0x00000  | ADCDAQ                       |             |
-- | 1  | Base + 0x00200  | (unused)                     |             |
-- | 2  | Base + 0x00400  | FFT                          |             |
-- | 3  | Base + 0x00600  | SCALER                       |             |
-- | 4  | Base + 0x00800  | PROBER                       |             |
-- | 5  | Base + 0x00A00  | FUNCGEN                      |             |
-- | 6  | Base + 0x00C00  | (unused)                     |             |
-- | 7  | Base + 0x00E00  | (unused)                     |             |

---------------------------------------------------------------------
-- Instantiate the Command router
-- Routes the commands to the requested module
---------------------------------------------------------------------
CTRL_ROUTER0: entity work.CTRL_ROUTER
    GENERIC MAP (
        NUMBER_OF_PORTS=>NUMBER_OF_MODULES,
        ADDRESS_MASK => "-------111---------" --'1': used to generate port index, '-' = don't care,
    )
    PORT MAP(
        -- Master control interface
        CMD_IN_DAT   => CTRL_CMD_IN_DAT,
        CMD_IN_RDY   => CTRL_CMD_IN_RDY,
        RPLY_OUT_DAT => CTRL_RPLY_OUT_DAT,
        RPLY_OUT_RDY => CTRL_RPLY_OUT_RDY,

        CMD_OUT_DAT => CMD_DAT,
        CMD_OUT_RDY => CMD_RDY,
        RPLY_IN_DAT => RPLY_DAT,
        RPLY_IN_RDY => RPLY_RDY,

        CLK => CTRL_CLK,
        RST => CTRL_RST

    );

-- Pass the ADC bus to the upper level to connect to the ADCDAQ module
ADC_CMD_DAT                  <= CMD_DAT(MODULE_ADCDAQ_ADDR);
CMD_RDY(MODULE_ADCDAQ_ADDR)  <= ADC_CMD_RDY;
RPLY_DAT(MODULE_ADCDAQ_ADDR) <= ADC_RPLY_DAT;
ADC_RPLY_RDY                 <= RPLY_RDY(MODULE_ADCDAQ_ADDR);


IMPL_GEN: if IMPLEMENT_CHAN=TRUE generate
---------------------------------------------------------------------
-- Propagates the ADCDAQ output through a couple of registers to facilitate timing between the ADCDAQ and FUNCGEN
-- Helps meet timing, since the bus can take two stops to route across the chip.
-- Placement of this logic should not be constrained.
--
-- Also pipeline and forwards key debugging signals for external moinitoring.
--
-- NOTE:  only TVALID is affected by the synchronous RESET line, not the
--    entire bus. This is because that reset would 1) drive a large load and
--    2) be routed to all the registers and will make timing harder to meet.
--1
-- NOTE: This process is implemented only when IMPLEMENT_CHAN=TRUE, otherwise
--   there will be assignment conflicts to OUT_DAT with the block that handle
--   IMPLEMENT_CHAN=FALSE, and that makes the Vivado simulator hang up.
---------------------------------------------------------------------
funcgen_blk: BLOCK
    -- Data and reset pipeline signals, level 1
    signal axis_adc_reg1_tdata: std_logic_vector(ADC_BITS_PER_WORD-1 downto 0);
    signal axis_adc_reg1_tuser: std_logic_vector(ADC_SAMPLES_PER_WORD-1 downto 0);
    signal axis_adc_reg1_tvalid: std_logic;
    signal axis_adc_reg1_tlast: std_logic;
    signal in_reset_adc_reg1: std_logic;

    attribute dont_touch of axis_adc_reg1_tdata, axis_adc_reg1_tuser, axis_adc_reg1_tvalid, axis_adc_reg1_tlast: signal is "true";
    attribute dont_touch of in_reset_adc_reg1: signal is "true";

    -- Data and reset pipeline signals, level 2
    signal axis_adc_reg2_tdata: std_logic_vector(ADC_BITS_PER_WORD-1 downto 0);
    signal axis_adc_reg2_tuser: std_logic_vector(ADC_SAMPLES_PER_WORD-1 downto 0);
    signal axis_adc_reg2_tvalid: std_logic;
    signal axis_adc_reg2_tlast: std_logic;
    signal in_reset_adc_reg2: std_logic;

    attribute dont_touch of axis_adc_reg2_tdata, axis_adc_reg2_tuser, axis_adc_reg2_tvalid, axis_adc_reg2_tlast: signal is "true";
    attribute dont_touch of in_reset_adc_reg2: signal is "true";

    signal funcgen_reset_in: std_logic;
    attribute keep of funcgen_reset_in: signal is "true";

    signal funcgen_out_pre_tdata: std_logic_vector(ADC_BITS_PER_WORD-1 downto 0);
    signal funcgen_out_pre_tuser: std_logic_vector(3 downto 0);
    signal funcgen_out_pre_tvalid: std_logic;
    signal funcgen_out_pre_tlast: std_logic;


    --attribute equivalent_register_removal of axis_adc_reg1: signal is "no";
    --attribute equivalent_register_removal of axis_adcdaq_out_reg2: signal is "no";
    --attribute shreg_extract of axis_adc_reg1: signal is "no";
    --attribute shreg_extract of axis_adcdaq_out_reg2: signal is "no";
begin

    ---------------------------------------------------------------------
    -- Propagates the ADCDAQ output through a couple of registers to facilitate timing between the ADCDAQ and FUNCGEN
    -- Helps meet timing, since the bus can take two stops to route across the chip.
    -- Placement of this logic should not be constrained.
    --
    -- Also pipeline and forwards key debugging signals for external moinitoring.
    --
    -- NOTE:  only TVALID is affected by the synchronous RESET line, not the
    --    entire bus. This is because that reset would 1) drive a large load and
    --    2) be routed to all the registers and will make timing harder to meet.
    --
    -- NOTE: This process is implemented only when IMPLEMENT_CHAN=TRUE, otherwise
    --   there will be assignment conflicts to OUT_DAT with the block that handle
    --   IMPLEMENT_CHAN=FALSE, and that makes the Vivado simulator hang up.
    ---------------------------------------------------------------------
    adc_pipe_proc: process(in_clk)
    begin
        if rising_edge(in_clk) then
            -- Pipeline input data and reset
            in_reset_adc_reg1 <= in_reset;

            axis_adc_reg1_tdata <= in_dat_tdata;
            axis_adc_reg1_tuser <= in_dat_tuser;
            axis_adc_reg1_tvalid <= in_dat_tvalid;
            axis_adc_reg1_tlast <= in_dat_tlast;

            if in_reset_adc_reg1 = '1' then
                axis_adc_reg1_tvalid <= '0';
            end if;

            -- Pipeline input data and reset again; we have a long distance to cover.
            in_reset_adc_reg2 <= in_reset_adc_reg1;

            axis_adc_reg2_tdata <= axis_adc_reg1_tdata;
            axis_adc_reg2_tuser <= axis_adc_reg1_tuser;
            axis_adc_reg2_tvalid <= axis_adc_reg1_tvalid;
            axis_adc_reg2_tlast <= axis_adc_reg1_tlast;

            if in_reset_adc_reg2 = '1' then
                axis_adc_reg2_tvalid <= '0';
            end if;

            funcgen_reset_in <= in_reset_adc_reg2;
            funcgen_reset_out <= funcgen_reset_in;

            axis_funcgen_out_tdata <= funcgen_out_pre_tdata;
            axis_funcgen_out_tuser <= funcgen_out_pre_tuser;
            axis_funcgen_out_tvalid <= funcgen_out_pre_tvalid when not funcgen_reset_out else '0';
            axis_funcgen_out_tlast <= funcgen_out_pre_tlast;

            -- Provide monitoring data
            lane_monitor(0) <= axis_scaler_out_tvalid xor axis_scaler_out_tlast;
            lane_monitor(1) <= axis_fft_out_tvalid xor axis_fft_out_tlast;
            lane_monitor(2) <= axis_funcgen_out_tvalid xor axis_funcgen_out_tlast;
        end if; --clk
    end process;

    -- Pipeline the reset signal to the funcgen
    funcgen_pipe_proc: process(in_clk)
        begin
            if rising_edge(in_clk) then
            end if;
        end process;


   ---------------------------------------------------------------------
    -- FUNCTION GENERATOR instance
    ---------------------------------------------------------------------
    -- The Function Generator either forwards the ADC data or injects user-programmable arbitrary waveforms
    FUNCGEN0: entity work.FUNCGEN
        generic map (
            ADC_BITS_PER_SAMPLE => ADC_BITS_PER_SAMPLE,
            ADC_SAMPLES_PER_WORD => ADC_SAMPLES_PER_WORD,
            ADC_SAMPLES_PER_FRAME => ADC_SAMPLES_PER_FRAME
        )
        PORT MAP(

            -- Input from the ADC
            s_axis_adc_tdata => axis_adc_reg2_tdata,
            s_axis_adc_tvalid => axis_adc_reg2_tvalid,
            s_axis_adc_tuser => axis_adc_reg2_tuser,
            s_axis_adc_tlast => axis_adc_reg2_tlast,
            trig   => trig,

            -- Output stream to FFT
            m_axis_adc_tdata => funcgen_out_pre_tdata,
            m_axis_adc_tvalid => funcgen_out_pre_tvalid,
            m_axis_adc_tuser => funcgen_out_pre_tuser,
            m_axis_adc_tlast => funcgen_out_pre_tlast,

            clk => in_clk,
            rst => funcgen_reset_in,

            -- Control interface
            ctrl_cmd_in_dat   => CMD_DAT(MODULE_FUNCGEN_ADDR),
            ctrl_cmd_in_rdy   => CMD_RDY(MODULE_FUNCGEN_ADDR),
            ctrl_rply_out_dat => RPLY_DAT(MODULE_FUNCGEN_ADDR),
            ctrl_rply_out_rdy => RPLY_RDY(MODULE_FUNCGEN_ADDR),
            ctrl_clk          => CTRL_CLK,
            ctrl_rst          => CTRL_RST
        );
end block funcgen_blk;


---------------------------------------------------------------------
-- Instantiate the FFT Block
---------------------------------------------------------------------
fft_blk: block
    signal axis_fft_in_tdata: std_logic_vector(ADC_BITS_PER_WORD-1 downto 0);
    signal axis_fft_in_tuser: std_logic_vector(3 downto 0);
    signal axis_fft_in_tvalid: std_logic;
    signal axis_fft_in_tlast: std_logic;
    signal fft_reset_in: std_logic;
    attribute keep of  fft_reset_in: signal is "true";

    signal axis_fft_in2_tdata: std_logic_vector(ADC_BITS_PER_WORD-1 downto 0);
    signal axis_fft_in2_tuser: std_logic_vector(3 downto 0);
    signal axis_fft_in2_tvalid: std_logic;
    signal axis_fft_in2_tlast: std_logic;
    signal fft_reset_in2: std_logic;
    attribute keep of  fft_reset_in2: signal is "true";

begin
    -- Pipeline the FFT reset (skip over the funcgen logic)
    fft_pipe_proc: process(in_clk)
        begin
            if rising_edge(in_clk) then
                fft_reset_in <= funcgen_reset_out;

                axis_fft_in_tdata <= axis_funcgen_out_tdata;
                axis_fft_in_tuser <= axis_funcgen_out_tuser;
                axis_fft_in_tlast <= axis_funcgen_out_tlast;
                axis_fft_in_tvalid <= '0' when funcgen_reset_out else axis_funcgen_out_tvalid;

                fft_reset_in2 <= fft_reset_in;

                axis_fft_in2_tdata <= axis_fft_in_tdata;
                axis_fft_in2_tuser <= axis_fft_in_tuser;
                axis_fft_in2_tlast <= axis_fft_in_tlast;
                axis_fft_in2_tvalid <= '0' when fft_reset_in else axis_fft_in_tvalid;

                fft_reset_out <= fft_reset_in2;
            end if;
        end process;

    -- This is a wrapper for the CASPER FFT so it can operate with AXI4 Streaming buses.
    -- Also adds a control interface to control the FFT operation.
    FFT0: entity work.FFT
        GENERIC MAP (
            IMPLEMENT_FFT        => IMPLEMENT_FFT,
            FFT_TYPE             => FFT_TYPE,
            ADC_BITS_PER_SAMPLE  => ADC_BITS_PER_SAMPLE,
		    ADC_SAMPLES_PER_WORD => ADC_SAMPLES_PER_WORD,
		    FFT_BITS_PER_BIN     => FFT_BITS_PER_BIN,
            ROTATE_BINS          => FFT_ROTATE_BINS
            )
        PORT MAP(

            -- Input stream from funcgen
            s_axis_in_dat_tdata  => axis_fft_in2_tdata,
            s_axis_in_dat_tvalid => axis_fft_in2_tvalid,
            s_axis_in_dat_tlast  => axis_fft_in2_tlast,
            s_axis_in_dat_tuser  => axis_fft_in2_tuser,

            -- Output stream to scaler
            m_axis_out_dat_tdata  => axis_fft_out_tdata,
            m_axis_out_dat_tvalid => axis_fft_out_tvalid,
            m_axis_out_dat_tlast  => axis_fft_out_tlast,
            m_axis_out_dat_tuser  => axis_fft_out_tuser,

            clk     => in_clk,
            reset   => fft_reset_in2,

            -- Control interface
            CTRL_CMD_IN_DAT   => CMD_DAT(MODULE_FFT_ADDR),
            CTRL_CMD_IN_RDY   => CMD_RDY(MODULE_FFT_ADDR),
            CTRL_RPLY_OUT_DAT => RPLY_DAT(MODULE_FFT_ADDR),
            CTRL_RPLY_OUT_RDY => RPLY_RDY(MODULE_FFT_ADDR),
            CTRL_CLK          => CTRL_CLK,
            CTRL_RST          => CTRL_RST
        );
end block fft_blk;


---------------------------------------------------------------------
-- Instantiate the SCALER Block
---------------------------------------------------------------------
-- Applies a complex correction factor to each sample coming out of the FFT and scales the data back to 8 bits or 4 bits format.
scaler_blk: block
    signal axis_scaler_in_tdata: std_logic_vector(FFT_BITS_PER_WORD-1 downto 0);
    signal axis_scaler_in_tuser: std_logic_vector(3 downto 0);
    signal axis_scaler_in_tvalid: std_logic;
    signal axis_scaler_in_tlast: std_logic;
    signal scaler_reset_in: std_logic;
    attribute keep of  scaler_reset_in: signal is "true";

--    signal funcgen_reset_out: std_logic;

begin
    -- Pipeline the SCALER reset (skip over the fft logic)
    scaler_pipe_proc: process(in_clk)
    begin
        if rising_edge(in_clk) then
           scaler_reset_in <= fft_reset_out;

            axis_scaler_in_tdata <= axis_fft_out_tdata;
            axis_scaler_in_tuser <= axis_fft_out_tuser;
            axis_scaler_in_tlast <= axis_fft_out_tlast;
            axis_scaler_in_tvalid <= axis_fft_out_tvalid;
            axis_scaler_in_tvalid <= '0' when fft_reset_out;

            scaler_reset_out <= scaler_reset_in;
        end if;
    end process;

    SCALER0: entity work.SCALER
        generic map (
            FFT_BITS_PER_BIN => FFT_BITS_PER_BIN, -- Real + Imaginary part
            FFT_BINS_PER_WORD => FFT_BINS_PER_WORD, -- half the number of ADC samples per word because the FFT drops half the spectrum (the negative frequencies)
            FFT_BINS_PER_FRAME => FFT_BINS_PER_FRAME, -- same comment
            USE_COMPLEX_GAINS => SCALER_USE_COMPLEX_GAINS,
            COEFF_BITS_PER_BIN => SCALER_COEFF_BITS_PER_BIN, -- typically 16 or 16+16. Includes both real and imaginary part. If USE_COMPLEX_GAINS=TRUE, half the bits are used for real and half for imaginary. Must be multiple of 8 as it is configured byte-wise.
            OUT_BITS_PER_BIN => SCALER_BITS_PER_BIN,
            CAP_BITS_PER_WORD => CAPTURE_BITS_PER_WORD
            )
        PORT MAP(
            -- Input data from the FFT
            s_axis_in_tdata => axis_scaler_in_TDATA,
            s_axis_in_tvalid => axis_scaler_in_TVALID,
            s_axis_in_tlast => axis_scaler_in_TLAST,
            s_axis_in_tuser => axis_scaler_in_TUSER,

            -- Output data
            m_axis_out_tdata => axis_scaler_out_tdata,
            m_axis_out_tvalid => axis_scaler_out_tvalid,
            m_axis_out_tlast => axis_scaler_out_tlast,
            m_axis_out_tuser => axis_scaler_out_tuser,


            m_axis_cap_tdata => axis_scaler_cap_tdata,
            m_axis_cap_tvalid => axis_scaler_cap_tvalid,
            m_axis_cap_tlast => axis_scaler_cap_tlast,

            clk       => in_clk,
            reset     => scaler_reset_in,

            fifo_overflow => fifo_overflow, -- We ask SCALER to monitor the channel FIFO for us
            mon_clk => out_clk,
            mon_tvalid => out_dat_tvalid,
            mon_tlast => out_dat_tlast,

            -- Control interface
            CTRL_CMD_IN_DAT   => CMD_DAT(MODULE_SCALER_ADDR),
            CTRL_CMD_IN_RDY   => CMD_RDY(MODULE_SCALER_ADDR),
            CTRL_RPLY_OUT_DAT => RPLY_DAT(MODULE_SCALER_ADDR),
            CTRL_RPLY_OUT_RDY => RPLY_RDY(MODULE_SCALER_ADDR),
            CTRL_CLK          => CTRL_CLK,
            CTRL_RST          => CTRL_RST
        );
end block scaler_blk;


---------------------------------------------------------------------
-- Instantiate the Channel FIFO
---------------------------------------------------------------------
-- This is a independant-clock FIFO, FWFT, 32+4 bits wide (data + 4 user flags), 0 latency.
--
-- We implement it with a built-in FIFO, with registers for better timing. The registers add no latency to an independent-clock built-in FIFO.
--
-- The channel FIFO crosses clock domains from the multiphase channelizer
-- clock to the 1st crossbar clock so we can confine the channelizer clock to
-- the channelizer region.
--
-- Using the channelizer clocks elsewhere in the design would cause every
-- region that use any of those clocks to infer one of the 12 clock buffer available
-- in each clock region. The corner-turn and shuffling logic uses many of
-- those buffers and some regions would run out of clock buffers.
--
-- It is more economical to sacrifice a block RAM per channelizer and have the
-- outputs of all channelizers operate on a single global clock.
--

-- Remap the scaler output to the FFT input. The FFT width matches the output width, but the scaler output may be wider so we can capture more of teh FFT bits in bypass mode.
fifo_blk:block
    signal fifo_reset_in: std_logic;
    attribute keep of  fifo_reset_in: signal is "true";



    signal fifo_rst: std_logic;



    signal axis_fifo_in_tdata: std_logic_vector(OUT_BITS_PER_WORD-1 downto 0);
    signal axis_fifo_in_tvalid: std_logic;
    signal axis_fifo_in_tlast: std_logic;
    signal axis_fifo_in_tuser: std_logic_vector(3 downto 0);


    signal axis_fifo_out_tdata  : std_logic_vector(OUT_BITS_PER_WORD-1 downto 0);
    signal axis_fifo_out_tvalid : std_logic;
    signal axis_fifo_out_tvalid_not_rst : std_logic;
    signal axis_fifo_out_tlast  : std_logic;
    signal axis_fifo_out_tuser  : std_logic_vector(3 downto 0);

    signal fifo_almost_full     : std_logic;
    signal fifo_almost_empty     : std_logic;

begin
    --FIFO_REMAP_GEN: for i in 0 to FFT_BINS_PER_WORD*2-1 generate
    --    axis_fifo_in_tdata((i+1)*OUT_BITS_PER_BIN/2-1 downto i*OUT_BITS_PER_BIN/2) <= axis_scaler_out_tdata((i+1)*SCALER_BITS_PER_BIN/2-1 downto (i+1)*SCALER_BITS_PER_BIN/2-OUT_BITS_PER_BIN/2);
    --end generate;
    --axis_fifo_in_tdata <= slv(cnt) & "0000" & slv(cnt+1) & "0000" & slv(cnt+2) & "0000" & slv(cnt+3) & "0000";

    axis_fifo_in_tdata <= axis_scaler_out_tdata;
    axis_fifo_in_tvalid <= axis_scaler_out_tvalid and not fifo_rst and (not fifo_almost_full or axis_scaler_out_tlast); -- make sure we don't write during reset
    axis_fifo_in_tlast <= axis_scaler_out_tlast;
    axis_fifo_in_tuser <= axis_scaler_out_tuser;

    lane_monitor(3) <= axis_fifo_in_tvalid xor axis_fifo_in_tlast; -- use FIFO input to stay in the right clock domain

    rst_proc: process(all) begin
        if rising_edge(in_clk) then
            fifo_reset_in <= scaler_reset_out;
        end if;
    end process;

    fifo0: entity work.chan_fifo
        generic map (
            FPGA_SERIES => FPGA_SERIES,
            DATA_WIDTH => OUT_BITS_PER_WORD,
            USER_WIDTH  => 4,
            ALMOST_FULL_THRESH => 500,
            ALMOST_EMPTY_THRESH => 16
            )
        port map (
            -- User AXI-Streaming data input (nnon-blocking)
            s_axis_tdata => axis_fifo_in_tdata,
            s_axis_tuser => axis_fifo_in_tuser,
            s_axis_tlast => axis_fifo_in_tlast,
            s_axis_tvalid=> axis_fifo_in_tvalid,
            s_axis_clk => in_clk,

            m_axis_tdata => axis_fifo_out_tdata,
            m_axis_tuser=> axis_fifo_out_tuser,
            m_axis_tlast=> axis_fifo_out_tlast,
            m_axis_tready => out_dat_send,
            m_axis_tvalid => axis_fifo_out_tvalid,
            m_axis_clk => out_clk,

            almost_full => fifo_almost_full,
            almost_empty => fifo_almost_empty,
            overflow => fifo_overflow,
            rst=> fifo_reset_in
            );

    ---------------------------------------------------------------------
    -- Assign the FIFO output to the channelizer output
    ---------------------------------------------------------------------
    out_proc: process(all) begin
        if rising_edge(out_clk) then
            out_dat_almost_empty <= fifo_almost_empty;
            out_dat_tdata <= axis_fifo_out_tdata;
            out_dat_tuser <= axis_fifo_out_tuser;
            out_dat_tlast <= axis_fifo_out_tlast;
            out_dat_tvalid <= axis_fifo_out_tvalid when out_dat_send and not out_reset else '0'; -- it is important to clear tvalid when send=0 as the FIFO still says it has new valid data but we are not sending that data
        end if; -- clk
    end process;

end block fifo_blk;




---------------------------------------------------------------------
-- DATA CAPTURE
---------------------------------------------------------------------
-- Captures a subset of the FUNGEN or SCALER output data for transmission over a slower link. There are 2 types of capture engines:
--   CAPTURE_TYPE = "BRAM": The capture engine is local to the channelizer and uses BRAM for storage. Each channelozer has its own capture engine (PROBER)
--        This is typically for application that have small frame sizes or on devices that don't have higher density UltraRAM.
--   CAPTURE_TYPE = "URAM": There us a centralized capture engine that uses UltraRAM to free up BRAM memory for other uses (such as the FFT).
--        The channelizer only implements the mux that selects the data source, and passes on the selected data to the capture port.
--
cap_blk: block

    -- funcgen pipeline
    signal axis_funcgen_tdata: std_logic_vector(ADC_BITS_PER_WORD-1 downto 0);
    signal axis_funcgen_tuser: std_logic_vector(3 downto 0);
    signal axis_funcgen_tvalid: std_logic;
    signal axis_funcgen_tlast: std_logic;

    signal axis_cap0_tdata: slv_array(0 to NUMBER_OF_CAPTURE_SOURCES-1)(CAPTURE_BITS_PER_WORD-1 downto 0);
    signal axis_cap0_tuser: slv_array(0 to NUMBER_OF_CAPTURE_SOURCES-1)(3 downto 0);
    signal axis_cap0_tvalid: std_logic_vector(0 to NUMBER_OF_CAPTURE_SOURCES-1);
    signal axis_cap0_tlast: std_logic_vector(0 to NUMBER_OF_CAPTURE_SOURCES-1);
    signal prober_reset_in: std_logic;
    attribute keep of prober_reset_in: signal is "true";

    constant CAPTURE_BITS_PER_SAMPLE: integer := CAPTURE_BITS_PER_WORD / ADC_SAMPLES_PER_WORD;

begin


    -- Pipeline the funcgen and scaler signals that are tapped of the main pipeline
    cap_pipe_proc: process(in_clk)
        begin
            if rising_edge(in_clk) then

                -- pipeline reset
                prober_reset_in <= funcgen_reset_out or scaler_reset_out;

                -- Pipeline data from FUNCGEN.
                axis_funcgen_tdata <= axis_funcgen_out_tdata;
                axis_funcgen_tuser <= axis_funcgen_out_tuser;
                axis_funcgen_tvalid <= '0' when prober_reset_in  else axis_funcgen_out_tvalid;
                axis_funcgen_tlast <= axis_funcgen_out_tlast;

                -- Assign to FUNCGEN data to capture bus.
                -- Repack the ADC samples on the MSB of the capture samples.
                axis_cap0_tdata(0) <= (others => '0');
                for i in 0 to ADC_SAMPLES_PER_WORD-1 loop
                    axis_cap0_tdata(0)((i+1) * CAPTURE_BITS_PER_SAMPLE-1 downto i*CAPTURE_BITS_PER_SAMPLE) <= msb_pad(axis_funcgen_tdata((i+1)*ADC_BITS_PER_SAMPLE-1 downto i*ADC_BITS_PER_SAMPLE), CAPTURE_BITS_PER_SAMPLE);
                end loop;
                axis_cap0_tuser(0) <= axis_funcgen_tuser;
                axis_cap0_tvalid(0) <= '0' when prober_reset_in else axis_funcgen_tvalid;
                axis_cap0_tlast(0) <= axis_funcgen_tlast;

                -- Assign SCALER data to capture bus.
                -- No additional SCALER pipelining is used since it is assumed SCALER is close to the external capture module
                axis_cap0_tdata(1) <= axis_scaler_cap_tdata; -- Scaler output width was already made equal to the capture width.
                axis_cap0_tvalid(1) <= '0' when prober_reset_in else axis_scaler_cap_tvalid;
                axis_cap0_tlast(1) <= axis_scaler_cap_tlast;

            end if; -- clk
        end process;
    -- Block-RAM-based local capture engine
    cap_gen: if CAPTURE_TYPE = "BRAM" generate

         -- Slow output data stream
        signal PRB_DAT: AXIS8_DAT_STRUCT;
        signal PRB_RDY: AXIS8_RDY_STRUCT;

    begin

        -- Connect capture streams to top level port
        prb_tdata <= prb_DAT.tdata;
        prb_tvalid <= prb_DAT.tvalid;
        prb_tlast <= prb_DAT.tlast;
        prb_RDY.tready <= prb_tready;

        -- Instantiate the local capture module
        PROBER0: entity work.PROBER
            generic map (
                SIM=>SIM
            )
            port map (
                -- Input data
                in_dat0   => (
                    TDATA => axis_cap0_tdata(0),
                    TUSER => axis_cap0_tuser(0),
                    TVALID => axis_cap0_tvalid(0),
                    TLAST => axis_cap0_tlast(0)),
                in_dat1   => (
                    TDATA => axis_cap0_tdata(1),
                    TUSER => axis_cap0_tuser(1),
                    TVALID => axis_cap0_tvalid(1),
                    TLAST => axis_cap0_tlast(1)),
                in_clk    => in_clk, -- both inputs must run on the same clock
                in_reset  => prober_reset_in, -- both inputs must run on the same reset

                -- Output data streams
                OUT_DAT => PRB_DAT,
                OUT_RDY => PRB_RDY,
                OUT_CLK => PRB_CLK,

                -- Control interface
                CTRL_CMD_IN_DAT   => CMD_DAT(MODULE_PROBER_ADDR),
                CTRL_CMD_IN_RDY   => CMD_RDY(MODULE_PROBER_ADDR),
                CTRL_RPLY_OUT_DAT => RPLY_DAT(MODULE_PROBER_ADDR),
                CTRL_RPLY_OUT_RDY => RPLY_RDY(MODULE_PROBER_ADDR),
                CTRL_CLK          => CTRL_CLK,
                CTRL_RST          => CTRL_RST
            );

    elsif CAPTURE_TYPE = "URAM" generate
         cap_proc: process(in_clk)
                variable src: integer range 0 to 1;
            begin
                if rising_edge(in_clk) then
                    cap_source_ack <= cap_source_req;
                    -- Select the data bus to pass on to the capture output
                    src := to_integer(to_unsigned(cap_source_ack));
                    m_axis_cap_tdata <= axis_cap0_tdata(src);
                    -- Pass the tlast * tvalid for *all* sources so UCAP can continuously track the frame numbers
                    m_axis_cap_tlast <= axis_cap0_tlast;
                    m_axis_cap_tvalid <= axis_cap0_tvalid;
                end if; -- clk
            end process;
    else generate
        assert FALSE report "Unsupported CAPTURE_TYPE" & CAPTURE_TYPE severity FAILURE;
    end generate cap_gen;

end block cap_blk;

end generate IMPL_GEN; -- IMPLEMENT_CHAN=TRUE



NOIMPL_GEN: if IMPLEMENT_CHAN = FALSE generate
    -- Force the output stream to send no data
    out_dat_tvalid <= '0'; -- this line makes the simulator crash
    out_dat_tdata <= (others=>'0');
    out_dat_tuser <= (others=>'0');
    out_dat_tlast <= '0';

    -- Force the command interface to accept and ignore any command and to reply nothing.
    -- Skip the ADCDAQ module because it is always implemented.
    MODn:   for i in MODULE_ADCDAQ_ADDR+1 to NUMBER_OF_MODULES-1 generate
                CMD_RDY(i).TREADY <= '1'; -- Always accept commands. Those will be ignored.
                RPLY_DAT(i).TVALID <= '0'; -- Do not send any reply
                RPLY_DAT(i).TLAST <= '0'; -- for nice simulations only
                RPLY_DAT(i).TDATA <= (others=>'0'); -- for nice simulations only
    end generate;
end generate NOIMPL_GEN; -- IMPLEMENT_CHAN=FALSE

end impl;

