----------------------------------------------------------------------------------
--! @file
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

--! @brief Implements the chanelizer pipeline, consisting of a function generator (FUNCGEN), FFT module (FFT), scaler (SCALER) and a resynchrozing FIFO (CHAN_FIFO).
entity CHAN is
    --GENERIC (
    --    --! Indicates if the channelizer is implemented. If not, a dummy module will be put in its place.
    --    --! In this case, an dummy ADCDAQ module is still instantiated to ensure that the LVDS receivers are instantiated
    --    --! (which would otherwise cause errors unless they were removed from the UCF file)
    --    IMPLEMENT_CHAN  : BOOLEAN :=TRUE; -- (and that woul dbe bad)
    --    IMPLEMENT_FFT   : BOOLEAN :=GLOBAL_IMPLEMENT_FFT;
    --    SIM             : BOOLEAN :=GLOBAL_SIM
    --    );

    PORT (

        --! Input Interface from ADC
        --! 32-bit wide, using the AXI4-Streaming Prototol

        in_dat_tdata    : in slv32;
        in_dat_tvalid   : in std_logic;
        in_dat_tlast    : in std_logic;
        in_dat_tuser    : in slv4;
        in_clk          : in std_logic; --! Input and signal processing clock
        in_reset        : in std_logic; --! Resets all the channelizer modules,
                                        --! except ADCDAQ. Must be synchronous to in_clk.

        --! Output Interface
        --! Output Data Stream in 32bit AXI4-Streaming

        out_dat_tdata   : out slv32;
        out_dat_tvalid  : out std_logic;
        out_dat_tlast   : out std_logic;
        out_dat_tuser   : out slv4;
        out_clk         : in  std_logic;
        out_reset       : in  std_logic;

        --! Common data interface signals
        --! Global trigger/capture signal.
        --! Indicates to SRCSEL when to start flagging the incoming frames the data capture.

        trig            : in  std_logic;
        lane_monitor    : out std_logic_vector(3 downto 0);

        --! UDP Command Control Interface (command and reply stream buses)

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

        --! Control Interface to be hooked-up  to the corresponding ADCDAQ module

        adc_cmd_tdata   : out std_logic_vector(7 downto 0);
        adc_cmd_tvalid  : out std_logic;
        adc_cmd_tlast   : out std_logic;
        adc_cmd_tready  : in  std_logic;

        adc_rply_tdata  : in  std_logic_vector(7 downto 0);
        adc_rply_tvalid : in  std_logic;
        adc_rply_tlast  : in  std_logic;
        adc_rply_tready : out std_logic;

        -- Data Probe Interface

        prb_tdata       : out std_logic_vector(7 downto 0);
        prb_tvalid      : out std_logic;
        prb_tlast       : out std_logic;
        prb_tready      : in  std_logic;
        PRB_CLK         : in  std_logic --! Data capture clock
        );
end CHAN;




------ Channelizer implementation
--! Implements the channelizer blocks
architecture Behavioral of CHAN is

constant IMPLEMENT_CHAN  : BOOLEAN :=TRUE; -- (and that woul dbe bad)
constant IMPLEMENT_FFT   : BOOLEAN :=GLOBAL_IMPLEMENT_FFT;
constant SIM             : BOOLEAN :=GLOBAL_SIM;

signal axis_adcdaq_out      : AXIS32_DAT_STRUCT; --! input bus from adc, 32-bit wide, using the AXI4-Streaming prototol
signal axis_adcdaq_out_reg1 : AXIS32_DAT_STRUCT;
signal axis_adcdaq_out_reg2 : AXIS32_DAT_STRUCT;
signal axis_funcgen_out     : AXIS32_DAT_STRUCT;
signal axis_fft_out         : AXIS72_DAT_STRUCT;
signal axis_scaler_out      : AXIS32_DAT_STRUCT;

signal axis_fifo_out_tvalid : std_logic;
signal axis_fifo_out_tdata  : slv32;
signal axis_fifo_out_tlast  : std_logic;
signal axis_fifo_out_tuser  : slv4;
signal fifo_overflow        : std_logic;


signal in_reset_reg         : std_logic :='1'; --! added =1 to see if it helps the reset problem
-- signal out_reset_reg: std_logic :='1';
-- Make sure the pipeline registers are not simplified by the synthesizer so they can be useful in helping meeting timing
attribute equivalent_register_removal: string;
attribute equivalent_register_removal of axis_adcdaq_out_reg1: signal is "no";
attribute equivalent_register_removal of axis_adcdaq_out_reg2: signal is "no";
attribute shreg_extract: string;
attribute shreg_extract of axis_adcdaq_out_reg1: signal is "no";
attribute shreg_extract of axis_adcdaq_out_reg2: signal is "no";


