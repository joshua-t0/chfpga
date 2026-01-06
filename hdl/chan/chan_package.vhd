----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
----------------------------------------------------------------------------------


use work.chfpga_package.all;
use work.chfpga_config.all;

-- Define constants local to this file only

package local_constants is
	constant FFT_TYPE: fft_type_enum            := CONFIG_CHAN_FFT_TYPE;
	constant CT_TYPE : ct_type_enum             := CONFIG_CT_TYPE; -- Used to determine the width of the output bus to the corner-turn engine

	constant ADC_BITS_PER_SAMPLE: integer       := FFT_INFO(FFT_TYPE).BITS_PER_SAMPLE;
	constant ADC_SAMPLES_PER_WORD: integer      := FFT_INFO(FFT_TYPE).SAMPLES_PER_WORD;
	constant ADC_SAMPLES_PER_FRAME: integer     := FFT_INFO(FFT_TYPE).SAMPLES_PER_FRAME;
	constant ADC_BITS_PER_WORD: integer         := ADC_BITS_PER_SAMPLE * ADC_SAMPLES_PER_WORD;
    constant CAPTURE_BITS_PER_WORD: integer     := CHAN_CAPTURE_INFO(CONFIG_CHAN_CAPTURE_TYPE).INPUT_WIDTH;
    constant OUT_BITS_PER_WORD: integer         := CT_INFO(CT_TYPE).INPUT_WIDTH; -- Width of the output data bus which feeds the corner-turn engine. Sets the scaler output width. BCT can receive 2x (8+8)-bits bins, UCT can receive 4x (4+4)-bit bins, so always 32. 

end package;

-- Now define the CHAN component that we will import

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.chfpga_package.all;
use work.chfpga_config.all;
use work.local_constants.all;


-- Defines the chan entity as a component so we can  defer binding in conditional if-generate blocks and prevent elaboration errors
package chan_package is

    ----------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------
    -- CHAN: Channelizer module component definition
    ----------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------
    COMPONENT chan is
        -- We cannot have GENERICS here if the module is to be used as an Out-Of-Contect (OOC) module.
        -- That is true EVEN IF all the GENERICS have default values and we don't have a GENERICS section in the component
        -- instantiation...
        --
        -- In order to simplify port declarations, we instead declared our generics as constants in the package local_package at the top of this file.
             
      PORT (
    
        in_dat_tdata: in std_logic_vector(ADC_BITS_PER_WORD - 1  downto 0);
        in_dat_tuser: in std_logic_vector(ADC_SAMPLES_PER_WORD - 1 downto 0);
        in_dat_tvalid: in std_logic;
        in_dat_tlast: in std_logic;
        in_reset: in std_logic; -- Resets all the antenna processor modules, except ADCDAQ. Must be synchronous to ANT_CLK.
        in_clk : in  std_logic; -- input interface clock, also used for data processing
    
    
        -- Output interface
        
        out_dat_tdata: out std_logic_vector(OUT_BITS_PER_WORD-1 downto 0);
        out_dat_tuser: out std_logic_vector(3 downto 0);
        out_dat_tvalid: out std_logic;
        out_dat_tlast: out std_logic;
        out_dat_almost_empty : out std_logic; -- assers about 15 clocks before the FIFO has no more data
        out_dat_send    : in  std_logic := '1'; -- high when output data can be sent. Has a one clock latency.
        out_clk: in std_logic;
        out_reset: in std_logic;
    
         -- Control interface (command and reply stream buses)
         
        s_axis_bsb_tdata: in std_logic_vector(7 downto 0);
        s_axis_bsb_tvalid: in std_logic;
        s_axis_bsb_tlast: in std_logic;
        s_axis_bsb_tready: out std_logic;
        m_axis_bsb_tdata: out std_logic_vector(7 downto 0);
        m_axis_bsb_tvalid: out std_logic;
        m_axis_bsb_tlast: out std_logic;
        m_axis_bsb_tready: in std_logic;
    
        bsb_clk : in  STD_LOGIC;
        bsb_rst : in  STD_LOGIC; -- Global asynchronous RESET, activated at power-up.
    
        -- Control interface to be hooked-up  to the corresponding ADCDAQ module
        
        m_axis_adcdaq_bsb_tdata: out std_logic_vector(7 downto 0);
        m_axis_adcdaq_bsb_tvalid: out std_logic;
        m_axis_adcdaq_bsb_tlast: out std_logic;
        m_axis_adcdaq_bsb_tready: in std_logic;
        s_axis_adcdaq_bsb_tdata: in std_logic_vector(7 downto 0);
        s_axis_adcdaq_bsb_tvalid: in std_logic;
        s_axis_adcdaq_bsb_tlast: in std_logic;
        s_axis_adcdaq_bsb_tready: out std_logic;
    
        -- packet capture interface
        
        cap_source_req: in std_logic := '0';
        cap_source_ack: out std_logic := '0';
        m_axis_cap_tdata: out std_logic_vector(CAPTURE_BITS_PER_WORD - 1 downto 0);
        m_axis_cap_tvalid: out std_logic_vector(0 to CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES - 1);
        m_axis_cap_tlast: out std_logic_vector(0 to CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES - 1);
    
    
        -- Data Capture interface
        
        prb_tdata: out std_logic_vector(7 downto 0);
        prb_tvalid: out std_logic;
        prb_tlast: out std_logic;
        prb_tready: in std_logic;
        prb_clk : in  STD_LOGIC  -- Data capture clock
        );
    end COMPONENT;
    

end chan_package;

