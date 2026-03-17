-- Consolidated 3 DSP complex multiplier for widest inputs (a=36, b=56)
-- Simplified: a = [re_a(35:18), im_a(17:0)], b = [re_b(55:28), im_b(27:0)]; ab = [re(93:47), im(46:0)]
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library xil_defaultlib;
use xil_defaultlib.conv_pkg.all;

entity hirax_bit_growth_3dsp_mult_wide is
  generic (
    A_WIDTH  : natural := 36;   -- Input a width (complex 18+18 bits per component)..
    B_WIDTH  : natural := 56;   -- Input b width. 
    AB_WIDTH : natural := 94   -- Output ab Must be A_WIDTH+B_WIDTH+2 (1 bit for Re and Im each for the final addition)
  );
  port (
    a_re : in signed( A_WIDTH/2-1 downto 0 );
    a_im : in signed( A_WIDTH/2-1 downto 0 );
    b_re : in signed( B_WIDTH/2-1 downto 0 );
    b_im : in signed( B_WIDTH/2-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    ab_re : out signed( AB_WIDTH/2-1 downto 0 );
    ab_im : out signed( AB_WIDTH/2-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult_wide;

architecture structural of hirax_bit_growth_3dsp_mult_wide is
  -- Slices: re = high half, im = low half
  signal a_re_plus_im : signed( A_WIDTH/2 downto 0 ); -- extra bit for carry
  signal b_re_plus_im : signed( B_WIDTH/2 downto 0 ); -- extra bit for carry
  signal b_im_minus_re : signed( B_WIDTH/2 downto 0 ); -- extra bit for carry
  signal a_re_plus_im_trunc : signed( A_WIDTH/2-1 downto 0 );
  signal b_re_plus_im_trunc : signed( B_WIDTH/2-1 downto 0 );
  signal b_im_minus_re_trunc : signed( B_WIDTH/2-1 downto 0 );
  signal p0, p_reg0 : signed(AB_WIDTH/2 - 2 downto 0 );
  signal p1, p_reg1 : signed(AB_WIDTH/2 - 2 downto 0 );
  signal p2, p_reg2 : signed(AB_WIDTH/2 - 2 downto 0 );
begin
  assert AB_WIDTH = A_WIDTH + B_WIDTH + 2 report "Multiplier width mismatch" severity failure;
  -- Input slices: a = [re(35:18), im(17:0)], b = [re(55:28), im(27:0)]
  -- Pre-multiplier add/sub: (a_re + a_im), (b_re + b_im), (b_im - b_re)
  -- An extra bit is added to handle the carry
  a_re_plus_im <= resize(a_re, A_WIDTH/2+1) + resize(a_im, A_WIDTH/2+1);
  b_re_plus_im <= resize(b_re, B_WIDTH/2+1) + resize(b_im, B_WIDTH/2+1); -- extra bit for carry
  b_im_minus_re <= resize(b_im, B_WIDTH/2+1) - resize(b_re, B_WIDTH/2+1); -- extra bit for carry

  -- Truncate to multiplier width - just take the MABs, discard the last bit 
  a_re_plus_im_trunc <= a_re_plus_im(A_WIDTH/2 downto 1);
  b_re_plus_im_trunc <= b_re_plus_im(B_WIDTH/2 downto 1);
  b_im_minus_re_trunc <= b_im_minus_re(B_WIDTH/2 downto 1);

   process(clk_1) begin
  if rising_edge(clk_1) then
    if ce_1 = '1' then
        -- 3 DSP multiplications
        -- mult0 = (a_re+a_im)*b_re, 
        -- mult1 = a_im*(b_re+b_im), 
        -- mult2 = a_re*(b_im-b_re)
        p0 <= a_re_plus_im_trunc * b_re;
        p_reg0 <= p0;
        p1 <= a_im * b_re_plus_im_trunc;
        p_reg1 <= p1;
        p2 <= a_re * b_im_minus_re_trunc;
        p_reg2 <= p2;
        
        -- re = mult0 - mult1, im = mult0 - mult2
  
        ab_re <= resize(signed(p_reg0), AB_WIDTH/2) - resize(signed(p_reg1), AB_WIDTH/2) ;
        ab_im <= resize(signed(p_reg0), AB_WIDTH/2) - resize(signed(p_reg2), AB_WIDTH/2);
    end if;
  end if;
  end process;
  
end structural;

-- Generic 3 DSP complex multiplier wrapper
-- Based on hirax_bit_growth_3dsp_mult1 (3-DSP algorithm); uses A_WIDTH, B_WIDTH, AB_WIDTH
-- for port widths and extends/truncates to the internal 36x56->94 core.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library xil_defaultlib;
use xil_defaultlib.conv_pkg.all;

entity hirax_bit_growth_3dsp_mult is
  generic (
    A_WIDTH  : natural := 36;   -- Input a width (complex 18+18 bits per component)
    B_WIDTH  : natural := 56;   -- Input b width (40, 42, 44, 46, 48, 50, 52, 54, or 56)
    AB_WIDTH : natural := 94   -- Output ab width (78, 80, 82, 84, 86, 88, 90, 92, or 94)
  );
  port (
    a     : in  std_logic_vector( A_WIDTH-1 downto 0 );
    b     : in  std_logic_vector( B_WIDTH-1 downto 0 );
    clk_1 : in  std_logic;
    ce_1  : in  std_logic;
    ab    : out std_logic_vector( AB_WIDTH-1 downto 0 )
  );
end hirax_bit_growth_3dsp_mult;

architecture structural of hirax_bit_growth_3dsp_mult is
  constant A_WIDTH_MAX   : natural := A_WIDTH;
  constant B_WIDTH_MAX   : natural := B_WIDTH;
  constant AB_WIDTH_MAX  : natural := A_WIDTH+B_WIDTH+2;
  signal ab_re : signed( AB_WIDTH_MAX/2-1 downto 0 );
  signal ab_im : signed( AB_WIDTH_MAX/2-1 downto 0 );
  signal a_re : signed( A_WIDTH_MAX/2-1 downto 0 );
  signal a_im : signed( A_WIDTH_MAX/2-1 downto 0 );
  signal b_re : signed( B_WIDTH_MAX/2-1 downto 0 );
  signal b_im : signed( B_WIDTH_MAX/2-1 downto 0 );
begin
  -- Sign-extend a/b to core width (36/56) when generic width is smaller
  a_re <= resize(signed(a(A_WIDTH-1 downto A_WIDTH/2)), A_WIDTH_MAX/2);
  a_im <= resize(signed(a(A_WIDTH/2-1 downto 0)), A_WIDTH_MAX/2);
  b_re <= resize(signed(b(B_WIDTH-1 downto B_WIDTH/2)), B_WIDTH_MAX/2);
  b_im <= resize(signed(b(B_WIDTH/2-1 downto 0)), B_WIDTH_MAX/2);
  mult_core : entity xil_defaultlib.hirax_bit_growth_3dsp_mult_wide
    generic map (
      A_WIDTH => A_WIDTH_MAX,
      B_WIDTH => B_WIDTH_MAX,
      AB_WIDTH => AB_WIDTH_MAX
    )
    port map (
      a_re => a_re,
      a_im => a_im,
      b_re => b_re,
      b_im => b_im,
      clk_1 => clk_1,
      ce_1 => ce_1,
      ab_re => ab_re,
      ab_im => ab_im
    );

  ab <= std_logic_vector(ab_re(AB_WIDTH/2-1 downto 0)) & std_logic_vector(ab_im(AB_WIDTH/2-1 downto 0));
end structural;

