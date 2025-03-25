--------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer:J.-F. Cliche
--
-- Create Date: 2025-03
-- Design Name: scaler_mul
-- Project Name: chFPGA
-- Target Device: 7-Series, Ultrascale+
-- Tool versions: Vivado 2022.2 
-- Programming language: VHDL 2008
-- Description:
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.chFPGA_package.all; -- get platform-specific configurations

library UNISIM;
use UNISIM.VComponents.all;

-- Returns signed product P=A*B where a is a signed value up to 42 bits, and B is a signed value up to 17 bits. 
-- The module uses one DSP48 if A is 25 bits or less, otherwise it uses two.  
-- Latency is 3 clock cycles in any case. 
entity SCALER_MUL is
	generic (
		A_WIDTH: integer := 18; -- should be <= 42 bits
		B_WIDTH: integer := 16; -- should <= 17 bits
		P_WIDTH: integer := A_WIDTH + B_WIDTH -- should be >= A_WIDTH + B_WIDTH
		);
   port (
		a : in  std_logic_vector(A_WIDTH-1 downto 0); -- Signed operand up to 42 bits
		b : in  std_logic_vector(B_WIDTH-1 downto 0); -- Unsigned operand up to 17 bits
		p : out std_logic_vector(P_WIDTH-1 downto 0); -- Signed product
		clk : in  std_logic
		);

end SCALER_MUL;

architecture impl of SCALER_MUL is

    constant NSTAGES: integer := sel(A_WIDTH>25, 2, 1);
    constant NSHIFT: integer:= 17; -- Shift-right performed by 2nd stage DSP on lower product. This is fixed by the DSP48.
    constant DSP1_PREG: integer:= sel(NSTAGES>1,0,1); -- DSP1 has no PREG if we have a second stage
    signal dsp1_a: std_logic_vector(29 downto 0); -- lower 17 bits of signed operand as 30-bit unsigned value
    signal dsp1_b: std_logic_vector(17 downto 0); -- unsigned operand resized to 18 bits 
    signal dsp1_bcout: std_logic_vector(17 downto 0);
    signal dsp1_p, dsp1_pcout: std_logic_vector(47 downto 0);

    signal dsp2_a: std_logic_vector(29 downto 0);
    signal dsp2_p: std_logic_vector(47 downto 0);


