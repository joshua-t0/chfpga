set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
#set_param general.maxThreads 4

##################################################################

##################################################################

## Constraints for the KC705 Kintex 7 Evaluation board          ##

##################################################################

##################################################################

set_property IOSTANDARD LVCMOS18 [get_ports SFPCLK_QO_P]
#################################

# TIMING CONSTRAINTS

#################################

# The following is because the SYSCLK BUFG and BUFGMUX on ANT[1].ADCDAQ are not in the same half. Should be f

#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets CLK0/CLK200]

#################################

# LOC CONSTRAINTS

#################################

#set_property LOC DCIRESET_X0Y0 [get_cells REFCLK0/DCIRESET0]

#set_property LOC USR_ACCESS_X0Y0 [get_cells GPIO0/USR_ACCESS0]

#set_property LOC XADC_X0Y0 [get_cells SYSMON0/SYSMON_TIMING_IGNORE]

# Force the CLK0 MMCM to be in the same half of the FPGA as the ADCDAQ PLL so their outputs can reach a single BUFGMUX that select which clock is to be used for data processing. 

#set_property LOC MMCME2_ADV_X0Y4 [get_cells CLK0/CLK200/MMCM0]

#################################

# SYSTEM CLOCK and RESET PINS

#################################

set_property IOSTANDARD LVDS [get_ports SYSCLK_P]
set_property DIFF_TERM FALSE [get_ports SYSCLK_P]
set_property DIFF_TERM FALSE [get_ports SYSCLK_N]
#set_property DIFF_TERM FALSE [get_ports SYSCLK_N]

set_property PACKAGE_PIN AD12 [get_ports SYSCLK_P]
set_property PACKAGE_PIN AD11 [get_ports SYSCLK_N]
set_property PACKAGE_PIN AB7 [get_ports CPU_RESET]
set_property IOSTANDARD LVCMOS15 [get_ports CPU_RESET]
#################################

# KC705 IIC

#################################

# Allows access to the KC705  as well as FMC I2C devices through a I2C switch 

set_property PACKAGE_PIN K21 [get_ports I2C_SCK]
set_property DRIVE 8 [get_ports I2C_SCK]
set_property IOSTANDARD LVCMOS25 [get_ports I2C_SCK]
set_property SLEW SLOW [get_ports I2C_SCK]
set_property PACKAGE_PIN L21 [get_ports I2C_SDA]
set_property DRIVE 8 [get_ports I2C_SDA]
set_property IOSTANDARD LVCMOS25 [get_ports I2C_SDA]
set_property SLEW SLOW [get_ports I2C_SDA]
#################################

# KC705 PMBUS

#################################

set_property PACKAGE_PIN AG17 [get_ports PMBUS_SCK]
set_property DRIVE 8 [get_ports PMBUS_SCK]
set_property IOSTANDARD LVCMOS15 [get_ports PMBUS_SCK]
set_property SLEW SLOW [get_ports PMBUS_SCK]
set_property PACKAGE_PIN Y14 [get_ports PMBUS_SDA]
set_property DRIVE 8 [get_ports PMBUS_SDA]
set_property IOSTANDARD LVCMOS15 [get_ports PMBUS_SDA]
set_property SLEW SLOW [get_ports PMBUS_SDA]
#set_property LOC P23 [ get_ports IIC_MUX_RESET_B[0]]

#set_property IOSTANDARD LVCMOS25 [ get_ports IIC_MUX_RESET_B[0]]

#set_property LOC AE20 [ get_ports IIC_MUX_RESET_B[1]]

#set_property IOSTANDARD LVCMOS25 [ get_ports IIC_MUX_RESET_B[1]]

#################################

# KC705 LED PINS

#################################

# Bank  33 VCCO - VCC1V5_FPGA

