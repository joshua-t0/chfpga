  sysgen_dut : entity xil_defaultlib.hirax_3dsp 
  port map (
    gateway_in5 => gateway_in5,
    pol_in1 => pol_in1,
    pol_in2 => pol_in2,
    pol_in3 => pol_in3,
    pol_in4 => pol_in4,
    sync_in => sync_in,
    clk => clk,
    out_00 => out_00,
    out_01 => out_01,
    overflow => overflow,
    sync_out => sync_out
  );
