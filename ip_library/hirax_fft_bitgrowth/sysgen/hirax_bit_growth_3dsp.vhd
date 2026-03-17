-- Generated 3 DSP multiplier variant of hirax_bit_growth
-- Uses 3 DSP48 multipliers instead of 4, with exact latency matching
library IEEE;
use IEEE.std_logic_1164.all;
library xil_defaultlib;
use xil_defaultlib.conv_pkg.all;

-- Consolidated 3 DSP complex multiplier for widest inputs (a=36, b=56)
-- This entity can be used for all variants with input extension/output truncation
entity hirax_bit_growth_3dsp_mult1 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 56-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab : out std_logic_vector( 94-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult1;

architecture structural of hirax_bit_growth_3dsp_mult1 is 
  signal concat_y_net : std_logic_vector( 94-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 56-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  
  -- Input expansion signals (same as original)
  signal reinterpret4_output_port_net_x0 : std_logic_vector( 18-1 downto 0 );
  signal reinterpret3_output_port_net : std_logic_vector( 18-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 18-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 18-1 downto 0 );
  signal concatenate_y_net_x0 : std_logic_vector( 72-1 downto 0 );
  signal reinterpret4_output_port_net : std_logic_vector( 28-1 downto 0 );
  signal reinterpret3_output_port_net_x0 : std_logic_vector( 28-1 downto 0 );
  signal reinterpret2_output_port_net_x0 : std_logic_vector( 28-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 28-1 downto 0 );
  signal concatenate_y_net : std_logic_vector( 112-1 downto 0 );
  
  -- 3 DSP algorithm signals
  -- Extract real/imaginary parts (combinational)
  signal a_re_signed : signed( 18-1 downto 0 );
  signal a_im_signed : signed( 18-1 downto 0 );
  signal b_re_signed : signed( 28-1 downto 0 );
  signal b_im_signed : signed( 28-1 downto 0 );
  
  -- Pre-multiplier add/sub results (combinational, will be truncated to fit multipliers)
  signal a_re_plus_im_signed : signed( 19-1 downto 0 );  -- a_re + a_im
  signal b_re_plus_im_signed : signed( 29-1 downto 0 );  -- b_re + b_im
  signal b_im_minus_re_signed : signed( 29-1 downto 0 ); -- b_im - b_re
  
  -- Truncated versions for multiplier inputs (18 bits for a, 28 bits for b)
  signal a_re_plus_im_trunc : std_logic_vector( 18-1 downto 0 );
  signal b_re_trunc : std_logic_vector( 28-1 downto 0 );
  signal b_re_plus_im_trunc : std_logic_vector( 28-1 downto 0 );
  signal b_im_minus_re_trunc : std_logic_vector( 28-1 downto 0 );
  signal a_im_trunc : std_logic_vector( 18-1 downto 0 );
  signal a_re_trunc : std_logic_vector( 18-1 downto 0 );
  
  -- Multiplier outputs (46 bits each, 2 cycles latency)
  signal mult0_p_net : std_logic_vector( 46-1 downto 0 );  -- (a_re + a_im) * b_re
  signal mult1_p_net : std_logic_vector( 46-1 downto 0 );  -- a_im * (b_re + b_im)
  signal mult2_p_net : std_logic_vector( 46-1 downto 0 );  -- a_re * (b_im - b_re)
  
  -- Post-multiplier add/sub (1 cycle latency, outputs 47 bits)
  signal addsub_re_s_net : std_logic_vector( 47-1 downto 0 );  -- mult0 - mult1 (real part)
  signal addsub_im_s_net : std_logic_vector( 47-1 downto 0 );  -- mult0 - mult2 (imaginary part)
  
  -- Output conversion
  signal convert_re_dout_net : std_logic_vector( 47-1 downto 0 );
  signal convert_im_dout_net : std_logic_vector( 47-1 downto 0 );
  
begin
  ab <= concat_y_net;
  reinterpret1_output_port_net <= a;
  reinterpret1_output_port_net_x0 <= b;
  clk_net <= clk_1;
  ce_net <= ce_1;
  
  -- Input expansion (same as original, combinational)
  a_expand : entity xil_defaultlib.hirax_bit_growth_a_expand_x6 
  port map (
    bus_in => concatenate_y_net_x0,
    msb_out4 => reinterpret4_output_port_net_x0,  -- a_re MSB
    out3 => reinterpret3_output_port_net,          -- a_im MSB
    out2 => reinterpret2_output_port_net,          -- a_re LSB
    lsb_out1 => reinterpret1_output_port_net_x1    -- a_im LSB
  );
  
  a_replicate : entity xil_defaultlib.hirax_bit_growth_a_replicate_x8 
  port map (
    in_x0 => reinterpret1_output_port_net,
    out_x0 => concatenate_y_net_x0
  );
  
  b_expand : entity xil_defaultlib.hirax_bit_growth_b_expand_x8 
  port map (
    bus_in => concatenate_y_net,
    msb_out4 => reinterpret4_output_port_net,      -- b_re MSB
    out3 => reinterpret3_output_port_net_x0,       -- b_im MSB
    out2 => reinterpret2_output_port_net_x0,       -- b_re LSB
    lsb_out1 => reinterpret1_output_port_net_x2    -- b_im LSB
  );
  
  b_replicate : entity xil_defaultlib.hirax_bit_growth_b_replicate_x8 
  port map (
    in_x0 => reinterpret1_output_port_net_x0,
    out_x0 => concatenate_y_net
  );
  
  -- Convert to signed for arithmetic (combinational)
  a_re_signed <= signed(reinterpret4_output_port_net_x0 & reinterpret2_output_port_net);
  a_im_signed <= signed(reinterpret3_output_port_net & reinterpret1_output_port_net_x1);
  b_re_signed <= signed(reinterpret4_output_port_net & reinterpret2_output_port_net_x0);
  b_im_signed <= signed(reinterpret3_output_port_net_x0 & reinterpret1_output_port_net_x2);
  
  -- Pre-multiplier add/sub operations (combinational to avoid adding latency)
  -- These compute: (a_re + a_im), (b_re + b_im), (b_im - b_re)
  a_re_plus_im_signed <= resize(a_re_signed, 19) + resize(a_im_signed, 19);
  b_re_plus_im_signed <= resize(b_re_signed, 29) + resize(b_im_signed, 29);
  b_im_minus_re_signed <= resize(b_im_signed, 29) - resize(b_re_signed, 29);
  
  -- Truncate to fit multiplier inputs
  -- For a_re_plus_im: 19 bits -> 18 bits 
  -- Take the 18 MSBs (bits 18 downto 1) to preserve sign and most significant bits
  a_re_plus_im_trunc <= std_logic_vector(a_re_plus_im_signed(18 downto 1));
  -- For b_re_plus_im and b_im_minus_re: 29 bits -> 28 bits (take 28 MSBs)
  b_re_plus_im_trunc <= std_logic_vector(b_re_plus_im_signed(28 downto 1));
  b_im_minus_re_trunc <= std_logic_vector(b_im_minus_re_signed(28 downto 1));
  b_re_trunc <= std_logic_vector(b_re_signed);
  a_im_trunc <= std_logic_vector(a_im_signed);
  a_re_trunc <= std_logic_vector(a_re_signed);
  
  -- 3 DSP multipliers (2 cycles latency each, same as original)
  -- The multiplier registers its inputs internally, so pre-add/sub can be combinational
  -- mult0 = (a_re + a_im) * b_re
  mult0 : entity xil_defaultlib.sysgen_mult_23e556baef 
  port map (
    clr => '0',
    a => a_re_plus_im_trunc,
    b => b_re_trunc,
    clk => clk_net,
    ce => ce_net,
    p => mult0_p_net
  );
  
  -- mult1 = a_im * (b_re + b_im)
  mult1 : entity xil_defaultlib.sysgen_mult_23e556baef 
  port map (
    clr => '0',
    a => a_im_trunc,
    b => b_re_plus_im_trunc,
    clk => clk_net,
    ce => ce_net,
    p => mult1_p_net
  );
  
  -- mult2 = a_re * (b_im - b_re)
  mult2 : entity xil_defaultlib.sysgen_mult_23e556baef 
  port map (
    clr => '0',
    a => a_re_trunc,
    b => b_im_minus_re_trunc,
    clk => clk_net,
    ce => ce_net,
    p => mult2_p_net
  );
  
  -- Post-multiplier add/sub (1 cycle latency, same as original)
  -- re = mult0 - mult1
  addsub_re : entity xil_defaultlib.sysgen_addsub_ca3115288e 
  port map (
    clr => '0',
    a => mult0_p_net,
    b => mult1_p_net,
    clk => clk_net,
    ce => ce_net,
    s => addsub_re_s_net
  );
  
  -- im = mult0 - mult2
  addsub_im : entity xil_defaultlib.sysgen_addsub_ead4107d02 
  port map (
    clr => '0',
    a => mult0_p_net,
    b => mult2_p_net,
    clk => clk_net,
    ce => ce_net,
    s => addsub_im_s_net
  );
  
  -- Output conversion (combinational, same as original)
  convert_re : entity xil_defaultlib.hirax_bit_growth_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 34,
    din_width => 47,
    dout_arith => 2,
    dout_bin_pt => 34,
    dout_width => 47,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => addsub_re_s_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert_re_dout_net
  );
  
  convert_im : entity xil_defaultlib.hirax_bit_growth_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 34,
    din_width => 47,
    dout_arith => 2,
    dout_bin_pt => 34,
    dout_width => 47,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => addsub_im_s_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert_im_dout_net
  );
  
  -- Combine real and imaginary into complex output
  ri_to_c : entity xil_defaultlib.hirax_bit_growth_ri_to_c_x17 
  port map (
    re => convert_re_dout_net,
    im => convert_im_dout_net,
    c => concat_y_net
  );
  