begin
    assert A_WIDTH <=42 report "A_WIDTH must be <=42" severity FAILURE;
    assert B_WIDTH <=17 report "B_WIDTH must be <=17" severity FAILURE;

    dsp1_b <= std_logic_vector(resize(unsigned(b), 18)); -- unsigned operand resized to 18 bits signed
    
    p_gen: if NSTAGES >1 generate
        dsp1_a <= std_logic_vector(resize(unsigned(a(NSHIFT-1 downto 0)), 30)); -- A = lower NSHIFT bits, treated as unsigned
        p(P_WIDTH-1 downto NSHIFT) <= dsp2_p(P_WIDTH-NSHIFT-1 downto 0); -- upper product bits registered in DSP2 PREG
 
        process(all) begin -- register lower product bits from 1st stage DSP in fabric registers 
           p(NSHIFT-1 downto 0) <= dsp1_p(NSHIFT-1 downto 0) when rising_edge(clk);
        end process;
     else generate
        dsp1_a <= std_logic_vector(resize(signed(a), 30));
        p <= dsp1_p(P_WIDTH-1 downto 0); -- upper product bits registered in DSP2 PREG
    end generate;

    -- The multiplier has a latency of 3 clocks:
    --
    -- CLK1: DSP1 input registers send lsb(A) & B to input of multiplier. BCOUT appears on DSP2 BCIN.
    -- CLK2: 
    --   - DSP1 Multiplier output (full product (NSTAGE=1) or lower partial product (NSTAGE=2) is clocked out of DSP1 MREG.  Product propagates to P and PCOUT if NSTAGE=1 (no PREG)
    --   - DSP2 Multiplier input receives msb(A) and B and upper partial product propagares to adder input (no MREG)
    -- CLK3:
    --   - DSP1 PREG clocks out the full product (NSTAGE=1)
    --   - Lower partial product from DSP1 P are registered in fabric registers (NSTAGE=2)
    --   - Upper partial product from DSP2 adder are registered on DSP2 P output (NSTAGE=2)
    
    -- First DSP: compute product of lower 17 bits of A with B.
    --  A, B & BCOUT have 1 pipeline register. BCOUT is a delayed version of B to be used by 2nd DSP while avoiding using fabric routing
    --  M has 1 output register
    --  P and PCOUT are the first partial product without register (straight from mul output).
    dsp1 : DSP48E1
        generic map (
            -- Register Control Attributes: Pipeline Register Configuration
            AREG               => 1, -- Number of pipeline stages for A (0, 1 or 2)
            BCASCREG           => 1, -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
            BREG               => 1, -- Number of pipeline stages for B (0, 1 or 2)
            MREG               => 1, -- Number of multiplier pipeline stages (0 or 1)
            PREG               => DSP1_PREG -- Number of pipeline stages for P (0 or 1)
        )
        port map (

            -- Mode control
            INMODE         => "00000", -- 5-bit input: INMODE control input: Mult  = A(AREG=1) *  B(BREG=1)
            OPMODE         => "0000101", -- 7-bit input: Operation mode input, X=M1, Y=M2, Z= 0
            ALUMODE        => "0000", -- 4-bit input: ALU control input. P = Z+X+Y+CIN
            CARRYINSEL     => "000", -- 3-bit input: Carry select input. Carry = CARRYIN

            -- Inputs
            A              => dsp1_a, -- 30-bit input: A data input
            B              => dsp1_b, -- 18-bit input: B data input
            C              => (others => '0'), -- 48-bit input: C data input
            CARRYIN        => '0', -- 1-bit input: Carry input signal
            D              => (others=> '0'), -- 25-bit input: D data input

            -- Unused inputs
            ACIN           => (others=> '0'), -- 30-bit input: A cascade data input
            BCIN           => (others=> '0'), -- 18-bit input: B cascade input
            CARRYCASCIN    => '0', -- 1-bit input: Cascade carry input
            MULTSIGNIN     => '0', -- 1-bit input: Multiplier sign input
            PCIN           => (others=> '0'), -- 48-bit input: P cascade input

            -- Outputs
            BCOUT          => dsp1_bcout, -- 18-bit output: B port cascade output
            PCOUT          => dsp1_pcout, -- 48-bit output: Cascade output
            P              => dsp1_p, -- 48-bit output: Primary data output

            -- Clock
            CLK            => clk, -- 1-bit input: Clock input

            -- Clock Enables
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


            -- Resets
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

    dsp2_gen: if NSTAGES > 1 generate 
        dsp2_a <= std_logic_vector(resize(signed(a(A_WIDTH-1 downto NSHIFT)), 30)); -- upper bits of signed operand as 30-bit *signed* value
  
        -- Second DSP: Computes the product of the upper A bits with B, and adds partial product shifted down by 17 bits
        --   A: Upper A bits, 2 registers, to match BCIN
        --   BCIN: B operand, 1 register (1 reg in DSP1 + 1 reg in DSP2 = t regs total)
        --   PCIN: partial product, shifted by 17 bits before adder. 
        --   PCOUT: upper partial product, 1 output register
        dsp2 : DSP48E1
            generic map (
                -- Feature Control Attributes: Data Path Selection
                B_INPUT            => "CASCADE", -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
                -- Register Control Attributes: Pipeline Register Configuration
                AREG               => 2, -- Number of pipeline stages for A (0, 1 or 2)
                BREG               => 1, -- Number of pipeline stages for B (0, 1 or 2)
                MREG               => 0, -- Number of multiplier pipeline stages (0 or 1)
                PREG               => 1 -- Number of pipeline stages for P (0 or 1)
            )
            port map (
    
                -- Mode Control
                INMODE         => "00000", -- 5-bit input: INMODE control input. Mult  = A(AREG=2) *  B(BREG=1)
                OPMODE         => "1010101", -- 7-bit input: Operation mode input. X=M1, Y=M2, Z= PCIN>>17
                ALUMODE        => "0000", -- 4-bit input: ALU control input:P = Z+X+Y+CIN
                CARRYINSEL     => "000", -- 3-bit input: Carry select input. CIN = CARRYIN
    
    
                -- Inputs
                A              => dsp2_a, -- 30-bit input: A data input
                BCIN           => dsp1_bcout, -- 18-bit input: B cascade input
                PCIN           => dsp1_pcout, -- 48-bit input: P cascade input
    
    
                -- Unused inputs
                B              => (others => '0'), -- 18-bit input: B data input -- we use BCIN
                C              => (others => '0'), -- 48-bit input: C data input
                CARRYIN        => '0', -- 1-bit input: Carry input signal
                D              => (others=> '0'), -- 25-bit input: D data input
                ACIN           => (others=> '0'), -- 30-bit input: A cascade data input
                CARRYCASCIN    => '0', -- 1-bit input: Cascade carry input
                MULTSIGNIN     => '0', -- 1-bit input: Multiplier sign input
    
                -- Output
                P => dsp2_p, -- 48-bit output: Primary data output
    
                -- Clock
                CLK            => clk, -- 1-bit input: Clock input
    
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
                CEM            => '0', -- 1-bit input: Clock enable input for MREG
                CEP            => '1', -- 1-bit input: Clock enable input for PREG
    
                -- resets
                
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
    end generate;
end architecture impl;
