-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

	library work;
	use work.chFPGA_Package.all;

  ENTITY CORR_testbench IS
  END CORR_testbench;

  ARCHITECTURE behavior OF CORR_testbench IS 

  signal CLK :  std_logic;
  signal RST :  std_logic;
  signal STREAM_IN :  AXIS32_DAT_STRUCT;
  signal STREAM_OUT: ACCUM_OUT_STRUCT;
  signal TEST_DATA1: Word32Array(0 to 3):=(X"12345678",X"F39F27AB", X"B8552DA2", X"036F0001");

  BEGIN

  -- Component Instantiation
	 CORR0: CORR 
		GENERIC MAP(
			N=>4
			)
		PORT MAP(
			STREAM_IN_DAT=>STREAM_IN,
			CLK=>CLK,
			RST=>RST
			);


clk_proc : PROCESS
	BEGIN
		CLK<='0';
		wait for 2.5 ns; 
		CLK<='1';
		wait for 2.5 ns; 
	END PROCESS;


  --  Test Bench Statements
     tb : PROCESS
     BEGIN
		RST<='1';
      wait for 10 ns; -- wait until global set/reset completes
		RST<='0';

		axis32_write_buffer(TEST_DATA1,STREAM_IN,CLK);
		
        -- Add user defined stimulus here

        wait; -- will wait forever
     END PROCESS tb;
  --  End Test Bench 

  END;