end structural;

-- Generic 3 DSP multiplier wrapper with configurable input/output widths
-- Uses the widest multiplier internally (36x56 -> 94) and handles extension/truncation
entity hirax_bit_growth_3dsp_mult1_generic is
  generic (
    B_WIDTH : natural := 56;   -- Input b width (40, 42, 44, 46, 48, 50, 52, 54, or 56)
    AB_WIDTH : natural := 94   -- Output ab width (78, 80, 82, 84, 86, 88, 90, 92, or 94)
  );
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( B_WIDTH-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab : out std_logic_vector( AB_WIDTH-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult1_generic;

architecture structural of hirax_bit_growth_3dsp_mult1_generic is
  constant B_WIDTH_MAX : natural := 56;
  constant AB_WIDTH_MAX : natural := 94;
  signal b_extended : std_logic_vector( B_WIDTH_MAX-1 downto 0 );
  signal ab_full : std_logic_vector( AB_WIDTH_MAX-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
begin
  clk_net <= clk_1;
  ce_net <= ce_1;
  
  -- Sign-extend b from B_WIDTH to 56 bits if needed
  extend_b : if B_WIDTH < B_WIDTH_MAX generate
    b_extended <= std_logic_vector(resize(signed(b), B_WIDTH_MAX));
  end generate;
  
  passthrough_b : if B_WIDTH = B_WIDTH_MAX generate
    b_extended <= b;
  end generate;
  
  -- Use consolidated 3 DSP multiplier (always uses widest)
  mult1_core : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1
  port map (
    a => a,
    b => b_extended,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => ab_full
  );
  
  -- Truncate output from 94 to AB_WIDTH bits if needed
  -- Output format: [real(93:47), imaginary(46:0)] = 94 bits total
  -- Pattern: real(93:94-W/2), imaginary(46:47-W/2) where W = AB_WIDTH
  truncate_ab : if AB_WIDTH < AB_WIDTH_MAX generate
    constant RE_BITS : natural := AB_WIDTH / 2;
    constant IM_BITS : natural := AB_WIDTH - RE_BITS;
    constant RE_LSB : natural := 94 - RE_BITS;  -- Real LSB = 94 - W/2
    constant IM_LSB : natural := 47 - IM_BITS;  -- Imaginary LSB = 47 - W/2
  begin
    -- Take MSBs of real part, LSBs of imaginary part (preserving binary point alignment)
    ab <= ab_full(93 downto RE_LSB) & ab_full(46 downto IM_LSB);
  end generate;
  
  passthrough_ab : if AB_WIDTH = AB_WIDTH_MAX generate
    ab <= ab_full;
  end generate;
  
end structural;

-- Wrapper entities for compatibility - use generic entity with appropriate generics
entity hirax_bit_growth_3dsp_mult1_x8 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 40-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab : out std_logic_vector( 78-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult1_x8;

architecture structural of hirax_bit_growth_3dsp_mult1_x8 is
begin
  mult1_inst : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 40,
    AB_WIDTH => 78
  )
  port map (
    a => a,
    b => b,
    clk_1 => clk_1,
    ce_1 => ce_1,
    ab => ab
  );
end structural;

entity hirax_bit_growth_3dsp_mult1_x6 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 42-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab : out std_logic_vector( 80-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult1_x6;

architecture structural of hirax_bit_growth_3dsp_mult1_x6 is
begin
  mult1_inst : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 42,
    AB_WIDTH => 80
  )
  port map (
    a => a,
    b => b,
    clk_1 => clk_1,
    ce_1 => ce_1,
    ab => ab
  );
end structural;

entity hirax_bit_growth_3dsp_mult1_x7 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 44-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab : out std_logic_vector( 82-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult1_x7;

architecture structural of hirax_bit_growth_3dsp_mult1_x7 is
begin
  mult1_inst : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 44,
    AB_WIDTH => 82
  )
  port map (
    a => a,
    b => b,
    clk_1 => clk_1,
    ce_1 => ce_1,
    ab => ab
  );
end structural;

entity hirax_bit_growth_3dsp_mult1_x5 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 46-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab : out std_logic_vector( 84-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult1_x5;

architecture structural of hirax_bit_growth_3dsp_mult1_x5 is
begin
  mult1_inst : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 46,
    AB_WIDTH => 84
  )
  port map (
    a => a,
    b => b,
    clk_1 => clk_1,
    ce_1 => ce_1,
    ab => ab
  );
end structural;

entity hirax_bit_growth_3dsp_mult1_x1 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 48-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab : out std_logic_vector( 86-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult1_x1;

architecture structural of hirax_bit_growth_3dsp_mult1_x1 is
begin
  mult1_inst : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 48,
    AB_WIDTH => 86
  )
  port map (
    a => a,
    b => b,
    clk_1 => clk_1,
    ce_1 => ce_1,
    ab => ab
  );
end structural;

entity hirax_bit_growth_3dsp_mult1_x2 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 50-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab : out std_logic_vector( 88-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult1_x2;

architecture structural of hirax_bit_growth_3dsp_mult1_x2 is
begin
  mult1_inst : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 50,
    AB_WIDTH => 88
  )
  port map (
    a => a,
    b => b,
    clk_1 => clk_1,
    ce_1 => ce_1,
    ab => ab
  );
end structural;

entity hirax_bit_growth_3dsp_mult1_x0 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 54-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab : out std_logic_vector( 92-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult1_x0;

architecture structural of hirax_bit_growth_3dsp_mult1_x0 is
begin
  mult1_inst : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 54,
    AB_WIDTH => 92
  )
  port map (
    a => a,
    b => b,
    clk_1 => clk_1,
    ce_1 => ce_1,
    ab => ab
  );
end structural;

entity hirax_bit_growth_3dsp_mult1_x4 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 56-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab : out std_logic_vector( 94-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult1_x4;

architecture structural of hirax_bit_growth_3dsp_mult1_x4 is
begin
  mult1_inst : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 56,
    AB_WIDTH => 94
  )
  port map (
    a => a,
    b => b,
    clk_1 => clk_1,
    ce_1 => ce_1,
    ab => ab
  );
end structural;

entity hirax_bit_growth_3dsp_mult1_x3 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 56-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab : out std_logic_vector( 94-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult1_x3;

architecture structural of hirax_bit_growth_3dsp_mult1_x3 is
begin
  mult1_inst : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 56,
    AB_WIDTH => 94
  )
  port map (
    a => a,
    b => b,
    clk_1 => clk_1,
    ce_1 => ce_1,
    ab => ab
  );
end structural;

-- Generic bus multiplier with configurable widths
-- Note: Helper entities (a_b_bussify, a_debus, b_debus, repa, repb, dmisc) are variant-specific
-- and cannot be parameterized in standard VHDL. The specific bus_mult_x* entities below
-- provide the complete implementation with correct helper entities.
-- This generic entity shows the structure but requires manual helper entity instantiation.
entity hirax_bit_growth_3dsp_bus_mult_generic is
  generic (
    B_WIDTH : natural := 40;      -- Input b width
    MISCI_WIDTH : natural := 41;  -- Input misci width (typically B_WIDTH + 1)
    AB_WIDTH : natural := 78;     -- Output a_b width
    MULT1_B_WIDTH : natural := 40; -- Multiplier b input width
    MULT1_AB_WIDTH : natural := 78  -- Multiplier ab output width
  );
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( B_WIDTH-1 downto 0 );
    misci : in std_logic_vector( MISCI_WIDTH-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    a_b : out std_logic_vector( AB_WIDTH-1 downto 0 );
    misco : out std_logic_vector( MISCI_WIDTH-1 downto 0 )
  );
end hirax_bit_growth_3dsp_bus_mult_generic;

architecture structural of hirax_bit_growth_3dsp_bus_mult_generic is
  signal reinterpret1_output_port_net_x0 : std_logic_vector( AB_WIDTH-1 downto 0 );
  signal dmisc_q_net : std_logic_vector( MISCI_WIDTH-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( B_WIDTH-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( MISCI_WIDTH-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal concat_y_net_x0 : std_logic_vector( AB_WIDTH-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x3 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( B_WIDTH-1 downto 0 );
  signal reinterpret1_output_port_net_x4 : std_logic_vector( B_WIDTH-1 downto 0 );
begin
  a_b <= reinterpret1_output_port_net_x0;
  misco <= dmisc_q_net;
  concat_y_net <= a;
  reinterpret2_output_port_net <= b;
  reinterpret1_output_port_net <= misci;
  clk_net <= clk_1;
  ce_net <= ce_1;
  
  -- Generic multiplier (parameterized)
  mult1 : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => MULT1_B_WIDTH,
    AB_WIDTH => MULT1_AB_WIDTH
  )
  port map (
    a => reinterpret1_output_port_net_x1,
    b => reinterpret1_output_port_net_x2,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => concat_y_net_x0
  );
  
  -- Helper entities must be instantiated manually based on variant
  -- See bus_mult_x* entities below for complete implementations
end structural;

-- Bus multiplier wrapper for x8 (b=40, misci=41, a_b=78)
entity hirax_bit_growth_3dsp_bus_mult_x8 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 40-1 downto 0 );
    misci : in std_logic_vector( 41-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    a_b : out std_logic_vector( 78-1 downto 0 );
    misco : out std_logic_vector( 41-1 downto 0 )
  );
end hirax_bit_growth_3dsp_bus_mult_x8;

architecture structural of hirax_bit_growth_3dsp_bus_mult_x8 is
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 78-1 downto 0 );
  signal dmisc_q_net : std_logic_vector( 41-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 40-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 41-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal concat_y_net_x0 : std_logic_vector( 78-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x3 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 40-1 downto 0 );
  signal reinterpret1_output_port_net_x4 : std_logic_vector( 40-1 downto 0 );
begin
  a_b <= reinterpret1_output_port_net_x0;
  misco <= dmisc_q_net;
  concat_y_net <= a;
  reinterpret2_output_port_net <= b;
  reinterpret1_output_port_net <= misci;
  clk_net <= clk_1;
  ce_net <= ce_1;
  
  a_b_bussify : entity xil_defaultlib.hirax_bit_growth_a_b_bussify_x8 
  port map (
    in1 => concat_y_net_x0,
    bus_out => reinterpret1_output_port_net_x0
  );
  
  a_debus : entity xil_defaultlib.hirax_bit_growth_a_debus_x51 
  port map (
    bus_in => reinterpret1_output_port_net_x3,
    msb_lsb_out1 => reinterpret1_output_port_net_x1
  );
  
  b_debus : entity xil_defaultlib.hirax_bit_growth_b_debus_x52 
  port map (
    bus_in => reinterpret1_output_port_net_x4,
    msb_lsb_out1 => reinterpret1_output_port_net_x2
  );
  
  mult1 : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 40,
    AB_WIDTH => 78
  )
  port map (
    a => reinterpret1_output_port_net_x1,
    b => reinterpret1_output_port_net_x2,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => concat_y_net_x0
  );
  
  repa : entity xil_defaultlib.hirax_bit_growth_repa_x8 
  port map (
    in_x0 => concat_y_net,
    out_x0 => reinterpret1_output_port_net_x3
  );
  
  repb : entity xil_defaultlib.hirax_bit_growth_repb_x8 
  port map (
    in_x0 => reinterpret2_output_port_net,
    out_x0 => reinterpret1_output_port_net_x4
  );
  
  dmisc : entity xil_defaultlib.sysgen_delay_2cd8325bea 
  port map (
    clr => '0',
    d => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => dmisc_q_net
  );
end structural;

-- Bus multiplier wrapper for x5 (b=42, misci=43, a_b=80)
entity hirax_bit_growth_3dsp_bus_mult_x5 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 42-1 downto 0 );
    misci : in std_logic_vector( 43-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    a_b : out std_logic_vector( 80-1 downto 0 );
    misco : out std_logic_vector( 43-1 downto 0 )
  );
end hirax_bit_growth_3dsp_bus_mult_x5;

architecture structural of hirax_bit_growth_3dsp_bus_mult_x5 is
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 80-1 downto 0 );
  signal dmisc_q_net : std_logic_vector( 43-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 42-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 43-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal concat_y_net_x0 : std_logic_vector( 80-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x3 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 42-1 downto 0 );
  signal reinterpret1_output_port_net_x4 : std_logic_vector( 42-1 downto 0 );
begin
  a_b <= reinterpret1_output_port_net_x0;
  misco <= dmisc_q_net;
  concat_y_net <= a;
  reinterpret2_output_port_net <= b;
  reinterpret1_output_port_net <= misci;
  clk_net <= clk_1;
  ce_net <= ce_1;
  a_b_bussify : entity xil_defaultlib.hirax_bit_growth_a_b_bussify_x5 
  port map (
    in1 => concat_y_net_x0,
    bus_out => reinterpret1_output_port_net_x0
  );
  a_debus : entity xil_defaultlib.hirax_bit_growth_a_debus_x37 
  port map (
    bus_in => reinterpret1_output_port_net_x3,
    msb_lsb_out1 => reinterpret1_output_port_net_x1
  );
  b_debus : entity xil_defaultlib.hirax_bit_growth_b_debus_x37 
  port map (
    bus_in => reinterpret1_output_port_net_x4,
    msb_lsb_out1 => reinterpret1_output_port_net_x2
  );
  mult1 : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 42,
    AB_WIDTH => 80
  )
  port map (
    a => reinterpret1_output_port_net_x1,
    b => reinterpret1_output_port_net_x2,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => concat_y_net_x0
  );
  repa : entity xil_defaultlib.hirax_bit_growth_repa_x6 
  port map (
    in_x0 => concat_y_net,
    out_x0 => reinterpret1_output_port_net_x3
  );
  repb : entity xil_defaultlib.hirax_bit_growth_repb_x6 
  port map (
    in_x0 => reinterpret2_output_port_net,
    out_x0 => reinterpret1_output_port_net_x4
  );
  dmisc : entity xil_defaultlib.sysgen_delay_27ccbe960e 
  port map (
    clr => '0',
    d => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => dmisc_q_net
  );
end structural;

-- Bus multiplier wrapper for x7 (b=44, misci=45, a_b=82)
entity hirax_bit_growth_3dsp_bus_mult_x7 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 44-1 downto 0 );
    misci : in std_logic_vector( 45-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    a_b : out std_logic_vector( 82-1 downto 0 );
    misco : out std_logic_vector( 45-1 downto 0 )
  );
end hirax_bit_growth_3dsp_bus_mult_x7;

architecture structural of hirax_bit_growth_3dsp_bus_mult_x7 is
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 82-1 downto 0 );
  signal dmisc_q_net : std_logic_vector( 45-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 44-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 45-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal concat_y_net_x0 : std_logic_vector( 82-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x3 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 44-1 downto 0 );
  signal reinterpret1_output_port_net_x4 : std_logic_vector( 44-1 downto 0 );
begin
  a_b <= reinterpret1_output_port_net_x0;
  misco <= dmisc_q_net;
  concat_y_net <= a;
  reinterpret2_output_port_net <= b;
  reinterpret1_output_port_net <= misci;
  clk_net <= clk_1;
  ce_net <= ce_1;
  a_b_bussify : entity xil_defaultlib.hirax_bit_growth_a_b_bussify_x7 
  port map (
    in1 => concat_y_net_x0,
    bus_out => reinterpret1_output_port_net_x0
  );
  a_debus : entity xil_defaultlib.hirax_bit_growth_a_debus_x42 
  port map (
    bus_in => reinterpret1_output_port_net_x3,
    msb_lsb_out1 => reinterpret1_output_port_net_x1
  );
  b_debus : entity xil_defaultlib.hirax_bit_growth_b_debus_x42 
  port map (
    bus_in => reinterpret1_output_port_net_x4,
    msb_lsb_out1 => reinterpret1_output_port_net_x2
  );
  mult1 : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 44,
    AB_WIDTH => 82
  )
  port map (
    a => reinterpret1_output_port_net_x1,
    b => reinterpret1_output_port_net_x2,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => concat_y_net_x0
  );
  repa : entity xil_defaultlib.hirax_bit_growth_repa_x7 
  port map (
    in_x0 => concat_y_net,
    out_x0 => reinterpret1_output_port_net_x3
  );
  repb : entity xil_defaultlib.hirax_bit_growth_repb_x7 
  port map (
    in_x0 => reinterpret2_output_port_net,
    out_x0 => reinterpret1_output_port_net_x4
  );
  dmisc : entity xil_defaultlib.sysgen_delay_e744650b95 
  port map (
    clr => '0',
    d => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => dmisc_q_net
  );