set_property IOSTANDARD LVCMOS15 [get_ports {GPIO_LED[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {GPIO_LED[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {GPIO_LED[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {GPIO_LED[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GPIO_LED[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GPIO_LED[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GPIO_LED[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GPIO_LED[7]}]
set_property PACKAGE_PIN AB8 [get_ports {GPIO_LED[0]}]
set_property PACKAGE_PIN AA8 [get_ports {GPIO_LED[1]}]
set_property PACKAGE_PIN AC9 [get_ports {GPIO_LED[2]}]
set_property PACKAGE_PIN AB9 [get_ports {GPIO_LED[3]}]
set_property PACKAGE_PIN AE26 [get_ports {GPIO_LED[4]}]
set_property PACKAGE_PIN G19 [get_ports {GPIO_LED[5]}]
set_property PACKAGE_PIN E18 [get_ports {GPIO_LED[6]}]
set_property PACKAGE_PIN F16 [get_ports {GPIO_LED[7]}]
#################################

# KC705 PUSHBUTTON PINS

#################################

set_property PACKAGE_PIN G12 [get_ports GPIO_BUTTON0]
set_property IOSTANDARD LVCMOS25 [get_ports GPIO_BUTTON0]
#################################

# KC705 DIP Switches

#################################

set_property IOSTANDARD LVCMOS25 [get_ports GPIO_DIP_SW*]
set_property PACKAGE_PIN Y29 [get_ports {GPIO_DIP_SW[0]}]
set_property PACKAGE_PIN W29 [get_ports {GPIO_DIP_SW[1]}]
set_property PACKAGE_PIN AA28 [get_ports {GPIO_DIP_SW[2]}]
set_property PACKAGE_PIN Y28 [get_ports {GPIO_DIP_SW[3]}]
#################################

# KC705 LCD Display PINS

#################################

set_property IOSTANDARD LVCMOS15 [get_ports LCD_*]
set_property PACKAGE_PIN Y11 [get_ports LCD_RS]
set_property PACKAGE_PIN AB13 [get_ports LCD_RW]
set_property PACKAGE_PIN AB10 [get_ports LCD_E]
set_property PACKAGE_PIN AA13 [get_ports {LCD_DB[4]}]
set_property PACKAGE_PIN AA10 [get_ports {LCD_DB[5]}]
set_property PACKAGE_PIN AA11 [get_ports {LCD_DB[6]}]
set_property PACKAGE_PIN Y10 [get_ports {LCD_DB[7]}]
#################################

# KC705 FAN

#################################

set_property IOSTANDARD LVCMOS25 [get_ports FAN_*]
set_property PACKAGE_PIN L26 [get_ports FAN_PWM]
set_property PACKAGE_PIN U22 [get_ports FAN_TACH]
#################################

# KC705 SMA connectors

#################################

set_property IOSTANDARD LVCMOS25 [get_ports USER_SMA_*]
set_property PACKAGE_PIN Y23 [get_ports USER_SMA_GPIO_P]
set_property PACKAGE_PIN Y24 [get_ports USER_SMA_GPIO_N]
set_property PACKAGE_PIN L25 [get_ports USER_SMA_CLOCK_P]
set_property PACKAGE_PIN K25 [get_ports USER_SMA_CLOCK_N]
#################################

# KC705 PHY PINS

#################################

set_property IOSTANDARD LVCMOS25 [get_ports PHY_*]
set_property PACKAGE_PIN U30 [get_ports {PHY_RXD[0]}]
set_property PACKAGE_PIN U25 [get_ports {PHY_RXD[1]}]
set_property PACKAGE_PIN T25 [get_ports {PHY_RXD[2]}]
set_property PACKAGE_PIN U28 [get_ports {PHY_RXD[3]}]
set_property PACKAGE_PIN R19 [get_ports {PHY_RXD[4]}]
set_property PACKAGE_PIN T27 [get_ports {PHY_RXD[5]}]
set_property PACKAGE_PIN T26 [get_ports {PHY_RXD[6]}]
set_property PACKAGE_PIN T28 [get_ports {PHY_RXD[7]}]
set_property PACKAGE_PIN N27 [get_ports {PHY_TXD[0]}]
set_property PACKAGE_PIN N25 [get_ports {PHY_TXD[1]}]
set_property PACKAGE_PIN M29 [get_ports {PHY_TXD[2]}]
set_property PACKAGE_PIN L28 [get_ports {PHY_TXD[3]}]
set_property PACKAGE_PIN J26 [get_ports {PHY_TXD[4]}]
set_property PACKAGE_PIN K26 [get_ports {PHY_TXD[5]}]
set_property PACKAGE_PIN L30 [get_ports {PHY_TXD[6]}]
set_property PACKAGE_PIN J28 [get_ports {PHY_TXD[7]}]
set_property PACKAGE_PIN L20 [get_ports PHY_RESET_L]
set_property PACKAGE_PIN U27 [get_ports PHY_RXCLK]
set_property PACKAGE_PIN R28 [get_ports PHY_RXCTRL_RXDV]
set_property PACKAGE_PIN K30 [get_ports PHY_TXC_GTXCLK]
set_property PACKAGE_PIN M28 [get_ports PHY_TXCLK]
set_property PACKAGE_PIN N29 [get_ports PHY_TXER]
set_property PACKAGE_PIN M27 [get_ports PHY_TXCTL_TXEN]
#################################

# SFP+ PINS

#################################

set_property PACKAGE_PIN P19 [get_ports SFP_LOS]
set_property IOSTANDARD LVCMOS25 [get_ports SFP_LOS]
set_property PACKAGE_PIN H2 [get_ports SFP_TX_P]
set_property PACKAGE_PIN H1 [get_ports SFP_TX_N]
set_property PACKAGE_PIN G3 [get_ports SFP_RX_P]
set_property PACKAGE_PIN G4 [get_ports SFP_RX_N]
# Reference clock for the SFP+: use the lon-board low jitter PLL SI5326 

# On MGTREFCLK0P_116 and MGTREFCLK0N_116

set_property PACKAGE_PIN L8 [get_ports SFPCLK_QO_P]

#################################

# XADC PINS

#################################

#set_property PACKAGE_PIN C39 [get_ports VAUX_CURR_N]

#set_property PACKAGE_PIN C38 [get_ports VAUX_CURR_P]

#set_property PACKAGE_PIN A34 [get_ports VAUX_VOLT_N]

#set_property PACKAGE_PIN B34 [get_ports VAUX_VOLT_P]

#set_property PACKAGE_PIN T14 [get_ports VN]

#set_property PACKAGE_PIN R15 [get_ports VP]

# [Netlist 29-55] Pins VAUXN[6], VAUXN[7], VAUXN[13], VAUXN[14], VAUXN[15], VAUXP[6], VAUXP[7], VAUXP[13], VAUXP[14] or VAUXP[15] are used on XADC instance 'SYSMON0/SYSMON_TIMING_IGNORE'. Please ensure that all of these pins are unconnected in order to avoid an unroutable situation. This instance will be converted to a black box element.

#NET  XADC_VAUX0P_R             LOC = J23  | IOSTANDARD=LVCMOS25; # Bank  15 VCCO - VCC2V5_FPGA - IO_L1P_T0_AD0P_15

#NET  XADC_VAUX0N_R             LOC = J24  | IOSTANDARD=LVCMOS25; # Bank  15 VCCO - VCC2V5_FPGA - IO_L1N_T0_AD0N_15

#NET  XADC_VAUX8P_R             LOC = L22  | IOSTANDARD=LVCMOS25; # Bank  15 VCCO - VCC2V5_FPGA - IO_L2P_T0_AD8P_15

#NET  XADC_VAUX8N_R             LOC = L23  | IOSTANDARD=LVCMOS25; # Bank  15 VCCO - VCC2V5_FPGA - IO_L2N_T0_AD8N_15

#####################################################

# FMC HPC Connections 

#####################################################

#------------------

# Buck regulator sync

#------------------

set_property IOSTANDARD LVCMOS25 [get_ports BUCK*_SYNC]
set_property PACKAGE_PIN AD28 [get_ports BUCK1V8_SYNC]
set_property PACKAGE_PIN AD27 [get_ports BUCK3V3_SYNC]

#------------------

# SPI

#------------------

set_property IOSTANDARD LVCMOS25 [get_ports {SPI_* PLL_LE}]
set_property PACKAGE_PIN F18 [get_ports PLL_LE]
#set_property PACKAGE_PIN C12 [get_ports PLL_LOCK]

set_property PACKAGE_PIN G17 [get_ports {SPI_ADDR[0]}]
set_property PACKAGE_PIN C22 [get_ports {SPI_ADDR[1]}]
set_property PACKAGE_PIN D22 [get_ports {SPI_ADDR[2]}]
set_property PACKAGE_PIN F17 [get_ports SPI_MISO]
set_property PACKAGE_PIN D16 [get_ports SPI_MOSI]
set_property PACKAGE_PIN B12 [get_ports SPI_RST_N_ALT]
set_property PACKAGE_PIN M20 [get_ports SPI_RST_N]
set_property PACKAGE_PIN C16 [get_ports SPI_SCK]
#------------------

# Reference Clock

# REFCLK_M2C_P is  KC705 with the FMC700 adapter.

#------------------

set_property IOSTANDARD LVDS_25 [get_ports REFCLK_M2C_P]
set_property LOC IDELAY_X0Y28 [get_cells CHFPGA0/REFCLK0/REFCLKDLY0]
set_property PACKAGE_PIN AE23 [get_ports REFCLK_M2C_P]
set_property PACKAGE_PIN AF23 [get_ports REFCLK_M2C_N]
#------------------

# ADC RESET

#------------------

set_property IOSTANDARD LVCMOS25 [get_ports ADC_RST_N]
set_property PACKAGE_PIN G18 [get_ports ADC_RST_N]
#------------------

# ADC SYNC

#------------------

set_property IOSTANDARD LVDS_25 [get_ports ADC_SYNC_P]
set_property PACKAGE_PIN E29 [get_ports ADC_SYNC_P]
set_property PACKAGE_PIN E30 [get_ports ADC_SYNC_N]
#------------------

# ADC Data buses and clocks

#------------------

set_property IOSTANDARD LVDS_25 [get_ports {ADC?_?DRP ADC?_?HDP}]
set_property LOC IDELAY_X0Y226 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y226 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y8 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN C25 [get_ports ADC0_ADRP]
set_property PACKAGE_PIN B25 [get_ports ADC0_ADRN]
set_property LOC ILOGIC_X0Y224 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y224 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN D27 [get_ports {ADC0_AHDP[0]}]
set_property PACKAGE_PIN C27 [get_ports {ADC0_AHDN[0]}]
set_property LOC ILOGIC_X0Y202 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y202 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN H30 [get_ports {ADC0_AHDP[1]}]
set_property PACKAGE_PIN G30 [get_ports {ADC0_AHDN[1]}]
set_property LOC ILOGIC_X0Y222 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y222 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN E28 [get_ports {ADC0_AHDP[2]}]
set_property PACKAGE_PIN D28 [get_ports {ADC0_AHDN[2]}]
set_property LOC ILOGIC_X0Y206 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y206 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN G29 [get_ports {ADC0_AHDP[3]}]
set_property PACKAGE_PIN F30 [get_ports {ADC0_AHDN[3]}]
set_property LOC ILOGIC_X0Y216 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y216 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN B30 [get_ports {ADC0_AHDP[4]}]
set_property PACKAGE_PIN A30 [get_ports {ADC0_AHDN[4]}]
set_property LOC ILOGIC_X0Y236 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y236 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN B27 [get_ports {ADC0_AHDP[5]}]
set_property PACKAGE_PIN A27 [get_ports {ADC0_AHDN[5]}]
set_property LOC ILOGIC_X0Y212 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y212 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN H24 [get_ports {ADC0_AHDP[6]}]
set_property PACKAGE_PIN H25 [get_ports {ADC0_AHDN[6]}]
set_property LOC ILOGIC_X0Y218 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y218 [get_cells {CHFPGA0/ANTGEN[0].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN D29 [get_ports {ADC0_AHDP[7]}]
set_property PACKAGE_PIN C30 [get_ports {ADC0_AHDN[7]}]
set_property LOC IDELAY_X0Y274 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y274 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y11 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN D17 [get_ports ADC0_BDRP]
set_property PACKAGE_PIN D18 [get_ports ADC0_BDRN]
set_property LOC ILOGIC_X0Y228 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y228 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN D26 [get_ports {ADC0_BHDP[0]}]
set_property PACKAGE_PIN C26 [get_ports {ADC0_BHDN[0]}]
set_property LOC ILOGIC_X0Y220 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y220 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN C29 [get_ports {ADC0_BHDP[1]}]
set_property PACKAGE_PIN B29 [get_ports {ADC0_BHDN[1]}]
set_property LOC ILOGIC_X0Y208 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y208 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN G27 [get_ports {ADC0_BHDP[2]}]
set_property PACKAGE_PIN F27 [get_ports {ADC0_BHDN[2]}]
set_property LOC ILOGIC_X0Y232 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y232 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN B28 [get_ports {ADC0_BHDP[3]}]
set_property PACKAGE_PIN A28 [get_ports {ADC0_BHDN[3]}]
set_property LOC ILOGIC_X0Y230 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y230 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN A25 [get_ports {ADC0_BHDP[4]}]
set_property PACKAGE_PIN A26 [get_ports {ADC0_BHDN[4]}]
set_property LOC ILOGIC_X0Y234 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y234 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN C24 [get_ports {ADC0_BHDP[5]}]
set_property PACKAGE_PIN B24 [get_ports {ADC0_BHDN[5]}]
set_property LOC ILOGIC_X0Y204 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y204 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN H26 [get_ports {ADC0_BHDP[6]}]
set_property PACKAGE_PIN H27 [get_ports {ADC0_BHDN[6]}]
set_property LOC ILOGIC_X0Y210 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y210 [get_cells {CHFPGA0/ANTGEN[1].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN G28 [get_ports {ADC0_BHDP[7]}]
set_property PACKAGE_PIN F28 [get_ports {ADC0_BHDN[7]}]
set_property LOC ILOGIC_X0Y278 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC IDELAY_X0Y278 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.CLKDLY0}]
set_property PACKAGE_PIN F21 [get_ports ADC0_CDRP]
set_property PACKAGE_PIN E21 [get_ports ADC0_CDRN]
set_property LOC ILOGIC_X0Y330 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y330 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN H11 [get_ports {ADC0_CHDP[0]}]
set_property PACKAGE_PIN H12 [get_ports {ADC0_CHDN[0]}]
set_property LOC ILOGIC_X0Y342 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y342 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN K13 [get_ports {ADC0_CHDP[1]}]
set_property PACKAGE_PIN J13 [get_ports {ADC0_CHDN[1]}]
set_property LOC ILOGIC_X0Y266 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y266 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN C17 [get_ports {ADC0_CHDP[2]}]
set_property PACKAGE_PIN B17 [get_ports {ADC0_CHDN[2]}]
set_property LOC ILOGIC_X0Y282 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y282 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN G22 [get_ports {ADC0_CHDP[3]}]
set_property PACKAGE_PIN F22 [get_ports {ADC0_CHDN[3]}]
set_property LOC ILOGIC_X0Y284 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y284 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN D21 [get_ports {ADC0_CHDP[4]}]
set_property PACKAGE_PIN C21 [get_ports {ADC0_CHDN[4]}]
set_property LOC ILOGIC_X0Y260 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y260 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN A16 [get_ports {ADC0_CHDP[5]}]
set_property PACKAGE_PIN A17 [get_ports {ADC0_CHDN[5]}]
set_property LOC ILOGIC_X0Y286 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y286 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN H21 [get_ports {ADC0_CHDP[6]}]
set_property PACKAGE_PIN H22 [get_ports {ADC0_CHDN[6]}]
set_property LOC ILOGIC_X0Y256 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y256 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN B18 [get_ports {ADC0_CHDP[7]}]
set_property PACKAGE_PIN A18 [get_ports {ADC0_CHDN[7]}]
set_property LOC IDELAY_X0Y276 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y276 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y10 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN F20 [get_ports ADC0_DDRP]
set_property PACKAGE_PIN E20 [get_ports ADC0_DDRN]
set_property LOC ILOGIC_X0Y334 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y334 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN J11 [get_ports {ADC0_DHDP[0]}]
set_property PACKAGE_PIN J12 [get_ports {ADC0_DHDN[0]}]
set_property LOC ILOGIC_X0Y338 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y338 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN L11 [get_ports {ADC0_DHDP[1]}]
set_property PACKAGE_PIN K11 [get_ports {ADC0_DHDN[1]}]
set_property LOC ILOGIC_X0Y344 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y344 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN L12 [get_ports {ADC0_DHDP[2]}]
set_property PACKAGE_PIN L13 [get_ports {ADC0_DHDN[2]}]
set_property LOC ILOGIC_X0Y252 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y252 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN C19 [get_ports {ADC0_DHDP[3]}]
set_property PACKAGE_PIN B19 [get_ports {ADC0_DHDN[3]}]
set_property LOC ILOGIC_X0Y258 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y258 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN A20 [get_ports {ADC0_DHDP[4]}]
set_property PACKAGE_PIN A21 [get_ports {ADC0_DHDN[4]}]
set_property LOC ILOGIC_X0Y254 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y254 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN B22 [get_ports {ADC0_DHDP[5]}]
set_property PACKAGE_PIN A22 [get_ports {ADC0_DHDN[5]}]
set_property LOC ILOGIC_X0Y262 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y262 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN C20 [get_ports {ADC0_DHDP[6]}]
set_property PACKAGE_PIN B20 [get_ports {ADC0_DHDN[6]}]
set_property LOC ILOGIC_X0Y272 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y272 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN E19 [get_ports {ADC0_DHDP[7]}]
set_property PACKAGE_PIN D19 [get_ports {ADC0_DHDN[7]}]
set_property LOC IDELAY_X0Y324 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC ILOGIC_X0Y324 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC BUFMRCE_X0Y13 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property PACKAGE_PIN D12 [get_ports ADC1_CDRP]
set_property PACKAGE_PIN D13 [get_ports ADC1_CDRN]
set_property LOC ILOGIC_X0Y326 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y326 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN G13 [get_ports {ADC1_CHDP[0]}]
set_property PACKAGE_PIN F13 [get_ports {ADC1_CHDN[0]}]
set_property LOC ILOGIC_X0Y340 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y340 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN K14 [get_ports {ADC1_CHDP[1]}]
set_property PACKAGE_PIN J14 [get_ports {ADC1_CHDN[1]}]
set_property LOC ILOGIC_X0Y314 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y314 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN D11 [get_ports {ADC1_CHDP[2]}]
set_property PACKAGE_PIN C11 [get_ports {ADC1_CHDN[2]}]
set_property LOC ILOGIC_X0Y310 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y310 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN E14 [get_ports {ADC1_CHDP[3]}]
set_property PACKAGE_PIN E15 [get_ports {ADC1_CHDN[3]}]
set_property LOC ILOGIC_X0Y318 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y318 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN F11 [get_ports {ADC1_CHDP[4]}]
set_property PACKAGE_PIN E11 [get_ports {ADC1_CHDN[4]}]
set_property LOC ILOGIC_X0Y312 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y312 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN F15 [get_ports {ADC1_CHDP[5]}]
set_property PACKAGE_PIN E16 [get_ports {ADC1_CHDN[5]}]
set_property LOC ILOGIC_X0Y308 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y308 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN D14 [get_ports {ADC1_CHDP[6]}]
set_property PACKAGE_PIN C14 [get_ports {ADC1_CHDN[6]}]
set_property LOC ILOGIC_X0Y302 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y302 [get_cells {CHFPGA0/ANTGEN[6].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN B14 [get_ports {ADC1_CHDP[7]}]
set_property PACKAGE_PIN A15 [get_ports {ADC1_CHDN[7]}]
set_property LOC BUFIO_X0Y27 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.NOEXTCLK.BUFIOGEN[0].BUFIO0}]
set_property LOC ILOGIC_X0Y328 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC IDELAY_X0Y328 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.CLKDLY0}]
set_property PACKAGE_PIN H14 [get_ports ADC1_DDRP]
set_property PACKAGE_PIN G14 [get_ports ADC1_DDRN]
set_property LOC ILOGIC_X0Y322 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property LOC IDELAY_X0Y322 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property PACKAGE_PIN F12 [get_ports {ADC1_DHDP[0]}]
set_property PACKAGE_PIN E13 [get_ports {ADC1_DHDN[0]}]
set_property LOC ILOGIC_X0Y316 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property LOC IDELAY_X0Y316 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property PACKAGE_PIN A11 [get_ports {ADC1_DHDP[1]}]
set_property PACKAGE_PIN A12 [get_ports {ADC1_DHDN[1]}]
set_property LOC ILOGIC_X0Y306 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property LOC IDELAY_X0Y306 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property PACKAGE_PIN B13 [get_ports {ADC1_DHDP[2]}]
set_property PACKAGE_PIN A13 [get_ports {ADC1_DHDN[2]}]
set_property LOC ILOGIC_X0Y304 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property LOC IDELAY_X0Y304 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property PACKAGE_PIN C15 [get_ports {ADC1_DHDP[3]}]
set_property PACKAGE_PIN B15 [get_ports {ADC1_DHDN[3]}]
set_property LOC ILOGIC_X0Y348 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property LOC IDELAY_X0Y348 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property PACKAGE_PIN L16 [get_ports {ADC1_DHDP[4]}]
set_property PACKAGE_PIN K16 [get_ports {ADC1_DHDN[4]}]
set_property LOC ILOGIC_X0Y332 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property LOC IDELAY_X0Y332 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property PACKAGE_PIN J16 [get_ports {ADC1_DHDP[5]}]
set_property PACKAGE_PIN H16 [get_ports {ADC1_DHDN[5]}]
set_property LOC ILOGIC_X0Y336 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property LOC IDELAY_X0Y336 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property PACKAGE_PIN H15 [get_ports {ADC1_DHDP[6]}]
set_property PACKAGE_PIN G15 [get_ports {ADC1_DHDN[6]}]
set_property LOC ILOGIC_X0Y346 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property LOC IDELAY_X0Y346 [get_cells {CHFPGA0/ANTGEN[7].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property PACKAGE_PIN L15 [get_ports {ADC1_DHDP[7]}]
set_property PACKAGE_PIN K15 [get_ports {ADC1_DHDN[7]}]
#Pins working only with FMC700 adapter

set_property LOC IDELAY_X0Y26 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.CLKDLY0}]
set_property LOC BUFMRCE_X0Y0 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property LOC ILOGIC_X0Y26 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.IDDR_CLK}]
set_property PACKAGE_PIN AD23 [get_ports ADC1_ADRP]
set_property PACKAGE_PIN AE24 [get_ports ADC1_ADRN]
set_property LOC IDELAY_X0Y16 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property LOC ILOGIC_X0Y16 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property PACKAGE_PIN AK23 [get_ports {ADC1_AHDP[0]}]
set_property PACKAGE_PIN AK24 [get_ports {ADC1_AHDN[0]}]
set_property LOC IDELAY_X0Y20 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property LOC ILOGIC_X0Y20 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property PACKAGE_PIN AJ24 [get_ports {ADC1_AHDP[1]}]
set_property PACKAGE_PIN AK25 [get_ports {ADC1_AHDN[1]}]
set_property LOC IDELAY_X0Y18 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property LOC ILOGIC_X0Y18 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property PACKAGE_PIN AE25 [get_ports {ADC1_AHDP[2]}]
set_property PACKAGE_PIN AF25 [get_ports {ADC1_AHDN[2]}]
set_property LOC IDELAY_X0Y38 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property LOC ILOGIC_X0Y38 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property PACKAGE_PIN AA20 [get_ports {ADC1_AHDP[3]}]
set_property PACKAGE_PIN AB20 [get_ports {ADC1_AHDN[3]}]
set_property LOC IDELAY_X0Y36 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property LOC ILOGIC_X0Y36 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property PACKAGE_PIN AB24 [get_ports {ADC1_AHDP[4]}]
set_property PACKAGE_PIN AC25 [get_ports {ADC1_AHDN[4]}]
set_property LOC IDELAY_X0Y30 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property LOC ILOGIC_X0Y30 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property PACKAGE_PIN AD21 [get_ports {ADC1_AHDP[5]}]
set_property PACKAGE_PIN AE21 [get_ports {ADC1_AHDN[5]}]
set_property LOC IDELAY_X0Y32 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property LOC ILOGIC_X0Y32 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property PACKAGE_PIN AC24 [get_ports {ADC1_AHDP[6]}]
set_property PACKAGE_PIN AD24 [get_ports {ADC1_AHDN[6]}]
set_property LOC IDELAY_X0Y34 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property LOC ILOGIC_X0Y34 [get_cells {CHFPGA0/ANTGEN[4].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property PACKAGE_PIN AC22 [get_ports {ADC1_AHDP[7]}]
set_property PACKAGE_PIN AD22 [get_ports {ADC1_AHDN[7]}]
set_property LOC BUFMRCE_X0Y2 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.YESBUFMR.BUFMRn}]
set_property LOC ILOGIC_X0Y76 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.IDDR_CLK}]
set_property LOC IDELAY_X0Y76 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.CLKDLY0}]
set_property PACKAGE_PIN AB27 [get_ports ADC1_BDRP]
set_property PACKAGE_PIN AC27 [get_ports ADC1_BDRN]
set_property LOC IDELAY_X0Y2 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[0].DLY0}]
set_property LOC ILOGIC_X0Y2 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[0].ISERDESE0}]
set_property PACKAGE_PIN AK20 [get_ports {ADC1_BHDP[0]}]
set_property PACKAGE_PIN AK21 [get_ports {ADC1_BHDN[0]}]
set_property LOC IDELAY_X0Y12 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[1].DLY0}]
set_property LOC ILOGIC_X0Y12 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[1].ISERDESE0}]
set_property PACKAGE_PIN AF20 [get_ports {ADC1_BHDP[1]}]
set_property PACKAGE_PIN AF21 [get_ports {ADC1_BHDN[1]}]
set_property LOC IDELAY_X0Y6 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[2].DLY0}]
set_property LOC ILOGIC_X0Y6 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[2].ISERDESE0}]
set_property PACKAGE_PIN AG20 [get_ports {ADC1_BHDP[2]}]
set_property PACKAGE_PIN AH20 [get_ports {ADC1_BHDN[2]}]
set_property LOC IDELAY_X0Y4 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[3].DLY0}]
set_property LOC ILOGIC_X0Y4 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[3].ISERDESE0}]
set_property PACKAGE_PIN AH21 [get_ports {ADC1_BHDP[3]}]
set_property PACKAGE_PIN AJ21 [get_ports {ADC1_BHDN[3]}]
set_property LOC IDELAY_X0Y10 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[4].DLY0}]
set_property LOC ILOGIC_X0Y10 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[4].ISERDESE0}]
set_property PACKAGE_PIN AG22 [get_ports {ADC1_BHDP[4]}]
set_property PACKAGE_PIN AH22 [get_ports {ADC1_BHDN[4]}]
set_property LOC IDELAY_X0Y52 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[5].DLY0}]
set_property LOC ILOGIC_X0Y52 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[5].ISERDESE0}]
set_property PACKAGE_PIN AJ26 [get_ports {ADC1_BHDP[5]}]
set_property PACKAGE_PIN AK26 [get_ports {ADC1_BHDN[5]}]
set_property LOC IDELAY_X0Y14 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[6].DLY0}]
set_property LOC ILOGIC_X0Y14 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[6].ISERDESE0}]
set_property PACKAGE_PIN AG25 [get_ports {ADC1_BHDP[6]}]
set_property PACKAGE_PIN AH25 [get_ports {ADC1_BHDN[6]}]
set_property LOC IDELAY_X0Y8 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[7].DLY0}]
set_property LOC ILOGIC_X0Y8 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.GBIT[7].ISERDESE0}]
set_property PACKAGE_PIN AJ22 [get_ports {ADC1_BHDP[7]}]
set_property PACKAGE_PIN AJ23 [get_ports {ADC1_BHDN[7]}]

