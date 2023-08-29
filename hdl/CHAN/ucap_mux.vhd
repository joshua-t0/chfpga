----------------------------------------------------------------------------------
--! @file
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date      : 2023-05-30
-- Design Name      : ucap_mux
-- Module Name      : ucap_mux - Behavioral
-- Project Name     : CHORD
-- Target Devices   : Ultrascale+
-- Tool versions    : Vivado 2022.2
-- Description      : Source selector for the data capture block  
--
-- Dependencies:
--
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

library work;
use work.chFPGA_package.all; -- Get all component definitions
 
--! @brief Implements the chanelizer pipeline, consisting of a function generator (FUNCGEN), FFT module (FFT), scaler (SCALER) and a resynchrozing FIFO (CHAN_FIFO).
entity ucap_mux is
    generic (
        PLATFORM_ID     : integer := CONFIG_PLATFORM_ID;-- PLATFORM_ID_MGK7MB; -- This generics is locked to the MGK7MB when using ucap_mux as an OOC.
        ADC_BITS_PER_SAMPLE: integer := CONFIG_ADC_BITS_PER_SAMPLE;
        ADC_SAMPLES_PER_WORD: integer := CONFIG_ADC_SAMPLES_PER_WORD
        );

    port (
        --! Input Interface from ADC
        --! 64-bit wide (4x 16-bit samples), using the AXI4-Streaming Prototol

        s_axis_in0_tdata    : in std_logic_vector(ADC_BITS_PER_SAMPLE * ADC_SAMPLES_PER_WORD-1 downto 0);
        s_axis_in0_tvalid   : in std_logic;
        s_axis_in0_tlast    : in std_logic;

        s_axis_in1_tdata    : in std_logic_vector(ADC_BITS_PER_SAMPLE * ADC_SAMPLES_PER_WORD-1 downto 0);
        s_axis_in1_tvalid   : in std_logic;
        s_axis_in1_tlast    : in std_logic;

        m_axis_out_tdata    : out std_logic_vector(ADC_BITS_PER_SAMPLE * ADC_SAMPLES_PER_WORD-1 downto 0);
        m_axis_out_tuser    : out std_logic_vector(2 downto 0); -- Frame tracker: bit 0: in0 EOF, bit 1: in1 EOF, bit 2: current source
        m_axis_out_tvalid   : out std_logic;
        m_axis_out_tlast    : out std_logic;

        clk             : in std_logic; 
        rst             : in std_logic; 

        -- UDP Command Control Interface (command and reply stream buses)

        s_axis_bsb_tdata  : in  std_logic_vector(7 downto 0);
        s_axis_bsb_tvalid : in  std_logic;
        s_axis_bsb_tlast  : in  std_logic;
        s_axis_bsb_tready : out std_logic;

        m_axis_bsb_tdata : out std_logic_vector(7 downto 0);
        m_axis_bsb_tvalid: out std_logic;
        m_axis_bsb_tlast : out std_logic;
        m_axis_bsb_tready: in  std_logic;
        bsb_clk        : in  std_logic;
        bsb_rst        : in  std_logic
        );
end ucap_mux;




------ Channelizer implementation
--! Implements the channelizer blocks
architecture impl of ucap_mux is

    -- Control and status bytes
    signal new_src: std_logic;
    signal current_src: std_logic;
    signal send_enable: std_logic;
begin

    -- Selects data source
    --
    -- Make sure we change source only when a new frame begins.
    sel_proc: process(clk) is
        variable last: std_logic; 
    begin
        if rising_edge(in_clk) then

            if current_src = '0' then
                m_axis_out_tvalid <= s_axis_in0_tvalid and send_enable;
                m_axis_out_tlast <= s_axis_in0_tlast;
                m_axis_out_tdata <= s_axis_in0_tdata;
                last := s_axis_in0_tvalid and s_axis_in0_tlast;
            else
                m_axis_out_tvalid <= s_axis_in1_tvalid and send_enable;
                m_axis_out_tlast <= s_axis_in1_tlast;
                m_axis_out_tdata <= s_axis_in1_tdata;
                last := s_axis_in1_tvalid and s_axis_in1_tlast;
            end if;
            -- Send frame number tracking signals so the destination can keep track of frame number of both sources even only one is selected and forwarded.
            m_axis_out_tuser(0) <= s_axis_in0_tvalid and s_axis_in0_tlast;
            m_axis_out_tuser(1) <= s_axis_in1_tvalid and s_axis_in1_tlast;
            m_axis_out_tuser(2) <= current_src;


            if current_src /= new_src then -- If we changed source, wait for the end of the packet on the current source then disable transmisson 
                if last = '1' then
                    send_enable <= '0';
                    current_src <= new_src;
                end if;
            elsif last = '1' then -- if we are on the curent source and the packet ends, enable transmission
                    send_enable <= '1';
            end if;

            if rst = '1' then
                send_enable <= '1';
                current_src <= new_src;
                m_axis_out_tvalid <= '0';
            end if;

        end if; --clk
    end process;


end impl;