-- make sure that the ADCDAQ logic is not removed if nothing is connected downstream
-- Make sure the synthesizer does not remove the I/O logic for the unused ADC outputs


--signal ADC_CLK_OUT_PLL_INT : STD_LOGIC;

-- Control bus signals
constant NUMBER_OF_MODULES  : integer:=7; --! Total number of modules to be implemented. Is used to set the number of ports of the control interface router.
constant MODULE_ADCDAQ_ADDR : integer:=0; --! Address of the ADC data acquisition module
constant MODULE_SRCSEL_ADDR : integer:=1; --! (unused) Address of the source selector module
constant MODULE_FFT_ADDR    : integer:=2; --! Address of the channelizer (FFT) module
constant MODULE_SCALER_ADDR : integer:=3; --! Address of the scaler module
constant MODULE_PROBER_ADDR : integer:=4; --! Address of the data capture module
constant MODULE_FUNCGEN_ADDR: integer:=5; --! Address of the function generator module
constant MODULE_INJECT_ADDR : integer:=6; --! (unused) Address of the data injection module

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

signal PRB_DAT: AXIS8_DAT_STRUCT; --! Data capture bus (AXI4 Streaming)
signal PRB_RDY: AXIS8_RDY_STRUCT;

begin

axis_adcdaq_out.TDATA <= in_dat_tdata;
axis_adcdaq_out.TVALID <= in_dat_tvalid;
axis_adcdaq_out.TLAST <= in_dat_tlast;
axis_adcdaq_out.TUSER <= in_dat_tuser;


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

prb_tdata <= prb_DAT.tdata;
prb_tvalid <= prb_DAT.tvalid;
prb_tlast <= prb_DAT.tlast;
prb_RDY.tready <= prb_tready;



--!@addtogroup memory_map
--! CHANNELIZER Memory Map
--!
--! |#   |  Addr           | Module                       | Description |
--! |----|-----------------|------------------------------|-------------|
--! | 0  | Base + 0x00000  | ADCDAQ                       |             |
--! | 1  | Base + 0x00100  | (unused)                     |             |
--! | 2  | Base + 0x00200  | FFT                          |             |
--! | 3  | Base + 0x00300  | SCALER                       |             |
--! | 4  | Base + 0x00400  | PROBER                       |             |
--! | 5  | Base + 0x00500  | FUNCGEN                      |             |
--! | 6  | Base + 0x00600  | (unused)                     |             |
--! | 7  | Base + 0x00700  | (unused)                     |             |

---------------------------------------------------------------------
-- Instantiate the Command router
--! Routes the commands to the requested module
---------------------------------------------------------------------
CTRL_ROUTER0: entity work.CTRL_ROUTER
    GENERIC MAP (
        NUMBER_OF_PORTS=>NUMBER_OF_MODULES,
        ADDRESS_MASK => "--------111---------" --'1': used to generate port index, '-' = don't care,
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

---------------------------------------------------------------------
--! Registers the synchronous reset for distribution across the internal modules
--! Helps meet timing, otherwise the fanout is too large
---------------------------------------------------------------------
rst_proc: process(in_clk)
    begin
        if rising_edge(in_clk) then
            in_reset_reg <= in_reset;
        end if;
    end process;


IMPL: if IMPLEMENT_CHAN=TRUE generate

---------------------------------------------------------------------
--! Propagates the ADCDAQ output through a couple of registers to facilitate timing between the ADCDAQ and FUNCGEN
--! Helps meet timing, since the bus can take two stops to route across the chip
--!
--! Also pipeline and forwards key debugging signals for external moinitoring.
--!
--! NOTE:  only TVALID is affected by the synchronous RESET line, not the
--!    entire bus. This is because that reset would 1) drive a large load and
--!    2) be routed to all the registers and will make timing harder to meet.
--1
--! NOTE: This process is implemented only when IMPLEMENT_CHAN=TRUE, otherwise
--!   there will be assignment conflicts to OUT_DAT with the block that handle
--!   IMPLEMENT_CHAN=FALSE, and that makes the Vivado simulator hang up.
---------------------------------------------------------------------
adcdat_proc: process(in_clk)
    begin
        if rising_edge(in_clk) then
            axis_adcdaq_out_reg1 <= axis_adcdaq_out;
            axis_adcdaq_out_reg2 <= axis_adcdaq_out_reg1;
            if in_reset_reg='1' then
                axis_adcdaq_out_reg1.TVALID <= '0';
                axis_adcdaq_out_reg2.TVALID <= '0';
            end if;
        lane_monitor(0) <= axis_scaler_out.TVALID xor axis_scaler_out.TLAST;
        lane_monitor(1) <= axis_fft_out.TVALID xor axis_fft_out.TLAST;
        lane_monitor(2) <= axis_funcgen_out.TVALID xor axis_funcgen_out.TLAST;
        lane_monitor(3) <= axis_fifo_out_tvalid xor axis_fifo_out_tlast;
        end if; --clk
    end process;