###################################

# AREA Contraints

###################################

create_pblock ANT0
add_cells_to_pblock [get_pblocks ANT0] [get_cells -quiet [list {CHFPGA0/ANTGEN[0].ANTn/CTRL_ROUTER0} {CHFPGA0/ANTGEN[0].ANTn/IMPL.FFT0} {CHFPGA0/ANTGEN[0].ANTn/IMPL.FUNCGEN0} {CHFPGA0/ANTGEN[0].ANTn/IMPL.INJECT0} {CHFPGA0/ANTGEN[0].ANTn/IMPL.SRCSEL0}]]
resize_pblock [get_pblocks ANT0] -add {SLICE_X8Y200:SLICE_X145Y224}
resize_pblock [get_pblocks ANT0] -add {DSP48_X0Y80:DSP48_X5Y89}
resize_pblock [get_pblocks ANT0] -add {RAMB18_X0Y80:RAMB18_X5Y89}
resize_pblock [get_pblocks ANT0] -add {RAMB36_X0Y40:RAMB36_X5Y44}
create_pblock ANT1
add_cells_to_pblock [get_pblocks ANT1] [get_cells -quiet [list {CHFPGA0/ANTGEN[1].ANTn/CTRL_ROUTER0} {CHFPGA0/ANTGEN[1].ANTn/IMPL.FFT0} {CHFPGA0/ANTGEN[1].ANTn/IMPL.FUNCGEN0} {CHFPGA0/ANTGEN[1].ANTn/IMPL.INJECT0} {CHFPGA0/ANTGEN[1].ANTn/IMPL.SRCSEL0}]]
resize_pblock [get_pblocks ANT1] -add {SLICE_X8Y225:SLICE_X145Y249}
resize_pblock [get_pblocks ANT1] -add {DSP48_X0Y90:DSP48_X5Y99}
resize_pblock [get_pblocks ANT1] -add {RAMB18_X0Y90:RAMB18_X5Y99}
resize_pblock [get_pblocks ANT1] -add {RAMB36_X0Y45:RAMB36_X5Y49}
create_pblock ANT2
add_cells_to_pblock [get_pblocks ANT2] [get_cells -quiet [list {CHFPGA0/ANTGEN[2].ANTn/CTRL_ROUTER0} {CHFPGA0/ANTGEN[2].ANTn/IMPL.FFT0} {CHFPGA0/ANTGEN[2].ANTn/IMPL.FUNCGEN0} {CHFPGA0/ANTGEN[2].ANTn/IMPL.INJECT0} {CHFPGA0/ANTGEN[2].ANTn/IMPL.SRCSEL0}]]
resize_pblock [get_pblocks ANT2] -add {SLICE_X8Y250:SLICE_X145Y274}
resize_pblock [get_pblocks ANT2] -add {DSP48_X0Y100:DSP48_X5Y109}
resize_pblock [get_pblocks ANT2] -add {RAMB18_X0Y100:RAMB18_X5Y109}
resize_pblock [get_pblocks ANT2] -add {RAMB36_X0Y50:RAMB36_X5Y54}
create_pblock ANT3
add_cells_to_pblock [get_pblocks ANT3] [get_cells -quiet [list {CHFPGA0/ANTGEN[3].ANTn/CTRL_ROUTER0} {CHFPGA0/ANTGEN[3].ANTn/IMPL.FFT0} {CHFPGA0/ANTGEN[3].ANTn/IMPL.FUNCGEN0} {CHFPGA0/ANTGEN[3].ANTn/IMPL.INJECT0} {CHFPGA0/ANTGEN[3].ANTn/IMPL.SRCSEL0}]]
resize_pblock [get_pblocks ANT3] -add {SLICE_X8Y275:SLICE_X145Y299}
resize_pblock [get_pblocks ANT3] -add {DSP48_X0Y110:DSP48_X5Y119}
resize_pblock [get_pblocks ANT3] -add {RAMB18_X0Y110:RAMB18_X5Y119}
resize_pblock [get_pblocks ANT3] -add {RAMB36_X0Y55:RAMB36_X5Y59}
#add_cells_to_pblock [get_pblocks ANT4] [get_cells  [list {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0}]]