end structural;

-- Bus multiplier wrapper for x6 (b=46, misci=47, a_b=84)
entity hirax_bit_growth_3dsp_bus_mult_x6 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 46-1 downto 0 );
    misci : in std_logic_vector( 47-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    a_b : out std_logic_vector( 84-1 downto 0 );
    misco : out std_logic_vector( 47-1 downto 0 )
  );
end hirax_bit_growth_3dsp_bus_mult_x6;

architecture structural of hirax_bit_growth_3dsp_bus_mult_x6 is
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 84-1 downto 0 );
  signal dmisc_q_net : std_logic_vector( 47-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 46-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 47-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal concat_y_net_x0 : std_logic_vector( 84-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x3 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 46-1 downto 0 );
  signal reinterpret1_output_port_net_x4 : std_logic_vector( 46-1 downto 0 );
begin
  a_b <= reinterpret1_output_port_net_x0;
  misco <= dmisc_q_net;
  concat_y_net <= a;
  reinterpret2_output_port_net <= b;
  reinterpret1_output_port_net <= misci;
  clk_net <= clk_1;
  ce_net <= ce_1;
  a_b_bussify : entity xil_defaultlib.hirax_bit_growth_a_b_bussify_x6 
  port map (
    in1 => concat_y_net_x0,
    bus_out => reinterpret1_output_port_net_x0
  );
  a_debus : entity xil_defaultlib.hirax_bit_growth_a_debus_x40 
  port map (
    bus_in => reinterpret1_output_port_net_x3,
    msb_lsb_out1 => reinterpret1_output_port_net_x1
  );
  b_debus : entity xil_defaultlib.hirax_bit_growth_b_debus_x41 
  port map (
    bus_in => reinterpret1_output_port_net_x4,
    msb_lsb_out1 => reinterpret1_output_port_net_x2
  );
  mult1 : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 46,
    AB_WIDTH => 84
  )
  port map (
    a => reinterpret1_output_port_net_x1,
    b => reinterpret1_output_port_net_x2,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => concat_y_net_x0
  );
  repa : entity xil_defaultlib.hirax_bit_growth_repa_x0 
  port map (
    in_x0 => concat_y_net,
    out_x0 => reinterpret1_output_port_net_x3
  );
  repb : entity xil_defaultlib.hirax_bit_growth_repb_x0 
  port map (
    in_x0 => reinterpret2_output_port_net,
    out_x0 => reinterpret1_output_port_net_x4
  );
  dmisc : entity xil_defaultlib.sysgen_delay_ba1be7bc9e 
  port map (
    clr => '0',
    d => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => dmisc_q_net
  );
end structural;

