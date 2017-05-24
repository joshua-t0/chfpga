
library ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_complex.ALL;

use work.chFPGA_Package.all;
use work.tb_package.all;


ENTITY cmac_testbench IS
END cmac_testbench;

ARCHITECTURE behavior OF cmac_testbench IS

signal CLK :  std_logic;
signal a,b,c,d: signed(3 downto 0);
signal re,im,re2,im2,re2_inv: signed(17 downto 0);
signal RST :  std_logic;
type cplx_type is array (natural range <>) of integer_array(0 to 3);
signal tvalid, tlast, last_frame: std_logic:='0';
signal tdata: slv(15 downto 0);
signal z_out_tvalid: std_logic;
signal z_out_tlast: std_logic;
signal z_out_tdata: std_logic_vector(35 downto 0);
signal send: std_logic;
signal local_data: std_logic;
signal z_out_re, z_out_im: integer;
signal chan, bin: integer;
signal z, zz: complex;
signal x,y: complex;

constant INTEGRATION_PERIOD: integer := 3000;
constant BINS_PER_FRAME: integer := 2;
constant PRODUCTS_PER_BIN: integer := 4;
constant X_FN: string := "-8j";
constant Y_FN: string := "-8j";

constant test_data: cplx_type:=(
	(1,1,1,1),
	(1,0,1,0)
	);

signal c1,c2,c3,c4,c5,c6,c7,c8: complex;
signal valid: std_logic;

function fn(func: string; frame, bin, chan: integer) return complex is
	variable x: signed(7 downto 0);
	variable a,b: signed(3 downto 0);
	variable r: complex;
begin
	if func = "i" then
		r := CMPLX(0, 1);
	elsif func = "1" then
		r := CMPLX(1, 0);
	elsif func = "128j" then
		r := CMPLX(-8, -8);
	elsif func = "128j" then
		r := CMPLX(-8, -8);
	elsif func = "-98j" then
		r := CMPLX(7, -7);
	elsif func = "-8" then
		r := CMPLX(-8, 0);
	elsif func = "-8j" then
		r := CMPLX(0, -8);
	elsif func = "-1" then
		r := CMPLX(-1, 0);
	elsif func = "all" then
		x := to_signed((chan+bin*PRODUCTS_PER_BIN+frame*BINS_PER_FRAME*PRODUCTS_PER_BIN) mod 256,8);
		r := CMPLX(x(3 downto 0), x(7 downto 4));
	elsif func = "f1" then
		r := CMPLX(chan, chan);
	elsif func = "chan" then
		r := CMPLX(chan, 0);
	else
		assert False report "Bad function type" severity failure;
	end if;

	assert r.RE>=-8.0 and r.RE<=7.0  report "Invalid real value" severity failure;
	assert r.IM>=-8.0 and r.IM<=7.0  report "Invalid imaginary value" severity failure;
	a := to_signed(integer(r.RE), 4);
	b := to_signed(integer(r.IM), 4);
	return CMPLX(a,b);
end fn;


begin


-- x <= std_logic_vector(a & b);
-- y <= std_logic_vector(c & d);
-- Component Instantiation
cmac0: entity work.cmac44
	PORT MAP(

		s_axis_xy_tvalid     => tvalid,
		s_axis_xy_tlast      => tlast,
		s_axis_xy_last_frame => last_frame,
		s_axis_xy_tdata      => tdata,
		re2                  => re2,
		im2                  => im2,
		m_axis_z_out_tdata   => z_out_tdata,
		m_axis_z_out_tvalid  => z_out_tvalid,
		m_axis_z_out_tlast   => z_out_tlast,
		m_axis_z_out_send    => send,
		m_axis_z_out_start => local_data,
		m_axis_z_out_local_data => local_data,

		clk                  => clk,
		rst                  => rst
		);

re2_inv <= -re2;
z_out_re <= to_integer(signed(z_out_tdata(35 downto 18)));
z_out_im <= to_integer(signed(z_out_tdata(17 downto 0)));
tdata <= to_slv(x.RE, 4) & to_slv(x.IM, 4) & to_slv(y.RE, 4) & to_slv(y.IM, 4);

clk_proc : PROCESS
	BEGIN
		CLK<='0';
		wait for 2.5 ns;
		CLK<='1';
		wait for 2.5 ns;
	END PROCESS;

--check: process(clk)
--begin
--	if rising_edge(clk) then
--	c1 <= complex'(real(to_integer(a)), real(to_integer(b))) * complex'(real(to_integer(c)), real(to_integer(d)));
--	c2 <=c1;
--  c3 <=c2;
--  c4 <=c3;
--  -- c5 <=c4;
--  -- c6 <=c5;
--  -- c7 <=c6;
--  -- c8 <=c7;
--  valid <= to_std_logic(integer(c4.re) = -to_integer(re2) and integer(c4.im) = to_integer(im2));
--	end if;