#add_cells_to_pblock [get_pblocks ANT4_FE] [get_cells  [list {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/pfb_fir_real1_8f5364a5e8}]]

create_pblock ANT5
add_cells_to_pblock [get_pblocks ANT5] [get_cells -quiet [list {CHFPGA0/ANTGEN[5].ANTn/CTRL_ROUTER0} {CHFPGA0/ANTGEN[5].ANTn/IMPL.FFT0} {CHFPGA0/ANTGEN[5].ANTn/IMPL.FUNCGEN0} {CHFPGA0/ANTGEN[5].ANTn/IMPL.INJECT0} {CHFPGA0/ANTGEN[5].ANTn/IMPL.SRCSEL0}]]
resize_pblock [get_pblocks ANT5] -add {SLICE_X8Y25:SLICE_X141Y49}
resize_pblock [get_pblocks ANT5] -add {DSP48_X0Y10:DSP48_X5Y19}
resize_pblock [get_pblocks ANT5] -add {RAMB18_X0Y10:RAMB18_X5Y19}
resize_pblock [get_pblocks ANT5] -add {RAMB36_X0Y5:RAMB36_X5Y9}
create_pblock ANT6
add_cells_to_pblock [get_pblocks ANT6] [get_cells -quiet [list {CHFPGA0/ANTGEN[6].ANTn/CTRL_ROUTER0} {CHFPGA0/ANTGEN[6].ANTn/IMPL.FFT0} {CHFPGA0/ANTGEN[6].ANTn/IMPL.FUNCGEN0} {CHFPGA0/ANTGEN[6].ANTn/IMPL.INJECT0} {CHFPGA0/ANTGEN[6].ANTn/IMPL.SRCSEL0}]]
resize_pblock [get_pblocks ANT6] -add {SLICE_X8Y300:SLICE_X145Y324}
resize_pblock [get_pblocks ANT6] -add {DSP48_X0Y120:DSP48_X5Y129}
resize_pblock [get_pblocks ANT6] -add {RAMB18_X0Y120:RAMB18_X5Y129}
resize_pblock [get_pblocks ANT6] -add {RAMB36_X0Y60:RAMB36_X5Y64}
create_pblock ANT7
add_cells_to_pblock [get_pblocks ANT7] [get_cells -quiet [list {CHFPGA0/ANTGEN[7].ANTn/CTRL_ROUTER0} {CHFPGA0/ANTGEN[7].ANTn/IMPL.FFT0} {CHFPGA0/ANTGEN[7].ANTn/IMPL.FUNCGEN0} {CHFPGA0/ANTGEN[7].ANTn/IMPL.INJECT0} {CHFPGA0/ANTGEN[7].ANTn/IMPL.SRCSEL0}]]
resize_pblock [get_pblocks ANT7] -add {SLICE_X8Y325:SLICE_X145Y349}
resize_pblock [get_pblocks ANT7] -add {DSP48_X0Y130:DSP48_X5Y139}
resize_pblock [get_pblocks ANT7] -add {RAMB18_X0Y130:RAMB18_X5Y139}
resize_pblock [get_pblocks ANT7] -add {RAMB36_X0Y65:RAMB36_X5Y69}
create_pblock CORR0
add_cells_to_pblock [get_pblocks CORR0] [get_cells -quiet [list {CHFPGA0/CORRGEN[0].CORBLK0}]]
resize_pblock [get_pblocks CORR0] -add {SLICE_X66Y50:SLICE_X153Y74}
resize_pblock [get_pblocks CORR0] -add {DSP48_X3Y20:DSP48_X5Y29}
resize_pblock [get_pblocks CORR0] -add {RAMB18_X3Y20:RAMB18_X6Y29}
resize_pblock [get_pblocks CORR0] -add {RAMB36_X3Y10:RAMB36_X6Y14}
#add_cells_to_pblock [get_pblocks CORR0] [get_cells -quiet [list {CHFPGA0/CORRGEN[0].CORBLK0/CORR_RESET_REG} {CHFPGA0/CORRGEN[0].CORBLK0/IMPL.ACC0} {CHFPGA0/CORRGEN[0].CORBLK0/VCC} {CHFPGA0/CORRGEN[0].CORBLK0/IMPL.XMUL0} {CHFPGA0/CORRGEN[0].CORBLK0/CTRL_ROUTER0} {CHFPGA0/CORRGEN[0].CORBLK0/GND} {CHFPGA0/CORRGEN[0].CORBLK0/IMPL.CH_DIST0}]]

