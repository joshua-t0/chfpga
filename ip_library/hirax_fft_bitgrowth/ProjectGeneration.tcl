# Note: This file is produced automatically, and will be overwritten the next
# time you press "Generate" in System Generator. 
#


namespace eval ::xilinx::dsp::planaheaddriver {
	set Compilation {HDL Netlist}
	set CompilationFlow {STANDARD}
	set DSPDevice {xc7k480ti}
	set DSPFamily {kintex7}
	set DSPPackage {ffv1156}
	set DSPSpeed {-2L}
	set FPGAClockPeriod 10
	set GenerateTestBench 0
	set HDLLanguage {vhdl}
	set IPOOCCacheRootPath {/home/vbidula/.Xilinx/Sysgen/SysgenVivado/lnx64.o/ip}
	set ImplStrategyName {Vivado Implementation Defaults}
	set Project {hirax_bit_growth}
	set ProjectFiles {
		{{conv_pkg.vhd} -lib {xil_defaultlib}}
		{{synth_reg.vhd} -lib {xil_defaultlib}}
		{{synth_reg_w_init.vhd} -lib {xil_defaultlib}}
		{{srl17e.vhd} -lib {xil_defaultlib}}
		{{srl33e.vhd} -lib {xil_defaultlib}}
		{{synth_reg_reg.vhd} -lib {xil_defaultlib}}
		{{single_reg_w_init.vhd} -lib {xil_defaultlib}}
		{{xlclockdriver_rd.vhd} -lib {xil_defaultlib}}
		{{xpm_4dd9cf_vivado.mem}}
		{{vivado_ip.tcl}}
		{{xpm_a6dbfc_vivado.mem}}
		{{xpm_73d646_vivado.mem}}
		{{xpm_53c368_vivado.mem}}
		{{hirax_bit_growth_dist_mem_gen_i0_vivado.coe}}
		{{hirax_bit_growth_dist_mem_gen_i1_vivado.coe}}
		{{hirax_bit_growth_dist_mem_gen_i2_vivado.coe}}
		{{xpm_effb0c_vivado.mem}}
		{{xpm_98f453_vivado.mem}}
		{{xpm_cb2434_vivado.mem}}
		{{xpm_45185a_vivado.mem}}
		{{xpm_a54c85_vivado.mem}}
		{{hirax_bit_growth_dist_mem_gen_i3_vivado.coe}}
		{{xpm_507089_vivado.mem}}
		{{xpm_955c94_vivado.mem}}
		{{xpm_32b33c_vivado.mem}}
		{{xpm_49a434_vivado.mem}}
		{{xpm_c4ecb4_vivado.mem}}
		{{xpm_22b535_vivado.mem}}
		{{xpm_f6cc85_vivado.mem}}
		{{xpm_6d4459_vivado.mem}}
		{{xpm_001a30_vivado.mem}}
		{{xpm_1066a8_vivado.mem}}
		{{xpm_049b19_vivado.mem}}
		{{xpm_3a6f77_vivado.mem}}
		{{xpm_f26a69_vivado.mem}}
		{{xpm_26a3eb_vivado.mem}}
		{{xpm_592097_vivado.mem}}
		{{xpm_b16998_vivado.mem}}
		{{xpm_b18b84_vivado.mem}}
		{{xpm_9eab54_vivado.mem}}
		{{xpm_c48330_vivado.mem}}
		{{hirax_bit_growth_entity_declarations.vhd} -lib {xil_defaultlib}}
		{{hirax_bit_growth.vhd} -lib {xil_defaultlib}}
		{{hirax_bit_growth_clock.xdc}}
		{{hirax_bit_growth.xdc}}
	}
	set SimPeriod 1
	set SimTime 6144
	set SimulationTime {61650.00000000 ns}
	set SynthStrategyName {Vivado Synthesis Defaults}
	set SynthesisTool {Vivado}
	set TargetDir {/home/vbidula/casper/simulations/netlist_bit_growth}
	set TopLevelModule {hirax_bit_growth}
	set TopLevelSimulinkHandle 0.000244141
	set VHDLLib {xil_defaultlib}
	set TopLevelPortInterface {}
	dict set TopLevelPortInterface sync_in Name {sync_in}
	dict set TopLevelPortInterface sync_in Type Bool
	dict set TopLevelPortInterface sync_in ArithmeticType xlUnsigned
	dict set TopLevelPortInterface sync_in BinaryPoint 0
	dict set TopLevelPortInterface sync_in Width 1
	dict set TopLevelPortInterface sync_in DatFile {hirax_bit_growth_sync_in.dat}
	dict set TopLevelPortInterface sync_in IconText {sync_in}
	dict set TopLevelPortInterface sync_in Direction in
	dict set TopLevelPortInterface sync_in Period 1
	dict set TopLevelPortInterface sync_in Interface 0
	dict set TopLevelPortInterface sync_in InterfaceName {}
	dict set TopLevelPortInterface sync_in InterfaceString {DATA}
	dict set TopLevelPortInterface sync_in ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface sync_in Locs {}
	dict set TopLevelPortInterface sync_in IOStandard {}
	dict set TopLevelPortInterface shift Name {shift}
	dict set TopLevelPortInterface shift Type UFix_11_0
	dict set TopLevelPortInterface shift ArithmeticType xlUnsigned
	dict set TopLevelPortInterface shift BinaryPoint 0
	dict set TopLevelPortInterface shift Width 11
	dict set TopLevelPortInterface shift DatFile {hirax_bit_growth_shift.dat}
	dict set TopLevelPortInterface shift IconText {shift}
	dict set TopLevelPortInterface shift Direction in
	dict set TopLevelPortInterface shift Period 1
	dict set TopLevelPortInterface shift Interface 0
	dict set TopLevelPortInterface shift InterfaceName {}
	dict set TopLevelPortInterface shift InterfaceString {DATA}
	dict set TopLevelPortInterface shift ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface shift Locs {}
	dict set TopLevelPortInterface shift IOStandard {}
	dict set TopLevelPortInterface pol_in4 Name {pol_in4}
	dict set TopLevelPortInterface pol_in4 Type Fix_8_0
	dict set TopLevelPortInterface pol_in4 ArithmeticType xlSigned
	dict set TopLevelPortInterface pol_in4 BinaryPoint 0
	dict set TopLevelPortInterface pol_in4 Width 8
	dict set TopLevelPortInterface pol_in4 DatFile {hirax_bit_growth_pol_in4.dat}
	dict set TopLevelPortInterface pol_in4 IconText {pol_in4}
	dict set TopLevelPortInterface pol_in4 Direction in
	dict set TopLevelPortInterface pol_in4 Period 1
	dict set TopLevelPortInterface pol_in4 Interface 0
	dict set TopLevelPortInterface pol_in4 InterfaceName {}
	dict set TopLevelPortInterface pol_in4 InterfaceString {DATA}
	dict set TopLevelPortInterface pol_in4 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface pol_in4 Locs {}
	dict set TopLevelPortInterface pol_in4 IOStandard {}
	dict set TopLevelPortInterface pol_in3 Name {pol_in3}
	dict set TopLevelPortInterface pol_in3 Type Fix_8_0
	dict set TopLevelPortInterface pol_in3 ArithmeticType xlSigned
	dict set TopLevelPortInterface pol_in3 BinaryPoint 0
	dict set TopLevelPortInterface pol_in3 Width 8
	dict set TopLevelPortInterface pol_in3 DatFile {hirax_bit_growth_pol_in3.dat}
	dict set TopLevelPortInterface pol_in3 IconText {pol_in3}
	dict set TopLevelPortInterface pol_in3 Direction in
	dict set TopLevelPortInterface pol_in3 Period 1
	dict set TopLevelPortInterface pol_in3 Interface 0
	dict set TopLevelPortInterface pol_in3 InterfaceName {}
	dict set TopLevelPortInterface pol_in3 InterfaceString {DATA}
	dict set TopLevelPortInterface pol_in3 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface pol_in3 Locs {}
	dict set TopLevelPortInterface pol_in3 IOStandard {}
	dict set TopLevelPortInterface pol_in2 Name {pol_in2}
	dict set TopLevelPortInterface pol_in2 Type Fix_8_0
	dict set TopLevelPortInterface pol_in2 ArithmeticType xlSigned
	dict set TopLevelPortInterface pol_in2 BinaryPoint 0
	dict set TopLevelPortInterface pol_in2 Width 8
	dict set TopLevelPortInterface pol_in2 DatFile {hirax_bit_growth_pol_in2.dat}
	dict set TopLevelPortInterface pol_in2 IconText {pol_in2}
	dict set TopLevelPortInterface pol_in2 Direction in
	dict set TopLevelPortInterface pol_in2 Period 1
	dict set TopLevelPortInterface pol_in2 Interface 0
	dict set TopLevelPortInterface pol_in2 InterfaceName {}
	dict set TopLevelPortInterface pol_in2 InterfaceString {DATA}
	dict set TopLevelPortInterface pol_in2 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface pol_in2 Locs {}
	dict set TopLevelPortInterface pol_in2 IOStandard {}
	dict set TopLevelPortInterface pol_in1 Name {pol_in1}
	dict set TopLevelPortInterface pol_in1 Type Fix_8_0
	dict set TopLevelPortInterface pol_in1 ArithmeticType xlSigned
	dict set TopLevelPortInterface pol_in1 BinaryPoint 0
	dict set TopLevelPortInterface pol_in1 Width 8
	dict set TopLevelPortInterface pol_in1 DatFile {hirax_bit_growth_pol_in1.dat}
	dict set TopLevelPortInterface pol_in1 IconText {pol_in1}
	dict set TopLevelPortInterface pol_in1 Direction in
	dict set TopLevelPortInterface pol_in1 Period 1
	dict set TopLevelPortInterface pol_in1 Interface 0
	dict set TopLevelPortInterface pol_in1 InterfaceName {}
	dict set TopLevelPortInterface pol_in1 InterfaceString {DATA}
	dict set TopLevelPortInterface pol_in1 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface pol_in1 Locs {}
	dict set TopLevelPortInterface pol_in1 IOStandard {}
	dict set TopLevelPortInterface out00 Name {out00}
	dict set TopLevelPortInterface out00 Type UFix_58_0
	dict set TopLevelPortInterface out00 ArithmeticType xlUnsigned
	dict set TopLevelPortInterface out00 BinaryPoint 0
	dict set TopLevelPortInterface out00 Width 58
	dict set TopLevelPortInterface out00 DatFile {hirax_bit_growth_out00.dat}
	dict set TopLevelPortInterface out00 IconText {out00}
	dict set TopLevelPortInterface out00 Direction out
	dict set TopLevelPortInterface out00 Period 1
	dict set TopLevelPortInterface out00 Interface 0
	dict set TopLevelPortInterface out00 InterfaceName {}
	dict set TopLevelPortInterface out00 InterfaceString {DATA}
	dict set TopLevelPortInterface out00 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface out00 Locs {}
	dict set TopLevelPortInterface out00 IOStandard {}
	dict set TopLevelPortInterface out01 Name {out01}
	dict set TopLevelPortInterface out01 Type UFix_58_0
	dict set TopLevelPortInterface out01 ArithmeticType xlUnsigned
	dict set TopLevelPortInterface out01 BinaryPoint 0
	dict set TopLevelPortInterface out01 Width 58
	dict set TopLevelPortInterface out01 DatFile {hirax_bit_growth_out01.dat}
	dict set TopLevelPortInterface out01 IconText {out01}
	dict set TopLevelPortInterface out01 Direction out
	dict set TopLevelPortInterface out01 Period 1
	dict set TopLevelPortInterface out01 Interface 0
	dict set TopLevelPortInterface out01 InterfaceName {}
	dict set TopLevelPortInterface out01 InterfaceString {DATA}
	dict set TopLevelPortInterface out01 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface out01 Locs {}
	dict set TopLevelPortInterface out01 IOStandard {}
	dict set TopLevelPortInterface overflow Name {overflow}
	dict set TopLevelPortInterface overflow Type UFix_1_0
	dict set TopLevelPortInterface overflow ArithmeticType xlUnsigned
	dict set TopLevelPortInterface overflow BinaryPoint 0
	dict set TopLevelPortInterface overflow Width 1
	dict set TopLevelPortInterface overflow DatFile {hirax_bit_growth_overflow.dat}
	dict set TopLevelPortInterface overflow IconText {overflow}
	dict set TopLevelPortInterface overflow Direction out
	dict set TopLevelPortInterface overflow Period 1
	dict set TopLevelPortInterface overflow Interface 0
	dict set TopLevelPortInterface overflow InterfaceName {}
	dict set TopLevelPortInterface overflow InterfaceString {DATA}
	dict set TopLevelPortInterface overflow ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface overflow Locs {}
	dict set TopLevelPortInterface overflow IOStandard {}
	dict set TopLevelPortInterface sync_out Name {sync_out}
	dict set TopLevelPortInterface sync_out Type Bool
	dict set TopLevelPortInterface sync_out ArithmeticType xlUnsigned
	dict set TopLevelPortInterface sync_out BinaryPoint 0
	dict set TopLevelPortInterface sync_out Width 1
	dict set TopLevelPortInterface sync_out DatFile {hirax_bit_growth_sync_out.dat}
	dict set TopLevelPortInterface sync_out IconText {sync_out}
	dict set TopLevelPortInterface sync_out Direction out
	dict set TopLevelPortInterface sync_out Period 1
	dict set TopLevelPortInterface sync_out Interface 0
	dict set TopLevelPortInterface sync_out InterfaceName {}
	dict set TopLevelPortInterface sync_out InterfaceString {DATA}
	dict set TopLevelPortInterface sync_out ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface sync_out Locs {}
	dict set TopLevelPortInterface sync_out IOStandard {}
	dict set TopLevelPortInterface gateway_out1 Name {gateway_out1}
	dict set TopLevelPortInterface gateway_out1 Type Fix_26_24
	dict set TopLevelPortInterface gateway_out1 ArithmeticType xlSigned
	dict set TopLevelPortInterface gateway_out1 BinaryPoint 24
	dict set TopLevelPortInterface gateway_out1 Width 26
	dict set TopLevelPortInterface gateway_out1 DatFile {hirax_bit_growth_pfb_fir_real_gateway_out1.dat}
	dict set TopLevelPortInterface gateway_out1 IconText {hirax_bit_growth/pfb_fir_real/Gateway Out1}
	dict set TopLevelPortInterface gateway_out1 Direction out
	dict set TopLevelPortInterface gateway_out1 Period 1
	dict set TopLevelPortInterface gateway_out1 Interface 0
	dict set TopLevelPortInterface gateway_out1 InterfaceName {}
	dict set TopLevelPortInterface gateway_out1 InterfaceString {DATA}
	dict set TopLevelPortInterface gateway_out1 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface gateway_out1 Locs {}
	dict set TopLevelPortInterface gateway_out1 IOStandard {}
	dict set TopLevelPortInterface gateway_out11 Name {gateway_out11}
	dict set TopLevelPortInterface gateway_out11 Type Fix_8_0
	dict set TopLevelPortInterface gateway_out11 ArithmeticType xlSigned
	dict set TopLevelPortInterface gateway_out11 BinaryPoint 0
	dict set TopLevelPortInterface gateway_out11 Width 8
	dict set TopLevelPortInterface gateway_out11 DatFile {hirax_bit_growth_pfb_fir_real_gateway_out11.dat}
	dict set TopLevelPortInterface gateway_out11 IconText {hirax_bit_growth/pfb_fir_real/Gateway Out11}
	dict set TopLevelPortInterface gateway_out11 Direction out
	dict set TopLevelPortInterface gateway_out11 Period 1
	dict set TopLevelPortInterface gateway_out11 Interface 0
	dict set TopLevelPortInterface gateway_out11 InterfaceName {}
	dict set TopLevelPortInterface gateway_out11 InterfaceString {DATA}
	dict set TopLevelPortInterface gateway_out11 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface gateway_out11 Locs {}
	dict set TopLevelPortInterface gateway_out11 IOStandard {}
	dict set TopLevelPortInterface gateway_out2 Name {gateway_out2}
	dict set TopLevelPortInterface gateway_out2 Type Fix_26_24
	dict set TopLevelPortInterface gateway_out2 ArithmeticType xlSigned
	dict set TopLevelPortInterface gateway_out2 BinaryPoint 24
	dict set TopLevelPortInterface gateway_out2 Width 26
	dict set TopLevelPortInterface gateway_out2 DatFile {hirax_bit_growth_pfb_fir_real_gateway_out2.dat}
	dict set TopLevelPortInterface gateway_out2 IconText {hirax_bit_growth/pfb_fir_real/Gateway Out2}
	dict set TopLevelPortInterface gateway_out2 Direction out
	dict set TopLevelPortInterface gateway_out2 Period 1
	dict set TopLevelPortInterface gateway_out2 Interface 0
	dict set TopLevelPortInterface gateway_out2 InterfaceName {}
	dict set TopLevelPortInterface gateway_out2 InterfaceString {DATA}
	dict set TopLevelPortInterface gateway_out2 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface gateway_out2 Locs {}
	dict set TopLevelPortInterface gateway_out2 IOStandard {}
	dict set TopLevelPortInterface gateway_out3 Name {gateway_out3}
	dict set TopLevelPortInterface gateway_out3 Type Fix_26_24
	dict set TopLevelPortInterface gateway_out3 ArithmeticType xlSigned
	dict set TopLevelPortInterface gateway_out3 BinaryPoint 24
	dict set TopLevelPortInterface gateway_out3 Width 26
	dict set TopLevelPortInterface gateway_out3 DatFile {hirax_bit_growth_pfb_fir_real_gateway_out3.dat}
	dict set TopLevelPortInterface gateway_out3 IconText {hirax_bit_growth/pfb_fir_real/Gateway Out3}
	dict set TopLevelPortInterface gateway_out3 Direction out
	dict set TopLevelPortInterface gateway_out3 Period 1
	dict set TopLevelPortInterface gateway_out3 Interface 0
	dict set TopLevelPortInterface gateway_out3 InterfaceName {}
	dict set TopLevelPortInterface gateway_out3 InterfaceString {DATA}
	dict set TopLevelPortInterface gateway_out3 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface gateway_out3 Locs {}
	dict set TopLevelPortInterface gateway_out3 IOStandard {}
	dict set TopLevelPortInterface gateway_out4 Name {gateway_out4}
	dict set TopLevelPortInterface gateway_out4 Type Fix_26_24
	dict set TopLevelPortInterface gateway_out4 ArithmeticType xlSigned
	dict set TopLevelPortInterface gateway_out4 BinaryPoint 24
	dict set TopLevelPortInterface gateway_out4 Width 26
	dict set TopLevelPortInterface gateway_out4 DatFile {hirax_bit_growth_pfb_fir_real_gateway_out4.dat}
	dict set TopLevelPortInterface gateway_out4 IconText {Gateway Out4}
	dict set TopLevelPortInterface gateway_out4 Direction out
	dict set TopLevelPortInterface gateway_out4 Period 1
	dict set TopLevelPortInterface gateway_out4 Interface 0
	dict set TopLevelPortInterface gateway_out4 InterfaceName {}
	dict set TopLevelPortInterface gateway_out4 InterfaceString {DATA}
	dict set TopLevelPortInterface gateway_out4 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface gateway_out4 Locs {}
	dict set TopLevelPortInterface gateway_out4 IOStandard {}
	dict set TopLevelPortInterface gateway_out1_x0 Name {gateway_out1_x0}
	dict set TopLevelPortInterface gateway_out1_x0 Type Fix_26_24
	dict set TopLevelPortInterface gateway_out1_x0 ArithmeticType xlSigned
	dict set TopLevelPortInterface gateway_out1_x0 BinaryPoint 24
	dict set TopLevelPortInterface gateway_out1_x0 Width 26
	dict set TopLevelPortInterface gateway_out1_x0 DatFile {hirax_bit_growth_pfb_fir_real_adder_1_1_gateway_out1.dat}
	dict set TopLevelPortInterface gateway_out1_x0 IconText {hirax_bit_growth/pfb_fir_real/adder_1_1/Gateway Out1}
	dict set TopLevelPortInterface gateway_out1_x0 Direction out
	dict set TopLevelPortInterface gateway_out1_x0 Period 1
	dict set TopLevelPortInterface gateway_out1_x0 Interface 0
	dict set TopLevelPortInterface gateway_out1_x0 InterfaceName {}
	dict set TopLevelPortInterface gateway_out1_x0 InterfaceString {DATA}
	dict set TopLevelPortInterface gateway_out1_x0 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface gateway_out1_x0 Locs {}
	dict set TopLevelPortInterface gateway_out1_x0 IOStandard {}
	dict set TopLevelPortInterface gateway_out2_x0 Name {gateway_out2_x0}
	dict set TopLevelPortInterface gateway_out2_x0 Type Fix_26_24
	dict set TopLevelPortInterface gateway_out2_x0 ArithmeticType xlSigned
	dict set TopLevelPortInterface gateway_out2_x0 BinaryPoint 24
	dict set TopLevelPortInterface gateway_out2_x0 Width 26
	dict set TopLevelPortInterface gateway_out2_x0 DatFile {hirax_bit_growth_pfb_fir_real_adder_1_1_gateway_out2.dat}
	dict set TopLevelPortInterface gateway_out2_x0 IconText {hirax_bit_growth/pfb_fir_real/adder_1_1/Gateway Out2}
	dict set TopLevelPortInterface gateway_out2_x0 Direction out
	dict set TopLevelPortInterface gateway_out2_x0 Period 1
	dict set TopLevelPortInterface gateway_out2_x0 Interface 0
	dict set TopLevelPortInterface gateway_out2_x0 InterfaceName {}
	dict set TopLevelPortInterface gateway_out2_x0 InterfaceString {DATA}
	dict set TopLevelPortInterface gateway_out2_x0 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface gateway_out2_x0 Locs {}
	dict set TopLevelPortInterface gateway_out2_x0 IOStandard {}
	dict set TopLevelPortInterface gateway_out3_x0 Name {gateway_out3_x0}
	dict set TopLevelPortInterface gateway_out3_x0 Type Fix_26_24
	dict set TopLevelPortInterface gateway_out3_x0 ArithmeticType xlSigned
	dict set TopLevelPortInterface gateway_out3_x0 BinaryPoint 24
	dict set TopLevelPortInterface gateway_out3_x0 Width 26
	dict set TopLevelPortInterface gateway_out3_x0 DatFile {hirax_bit_growth_pfb_fir_real_adder_1_1_gateway_out3.dat}
	dict set TopLevelPortInterface gateway_out3_x0 IconText {hirax_bit_growth/pfb_fir_real/adder_1_1/Gateway Out3}
	dict set TopLevelPortInterface gateway_out3_x0 Direction out
	dict set TopLevelPortInterface gateway_out3_x0 Period 1
	dict set TopLevelPortInterface gateway_out3_x0 Interface 0
	dict set TopLevelPortInterface gateway_out3_x0 InterfaceName {}
	dict set TopLevelPortInterface gateway_out3_x0 InterfaceString {DATA}
	dict set TopLevelPortInterface gateway_out3_x0 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface gateway_out3_x0 Locs {}
	dict set TopLevelPortInterface gateway_out3_x0 IOStandard {}
	dict set TopLevelPortInterface gateway_out1_x1 Name {gateway_out1_x1}
	dict set TopLevelPortInterface gateway_out1_x1 Type Fix_8_7
	dict set TopLevelPortInterface gateway_out1_x1 ArithmeticType xlSigned
	dict set TopLevelPortInterface gateway_out1_x1 BinaryPoint 7
	dict set TopLevelPortInterface gateway_out1_x1 Width 8
	dict set TopLevelPortInterface gateway_out1_x1 DatFile {hirax_bit_growth_pfb_fir_real_pol1_in1_first_tap_gateway_out1.dat}
	dict set TopLevelPortInterface gateway_out1_x1 IconText {hirax_bit_growth/pfb_fir_real/pol1_in1_first_tap/Gateway Out1}
	dict set TopLevelPortInterface gateway_out1_x1 Direction out
	dict set TopLevelPortInterface gateway_out1_x1 Period 1
	dict set TopLevelPortInterface gateway_out1_x1 Interface 0
	dict set TopLevelPortInterface gateway_out1_x1 InterfaceName {}
	dict set TopLevelPortInterface gateway_out1_x1 InterfaceString {DATA}
	dict set TopLevelPortInterface gateway_out1_x1 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface gateway_out1_x1 Locs {}
	dict set TopLevelPortInterface gateway_out1_x1 IOStandard {}
	dict set TopLevelPortInterface gateway_out11_x0 Name {gateway_out11_x0}
	dict set TopLevelPortInterface gateway_out11_x0 Type Fix_18_17
	dict set TopLevelPortInterface gateway_out11_x0 ArithmeticType xlSigned
	dict set TopLevelPortInterface gateway_out11_x0 BinaryPoint 17
	dict set TopLevelPortInterface gateway_out11_x0 Width 18
	dict set TopLevelPortInterface gateway_out11_x0 DatFile {hirax_bit_growth_pfb_fir_real_pol1_in1_first_tap_gateway_out11.dat}
	dict set TopLevelPortInterface gateway_out11_x0 IconText {hirax_bit_growth/pfb_fir_real/pol1_in1_first_tap/Gateway Out11}
	dict set TopLevelPortInterface gateway_out11_x0 Direction out
	dict set TopLevelPortInterface gateway_out11_x0 Period 1
	dict set TopLevelPortInterface gateway_out11_x0 Interface 0
	dict set TopLevelPortInterface gateway_out11_x0 InterfaceName {}
	dict set TopLevelPortInterface gateway_out11_x0 InterfaceString {DATA}
	dict set TopLevelPortInterface gateway_out11_x0 ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface gateway_out11_x0 Locs {}
	dict set TopLevelPortInterface gateway_out11_x0 IOStandard {}
	dict set TopLevelPortInterface clk Name {clk}
	dict set TopLevelPortInterface clk Type -
	dict set TopLevelPortInterface clk ArithmeticType xlUnsigned
	dict set TopLevelPortInterface clk BinaryPoint 0
	dict set TopLevelPortInterface clk Width 1
	dict set TopLevelPortInterface clk DatFile {}
	dict set TopLevelPortInterface clk Direction in
	dict set TopLevelPortInterface clk Period 1
	dict set TopLevelPortInterface clk Interface 6
	dict set TopLevelPortInterface clk InterfaceName {}
	dict set TopLevelPortInterface clk InterfaceString {CLOCK}
	dict set TopLevelPortInterface clk ClockDomain {hirax_bit_growth}
	dict set TopLevelPortInterface clk Locs {}
	dict set TopLevelPortInterface clk IOStandard {}
	dict set TopLevelPortInterface clk AssociatedInterfaces {}
	dict set TopLevelPortInterface clk AssociatedResets {}
	set MemoryMappedPort {}
}

source SgPaProject.tcl
::xilinx::dsp::planaheadworker::dsp_create_project