library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.chFPGA_package.all; -- get platform-specific configurations

library UNISIM;
use UNISIM.VComponents.all;

entity SCALER_MUL is
	generic (
		A_WIDTH: integer := 16; -- should be smaller than 18
		B_WIDTH: integer := 32;
		P_WIDTH: integer := A_WIDTH + B_WIDTH -- should be >= A_WIDTH + B_WIDTH
		);
   port (
		a : in  signed(A_WIDTH-1 downto 0);
		b : in  signed(B_WIDTH-1 downto 0);
		p : out  signed(P_WIDTH-1 downto 0);
		clk : in  std_logic;
		rst : in  std_logic
		);

end SCALER_MUL;

architecture impl of SCALER_MUL is

    signal a1: signed(A_WIDTH-1 downto 0);
    signal b1: signed(B_WIDTH-1 downto 0);

    constant B_WIDTH_MAX: integer := 18; -- use  2 multipliers if B_WIDTH > B_WIDTH_MAX
    constant IM1_WIDTH:integer := B_WIDTH_MAX + A_WIDTH + 1; -- b1 unsigned slice has a extra guard bit to make it signed
    constant IM2_WIDTH: integer := B_WIDTH - B_WIDTH_MAX + A_WIDTH;
    signal im1: signed(IM1_WIDTH-1 downto 0);
    signal im2: signed(IM2_WIDTH-1 downto 0);


            signal dsp1_pcout: std_logic_vector(47 downto 0);
            signal dsp2_a: std_logic_vector(29 downto 0);
            signal dsp2_b: std_logic_vector(17 downto 0);

        signal dsp2_opmode: std_logic_vector(6 downto 0);