---------------------------------------------------------------------
-- Instantiate the FUNCTION GENERATOR
---------------------------------------------------------------------
-- The Function Generator either forwards the ADC data or injects user-programmable arbitrary waveforms
FUNCGEN0: entity work.FUNCGEN
    PORT MAP(

        -- Input from the ADC
        in_dat => axis_adcdaq_out_reg2,
        trig   => trig,

        -- Output stream to FFT
        out_dat => axis_funcgen_out,

        clk => in_clk,
        rst => in_reset_reg,

        -- Control interface
        ctrl_cmd_in_dat   => CMD_DAT(MODULE_FUNCGEN_ADDR),
        ctrl_cmd_in_rdy   => CMD_RDY(MODULE_FUNCGEN_ADDR),
        ctrl_rply_out_dat => RPLY_DAT(MODULE_FUNCGEN_ADDR),
        ctrl_rply_out_rdy => RPLY_RDY(MODULE_FUNCGEN_ADDR),
        ctrl_clk          => CTRL_CLK,
        ctrl_rst          => CTRL_RST
    );


-- Tying up unused control ports so the router will no lock-up
-- These were for INJECT and SRCSEL modules whose functionnalities have been merged into FUNCGEN

CMD_RDY(MODULE_INJECT_ADDR).TREADY  <= '1'; --! Always accept commands. Those will be ignored.
RPLY_DAT(MODULE_INJECT_ADDR).TVALID <= '0'; --! Do not send any reply
RPLY_DAT(MODULE_INJECT_ADDR).TLAST  <= '0'; --! for nice simulations only
RPLY_DAT(MODULE_INJECT_ADDR).TDATA  <= (others=>'0'); --! for nice simulations only

CMD_RDY(MODULE_SRCSEL_ADDR).TREADY  <= '1'; --! Always accept commands. Those will be ignored.
RPLY_DAT(MODULE_SRCSEL_ADDR).TVALID <= '0'; --! Do not send any reply
RPLY_DAT(MODULE_SRCSEL_ADDR).TLAST  <= '0'; --! for nice simulations only
RPLY_DAT(MODULE_SRCSEL_ADDR).TDATA  <= (others=>'0'); --! for nice simulations only

---------------------------------------------------------------------
-- Instantiate the FFT Block
---------------------------------------------------------------------
-- This is a wrapper for the CASPER FFT so it can operate with AXI4 Streaming buses.
-- Also adds a control interface to control the FFT operation.
FFT0: entity work.FFT
    GENERIC MAP (
        IMPLEMENT_FFT=>IMPLEMENT_FFT
        )
    PORT MAP(
        -- Input and output interfaces
        in_dat  => axis_funcgen_out,
        out_dat => axis_fft_out,
        clk     => in_clk,
        reset   => in_reset_reg,

        -- Control interface
        CTRL_CMD_IN_DAT   => CMD_DAT(MODULE_FFT_ADDR),
        CTRL_CMD_IN_RDY   => CMD_RDY(MODULE_FFT_ADDR),
        CTRL_RPLY_OUT_DAT => RPLY_DAT(MODULE_FFT_ADDR),
        CTRL_RPLY_OUT_RDY => RPLY_RDY(MODULE_FFT_ADDR),
        CTRL_CLK          => CTRL_CLK,
        CTRL_RST          => CTRL_RST
    );

