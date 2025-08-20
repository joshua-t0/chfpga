  sysgen_dut : entity xil_defaultlib.hirax_bit_growth 
  port map (
    pol_in1 => pol_in1,
    pol_in2 => pol_in2,
    pol_in3 => pol_in3,
    pol_in4 => pol_in4,
    shift => shift,
    sync_in => sync_in,
    clk => clk,
    out00 => out00,
    out01 => out01,
    overflow => overflow,
    sync_out => sync_out,
    gateway_out1 => gateway_out1,
    gateway_out11 => gateway_out11,
    gateway_out2 => gateway_out2,
    gateway_out3 => gateway_out3,
    gateway_out4 => gateway_out4,
    gateway_out1_x0 => gateway_out1_x0,
    gateway_out2_x0 => gateway_out2_x0,
    gateway_out3_x0 => gateway_out3_x0,
    gateway_out1_x1 => gateway_out1_x1,
    gateway_out11_x0 => gateway_out11_x0
  );
