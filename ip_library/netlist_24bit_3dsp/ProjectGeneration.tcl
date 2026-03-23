# Note: This file is produced automatically, and will be overwritten the next
# time you press "Generate" in System Generator. 
#


namespace eval ::xilinx::dsp::planaheaddriver {
	set Compilation {HDL Netlist}
	set CompilationFlow {STANDARD}
	set DSPDevice {xc7k325t}
	set DSPFamily {kintex7}
	set DSPPackage {fbg676}
	set DSPSpeed {-3}
	set FPGAClockPeriod 10
	set GenerateTestBench 0
	set HDLLanguage {vhdl}
	set IPOOCCacheRootPath {/home/vbidula/.Xilinx/Sysgen/SysgenVivado/lnx64.o/ip}
	set ImplStrategyName {Vivado Implementation Defaults}
	set Project {hirax_3dsp}
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
		{{hirax_3dsp_dist_mem_gen_i0_vivado.coe}}
		{{hirax_3dsp_dist_mem_gen_i1_vivado.coe}}
		{{hirax_3dsp_dist_mem_gen_i2_vivado.coe}}
		{{xpm_effb0c_vivado.mem}}
		{{xpm_98f453_vivado.mem}}
		{{xpm_cb2434_vivado.mem}}
		{{xpm_45185a_vivado.mem}}
		{{xpm_a54c85_vivado.mem}}
		{{hirax_3dsp_dist_mem_gen_i3_vivado.coe}}
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
		{{hirax_3dsp_entity_declarations.vhd} -lib {xil_defaultlib}}
		{{hirax_3dsp.vhd} -lib {xil_defaultlib}}
		{{hirax_3dsp_clock.xdc}}
		{{hirax_3dsp.xdc}}
	}
	set SimPeriod 1
	set SimTime 6144
	set SimulationTime {61650.00000000 ns}
	set SynthStrategyName {Vivado Synthesis Defaults}
	set SynthesisTool {Vivado}
	set TargetDir {/home/vbidula/casper_3dsp/mlib_devel/hirax_models/netlist_24bit_3dsp}
	set TopLevelModule {hirax_3dsp}
	set TopLevelSimulinkHandle 16853
	set VHDLLib {xil_defaultlib}
	set TopLevelPortInterface {}
	dict set TopLevelPortInterface sync_in Name {sync_in}
	dict set TopLevelPortInterface sync_in Type Bool
	dict set TopLevelPortInterface sync_in ArithmeticType xlUnsigned
	dict set TopLevelPortInterface sync_in BinaryPoint 0
	dict set TopLevelPortInterface sync_in Width 1
	dict set TopLevelPortInterface sync_in DatFile {hirax_3dsp_sync_in.dat}
	dict set TopLevelPortInterface sync_in IconText {sync_in}
	dict set TopLevelPortInterface sync_in Direction in
	dict set TopLevelPortInterface sync_in Period 1
	dict set TopLevelPortInterface sync_in Interface 0
	dict set TopLevelPortInterface sync_in InterfaceName {}
	dict set TopLevelPortInterface sync_in InterfaceString {DATA}
	dict set TopLevelPortInterface sync_in ClockDomain {hirax_3dsp}
	dict set TopLevelPortInterface sync_in Locs {}
	dict set TopLevelPortInterface sync_in IOStandard {}
	dict set TopLevelPortInterface pol_in4 Name {pol_in4}
	dict set TopLevelPortInterface pol_in4 Type Fix_8_0
	dict set TopLevelPortInterface pol_in4 ArithmeticType xlSigned
	dict set TopLevelPortInterface pol_in4 BinaryPoint 0
	dict set TopLevelPortInterface pol_in4 Width 8
	dict set TopLevelPortInterface pol_in4 DatFile {hirax_3dsp_pol_in4.dat}
	dict set TopLevelPortInterface pol_in4 IconText {pol_in4}
	dict set TopLevelPortInterface pol_in4 Direction in
	dict set TopLevelPortInterface pol_in4 Period 1
	dict set TopLevelPortInterface pol_in4 Interface 0
	dict set TopLevelPortInterface pol_in4 InterfaceName {}
	dict set TopLevelPortInterface pol_in4 InterfaceString {DATA}
	dict set TopLevelPortInterface pol_in4 ClockDomain {hirax_3dsp}
	dict set TopLevelPortInterface pol_in4 Locs {}
	dict set TopLevelPortInterface pol_in4 IOStandard {}
	dict set TopLevelPortInterface pol_in3 Name {pol_in3}
	dict set TopLevelPortInterface pol_in3 Type Fix_8_0
	dict set TopLevelPortInterface pol_in3 ArithmeticType xlSigned
	dict set TopLevelPortInterface pol_in3 BinaryPoint 0
	dict set TopLevelPortInterface pol_in3 Width 8
	dict set TopLevelPortInterface pol_in3 DatFile {hirax_3dsp_pol_in3.dat}
	dict set TopLevelPortInterface pol_in3 IconText {pol_in3}
	dict set TopLevelPortInterface pol_in3 Direction in
	dict set TopLevelPortInterface pol_in3 Period 1
	dict set TopLevelPortInterface pol_in3 Interface 0
	dict set TopLevelPortInterface pol_in3 InterfaceName {}
	dict set TopLevelPortInterface pol_in3 InterfaceString {DATA}
	dict set TopLevelPortInterface pol_in3 ClockDomain {hirax_3dsp}
	dict set TopLevelPortInterface pol_in3 Locs {}
	dict set TopLevelPortInterface pol_in3 IOStandard {}
	dict set TopLevelPortInterface pol_in2 Name {pol_in2}
	dict set TopLevelPortInterface pol_in2 Type Fix_8_0
	dict set TopLevelPortInterface pol_in2 ArithmeticType xlSigned
	dict set TopLevelPortInterface pol_in2 BinaryPoint 0
	dict set TopLevelPortInterface pol_in2 Width 8
	dict set TopLevelPortInterface pol_in2 DatFile {hirax_3dsp_pol_in2.dat}
	dict set TopLevelPortInterface pol_in2 IconText {pol_in2}
	dict set TopLevelPortInterface pol_in2 Direction in
	dict set TopLevelPortInterface pol_in2 Period 1
	dict set TopLevelPortInterface pol_in2 Interface 0
	dict set TopLevelPortInterface pol_in2 InterfaceName {}
	dict set TopLevelPortInterface pol_in2 InterfaceString {DATA}
	dict set TopLevelPortInterface pol_in2 ClockDomain {hirax_3dsp}
	dict set TopLevelPortInterface pol_in2 Locs {}
	dict set TopLevelPortInterface pol_in2 IOStandard {}
	dict set TopLevelPortInterface pol_in1 Name {pol_in1}
	dict set TopLevelPortInterface pol_in1 Type Fix_8_0
	dict set TopLevelPortInterface pol_in1 ArithmeticType xlSigned
	dict set TopLevelPortInterface pol_in1 BinaryPoint 0
	dict set TopLevelPortInterface pol_in1 Width 8
	dict set TopLevelPortInterface pol_in1 DatFile {hirax_3dsp_pol_in1.dat}
	dict set TopLevelPortInterface pol_in1 IconText {pol_in1}
	dict set TopLevelPortInterface pol_in1 Direction in
	dict set TopLevelPortInterface pol_in1 Period 1
	dict set TopLevelPortInterface pol_in1 Interface 0
	dict set TopLevelPortInterface pol_in1 InterfaceName {}
	dict set TopLevelPortInterface pol_in1 InterfaceString {DATA}
	dict set TopLevelPortInterface pol_in1 ClockDomain {hirax_3dsp}
	dict set TopLevelPortInterface pol_in1 Locs {}
	dict set TopLevelPortInterface pol_in1 IOStandard {}
	dict set TopLevelPortInterface gateway_in5 Name {gateway_in5}
	dict set TopLevelPortInterface gateway_in5 Type Fix_11_0
	dict set TopLevelPortInterface gateway_in5 ArithmeticType xlSigned
	dict set TopLevelPortInterface gateway_in5 BinaryPoint 0
	dict set TopLevelPortInterface gateway_in5 Width 11
	dict set TopLevelPortInterface gateway_in5 DatFile {hirax_3dsp_gateway_in5.dat}
	dict set TopLevelPortInterface gateway_in5 IconText {Gateway In5}
	dict set TopLevelPortInterface gateway_in5 Direction in
	dict set TopLevelPortInterface gateway_in5 Period 1
	dict set TopLevelPortInterface gateway_in5 Interface 0
	dict set TopLevelPortInterface gateway_in5 InterfaceName {}
	dict set TopLevelPortInterface gateway_in5 InterfaceString {DATA}
	dict set TopLevelPortInterface gateway_in5 ClockDomain {hirax_3dsp}
	dict set TopLevelPortInterface gateway_in5 Locs {}
	dict set TopLevelPortInterface gateway_in5 IOStandard {}
	dict set TopLevelPortInterface out_00 Name {out_00}
	dict set TopLevelPortInterface out_00 Type UFix_48_0
	dict set TopLevelPortInterface out_00 ArithmeticType xlUnsigned
	dict set TopLevelPortInterface out_00 BinaryPoint 0
	dict set TopLevelPortInterface out_00 Width 48
	dict set TopLevelPortInterface out_00 DatFile {hirax_3dsp_out_00.dat}
	dict set TopLevelPortInterface out_00 IconText {out_00}
	dict set TopLevelPortInterface out_00 Direction out
	dict set TopLevelPortInterface out_00 Period 1
	dict set TopLevelPortInterface out_00 Interface 0
	dict set TopLevelPortInterface out_00 InterfaceName {}
	dict set TopLevelPortInterface out_00 InterfaceString {DATA}
	dict set TopLevelPortInterface out_00 ClockDomain {hirax_3dsp}
	dict set TopLevelPortInterface out_00 Locs {}
	dict set TopLevelPortInterface out_00 IOStandard {}
	dict set TopLevelPortInterface out_01 Name {out_01}
	dict set TopLevelPortInterface out_01 Type UFix_48_0
	dict set TopLevelPortInterface out_01 ArithmeticType xlUnsigned
	dict set TopLevelPortInterface out_01 BinaryPoint 0
	dict set TopLevelPortInterface out_01 Width 48
	dict set TopLevelPortInterface out_01 DatFile {hirax_3dsp_out_01.dat}
	dict set TopLevelPortInterface out_01 IconText {out_01}
	dict set TopLevelPortInterface out_01 Direction out
	dict set TopLevelPortInterface out_01 Period 1
	dict set TopLevelPortInterface out_01 Interface 0
	dict set TopLevelPortInterface out_01 InterfaceName {}
	dict set TopLevelPortInterface out_01 InterfaceString {DATA}
	dict set TopLevelPortInterface out_01 ClockDomain {hirax_3dsp}
	dict set TopLevelPortInterface out_01 Locs {}
	dict set TopLevelPortInterface out_01 IOStandard {}
	dict set TopLevelPortInterface overflow Name {overflow}
	dict set TopLevelPortInterface overflow Type UFix_1_0
	dict set TopLevelPortInterface overflow ArithmeticType xlUnsigned
	dict set TopLevelPortInterface overflow BinaryPoint 0
	dict set TopLevelPortInterface overflow Width 1
	dict set TopLevelPortInterface overflow DatFile {hirax_3dsp_overflow.dat}
	dict set TopLevelPortInterface overflow IconText {overflow}
	dict set TopLevelPortInterface overflow Direction out
	dict set TopLevelPortInterface overflow Period 1
	dict set TopLevelPortInterface overflow Interface 0
	dict set TopLevelPortInterface overflow InterfaceName {}
	dict set TopLevelPortInterface overflow InterfaceString {DATA}
	dict set TopLevelPortInterface overflow ClockDomain {hirax_3dsp}
	dict set TopLevelPortInterface overflow Locs {}
	dict set TopLevelPortInterface overflow IOStandard {}
	dict set TopLevelPortInterface sync_out Name {sync_out}
	dict set TopLevelPortInterface sync_out Type Bool
	dict set TopLevelPortInterface sync_out ArithmeticType xlUnsigned
	dict set TopLevelPortInterface sync_out BinaryPoint 0
	dict set TopLevelPortInterface sync_out Width 1
	dict set TopLevelPortInterface sync_out DatFile {hirax_3dsp_sync_out.dat}
	dict set TopLevelPortInterface sync_out IconText {sync_out}
	dict set TopLevelPortInterface sync_out Direction out
	dict set TopLevelPortInterface sync_out Period 1
	dict set TopLevelPortInterface sync_out Interface 0
	dict set TopLevelPortInterface sync_out InterfaceName {}
	dict set TopLevelPortInterface sync_out InterfaceString {DATA}
	dict set TopLevelPortInterface sync_out ClockDomain {hirax_3dsp}
	dict set TopLevelPortInterface sync_out Locs {}
	dict set TopLevelPortInterface sync_out IOStandard {}
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
	dict set TopLevelPortInterface clk ClockDomain {hirax_3dsp}
	dict set TopLevelPortInterface clk Locs {}
	dict set TopLevelPortInterface clk IOStandard {}
	dict set TopLevelPortInterface clk AssociatedInterfaces {}
	dict set TopLevelPortInterface clk AssociatedResets {}
	set MemoryMappedPort {}
}

source SgPaProject.tcl
::xilinx::dsp::planaheadworker::dsp_create_project