create_pblock PHY
add_cells_to_pblock [get_pblocks PHY] [get_cells -quiet [list CHFPGA0/UDP_PHY0]]
resize_pblock [get_pblocks PHY] -add {SLICE_X0Y150:SLICE_X11Y199}
resize_pblock [get_pblocks PHY] -add {RAMB18_X0Y60:RAMB18_X0Y79}
resize_pblock [get_pblocks PHY] -add {RAMB36_X0Y30:RAMB36_X0Y39}
create_pblock I2C
add_cells_to_pblock [get_pblocks I2C] [get_cells -quiet [list CHFPGA0/I2C0]]
resize_pblock [get_pblocks I2C] -add {SLICE_X0Y50:SLICE_X11Y99}
create_pblock SPI
add_cells_to_pblock [get_pblocks SPI] [get_cells -quiet [list CHFPGA0/SPI0]]
resize_pblock [get_pblocks SPI] -add {SLICE_X0Y100:SLICE_X7Y149}
create_pblock ADCDAQ0
add_cells_to_pblock [get_pblocks ADCDAQ0] [get_cells -quiet [list {CHFPGA0/ANTGEN[0].ADCDAQ0}]]
resize_pblock [get_pblocks ADCDAQ0] -add {SLICE_X0Y200:SLICE_X7Y224}
resize_pblock [get_pblocks ADCDAQ0] -add {RAMB18_X0Y80:RAMB18_X0Y89}
resize_pblock [get_pblocks ADCDAQ0] -add {RAMB36_X0Y40:RAMB36_X0Y44}
create_pblock ADCDAQ1
resize_pblock [get_pblocks ADCDAQ1] -add {SLICE_X0Y225:SLICE_X7Y249}
resize_pblock [get_pblocks ADCDAQ1] -add {RAMB18_X0Y90:RAMB18_X0Y99}
resize_pblock [get_pblocks ADCDAQ1] -add {RAMB36_X0Y45:RAMB36_X0Y49}
create_pblock ADCDAQ2
add_cells_to_pblock [get_pblocks ADCDAQ2] [get_cells -quiet [list {CHFPGA0/ANTGEN[2].ADCDAQ0}]]
resize_pblock [get_pblocks ADCDAQ2] -add {SLICE_X0Y250:SLICE_X7Y274}
resize_pblock [get_pblocks ADCDAQ2] -add {RAMB18_X0Y100:RAMB18_X0Y109}
resize_pblock [get_pblocks ADCDAQ2] -add {RAMB36_X0Y50:RAMB36_X0Y54}
create_pblock ADCDAQ3
add_cells_to_pblock [get_pblocks ADCDAQ3] [get_cells -quiet [list {CHFPGA0/ANTGEN[3].ADCDAQ0}]]
resize_pblock [get_pblocks ADCDAQ3] -add {SLICE_X0Y275:SLICE_X7Y298}
resize_pblock [get_pblocks ADCDAQ3] -add {RAMB18_X0Y110:RAMB18_X0Y117}
resize_pblock [get_pblocks ADCDAQ3] -add {RAMB36_X0Y55:RAMB36_X0Y58}
create_pblock ADCDAQ4
add_cells_to_pblock [get_pblocks ADCDAQ4] [get_cells -quiet [list {CHFPGA0/ANTGEN[4].ADCDAQ0}]]
resize_pblock [get_pblocks ADCDAQ4] -add {SLICE_X0Y0:SLICE_X7Y24}
resize_pblock [get_pblocks ADCDAQ4] -add {RAMB18_X0Y0:RAMB18_X0Y9}
resize_pblock [get_pblocks ADCDAQ4] -add {RAMB36_X0Y0:RAMB36_X0Y4}
create_pblock ADCDAQ5
add_cells_to_pblock [get_pblocks ADCDAQ5] [get_cells -quiet [list {CHFPGA0/ANTGEN[5].ADCDAQ0}]]
resize_pblock [get_pblocks ADCDAQ5] -add {SLICE_X0Y25:SLICE_X7Y49}
resize_pblock [get_pblocks ADCDAQ5] -add {RAMB18_X0Y10:RAMB18_X0Y19}
resize_pblock [get_pblocks ADCDAQ5] -add {RAMB36_X0Y5:RAMB36_X0Y9}
create_pblock ADCDAQ6
add_cells_to_pblock [get_pblocks ADCDAQ6] [get_cells -quiet [list {CHFPGA0/ANTGEN[6].ADCDAQ0}]]
resize_pblock [get_pblocks ADCDAQ6] -add {SLICE_X0Y300:SLICE_X7Y324}
resize_pblock [get_pblocks ADCDAQ6] -add {RAMB18_X0Y120:RAMB18_X0Y129}
resize_pblock [get_pblocks ADCDAQ6] -add {RAMB36_X0Y60:RAMB36_X0Y64}
create_pblock ADCDAQ7
add_cells_to_pblock [get_pblocks ADCDAQ7] [get_cells -quiet [list {CHFPGA0/ANTGEN[7].ADCDAQ0}]]
resize_pblock [get_pblocks ADCDAQ7] -add {SLICE_X0Y325:SLICE_X7Y349}
resize_pblock [get_pblocks ADCDAQ7] -add {RAMB18_X0Y130:RAMB18_X0Y139}
resize_pblock [get_pblocks ADCDAQ7] -add {RAMB36_X0Y65:RAMB36_X0Y69}
create_pblock ANT4
add_cells_to_pblock [get_pblocks ANT4] [get_cells -quiet [list {CHFPGA0/ANTGEN[4].ANTn/CTRL_ROUTER0}]]
resize_pblock [get_pblocks ANT4] -add {SLICE_X42Y0:SLICE_X135Y24}
resize_pblock [get_pblocks ANT4] -add {DSP48_X2Y0:DSP48_X5Y9}
resize_pblock [get_pblocks ANT4] -add {RAMB18_X2Y0:RAMB18_X5Y9}
resize_pblock [get_pblocks ANT4] -add {RAMB36_X2Y0:RAMB36_X5Y4}
#add_cells_to_pblock [get_pblocks ANT4] [get_cells  [list {CHFPGA0/ANTGEN[4].ANTn/CTRL_ROUTER0} {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0}]]