--end process;

readout_send: process
begin
	send <= '0';
	for i in 0 to 0 loop
		wait until clk='1';
	end loop;
	send <= '1';
	wait until clk='1';
end process;

readout_data: process(clk)
variable x,y, xy, z_var, zz_var: complex;
begin
	if rising_edge(clk) then
		if z_out_tvalid='1' then
			z_var := CMPLX(signed(z_out_tdata(35 downto 18)), signed(z_out_tdata(17 downto 0)));
			zz_var := CMPLX(0, 0);
			for frame in 0 to INTEGRATION_PERIOD-1 loop
				x := fn(X_FN, frame, BINS_PER_FRAME-1-bin, PRODUCTS_PER_BIN-1-chan);
				y := fn(Y_FN, frame, BINS_PER_FRAME-1-bin, PRODUCTS_PER_BIN-1-chan);
				xy := x*y;
				--report "x*y=" & real'image(xy.RE) & "+" & real'image(xy.IM) & "i";
				zz_var := zz_var + (x * y);
				--report "zz=" & real'image(zz_var.RE) & "+" & real'image(zz_var.IM) & "i";
			end loop;
			z <= z_var;
			zz <= zz_var;
			valid <= to_std_logic(zz_var = z_var);
			chan <= chan + 1;
			if chan = PRODUCTS_PER_BIN-1 then
				chan <= 0;
				bin <= bin + 1;
				--if bin = BINS_PER_FRAME-1 then
				--	bin <= 0;
				--end if;
			end if;
			if z_out_tlast='1' then
				chan <= 0;
				bin <= 0;
			end if;
		end if;
		if rst='1' then
			bin <= 0;
			chan <= 0;
		end if;
	end if; --clk
end process;

  --  Test Bench Statements
tb: process
	 --variable x, y: complex;
begin
	a <= "0000";
	b <= "0000";
	c <= "0000";
	d <= "0000";
	rst <= '1';
	wait until clk='1'; -- wait until global set/reset completes
	wait until clk='1'; -- wait until global set/reset completes
	wait until clk='1'; -- wait until global set/reset completes
	wait until clk='1'; -- wait until global set/reset completes
	wait until clk='1'; -- wait until global set/reset completes
	wait until clk='1'; -- wait until global set/reset completes
	rst <= '0';
	wait until clk='1';
	wait until clk='1';
	wait until clk='1';
	-- for j in 0 to 100 loop
	-- 	for i in 0 to test_data'length-1 loop
	-- 		a <= to_signed(test_data(i)(0),4);
	-- 		b <= to_signed(test_data(i)(1),4);
	-- 		c <= to_signed(test_data(i)(2),4);
	-- 		d <= to_signed(test_data(i)(3),4);
	-- 		wait until clk='1';
	-- 	end loop;
	-- end loop;


	for integ in 0 to 5 loop
		for frame in 0 to INTEGRATION_PERIOD-1 loop

			last_frame <= '0';
			if frame = INTEGRATION_PERIOD-1 then
				last_frame <='1';
			end if;

			for bin in 0 to BINS_PER_FRAME-1 loop

				for chan in 0 to PRODUCTS_PER_BIN-1 loop
					x <= fn(X_FN, frame, bin, chan);
					y <= fn(Y_FN, frame, bin, chan);
					tvalid <= '1';
					tlast <= '0';
					if chan = PRODUCTS_PER_BIN-1 and bin = BINS_PER_FRAME-1 then
						tlast <= '1';
					end if;
					wait until clk='1';
				end loop;
			end loop;
		end loop;
		tvalid <= '0';
		wait until clk='1';
		wait until clk='1';
		wait until clk='1' and z_out_tvalid='1' and z_out_tlast='1';
	end loop;
	wait until clk='1';


	--for aa in -8 to 7 loop
	--	for bb in -8 to 7 loop
	--		for cc in -8 to 7 loop
	--			for dd in -8 to 7 loop
	--				a <= to_signed(aa,4);
	--				b <= to_signed(bb,4);
	--				c <= to_signed(cc,4);
	--				d <= to_signed(dd,4);
	--				wait until clk='1';
	--				wait until clk='1';
	--				wait until clk='1';
	--				wait until clk='1';
	--			end loop;
	--		end loop;
	--	end loop;
	--end loop;
	wait; -- will wait forever
end process tb;
  --  End Test Bench

END;