-- Bus multiplier wrapper for x1 (b=48, misci=49, a_b=86)
entity hirax_bit_growth_3dsp_bus_mult_x1 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 48-1 downto 0 );
    misci : in std_logic_vector( 49-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    a_b : out std_logic_vector( 86-1 downto 0 );
    misco : out std_logic_vector( 49-1 downto 0 )
  );
end hirax_bit_growth_3dsp_bus_mult_x1;

architecture structural of hirax_bit_growth_3dsp_bus_mult_x1 is
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 86-1 downto 0 );
  signal dmisc_q_net : std_logic_vector( 49-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 48-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 49-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal concat_y_net_x0 : std_logic_vector( 86-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x3 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 48-1 downto 0 );
  signal reinterpret1_output_port_net_x4 : std_logic_vector( 48-1 downto 0 );
begin
  a_b <= reinterpret1_output_port_net_x0;
  misco <= dmisc_q_net;
  concat_y_net <= a;
  reinterpret2_output_port_net <= b;
  reinterpret1_output_port_net <= misci;
  clk_net <= clk_1;
  ce_net <= ce_1;
  a_b_bussify : entity xil_defaultlib.hirax_bit_growth_a_b_bussify_x1 
  port map (
    in1 => concat_y_net_x0,
    bus_out => reinterpret1_output_port_net_x0
  );
  a_debus : entity xil_defaultlib.hirax_bit_growth_a_debus_x9 
  port map (
    bus_in => reinterpret1_output_port_net_x3,
    msb_lsb_out1 => reinterpret1_output_port_net_x1
  );
  b_debus : entity xil_defaultlib.hirax_bit_growth_b_debus_x9 
  port map (
    bus_in => reinterpret1_output_port_net_x4,
    msb_lsb_out1 => reinterpret1_output_port_net_x2
  );
  mult1 : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 48,
    AB_WIDTH => 86
  )
  port map (
    a => reinterpret1_output_port_net_x1,
    b => reinterpret1_output_port_net_x2,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => concat_y_net_x0
  );
  repa : entity xil_defaultlib.hirax_bit_growth_repa_x2 
  port map (
    in_x0 => concat_y_net,
    out_x0 => reinterpret1_output_port_net_x3
  );
  repb : entity xil_defaultlib.hirax_bit_growth_repb_x2 
  port map (
    in_x0 => reinterpret2_output_port_net,
    out_x0 => reinterpret1_output_port_net_x4
  );
  dmisc : entity xil_defaultlib.sysgen_delay_32e213e6a0 
  port map (
    clr => '0',
    d => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => dmisc_q_net
  );
end structural;

-- Bus multiplier wrapper for x2 (b=50, misci=51, a_b=88)
entity hirax_bit_growth_3dsp_bus_mult_x2 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 50-1 downto 0 );
    misci : in std_logic_vector( 51-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    a_b : out std_logic_vector( 88-1 downto 0 );
    misco : out std_logic_vector( 51-1 downto 0 )
  );
end hirax_bit_growth_3dsp_bus_mult_x2;

architecture structural of hirax_bit_growth_3dsp_bus_mult_x2 is
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 88-1 downto 0 );
  signal dmisc_q_net : std_logic_vector( 51-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 50-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 51-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal concat_y_net_x0 : std_logic_vector( 88-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x3 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 50-1 downto 0 );
  signal reinterpret1_output_port_net_x4 : std_logic_vector( 50-1 downto 0 );
begin
  a_b <= reinterpret1_output_port_net_x0;
  misco <= dmisc_q_net;
  concat_y_net <= a;
  reinterpret2_output_port_net <= b;
  reinterpret1_output_port_net <= misci;
  clk_net <= clk_1;
  ce_net <= ce_1;
  a_b_bussify : entity xil_defaultlib.hirax_bit_growth_a_b_bussify_x2 
  port map (
    in1 => concat_y_net_x0,
    bus_out => reinterpret1_output_port_net_x0
  );
  a_debus : entity xil_defaultlib.hirax_bit_growth_a_debus_x13 
  port map (
    bus_in => reinterpret1_output_port_net_x3,
    msb_lsb_out1 => reinterpret1_output_port_net_x1
  );
  b_debus : entity xil_defaultlib.hirax_bit_growth_b_debus_x13 
  port map (
    bus_in => reinterpret1_output_port_net_x4,
    msb_lsb_out1 => reinterpret1_output_port_net_x2
  );
  mult1 : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 50,
    AB_WIDTH => 88
  )
  port map (
    a => reinterpret1_output_port_net_x1,
    b => reinterpret1_output_port_net_x2,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => concat_y_net_x0
  );
  repa : entity xil_defaultlib.hirax_bit_growth_repa_x1 
  port map (
    in_x0 => concat_y_net,
    out_x0 => reinterpret1_output_port_net_x3
  );
  repb : entity xil_defaultlib.hirax_bit_growth_repb_x1 
  port map (
    in_x0 => reinterpret2_output_port_net,
    out_x0 => reinterpret1_output_port_net_x4
  );
  dmisc : entity xil_defaultlib.sysgen_delay_1811756427 
  port map (
    clr => '0',
    d => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => dmisc_q_net
  );
end structural;

-- Bus multiplier wrapper for x4 (b=56, misci=57, a_b=94)
entity hirax_bit_growth_3dsp_bus_mult_x4 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 56-1 downto 0 );
    misci : in std_logic_vector( 57-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    a_b : out std_logic_vector( 94-1 downto 0 );
    misco : out std_logic_vector( 57-1 downto 0 )
  );
end hirax_bit_growth_3dsp_bus_mult_x4;

architecture structural of hirax_bit_growth_3dsp_bus_mult_x4 is
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 94-1 downto 0 );
  signal dmisc_q_net : std_logic_vector( 57-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 56-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 57-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal concat_y_net_x0 : std_logic_vector( 94-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x3 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 56-1 downto 0 );
  signal reinterpret1_output_port_net_x4 : std_logic_vector( 56-1 downto 0 );
begin
  a_b <= reinterpret1_output_port_net_x0;
  misco <= dmisc_q_net;
  concat_y_net <= a;
  reinterpret2_output_port_net <= b;
  reinterpret1_output_port_net <= misci;
  clk_net <= clk_1;
  ce_net <= ce_1;
  a_b_bussify : entity xil_defaultlib.hirax_bit_growth_a_b_bussify_x4 
  port map (
    in1 => concat_y_net_x0,
    bus_out => reinterpret1_output_port_net_x0
  );
  a_debus : entity xil_defaultlib.hirax_bit_growth_a_debus_x22 
  port map (
    bus_in => reinterpret1_output_port_net_x3,
    msb_lsb_out1 => reinterpret1_output_port_net_x1
  );
  b_debus : entity xil_defaultlib.hirax_bit_growth_b_debus_x22 
  port map (
    bus_in => reinterpret1_output_port_net_x4,
    msb_lsb_out1 => reinterpret1_output_port_net_x2
  );
  mult1 : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 56,
    AB_WIDTH => 94
  )
  port map (
    a => reinterpret1_output_port_net_x1,
    b => reinterpret1_output_port_net_x2,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => concat_y_net_x0
  );
  repa : entity xil_defaultlib.hirax_bit_growth_repa_x5 
  port map (
    in_x0 => concat_y_net,
    out_x0 => reinterpret1_output_port_net_x3
  );
  repb : entity xil_defaultlib.hirax_bit_growth_repb_x5 
  port map (
    in_x0 => reinterpret2_output_port_net,
    out_x0 => reinterpret1_output_port_net_x4
  );
  dmisc : entity xil_defaultlib.sysgen_delay_f5b3aef52c 
  port map (
    clr => '0',
    d => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => dmisc_q_net
  );
end structural;

-- Bus multiplier wrapper for x3 (b=56, misci=57, a_b=94)
entity hirax_bit_growth_3dsp_bus_mult_x3 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 56-1 downto 0 );
    misci : in std_logic_vector( 57-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    a_b : out std_logic_vector( 94-1 downto 0 );
    misco : out std_logic_vector( 57-1 downto 0 )
  );
end hirax_bit_growth_3dsp_bus_mult_x3;

architecture structural of hirax_bit_growth_3dsp_bus_mult_x3 is
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 94-1 downto 0 );
  signal dmisc_q_net : std_logic_vector( 57-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 56-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 57-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal concat_y_net_x0 : std_logic_vector( 94-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x3 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 56-1 downto 0 );
  signal reinterpret1_output_port_net_x4 : std_logic_vector( 56-1 downto 0 );
begin
  a_b <= reinterpret1_output_port_net_x0;
  misco <= dmisc_q_net;
  concat_y_net <= a;
  reinterpret2_output_port_net <= b;
  reinterpret1_output_port_net <= misci;
  clk_net <= clk_1;
  ce_net <= ce_1;
  a_b_bussify : entity xil_defaultlib.hirax_bit_growth_a_b_bussify_x3 
  port map (
    in1 => concat_y_net_x0,
    bus_out => reinterpret1_output_port_net_x0
  );
  a_debus : entity xil_defaultlib.hirax_bit_growth_a_debus_x15 
  port map (
    bus_in => reinterpret1_output_port_net_x3,
    msb_lsb_out1 => reinterpret1_output_port_net_x1
  );
  b_debus : entity xil_defaultlib.hirax_bit_growth_b_debus_x15 
  port map (
    bus_in => reinterpret1_output_port_net_x4,
    msb_lsb_out1 => reinterpret1_output_port_net_x2
  );
  mult1 : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 56,
    AB_WIDTH => 94
  )
  port map (
    a => reinterpret1_output_port_net_x1,
    b => reinterpret1_output_port_net_x2,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => concat_y_net_x0
  );
  repa : entity xil_defaultlib.hirax_bit_growth_repa_x3 
  port map (
    in_x0 => concat_y_net,
    out_x0 => reinterpret1_output_port_net_x3
  );
  repb : entity xil_defaultlib.hirax_bit_growth_repb_x3 
  port map (
    in_x0 => reinterpret2_output_port_net,
    out_x0 => reinterpret1_output_port_net_x4
  );
  dmisc : entity xil_defaultlib.sysgen_delay_f5b3aef52c 
  port map (
    clr => '0',
    d => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => dmisc_q_net
  );