#This must come after ANT4

create_pblock ANT4_FE
add_cells_to_pblock [get_pblocks ANT4_FE] [get_cells -quiet [list {CHFPGA0/ANTGEN[4].ANTn/IMPL.FUNCGEN0} {CHFPGA0/ANTGEN[4].ANTn/IMPL.INJECT0} {CHFPGA0/ANTGEN[4].ANTn/IMPL.SRCSEL0}]]
resize_pblock [get_pblocks ANT4_FE] -add {SLICE_X8Y0:SLICE_X41Y24}
resize_pblock [get_pblocks ANT4_FE] -add {DSP48_X0Y0:DSP48_X1Y9}
resize_pblock [get_pblocks ANT4_FE] -add {RAMB18_X0Y0:RAMB18_X1Y9}
resize_pblock [get_pblocks ANT4_FE] -add {RAMB36_X0Y0:RAMB36_X1Y4}
create_pblock ANT4_BE
resize_pblock [get_pblocks ANT4_BE] -add {SLICE_X136Y0:SLICE_X141Y24}
#create_pblock NOC

#add_cells_to_pblock [get_pblocks NOC] [get_cells -hierarchical *TIMING_REG*]

#add_cells_to_pblock [get_pblocks NOC] [get_cells {CHFPGA0/ANTGEN[6].ANTn/IMPL.PROBER0 CHFPGA0/ANTGEN[6].ANTn/IMPL.SCALER0 CHFPGA0/ANTGEN[4].ANTn/IMPL.PROBER0 CHFPGA0/ANTGEN[4].ANTn/IMPL.SCALER0 CHFPGA0/ANTGEN[1].ANTn/IMPL.PROBER0 CHFPGA0/ANTGEN[1].ANTn/IMPL.SCALER0 CHFPGA0/ANTGEN[1].ADCDAQ0 CHFPGA0/ANTGEN[3].ANTn/IMPL.PROBER0 CHFPGA0/ANTGEN[3].ANTn/IMPL.SCALER0 CHFPGA0/ANTGEN[5].ANTn/IMPL.SCALER0 CHFPGA0/ANTGEN[5].ANTn/IMPL.PROBER0 CHFPGA0/CORRGEN[0].CORBLK0 CHFPGA0/ANTGEN[7].ANTn/IMPL.PROBER0 CHFPGA0/ANTGEN[7].ANTn/IMPL.SCALER0 CHFPGA0/ANTGEN[2].ANTn/IMPL.PROBER0 CHFPGA0/ANTGEN[2].ANTn/IMPL.SCALER0 CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0}]