begin


    -- Instantiate the two DSPs
    dsp1 : DSP48E1
        generic map (
            -- Feature Control Attributes: Data Path Selection
            A_INPUT            => "DIRECT", -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
            B_INPUT            => "DIRECT", -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
            USE_DPORT          => FALSE, -- Select D port usage (TRUE or FALSE)
            USE_MULT           => "MULTIPLY", -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
            USE_SIMD           => "ONE48", -- SIMD selection ("ONE48", "TWO24", "FOUR12")
            -- Pattern Detector Attributes: Pattern Detection Configuration
            AUTORESET_PATDET   => "NO_RESET", -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH"
            MASK               => X"3fffffffffff", -- 48-bit mask value for pattern detect (1=ignore)
            PATTERN            => X"000000000000", -- 48-bit pattern match for pattern detect
            SEL_MASK           => "MASK", -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2"
            SEL_PATTERN        => "PATTERN", -- Select pattern value ("PATTERN" or "C")
            USE_PATTERN_DETECT => "NO_PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
            -- Register Control Attributes: Pipeline Register Configuration
            ACASCREG           => 1, -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
            ADREG              => 1, -- Number of pipeline stages for pre-adder (0 or 1)
            ALUMODEREG         => 1, -- Number of pipeline stages for ALUMODE (0 or 1)
            AREG               => 1, -- Number of pipeline stages for A (0, 1 or 2)
            BCASCREG           => 1, -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
            BREG               => 1, -- Number of pipeline stages for B (0, 1 or 2)
            CARRYINREG         => 1, -- Number of pipeline stages for CARRYIN (0 or 1)
            CARRYINSELREG      => 1, -- Number of pipeline stages for CARRYINSEL (0 or 1)
            CREG               => 1, -- Number of pipeline stages for C (0 or 1)
            DREG               => 1, -- Number of pipeline stages for D (0 or 1)
            INMODEREG          => 1, -- Number of pipeline stages for INMODE (0 or 1)
            MREG               => 1, -- Number of multiplier pipeline stages (0 or 1)
            OPMODEREG          => 1, -- Number of pipeline stages for OPMODE (0 or 1)
            PREG               => 1 -- Number of pipeline stages for P (0 or 1)
        )
        port map (
            -- Cascade: 30-bit (each) output: Cascade Ports
            ACOUT          => open, -- 30-bit output: A port cascade output
            BCOUT          => open, -- 18-bit output: B port cascade output
            CARRYCASCOUT   => open, -- 1-bit output: Cascade carry output
            MULTSIGNOUT    => open, -- 1-bit output: Multiplier sign cascade output
            PCOUT          => dsp1_pcout, -- 48-bit output: Cascade output
            P              => dsp1_p, -- 48-bit output: Primary data output
            -- Control: 1-bit (each) output: Control Inputs/Status Bits
            OVERFLOW       => open, -- 1-bit output: Overflow in add/acc output
            PATTERNBDETECT => open, -- 1-bit output: Pattern bar detect output
            PATTERNDETECT  => open, -- 1-bit output: Pattern detect output
            UNDERFLOW      => open, -- 1-bit output: Underflow in add/acc output
            -- Data: 4-bit (each) output: Data Ports
            CARRYOUT       => open, -- 4-bit output: Carry output
            -- Cascade: 30-bit (each) input: Cascade Ports
            ACIN           => (others=> '0'), -- 30-bit input: A cascade data input
            BCIN           => (others=> '0'), -- 18-bit input: B cascade input
            CARRYCASCIN    => '0', -- 1-bit input: Cascade carry input
            MULTSIGNIN     => '0', -- 1-bit input: Multiplier sign input
            PCIN           => (others=> '0'), -- 48-bit input: P cascade input
            -- Control: 4-bit (each) input: Control Inputs/Status Bits
            ALUMODE        => dsp1_alumode, -- 4-bit input: ALU control input
            CARRYINSEL     => "000", -- 3-bit input: Carry select input
            CLK            => clk, -- 1-bit input: Clock input
            INMODE         => "00000", -- 5-bit input: INMODE control input
            OPMODE         => "0110101", -- 7-bit input: Operation mode input, X/Y=M, P=C
            -- Data: 30-bit (each) input: Data Ports
            A              => dsp1_a, -- 30-bit input: A data input
            B              => dsp1_b, -- 18-bit input: B data input
            C              => dsp1_c, -- 48-bit input: C data input
            CARRYIN        => dsp1_cin, -- 1-bit input: Carry input signal
            D              => (others=> '0'), -- 25-bit input: D data input
            -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
            CEA1           => '1', -- 1-bit input: Clock enable input for 1st stage AREG
            CEA2           => '1', -- 1-bit input: Clock enable input for 2nd stage AREG
            CEAD           => '0', -- 1-bit input: Clock enable input for ADREG
            CEALUMODE      => '1', -- 1-bit input: Clock enable input for ALUMODE
            CEB1           => '1', -- 1-bit input: Clock enable input for 1st stage BREG
            CEB2           => '1', -- 1-bit input: Clock enable input for 2nd stage BREG
            CEC            => '1', -- 1-bit input: Clock enable input for CREG
            CECARRYIN      => '1', -- 1-bit input: Clock enable input for CARRYINREG
            CECTRL         => '1', -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
            CED            => '0', -- 1-bit input: Clock enable input for DREG
            CEINMODE       => '1', -- 1-bit input: Clock enable input for INMODEREG
            CEM            => '1', -- 1-bit input: Clock enable input for MREG
            CEP            => '1', -- 1-bit input: Clock enable input for PREG
            RSTA           => '0', -- 1-bit input: Reset input for AREG
            RSTALLCARRYIN  => '0', -- 1-bit input: Reset input for CARRYINREG
            RSTALUMODE     => '0', -- 1-bit input: Reset input for ALUMODEREG
            RSTB           => '0', -- 1-bit input: Reset input for BREG
            RSTC           => '0', -- 1-bit input: Reset input for CREG
            RSTCTRL        => '0', -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
            RSTD           => '0', -- 1-bit input: Reset input for DREG and ADREG
            RSTINMODE      => '0', -- 1-bit input: Reset input for INMODEREG
            RSTM           => '0', -- 1-bit input: Reset input for MREG
            RSTP           => '0' -- 1-bit input: Reset input for PREG
        );

    -- Second DSP: sums the ad and bd terms, and adds the accumulator output to the (ac+bd) and (ad-bc)
    -- terms, with guard bits to allow for overflow detection.
    dsp2 : DSP48E1
        generic map (
            -- Feature Control Attributes: Data Path Selection
            A_INPUT            => "DIRECT", -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
            B_INPUT            => "DIRECT", -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
            USE_DPORT          => FALSE, -- Select D port usage (TRUE or FALSE)
            USE_MULT           => "MULTIPLY", -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
            USE_SIMD           => "ONE48", -- SIMD selection ("ONE48", "TWO24", "FOUR12")
            -- Pattern Detector Attributes: Pattern Detection Configuration
            AUTORESET_PATDET   => "NO_RESET", -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH"
            MASK               => X"3fffffffffff", -- 48-bit mask value for pattern detect (1=ignore)
            PATTERN            => X"000000000000", -- 48-bit pattern match for pattern detect
            SEL_MASK           => "MASK", -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2"
            SEL_PATTERN        => "PATTERN", -- Select pattern value ("PATTERN" or "C")
            USE_PATTERN_DETECT => "NO_PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
            -- Register Control Attributes: Pipeline Register Configuration
            ACASCREG           => 0, -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
            ADREG              => 1, -- Number of pipeline stages for pre-adder (0 or 1)
            ALUMODEREG         => 1, -- Number of pipeline stages for ALUMODE (0 or 1)
            AREG               => 0, -- Number of pipeline stages for A (0, 1 or 2)
            BCASCREG           => 0, -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
            BREG               => 0, -- Number of pipeline stages for B (0, 1 or 2)
            CARRYINREG         => 1, -- Number of pipeline stages for CARRYIN (0 or 1)
            CARRYINSELREG      => 1, -- Number of pipeline stages for CARRYINSEL (0 or 1)
            CREG               => 1, -- Number of pipeline stages for C (0 or 1)
            DREG               => 1, -- Number of pipeline stages for D (0 or 1)
            INMODEREG          => 1, -- Number of pipeline stages for INMODE (0 or 1)
            MREG               => 1, -- Number of multiplier pipeline stages (0 or 1)
            OPMODEREG          => 1, -- Number of pipeline stages for OPMODE (0 or 1)
            PREG               => 1 -- Number of pipeline stages for P (0 or 1)
        )
        port map (
            -- Cascade: 30-bit (each) output: Cascade Ports
            ACOUT          => open, -- 30-bit output: A port cascade output
            BCOUT          => open, -- 18-bit output: B port cascade output
            CARRYCASCOUT   => open, -- 1-bit output: Cascade carry output
            MULTSIGNOUT    => open, -- 1-bit output: Multiplier sign cascade output
            PCOUT          => open, -- 48-bit output: Cascade output
            P              => dsp2_p, -- 48-bit output: Primary data output
            -- Control: 1-bit (each) output: Control Inputs/Status Bits
            OVERFLOW       => open, -- 1-bit output: Overflow in add/acc output
            PATTERNBDETECT => open, -- 1-bit output: Pattern bar detect output
            PATTERNDETECT  => open, -- 1-bit output: Pattern detect output
            UNDERFLOW      => open, -- 1-bit output: Underflow in add/acc output
            -- Data: 4-bit (each) output: Data Ports
            CARRYOUT       => open, -- 4-bit output: Carry output
            -- Cascade: 30-bit (each) input: Cascade Ports
            ACIN           => (others=> '0'), -- 30-bit input: A cascade data input
            BCIN           => (others=> '0'), -- 18-bit input: B cascade input
            CARRYCASCIN    => '0', -- 1-bit input: Cascade carry input
            MULTSIGNIN     => '0', -- 1-bit input: Multiplier sign input
            PCIN           => dsp1_pcout, -- 48-bit input: P cascade input
            -- Control: 4-bit (each) input: Control Inputs/Status Bits
            ALUMODE        => "0001", -- 4-bit input: ALU control input:
            CARRYINSEL     => "000", -- 3-bit input: Carry select input
            CLK            => clk, -- 1-bit input: Clock input
            INMODE         => "00000", -- 5-bit input: INMODE control input
            OPMODE         => dsp2_opmode, -- 7-bit input: Operation mode input
            -- Data: 30-bit (each) input: Data Ports
            A              => dsp2_a, -- 30-bit input: A data input
            B              => dsp2_b, -- 18-bit input: B data input
            C              => (others => '0'), -- 48-bit input: C data input
            CARRYIN        => '0', -- 1-bit input: Carry input signal
            D              => (others=> '0'), -- 25-bit input: D data input
            -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
            CEA1           => '0', -- 1-bit input: Clock enable input for 1st stage AREG
            CEA2           => '0', -- 1-bit input: Clock enable input for 2nd stage AREG
            CEAD           => '0', -- 1-bit input: Clock enable input for ADREG
            CEALUMODE      => '1', -- 1-bit input: Clock enable input for ALUMODE
            CEB1           => '0', -- 1-bit input: Clock enable input for 1st stage BREG
            CEB2           => '0', -- 1-bit input: Clock enable input for 2nd stage BREG
            CEC            => '1', -- 1-bit input: Clock enable input for CREG
            CECARRYIN      => '1', -- 1-bit input: Clock enable input for CARRYINREG
            CECTRL         => '1', -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
            CED            => '0', -- 1-bit input: Clock enable input for DREG
            CEINMODE       => '1', -- 1-bit input: Clock enable input for INMODEREG
            CEM            => '1', -- 1-bit input: Clock enable input for MREG
            CEP            => '1', -- 1-bit input: Clock enable input for PREG
            RSTA           => '0', -- 1-bit input: Reset input for AREG
            RSTALLCARRYIN  => '0', -- 1-bit input: Reset input for CARRYINREG
            RSTALUMODE     => '0', -- 1-bit input: Reset input for ALUMODEREG
            RSTB           => '0', -- 1-bit input: Reset input for BREG
            RSTC           => '0', -- 1-bit input: Reset input for CREG
            RSTCTRL        => '0', -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
            RSTD           => '0', -- 1-bit input: Reset input for DREG and ADREG
            RSTINMODE      => '0', -- 1-bit input: Reset input for INMODEREG
            RSTM           => '0', -- 1-bit input: Reset input for MREG
            RSTP           => '0' -- 1-bit input: Reset input for PREG
        );



mul_proc: process(clk)
    begin
        if rising_edge(clk) then
            a1 <= a;
            b1 <= b;

            if B_WIDTH <= B_WIDTH_MAX then
                p <= resize(a1 * b1, P_WIDTH);
            else
                im1 <= a1 * signed(resize(unsigned(b1(B_WIDTH_MAX-1 downto 0)), B_WIDTH_MAX + 1));
                im2 <= a1 * b1(B_WIDTH-1 downto B_WIDTH_MAX);
                p <= shift_left(resize(im2, P_WIDTH), B_WIDTH_MAX) + im1;
            end if;
        end if; --clk
    end process;

end architecture impl;