---------------------------------------------------------------------
-- Instantiate the SCALER Block
---------------------------------------------------------------------
-- Applies a complex correction factor to each sample coming out of the FFT and scales the data back to 8 bits or 4 bits format.
SCALER0: entity work.SCALER
    PORT MAP(
        -- Input and output interfaces
        in_dat    => axis_fft_out,
        out_dat   => axis_scaler_out,
        clk       => in_clk,
        reset => in_reset_reg,

        fifo_overflow => fifo_overflow,
        -- Control interface
        CTRL_CMD_IN_DAT   => CMD_DAT(MODULE_SCALER_ADDR),
        CTRL_CMD_IN_RDY   => CMD_RDY(MODULE_SCALER_ADDR),
        CTRL_RPLY_OUT_DAT => RPLY_DAT(MODULE_SCALER_ADDR),
        CTRL_RPLY_OUT_RDY => RPLY_RDY(MODULE_SCALER_ADDR),
        CTRL_CLK          => CTRL_CLK,
        CTRL_RST          => CTRL_RST
    );


---------------------------------------------------------------------
-- Instantiate the Channel FIFO
---------------------------------------------------------------------
-- The channel FIFO crosses clock domains from the multiphase channelizer
-- clock to the 1st crossbar clock so we can confine the channelizer clock to
-- the channelizer region.
--
-- Using the channelizer clocks elsewhere in the design would cause every
-- region that use any of those clocks to infer one of the 12 buffer available
-- in each clock region. The corner-turn and shuffling logic uses many of
-- those buffers and some regions would run out of clock buffers.
--
-- It is more economical to sacrifice a block RAM pe rchannelizer and have the
-- outputs of all channelizers operate on a  single global clock.
chan_fifo0 : entity work.CHAN_FIFO2
    PORT MAP (
        rst                => in_reset_reg,
        wr_clk             => in_clk,
        wr_en              => axis_scaler_out.TVALID,
        din(31 downto 0)   => axis_scaler_out.TDATA,
        din(32)            => axis_scaler_out.TLAST,
        din(36 downto 33)  => axis_scaler_out.TUSER,

        rd_clk             => out_clk,
        rd_en              => axis_fifo_out_tvalid, -- start reading only when there is data. In simulation, tying rd_en to '1' causes 'valid' to be invalid.
        dout(31 downto 0)  => axis_fifo_out_tdata,
        dout(32)           => axis_fifo_out_tlast,
        dout(36 downto 33) => axis_fifo_out_tuser,
        valid              => axis_fifo_out_tvalid,
        full               => open,
        overflow           => fifo_overflow,
        empty              => open
    );


---------------------------------------------------------------------
-- Assign the FIFO output to the channelizer output
---------------------------------------------------------------------
out_proc: process(out_clk)
    begin
        if rising_edge(out_clk) then
            -- out_reset_reg <= out_reset;
            if out_reset = '1' then
                out_dat_tvalid <= '0';
            else
                out_dat_tvalid <= axis_fifo_out_tvalid;
            end if;

            out_dat_tdata <= axis_fifo_out_tdata;
            out_dat_tuser <= axis_fifo_out_tuser;
            out_dat_tlast <= axis_fifo_out_tlast;
        end if; -- clk
    end process;

---------------------------------------------------------------------
-- Instantiate the data capture module
---------------------------------------------------------------------
-- Captures a subset of the FUNGEN or SCALER output and send it over a slow
-- 8-bit bus that can be connected to the 1G Ethernet packet transmitter.
PROBER0: entity work.PROBER
    generic map (
        SIM=>SIM
    )
    port map (
        -- Input data
        in_dat0   => axis_funcgen_out,
        in_dat1   => axis_scaler_out,
        in_clk    => in_clk, -- both inputs must run on the same clock
        in_reset  => in_reset_reg, -- both inputs must run on the same reset

        -- Output data
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
end generate; -- IMPLEMENT_CHAN=TRUE



NO_ANT: if IMPLEMENT_CHAN=FALSE generate
    --! Force the output stream to send no data
    out_dat_tvalid <= '0'; -- this line makes the simulator crash
    out_dat_tdata <= (others=>'0');
    out_dat_tuser <= (others=>'0');
    out_dat_tlast <= '0';

    --! Force the command interface to accept and ignore any command and to reply nothing.
    --! Skip the ADCDAQ module because it is always implemented.
    MODn:   for i in MODULE_ADCDAQ_ADDR+1 to NUMBER_OF_MODULES-1 generate
                CMD_RDY(i).TREADY<= '1'; --! Always accept commands. Those will be ignored.
                RPLY_DAT(i).TVALID<='0'; --! Do not send any reply
                RPLY_DAT(i).TLAST<='0'; -- for nice simulations only
                RPLY_DAT(i).TDATA<=(others=>'0'); -- for nice simulations only
    end generate;
end generate; -- IMPLEMENT_CHAN=FALSE

end Behavioral;