#resize_pblock [get_pblocks NOC] -add {CLOCKREGION_X0Y0:CLOCKREGION_X1Y6}

#add_cells_to_pblock [get_pblocks NOC] [get_cells -hierarchical *TIMING_REG*]

# Remove cells containing TIMING_REG in their name from all pblocks so they can be freely placed to meet timing

# The commands are automatically generated by the following script line:

#  foreach x [get_pblocks -of_objects [get_cells -match_style UCF *TIMING_REG*]] {puts "remove_cells_from_pblock -quiet $x \[get_cells -match_style UCF *TIMING_REG* -filter Pblock==$x\]"}

# Specific component LOC'ing

### ANT4 DSP LOC'ing

set_property LOC DSP48_X2Y9 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_3_96534c353a/butterfly_direct_50808961d0/twiddle_general_3mult_bb4dfd79c5/mult0/comp0.core_instance0/blk00000003}]
set_property LOC DSP48_X2Y8 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_3_96534c353a/butterfly_direct_50808961d0/twiddle_general_3mult_bb4dfd79c5/mult1/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X2Y7 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_3_96534c353a/butterfly_direct_50808961d0/twiddle_general_3mult_bb4dfd79c5/mult2/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X2Y6 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_4_d21032e16e/butterfly_direct_1fc1d2b049/twiddle_general_3mult_0689a61b43/mult0/comp0.core_instance0/blk00000003}]
set_property LOC DSP48_X2Y5 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_4_d21032e16e/butterfly_direct_1fc1d2b049/twiddle_general_3mult_0689a61b43/mult1/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X2Y4 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_4_d21032e16e/butterfly_direct_1fc1d2b049/twiddle_general_3mult_0689a61b43/mult2/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X2Y3 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_5_521e6eb210/butterfly_direct_c96c7425d3/twiddle_general_3mult_c41c62dfcf/mult0/comp0.core_instance0/blk00000003}]
set_property LOC DSP48_X2Y2 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_5_521e6eb210/butterfly_direct_c96c7425d3/twiddle_general_3mult_c41c62dfcf/mult1/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X2Y1 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_5_521e6eb210/butterfly_direct_c96c7425d3/twiddle_general_3mult_c41c62dfcf/mult2/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X3Y1 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_6_3f6b6d5ea5/butterfly_direct_0c0b0db8d3/twiddle_general_3mult_12e153c68e/mult0/comp0.core_instance0/blk00000003}]
set_property LOC DSP48_X3Y2 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_6_3f6b6d5ea5/butterfly_direct_0c0b0db8d3/twiddle_general_3mult_12e153c68e/mult1/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X3Y3 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_6_3f6b6d5ea5/butterfly_direct_0c0b0db8d3/twiddle_general_3mult_12e153c68e/mult2/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X3Y4 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_7_09edaf7a48/butterfly_direct_a14d5b8667/twiddle_general_3mult_4feca36b72/mult0/comp0.core_instance0/blk00000003}]
set_property LOC DSP48_X3Y5 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_7_09edaf7a48/butterfly_direct_a14d5b8667/twiddle_general_3mult_4feca36b72/mult1/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X3Y6 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_7_09edaf7a48/butterfly_direct_a14d5b8667/twiddle_general_3mult_4feca36b72/mult2/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X3Y7 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_8_12753ece67/butterfly_direct_b64b9dc4dd/twiddle_general_3mult_cad14affaf/mult0/comp0.core_instance0/blk00000003}]
set_property LOC DSP48_X3Y8 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_8_12753ece67/butterfly_direct_b64b9dc4dd/twiddle_general_3mult_cad14affaf/mult1/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X3Y9 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_8_12753ece67/butterfly_direct_b64b9dc4dd/twiddle_general_3mult_cad14affaf/mult2/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X4Y9 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_9_61cde768a9/butterfly_direct_bfe329cdbb/twiddle_general_3mult_82f62cbc05/mult0/comp0.core_instance0/blk00000003}]
set_property LOC DSP48_X4Y8 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_9_61cde768a9/butterfly_direct_bfe329cdbb/twiddle_general_3mult_82f62cbc05/mult1/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X4Y7 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_biplex_real_4x0_a6db7c2226/biplex_core_9fdf53fa96/fft_stage_9_61cde768a9/butterfly_direct_bfe329cdbb/twiddle_general_3mult_82f62cbc05/mult2/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X4Y6 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly1_0_707d4af107/twiddle_general_3mult_2d7d51b9a9/mult0/comp0.core_instance0/blk00000003}]
set_property LOC DSP48_X4Y5 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly1_0_707d4af107/twiddle_general_3mult_2d7d51b9a9/mult1/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X4Y4 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly1_0_707d4af107/twiddle_general_3mult_2d7d51b9a9/mult2/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X4Y3 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly1_1_aa094e2b14/twiddle_general_3mult_d62f26f1ee/mult0/comp0.core_instance0/blk00000003}]
set_property LOC DSP48_X4Y2 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly1_1_aa094e2b14/twiddle_general_3mult_d62f26f1ee/mult1/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X4Y1 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly1_1_aa094e2b14/twiddle_general_3mult_d62f26f1ee/mult2/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X5Y6 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly2_0_bb9773f5f5/twiddle_general_3mult_8f71bd60be/mult0/comp0.core_instance0/blk00000003}]
set_property LOC DSP48_X5Y5 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly2_0_bb9773f5f5/twiddle_general_3mult_8f71bd60be/mult1/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X5Y4 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly2_0_bb9773f5f5/twiddle_general_3mult_8f71bd60be/mult2/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X5Y3 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly2_1_4559277e38/twiddle_general_3mult_f10710e567/mult0/comp0.core_instance0/blk00000003}]
set_property LOC DSP48_X5Y2 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly2_1_4559277e38/twiddle_general_3mult_f10710e567/mult1/comp1.core_instance1/blk00000003}]
set_property LOC DSP48_X5Y1 [get_cells {CHFPGA0/ANTGEN[4].ANTn/IMPL.FFT0/FFT_GEN.FFT0/fft_wideband_real_11fe8dc52f/fft_direct_578bf29dcc/butterfly2_1_4559277e38/twiddle_general_3mult_f10710e567/mult2/comp1.core_instance1/blk00000003}]
set_property LOC DCIRESET_X0Y0 [get_cells CHFPGA0/REFCLK0/DCIRESET0]
#set_property LOC USR_ACCESS_X0Y0 [get_cells CHFPGA0/GPIO0/USR_ACCESS0]

