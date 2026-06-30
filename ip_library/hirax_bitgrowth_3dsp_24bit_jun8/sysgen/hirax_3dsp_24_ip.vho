  sysgen_dut : entity xil_defaultlib.hirax_3dsp_24_ip 
  port map (
    bitshift => bitshift,
    pol_in_1 => pol_in_1,
    pol_in_2 => pol_in_2,
    pol_in_3 => pol_in_3,
    pol_in_4 => pol_in_4,
    sync_in => sync_in,
    clk => clk,
    out00 => out00,
    out01 => out01,
    overflow => overflow,
    sync_out => sync_out
  );