end structural;

-- Twiddle entity wrapper for x9 - uses bus_mult_3dsp_x8
entity hirax_bit_growth_3dsp_twiddle_x9 is
  port (
    ai : in std_logic_vector( 40-1 downto 0 );
    bi : in std_logic_vector( 40-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ao : out std_logic_vector( 40-1 downto 0 );
    bwo : out std_logic_vector( 42-1 downto 0 );
    sync_out : out std_logic_vector( 1-1 downto 0 )
  );
end hirax_bit_growth_3dsp_twiddle_x9;

architecture structural of hirax_bit_growth_3dsp_twiddle_x9 is 
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 40-1 downto 0 );
  signal concatenate_y_net : std_logic_vector( 42-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 40-1 downto 0 );
  signal dmux0_q_net : std_logic_vector( 40-1 downto 0 );
  signal mux_y_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal dmisc_q_net : std_logic_vector( 41-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 78-1 downto 0 );
  signal dmisc_q_net_x0 : std_logic_vector( 41-1 downto 0 );
  signal concatenate_y_net_x0 : std_logic_vector( 81-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 40-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 41-1 downto 0 );
  signal delay1_q_net : std_logic_vector( 81-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
begin
  ao <= reinterpret1_output_port_net_x0;
  bwo <= concatenate_y_net;
  sync_out <= slice2_y_net;
  reinterpret1_output_port_net_x2 <= ai;
  dmux0_q_net <= bi;
  mux_y_net <= sync_in;
  clk_net <= clk_1;
  ce_net <= ce_1;
  bus_convert : entity xil_defaultlib.hirax_bit_growth_bus_convert_x22 
  port map (
    din => reinterpret1_output_port_net_x1,
    misci => dmisc_q_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    dout => concatenate_y_net,
    misco => dmisc_q_net
  );
  bus_create : entity xil_defaultlib.hirax_bit_growth_bus_create_x13 
  port map (
    in1 => dmux0_q_net,
    in2 => mux_y_net,
    in3 => reinterpret1_output_port_net_x2,
    bus_out => concatenate_y_net_x0
  );
  bus_expand : entity xil_defaultlib.hirax_bit_growth_bus_expand_x27 
  port map (
    bus_in => delay1_q_net,
    msb_out2 => reinterpret2_output_port_net,
    lsb_out1 => reinterpret1_output_port_net
  );
  bus_expand1 : entity xil_defaultlib.hirax_bit_growth_bus_expand1_x8 
  port map (
    bus_in => dmisc_q_net,
    msb_out2 => slice2_y_net,
    lsb_out1 => reinterpret1_output_port_net_x0
  );
  bus_mult : entity xil_defaultlib.hirax_bit_growth_3dsp_bus_mult_x8 
  port map (
    a => concat_y_net,
    b => reinterpret2_output_port_net,
    misci => reinterpret1_output_port_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    a_b => reinterpret1_output_port_net_x1,
    misco => dmisc_q_net_x0
  );
  coeff_gen : entity xil_defaultlib.hirax_bit_growth_coeff_gen_x8 
  port map (
    rst => mux_y_net,
    misci => concatenate_y_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    w => concat_y_net,
    misco => delay1_q_net
  );
end structural;

-- Twiddle entity wrapper for x8 - uses bus_mult_3dsp_x5
entity hirax_bit_growth_3dsp_twiddle_x8 is
  port (
    ai : in std_logic_vector( 42-1 downto 0 );
    bi : in std_logic_vector( 42-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ao : out std_logic_vector( 42-1 downto 0 );
    bwo : out std_logic_vector( 44-1 downto 0 );
    sync_out : out std_logic_vector( 1-1 downto 0 )
  );
end hirax_bit_growth_3dsp_twiddle_x8;

architecture structural of hirax_bit_growth_3dsp_twiddle_x8 is 
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 42-1 downto 0 );
  signal concatenate_y_net : std_logic_vector( 44-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 42-1 downto 0 );
  signal dmux0_q_net : std_logic_vector( 42-1 downto 0 );
  signal mux_y_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal dmisc_q_net : std_logic_vector( 43-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 80-1 downto 0 );
  signal dmisc_q_net_x0 : std_logic_vector( 43-1 downto 0 );
  signal concatenate_y_net_x0 : std_logic_vector( 85-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 42-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 43-1 downto 0 );
  signal delay1_q_net : std_logic_vector( 85-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
begin
  ao <= reinterpret1_output_port_net_x0;
  bwo <= concatenate_y_net;
  sync_out <= slice2_y_net;
  reinterpret1_output_port_net_x2 <= ai;
  dmux0_q_net <= bi;
  mux_y_net <= sync_in;
  clk_net <= clk_1;
  ce_net <= ce_1;
  bus_convert : entity xil_defaultlib.hirax_bit_growth_bus_convert_x16 
  port map (
    din => reinterpret1_output_port_net_x1,
    misci => dmisc_q_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    dout => concatenate_y_net,
    misco => dmisc_q_net
  );
  bus_create : entity xil_defaultlib.hirax_bit_growth_bus_create_x10 
  port map (
    in1 => dmux0_q_net,
    in2 => mux_y_net,
    in3 => reinterpret1_output_port_net_x2,
    bus_out => concatenate_y_net_x0
  );
  bus_expand : entity xil_defaultlib.hirax_bit_growth_bus_expand_x20 
  port map (
    bus_in => delay1_q_net,
    msb_out2 => reinterpret2_output_port_net,
    lsb_out1 => reinterpret1_output_port_net
  );
  bus_expand1 : entity xil_defaultlib.hirax_bit_growth_bus_expand1_x5 
  port map (
    bus_in => dmisc_q_net,
    msb_out2 => slice2_y_net,
    lsb_out1 => reinterpret1_output_port_net_x0
  );
  bus_mult : entity xil_defaultlib.hirax_bit_growth_3dsp_bus_mult_x5 
  port map (
    a => concat_y_net,
    b => reinterpret2_output_port_net,
    misci => reinterpret1_output_port_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    a_b => reinterpret1_output_port_net_x1,
    misco => dmisc_q_net_x0
  );
  coeff_gen : entity xil_defaultlib.hirax_bit_growth_coeff_gen_x5 
  port map (
    rst => mux_y_net,
    misci => concatenate_y_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    w => concat_y_net,
    misco => delay1_q_net
  );
end structural;

-- Twiddle entity wrapper for x5 - uses bus_mult_3dsp_x7
entity hirax_bit_growth_3dsp_twiddle_x5 is
  port (
    ai : in std_logic_vector( 44-1 downto 0 );
    bi : in std_logic_vector( 44-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ao : out std_logic_vector( 44-1 downto 0 );
    bwo : out std_logic_vector( 46-1 downto 0 );
    sync_out : out std_logic_vector( 1-1 downto 0 )
  );
end hirax_bit_growth_3dsp_twiddle_x5;

architecture structural of hirax_bit_growth_3dsp_twiddle_x5 is 
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 44-1 downto 0 );
  signal concatenate_y_net : std_logic_vector( 46-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 44-1 downto 0 );
  signal dmux0_q_net : std_logic_vector( 44-1 downto 0 );
  signal mux_y_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal dmisc_q_net : std_logic_vector( 45-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 82-1 downto 0 );
  signal dmisc_q_net_x0 : std_logic_vector( 45-1 downto 0 );
  signal concatenate_y_net_x0 : std_logic_vector( 89-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 44-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 45-1 downto 0 );
  signal delay1_q_net : std_logic_vector( 89-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
begin
  ao <= reinterpret1_output_port_net_x0;
  bwo <= concatenate_y_net;
  sync_out <= slice2_y_net;
  reinterpret1_output_port_net_x2 <= ai;
  dmux0_q_net <= bi;
  mux_y_net <= sync_in;
  clk_net <= clk_1;
  ce_net <= ce_1;
  bus_convert : entity xil_defaultlib.hirax_bit_growth_bus_convert_x15 
  port map (
    din => reinterpret1_output_port_net_x1,
    misci => dmisc_q_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    dout => concatenate_y_net,
    misco => dmisc_q_net
  );
  bus_create : entity xil_defaultlib.hirax_bit_growth_bus_create_x9 
  port map (
    in1 => dmux0_q_net,
    in2 => mux_y_net,
    in3 => reinterpret1_output_port_net_x2,
    bus_out => concatenate_y_net_x0
  );
  bus_expand : entity xil_defaultlib.hirax_bit_growth_bus_expand_x19 
  port map (
    bus_in => delay1_q_net,
    msb_out2 => reinterpret2_output_port_net,
    lsb_out1 => reinterpret1_output_port_net
  );
  bus_expand1 : entity xil_defaultlib.hirax_bit_growth_bus_expand1_x6 
  port map (
    bus_in => dmisc_q_net,
    msb_out2 => slice2_y_net,
    lsb_out1 => reinterpret1_output_port_net_x0
  );
  bus_mult : entity xil_defaultlib.hirax_bit_growth_3dsp_bus_mult_x7 
  port map (
    a => concat_y_net,
    b => reinterpret2_output_port_net,
    misci => reinterpret1_output_port_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    a_b => reinterpret1_output_port_net_x1,
    misco => dmisc_q_net_x0
  );
  coeff_gen : entity xil_defaultlib.hirax_bit_growth_coeff_gen_x7 
  port map (
    rst => mux_y_net,
    misci => concatenate_y_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    w => concat_y_net,
    misco => delay1_q_net
  );
end structural;

-- Twiddle entity wrapper for x6 - uses bus_mult_3dsp_x6
entity hirax_bit_growth_3dsp_twiddle_x6 is
  port (
    ai : in std_logic_vector( 46-1 downto 0 );
    bi : in std_logic_vector( 46-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ao : out std_logic_vector( 46-1 downto 0 );
    bwo : out std_logic_vector( 48-1 downto 0 );
    sync_out : out std_logic_vector( 1-1 downto 0 )
  );
end hirax_bit_growth_3dsp_twiddle_x6;

architecture structural of hirax_bit_growth_3dsp_twiddle_x6 is 
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 46-1 downto 0 );
  signal concatenate_y_net : std_logic_vector( 48-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 46-1 downto 0 );
  signal dmux0_q_net : std_logic_vector( 46-1 downto 0 );
  signal mux_y_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal dmisc_q_net : std_logic_vector( 47-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 84-1 downto 0 );
  signal dmisc_q_net_x0 : std_logic_vector( 47-1 downto 0 );
  signal concatenate_y_net_x0 : std_logic_vector( 93-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 46-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 47-1 downto 0 );
  signal delay1_q_net : std_logic_vector( 93-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
begin
  ao <= reinterpret1_output_port_net_x0;
  bwo <= concatenate_y_net;
  sync_out <= slice2_y_net;
  reinterpret1_output_port_net_x2 <= ai;
  dmux0_q_net <= bi;
  mux_y_net <= sync_in;
  clk_net <= clk_1;
  ce_net <= ce_1;
  bus_convert : entity xil_defaultlib.hirax_bit_growth_bus_convert_x18 
  port map (
    din => reinterpret1_output_port_net_x1,
    misci => dmisc_q_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    dout => concatenate_y_net,
    misco => dmisc_q_net
  );
  bus_create : entity xil_defaultlib.hirax_bit_growth_bus_create_x11 
  port map (
    in1 => dmux0_q_net,
    in2 => mux_y_net,
    in3 => reinterpret1_output_port_net_x2,
    bus_out => concatenate_y_net_x0
  );
  bus_expand : entity xil_defaultlib.hirax_bit_growth_bus_expand_x22 
  port map (
    bus_in => delay1_q_net,
    msb_out2 => reinterpret2_output_port_net,
    lsb_out1 => reinterpret1_output_port_net
  );
  bus_expand1 : entity xil_defaultlib.hirax_bit_growth_bus_expand1_x7 
  port map (
    bus_in => dmisc_q_net,
    msb_out2 => slice2_y_net,
    lsb_out1 => reinterpret1_output_port_net_x0
  );
  bus_mult : entity xil_defaultlib.hirax_bit_growth_3dsp_bus_mult_x6 
  port map (
    a => concat_y_net,
    b => reinterpret2_output_port_net,
    misci => reinterpret1_output_port_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    a_b => reinterpret1_output_port_net_x1,
    misco => dmisc_q_net_x0
  );
  coeff_gen : entity xil_defaultlib.hirax_bit_growth_coeff_gen_x6 
  port map (
    rst => mux_y_net,
    misci => concatenate_y_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    w => concat_y_net,
    misco => delay1_q_net
  );
end structural;

-- Twiddle entity wrapper for x1 - uses bus_mult_3dsp_x1
entity hirax_bit_growth_3dsp_twiddle_x1 is
  port (
    ai : in std_logic_vector( 48-1 downto 0 );
    bi : in std_logic_vector( 48-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ao : out std_logic_vector( 48-1 downto 0 );
    bwo : out std_logic_vector( 50-1 downto 0 );
    sync_out : out std_logic_vector( 1-1 downto 0 )
  );
end hirax_bit_growth_3dsp_twiddle_x1;

architecture structural of hirax_bit_growth_3dsp_twiddle_x1 is 
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 48-1 downto 0 );
  signal concatenate_y_net : std_logic_vector( 50-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 48-1 downto 0 );
  signal dmux0_q_net : std_logic_vector( 48-1 downto 0 );
  signal mux_y_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal dmisc_q_net : std_logic_vector( 49-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 86-1 downto 0 );
  signal dmisc_q_net_x0 : std_logic_vector( 49-1 downto 0 );
  signal concatenate_y_net_x0 : std_logic_vector( 97-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 48-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 49-1 downto 0 );
  signal delay1_q_net : std_logic_vector( 97-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
begin
  ao <= reinterpret1_output_port_net_x0;
  bwo <= concatenate_y_net;
  sync_out <= slice2_y_net;
  reinterpret1_output_port_net_x2 <= ai;
  dmux0_q_net <= bi;
  mux_y_net <= sync_in;
  clk_net <= clk_1;
  ce_net <= ce_1;
  bus_convert : entity xil_defaultlib.hirax_bit_growth_bus_convert_x3 
  port map (
    din => reinterpret1_output_port_net_x1,
    misci => dmisc_q_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    dout => concatenate_y_net,
    misco => dmisc_q_net
  );
  bus_create : entity xil_defaultlib.hirax_bit_growth_bus_create_x1 
  port map (
    in1 => dmux0_q_net,
    in2 => mux_y_net,
    in3 => reinterpret1_output_port_net_x2,
    bus_out => concatenate_y_net_x0
  );
  bus_expand : entity xil_defaultlib.hirax_bit_growth_bus_expand_x4 
  port map (
    bus_in => delay1_q_net,
    msb_out2 => reinterpret2_output_port_net,
    lsb_out1 => reinterpret1_output_port_net
  );
  bus_expand1 : entity xil_defaultlib.hirax_bit_growth_bus_expand1_x1 
  port map (
    bus_in => dmisc_q_net,
    msb_out2 => slice2_y_net,
    lsb_out1 => reinterpret1_output_port_net_x0
  );
  bus_mult : entity xil_defaultlib.hirax_bit_growth_3dsp_bus_mult_x1 
  port map (
    a => concat_y_net,
    b => reinterpret2_output_port_net,
    misci => reinterpret1_output_port_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    a_b => reinterpret1_output_port_net_x1,
    misco => dmisc_q_net_x0
  );
  coeff_gen : entity xil_defaultlib.hirax_bit_growth_coeff_gen_x1 
  port map (
    rst => mux_y_net,
    misci => concatenate_y_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    w => concat_y_net,
    misco => delay1_q_net
  );
end structural;

-- Twiddle entity wrapper for x2 - uses bus_mult_3dsp_x2
entity hirax_bit_growth_3dsp_twiddle_x2 is
  port (
    ai : in std_logic_vector( 50-1 downto 0 );
    bi : in std_logic_vector( 50-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ao : out std_logic_vector( 50-1 downto 0 );
    bwo : out std_logic_vector( 52-1 downto 0 );
    sync_out : out std_logic_vector( 1-1 downto 0 )
  );
end hirax_bit_growth_3dsp_twiddle_x2;

architecture structural of hirax_bit_growth_3dsp_twiddle_x2 is 
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 50-1 downto 0 );
  signal concatenate_y_net : std_logic_vector( 52-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 50-1 downto 0 );
  signal dmux0_q_net : std_logic_vector( 50-1 downto 0 );
  signal mux_y_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal dmisc_q_net : std_logic_vector( 51-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 88-1 downto 0 );
  signal dmisc_q_net_x0 : std_logic_vector( 51-1 downto 0 );
  signal concatenate_y_net_x0 : std_logic_vector( 101-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 50-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 51-1 downto 0 );
  signal delay1_q_net : std_logic_vector( 101-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
begin
  ao <= reinterpret1_output_port_net_x0;
  bwo <= concatenate_y_net;
  sync_out <= slice2_y_net;
  reinterpret1_output_port_net_x2 <= ai;
  dmux0_q_net <= bi;
  mux_y_net <= sync_in;
  clk_net <= clk_1;
  ce_net <= ce_1;
  bus_convert : entity xil_defaultlib.hirax_bit_growth_bus_convert_x5 
  port map (
    din => reinterpret1_output_port_net_x1,
    misci => dmisc_q_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    dout => concatenate_y_net,
    misco => dmisc_q_net
  );
  bus_create : entity xil_defaultlib.hirax_bit_growth_bus_create_x2 
  port map (
    in1 => dmux0_q_net,
    in2 => mux_y_net,
    in3 => reinterpret1_output_port_net_x2,
    bus_out => concatenate_y_net_x0
  );
  bus_expand : entity xil_defaultlib.hirax_bit_growth_bus_expand_x5 
  port map (
    bus_in => delay1_q_net,
    msb_out2 => reinterpret2_output_port_net,
    lsb_out1 => reinterpret1_output_port_net
  );
  bus_expand1 : entity xil_defaultlib.hirax_bit_growth_bus_expand1_x2 
  port map (
    bus_in => dmisc_q_net,
    msb_out2 => slice2_y_net,
    lsb_out1 => reinterpret1_output_port_net_x0
  );
  bus_mult : entity xil_defaultlib.hirax_bit_growth_3dsp_bus_mult_x2 
  port map (
    a => concat_y_net,
    b => reinterpret2_output_port_net,
    misci => reinterpret1_output_port_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    a_b => reinterpret1_output_port_net_x1,
    misco => dmisc_q_net_x0
  );
  coeff_gen : entity xil_defaultlib.hirax_bit_growth_coeff_gen_x2 
  port map (
    rst => mux_y_net,
    misci => concatenate_y_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    w => concat_y_net,
    misco => delay1_q_net
  );
end structural;





-- Twiddle entity wrapper for x3 - uses bus_mult_3dsp_x4
entity hirax_bit_growth_3dsp_twiddle_x3 is
  port (
    ai : in std_logic_vector( 56-1 downto 0 );
    bi : in std_logic_vector( 56-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ao : out std_logic_vector( 56-1 downto 0 );
    bwo : out std_logic_vector( 58-1 downto 0 );
    sync_out : out std_logic_vector( 1-1 downto 0 )
  );
end hirax_bit_growth_3dsp_twiddle_x3;

architecture structural of hirax_bit_growth_3dsp_twiddle_x3 is 
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 56-1 downto 0 );
  signal concatenate_y_net : std_logic_vector( 58-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 56-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 56-1 downto 0 );
  signal delay0_q_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal dmisc_q_net : std_logic_vector( 57-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 94-1 downto 0 );
  signal dmisc_q_net_x0 : std_logic_vector( 57-1 downto 0 );
  signal concatenate_y_net_x0 : std_logic_vector( 113-1 downto 0 );
  signal reinterpret2_output_port_net_x0 : std_logic_vector( 56-1 downto 0 );
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 57-1 downto 0 );
  signal dmisc_q_net_x1 : std_logic_vector( 113-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
begin
  ao <= reinterpret1_output_port_net_x1;
  bwo <= concatenate_y_net;
  sync_out <= slice2_y_net;
  reinterpret2_output_port_net <= ai;
  reinterpret1_output_port_net <= bi;
  delay0_q_net <= sync_in;
  clk_net <= clk_1;
  ce_net <= ce_1;
  bus_convert : entity xil_defaultlib.hirax_bit_growth_bus_convert_x8 
  port map (
    din => reinterpret1_output_port_net_x2,
    misci => dmisc_q_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    dout => concatenate_y_net,
    misco => dmisc_q_net
  );
  bus_create : entity xil_defaultlib.hirax_bit_growth_bus_create_x3 
  port map (
    in1 => reinterpret1_output_port_net,
    in2 => delay0_q_net,
    in3 => reinterpret2_output_port_net,
    bus_out => concatenate_y_net_x0
  );
  bus_expand : entity xil_defaultlib.hirax_bit_growth_bus_expand_x8 
  port map (
    bus_in => dmisc_q_net_x1,
    msb_out2 => reinterpret2_output_port_net_x0,
    lsb_out1 => reinterpret1_output_port_net_x0
  );
  bus_expand1 : entity xil_defaultlib.hirax_bit_growth_bus_expand1_x3 
  port map (
    bus_in => dmisc_q_net,
    msb_out2 => slice2_y_net,
    lsb_out1 => reinterpret1_output_port_net_x1
  );
  bus_mult : entity xil_defaultlib.hirax_bit_growth_3dsp_bus_mult_x4 
  port map (
    a => concat_y_net,
    b => reinterpret2_output_port_net_x0,
    misci => reinterpret1_output_port_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    a_b => reinterpret1_output_port_net_x2,
    misco => dmisc_q_net_x0
  );
  coeff_gen : entity xil_defaultlib.hirax_bit_growth_coeff_gen_x5 
  port map (
    rst => delay0_q_net,
    misci => concatenate_y_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    w => concat_y_net,
    misco => dmisc_q_net_x1
  );
end structural;

-- Twiddle entity wrapper for x4 - uses bus_mult_3dsp_x3
entity hirax_bit_growth_3dsp_twiddle_x4 is
  port (
    ai : in std_logic_vector( 56-1 downto 0 );
    bi : in std_logic_vector( 56-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ao : out std_logic_vector( 56-1 downto 0 );
    bwo : out std_logic_vector( 58-1 downto 0 )
  );
end hirax_bit_growth_3dsp_twiddle_x4;

architecture structural of hirax_bit_growth_3dsp_twiddle_x4 is 
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 56-1 downto 0 );
  signal concatenate_y_net : std_logic_vector( 58-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 56-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 56-1 downto 0 );
  signal delay0_q_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal dmisc_q_net : std_logic_vector( 57-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 94-1 downto 0 );
  signal dmisc_q_net_x0 : std_logic_vector( 57-1 downto 0 );
  signal concatenate_y_net_x0 : std_logic_vector( 113-1 downto 0 );
  signal reinterpret2_output_port_net_x0 : std_logic_vector( 56-1 downto 0 );
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 57-1 downto 0 );
  signal dmisc_q_net_x1 : std_logic_vector( 113-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
begin
  ao <= reinterpret1_output_port_net_x1;
  bwo <= concatenate_y_net;
  reinterpret2_output_port_net <= ai;
  reinterpret1_output_port_net <= bi;
  delay0_q_net <= sync_in;
  clk_net <= clk_1;
  ce_net <= ce_1;
  bus_convert : entity xil_defaultlib.hirax_bit_growth_bus_convert_x10 
  port map (
    din => reinterpret1_output_port_net_x2,
    misci => dmisc_q_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    dout => concatenate_y_net,
    misco => dmisc_q_net
  );
  bus_create : entity xil_defaultlib.hirax_bit_growth_bus_create_x4 
  port map (
    in1 => reinterpret1_output_port_net,
    in2 => delay0_q_net,
    in3 => reinterpret2_output_port_net,
    bus_out => concatenate_y_net_x0
  );
  bus_expand : entity xil_defaultlib.hirax_bit_growth_bus_expand_x10 
  port map (
    bus_in => dmisc_q_net_x1,
    msb_out2 => reinterpret2_output_port_net_x0,
    lsb_out1 => reinterpret1_output_port_net_x0
  );
  bus_expand1 : entity xil_defaultlib.hirax_bit_growth_bus_expand1_x4 
  port map (
    bus_in => dmisc_q_net,
    lsb_out1 => reinterpret1_output_port_net_x1
  );
  bus_mult : entity xil_defaultlib.hirax_bit_growth_3dsp_bus_mult_x3 
  port map (
    a => concat_y_net,
    b => reinterpret2_output_port_net_x0,
    misci => reinterpret1_output_port_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    a_b => reinterpret1_output_port_net_x2,
    misco => dmisc_q_net_x0
  );
  coeff_gen : entity xil_defaultlib.hirax_bit_growth_coeff_gen_x3 
  port map (
    rst => delay0_q_net,
    misci => concatenate_y_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    w => concat_y_net,
    misco => dmisc_q_net_x1
  );
end structural;

-- mult2 is the same as mult1_x0 (a=36, b=54, ab=92) - use the same 3dsp implementation
entity hirax_bit_growth_3dsp_mult2 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 54-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab : out std_logic_vector( 92-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult2;

architecture structural of hirax_bit_growth_3dsp_mult2 is
begin
  -- Use the same implementation as mult1_x0 (b=54, ab=92)
  mult1_core : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 54,
    AB_WIDTH => 92
  )
  port map (
    a => a,
    b => b,
    clk_1 => clk_1,
    ce_1 => ce_1,
    ab => ab
  );
end structural;

-- Bus multiplier wrapper for x0 (b=108, uses two multipliers: mult1_x0 and mult2)
entity hirax_bit_growth_3dsp_bus_mult_x0 is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 108-1 downto 0 );
    misci : in std_logic_vector( 109-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    a_b : out std_logic_vector( 184-1 downto 0 );
    misco : out std_logic_vector( 109-1 downto 0 )
  );
end hirax_bit_growth_3dsp_bus_mult_x0;

architecture structural of hirax_bit_growth_3dsp_bus_mult_x0 is
  signal concatenate_y_net : std_logic_vector( 184-1 downto 0 );
  signal dmisc_q_net : std_logic_vector( 109-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 108-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 109-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal concat_y_net_x0 : std_logic_vector( 92-1 downto 0 );
  signal concat_y_net_x1 : std_logic_vector( 92-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x3 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret2_output_port_net_x0 : std_logic_vector( 54-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 54-1 downto 0 );
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 108-1 downto 0 );
begin
  a_b <= concatenate_y_net;
  misco <= dmisc_q_net;
  concat_y_net <= a;
  reinterpret2_output_port_net <= b;
  reinterpret1_output_port_net <= misci;
  clk_net <= clk_1;
  ce_net <= ce_1;
  a_b_bussify : entity xil_defaultlib.hirax_bit_growth_a_b_bussify_x0 
  port map (
    in1 => concat_y_net_x0,
    in2 => concat_y_net_x1,
    bus_out => concatenate_y_net
  );
  a_debus : entity xil_defaultlib.hirax_bit_growth_a_debus_x5 
  port map (
    bus_in => reinterpret1_output_port_net_x3,
    msb_lsb_out1 => reinterpret1_output_port_net_x1
  );
  b_debus : entity xil_defaultlib.hirax_bit_growth_b_debus_x5 
  port map (
    bus_in => reinterpret1_output_port_net_x0,
    msb_out2 => reinterpret2_output_port_net_x0,
    lsb_out1 => reinterpret1_output_port_net_x2
  );
  mult1 : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 54,
    AB_WIDTH => 92
  )
  port map (
    a => reinterpret1_output_port_net_x1,
    b => reinterpret2_output_port_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => concat_y_net_x0
  );
  mult2 : entity xil_defaultlib.hirax_bit_growth_3dsp_mult2 
  port map (
    a => reinterpret1_output_port_net_x1,
    b => reinterpret1_output_port_net_x2,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => concat_y_net_x1
  );
  repa : entity xil_defaultlib.hirax_bit_growth_repa_x4 
  port map (
    in_x0 => concat_y_net,
    out_x0 => reinterpret1_output_port_net_x3
  );
  repb : entity xil_defaultlib.hirax_bit_growth_repb_x4 
  port map (
    in_x0 => reinterpret2_output_port_net,
    out_x0 => reinterpret1_output_port_net_x0
  );
  dmisc : entity xil_defaultlib.sysgen_delay_f3453d3832 
  port map (
    clr => '0',
    d => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => dmisc_q_net
  );
end structural;

-- Twiddle entity wrapper for x0 - uses bus_mult_3dsp_x0
entity hirax_bit_growth_3dsp_twiddle_x0 is
  port (
    ai : in std_logic_vector( 108-1 downto 0 );
    bi : in std_logic_vector( 108-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ao : out std_logic_vector( 108-1 downto 0 );
    bwo : out std_logic_vector( 112-1 downto 0 );
    sync_out : out std_logic_vector( 1-1 downto 0 )
  );
end hirax_bit_growth_3dsp_twiddle_x0;

architecture structural of hirax_bit_growth_3dsp_twiddle_x0 is 
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 108-1 downto 0 );
  signal concatenate_y_net_x1 : std_logic_vector( 112-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal concatenate_y_net : std_logic_vector( 108-1 downto 0 );
  signal concatenate_y_net_x0 : std_logic_vector( 108-1 downto 0 );
  signal register0_q_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal dmisc_q_net : std_logic_vector( 109-1 downto 0 );
  signal concatenate_y_net_x3 : std_logic_vector( 184-1 downto 0 );
  signal dmisc_q_net_x0 : std_logic_vector( 109-1 downto 0 );
  signal concatenate_y_net_x2 : std_logic_vector( 217-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 108-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 109-1 downto 0 );
  signal dmisc_q_net_x1 : std_logic_vector( 217-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
begin
  ao <= reinterpret1_output_port_net_x0;
  bwo <= concatenate_y_net_x1;
  sync_out <= slice2_y_net;
  concatenate_y_net <= ai;
  concatenate_y_net_x0 <= bi;
  register0_q_net <= sync_in;
  clk_net <= clk_1;
  ce_net <= ce_1;
  bus_convert : entity xil_defaultlib.hirax_bit_growth_bus_convert_x1 
  port map (
    din => concatenate_y_net_x3,
    misci => dmisc_q_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    dout => concatenate_y_net_x1,
    misco => dmisc_q_net
  );
  bus_create : entity xil_defaultlib.hirax_bit_growth_bus_create_x0 
  port map (
    in1 => concatenate_y_net_x0,
    in2 => register0_q_net,
    in3 => concatenate_y_net,
    bus_out => concatenate_y_net_x2
  );
  bus_expand : entity xil_defaultlib.hirax_bit_growth_bus_expand_x2 
  port map (
    bus_in => dmisc_q_net_x1,
    msb_out2 => reinterpret2_output_port_net,
    lsb_out1 => reinterpret1_output_port_net
  );
  bus_expand1 : entity xil_defaultlib.hirax_bit_growth_bus_expand1_x0 
  port map (
    bus_in => dmisc_q_net,
    msb_out2 => slice2_y_net,
    lsb_out1 => reinterpret1_output_port_net_x0
  );
  bus_mult : entity xil_defaultlib.hirax_bit_growth_3dsp_bus_mult_x0 
  port map (
    a => concat_y_net,
    b => reinterpret2_output_port_net,
    misci => reinterpret1_output_port_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    a_b => concatenate_y_net_x3,
    misco => dmisc_q_net_x0
  );
  coeff_gen : entity xil_defaultlib.hirax_bit_growth_coeff_gen_x4 
  port map (
    rst => register0_q_net,
    misci => concatenate_y_net_x2,
    clk_1 => clk_net,
    ce_1 => ce_net,
    w => concat_y_net,
    misco => dmisc_q_net_x1
  );
end structural;

-- Bus multiplier wrapper (no suffix) - b=52, misci=53, a_b=90
entity hirax_bit_growth_3dsp_bus_mult is
  port (
    a : in std_logic_vector( 36-1 downto 0 );
    b : in std_logic_vector( 52-1 downto 0 );
    misci : in std_logic_vector( 53-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    a_b : out std_logic_vector( 90-1 downto 0 );
    misco : out std_logic_vector( 53-1 downto 0 )
  );
end hirax_bit_growth_3dsp_bus_mult;

architecture structural of hirax_bit_growth_3dsp_bus_mult is
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 90-1 downto 0 );
  signal dmisc_q_net : std_logic_vector( 53-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 52-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 53-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal concat_y_net_x0 : std_logic_vector( 90-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x3 : std_logic_vector( 36-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 52-1 downto 0 );
  signal reinterpret1_output_port_net_x4 : std_logic_vector( 52-1 downto 0 );
begin
  a_b <= reinterpret1_output_port_net_x0;
  misco <= dmisc_q_net;
  concat_y_net <= a;
  reinterpret2_output_port_net <= b;
  reinterpret1_output_port_net <= misci;
  clk_net <= clk_1;
  ce_net <= ce_1;
  a_b_bussify : entity xil_defaultlib.hirax_bit_growth_a_b_bussify 
  port map (
    in1 => concat_y_net_x0,
    bus_out => reinterpret1_output_port_net_x0
  );
  a_debus : entity xil_defaultlib.hirax_bit_growth_a_debus 
  port map (
    bus_in => reinterpret1_output_port_net_x3,
    msb_lsb_out1 => reinterpret1_output_port_net_x1
  );
  b_debus : entity xil_defaultlib.hirax_bit_growth_b_debus_x0 
  port map (
    bus_in => reinterpret1_output_port_net_x4,
    msb_lsb_out1 => reinterpret1_output_port_net_x2
  );
  mult1 : entity xil_defaultlib.hirax_bit_growth_3dsp_mult1_generic
  generic map (
    B_WIDTH => 52,
    AB_WIDTH => 90
  )
  port map (
    a => reinterpret1_output_port_net_x1,
    b => reinterpret1_output_port_net_x2,
    clk_1 => clk_net,
    ce_1 => ce_net,
    ab => concat_y_net_x0
  );
  repa : entity xil_defaultlib.hirax_bit_growth_repa 
  port map (
    in_x0 => concat_y_net,
    out_x0 => reinterpret1_output_port_net_x3
  );
  repb : entity xil_defaultlib.hirax_bit_growth_repb 
  port map (
    in_x0 => reinterpret2_output_port_net,
    out_x0 => reinterpret1_output_port_net_x4
  );
  dmisc : entity xil_defaultlib.sysgen_delay_2aac1c2095 
  port map (
    clr => '0',
    d => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => dmisc_q_net
  );
end structural;

-- Twiddle entity wrapper (no suffix) - uses bus_mult_3dsp
entity hirax_bit_growth_3dsp_twiddle is
  port (
    ai : in std_logic_vector( 52-1 downto 0 );
    bi : in std_logic_vector( 52-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ao : out std_logic_vector( 52-1 downto 0 );
    bwo : out std_logic_vector( 54-1 downto 0 );
    sync_out : out std_logic_vector( 1-1 downto 0 )
  );
end hirax_bit_growth_3dsp_twiddle;

architecture structural of hirax_bit_growth_3dsp_twiddle is 
  signal reinterpret1_output_port_net_x0 : std_logic_vector( 52-1 downto 0 );
  signal concatenate_y_net : std_logic_vector( 54-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal reinterpret1_output_port_net_x2 : std_logic_vector( 52-1 downto 0 );
  signal dmux0_q_net : std_logic_vector( 52-1 downto 0 );
  signal mux_y_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal dmisc_q_net : std_logic_vector( 53-1 downto 0 );
  signal reinterpret1_output_port_net_x1 : std_logic_vector( 90-1 downto 0 );
  signal dmisc_q_net_x0 : std_logic_vector( 53-1 downto 0 );
  signal concatenate_y_net_x0 : std_logic_vector( 105-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 52-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 53-1 downto 0 );
  signal delay1_q_net : std_logic_vector( 105-1 downto 0 );
  signal concat_y_net : std_logic_vector( 36-1 downto 0 );
begin
  ao <= reinterpret1_output_port_net_x0;
  bwo <= concatenate_y_net;
  sync_out <= slice2_y_net;
  reinterpret1_output_port_net_x2 <= ai;
  dmux0_q_net <= bi;
  mux_y_net <= sync_in;
  clk_net <= clk_1;
  ce_net <= ce_1;
  bus_convert : entity xil_defaultlib.hirax_bit_growth_bus_convert 
  port map (
    din => reinterpret1_output_port_net_x1,
    misci => dmisc_q_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    dout => concatenate_y_net,
    misco => dmisc_q_net
  );
  bus_create : entity xil_defaultlib.hirax_bit_growth_bus_create 
  port map (
    in1 => dmux0_q_net,
    in2 => mux_y_net,
    in3 => reinterpret1_output_port_net_x2,
    bus_out => concatenate_y_net_x0
  );
  bus_expand : entity xil_defaultlib.hirax_bit_growth_bus_expand 
  port map (
    bus_in => delay1_q_net,
    msb_out2 => reinterpret2_output_port_net,
    lsb_out1 => reinterpret1_output_port_net
  );
  bus_expand1 : entity xil_defaultlib.hirax_bit_growth_bus_expand1 
  port map (
    bus_in => dmisc_q_net,
    msb_out2 => slice2_y_net,
    lsb_out1 => reinterpret1_output_port_net_x0
  );
  bus_mult : entity xil_defaultlib.hirax_bit_growth_3dsp_bus_mult 
  port map (
    a => concat_y_net,
    b => reinterpret2_output_port_net,
    misci => reinterpret1_output_port_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    a_b => reinterpret1_output_port_net_x1,
    misco => dmisc_q_net_x0
  );
  coeff_gen : entity xil_defaultlib.hirax_bit_growth_coeff_gen_x0 
  port map (
    rst => mux_y_net,
    misci => concatenate_y_net_x0,
    clk_1 => clk_net,
    ce_1 => ce_net,
    w => concat_y_net,
    misco => delay1_q_net
  );
end structural;