set_property LOC BUFR_X0Y23 [get_cells {CHFPGA0/ANTGEN[2].ADCDAQ0/IMPL.BUFRGEN[0].BUFRn}]
set_property LOC BUFR_X0Y22 [get_cells {CHFPGA0/ANTGEN[3].ADCDAQ0/IMPL.BUFRGEN[0].BUFRn}]
set_property LOC BUFR_X0Y1 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.BUFRGEN[0].BUFRn}]
set_property LOC BUFR_X0Y5 [get_cells {CHFPGA0/ANTGEN[5].ADCDAQ0/IMPL.BUFRGEN[1].BUFRn}]
set_property DRIVE 4 [get_ports SPI_SCK]
set_property SLEW SLOW [get_ports SPI_SCK]
# Fix FIFO XDCs

set_false_path -from [get_cells -hierarchical ngwrdrst.grst.rd_rst_reg*]
set_false_path -from [get_cells -hierarchical ngwrdrst.grst.wr_rst_reg*]
set_property LOC USR_ACCESS_X0Y0 [get_cells CHFPGA0/GPIO0/USRACCESS_7.USR_ACCESS0]
set_property LOC XADC_X0Y0 [get_cells CHFPGA0/SYSMON0/SYSMON7_GEN.XADC0]
set_default_switching_activity -toggle_rate 10.000 -type {clock}
set_operating_conditions -board_layers 16+
create_pblock CORR2
add_cells_to_pblock [get_pblocks CORR2] [get_cells -quiet [list {CHFPGA0/CORRGEN[2].CORBLK0}]]
resize_pblock [get_pblocks CORR2] -add {SLICE_X66Y100:SLICE_X153Y124}
resize_pblock [get_pblocks CORR2] -add {DSP48_X3Y40:DSP48_X5Y49}
resize_pblock [get_pblocks CORR2] -add {RAMB18_X3Y40:RAMB18_X6Y49}
resize_pblock [get_pblocks CORR2] -add {RAMB36_X3Y20:RAMB36_X6Y24}
create_pblock CORR3
add_cells_to_pblock [get_pblocks CORR3] [get_cells -quiet [list {CHFPGA0/CORRGEN[3].CORBLK0}]]
resize_pblock [get_pblocks CORR3] -add {SLICE_X66Y125:SLICE_X153Y149}
resize_pblock [get_pblocks CORR3] -add {DSP48_X3Y50:DSP48_X5Y59}
resize_pblock [get_pblocks CORR3] -add {RAMB18_X3Y50:RAMB18_X6Y59}
resize_pblock [get_pblocks CORR3] -add {RAMB36_X3Y25:RAMB36_X6Y29}
create_pblock CORR4
add_cells_to_pblock [get_pblocks CORR4] [get_cells -quiet [list {CHFPGA0/CORRGEN[4].CORBLK0}]]
resize_pblock [get_pblocks CORR4] -add {SLICE_X80Y150:SLICE_X125Y199}
resize_pblock [get_pblocks CORR4] -add {DSP48_X3Y60:DSP48_X4Y79}
resize_pblock [get_pblocks CORR4] -add {RAMB18_X3Y60:RAMB18_X4Y79}
resize_pblock [get_pblocks CORR4] -add {RAMB36_X3Y30:RAMB36_X4Y39}
create_pblock CORR5
add_cells_to_pblock [get_pblocks CORR5] [get_cells -quiet [list {CHFPGA0/CORRGEN[5].CORBLK0}]]
resize_pblock [get_pblocks CORR5] -add {SLICE_X12Y150:SLICE_X79Y199}
resize_pblock [get_pblocks CORR5] -add {DSP48_X1Y60:DSP48_X2Y79}
resize_pblock [get_pblocks CORR5] -add {RAMB18_X1Y60:RAMB18_X2Y79}
resize_pblock [get_pblocks CORR5] -add {RAMB36_X1Y30:RAMB36_X2Y39}
create_pblock CORR6
add_cells_to_pblock [get_pblocks CORR6] [get_cells -quiet [list {CHFPGA0/CORRGEN[6].CORBLK0}]]
resize_pblock [get_pblocks CORR6] -add {SLICE_X14Y50:SLICE_X63Y99}
resize_pblock [get_pblocks CORR6] -add {DSP48_X1Y20:DSP48_X2Y39}
resize_pblock [get_pblocks CORR6] -add {RAMB18_X1Y20:RAMB18_X2Y39}
resize_pblock [get_pblocks CORR6] -add {RAMB36_X1Y10:RAMB36_X2Y19}
create_pblock CORR7
add_cells_to_pblock [get_pblocks CORR7] [get_cells -quiet [list {CHFPGA0/CORRGEN[7].CORBLK0}]]
resize_pblock [get_pblocks CORR7] -add {SLICE_X8Y100:SLICE_X63Y149}
resize_pblock [get_pblocks CORR7] -add {DSP48_X0Y40:DSP48_X2Y59}
resize_pblock [get_pblocks CORR7] -add {RAMB18_X1Y40:RAMB18_X2Y59}
resize_pblock [get_pblocks CORR7] -add {RAMB36_X1Y20:RAMB36_X2Y29}
create_pblock CORR1
add_cells_to_pblock [get_pblocks CORR1] [get_cells -quiet [list {CHFPGA0/CORRGEN[1].CORBLK0}]]
resize_pblock [get_pblocks CORR1] -add {SLICE_X66Y75:SLICE_X153Y99}
resize_pblock [get_pblocks CORR1] -add {DSP48_X3Y30:DSP48_X5Y39}
resize_pblock [get_pblocks CORR1] -add {RAMB18_X3Y30:RAMB18_X6Y39}
resize_pblock [get_pblocks CORR1] -add {RAMB36_X3Y15:RAMB36_X6Y19}

set_property BITSTREAM.GENERAL.CRC Enable [current_design]
set_property BITSTREAM.READBACK.READBACK true [current_design]
set_property PACKAGE_PIN L7 [get_ports SFPCLK_QO_N]

set_property PACKAGE_PIN L7 [get_ports SFPCLK_QO_N]
