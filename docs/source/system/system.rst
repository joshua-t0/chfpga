.. title:: SYSTEM

**********************************************
:entity:`SYSTEM` (*system.vhd*): System module
**********************************************

.. toctree::
   :maxdepth: 1
   :hidden:

   gpio
   i2c
   spi
   blinker
   refclk
   sysmon
   freq_ctr
   ../navbar_separator

.. parse:: hdl/system/system.vhd

.. default-role:: vhdl:entity

.. figure:: ../images/SYSTEM/system.svg
    :width: 50%

    SYSTEM module block diagram showing the command router and sub-modules.



Entity documentation
====================

.. autoentity:: system

Parameters
==========

- **PLATFORM_TYPE:** Target platform, defined as ``platform_type_enum`` in :doc:`../chfpga_package`. Selects FPGA-series-specific primitives throughout all sub-modules.
- **COOKIE:** 7-bit application firmware identifier reported in the GPIO STATUS register (default ``0x42``).
- **PROTOCOL_VERSION:** 16-bit protocol version reported to the host software for compatibility checking.
- **NUMBER_OF_ADCS:** Number of ADC channels implemented.
- **CHAN_CLK_SOURCE_LANE:** ADC lane index from which the channelizer clocks are derived.
- **ADC_SAMPLES_PER_FRAME / ADC_SAMPLES_PER_WORD / ADC_BITS_PER_SAMPLE:** ADC data frame geometry parameters passed to :entity:`gpio`.
- **NUMBER_OF_ADC_BOARDS:** Number of FMC ADC mezzanine boards (default 1).
- **NUMBER_OF_CHANNELIZERS / NUMBER_OF_CHANNELIZERS_WITH_FFT:** F-engine channelizer counts.
- **FFT_TYPE / CT_TYPE / CT_LEVEL:** FFT and corner-turn engine type enumerations.
- **NUMBER_OF_CT_INPUTS / NUMBER_OF_CT_CB1_OUTPUTS / NUMBER_OF_CT_REFCLKS:** Corner-turn input/output and reference-clock counts.
- **NUMBER_OF_GPU_LINKS / NUMBER_OF_GPU_REFCLKS:** GPU link and reference-clock counts.
- **NUMBER_OF_CORRELATORS / NUMBER_OF_CHANNELIZERS_TO_CORRELATE:** X-engine correlator configuration.
- **NUMBER_OF_BUCK_SYNC_LINES:** Number of buck regulator SYNC outputs (default 16).
- **BUCK_SYNC_ENABLE:** Default startup state of the buck SYNC outputs (default ``TRUE``).
- **BUCK_CLK_DIVIDE_FACTOR:** Divider for the buck SYNC clock (``200 MHz / factor / 16``).
- **NUMBER_OF_SPI_PORTS:** Number of SPI chip-select lines exposed via the :entity:`spi` sub-module.
- **NUMBER_OF_I2C_PORTS:** Number of I2C bus ports exposed via the :entity:`i2c` sub-module.
- **MAC_ADDRESS_OUI_CODE:** 24-bit OUI prefix for the local MAC address (default ``X"000A35"``).
- **NUMBER_OF_USER_SMA_SIGNALS:** Number of sources in the user SMA output mux.
- **IMPLEMENT_LCD:** When ``TRUE``, instantiates LCD display control logic.
- **IMPLEMENT_SWITCHER_SYNC:** When ``TRUE``, instantiates buck-regulator SYNC logic.
- **IMPLEMENT_FAN:** When ``TRUE``, instantiates fan tachymeter and PWM control.
- **IMPLEMENT_ARM_SPI:** When ``TRUE``, instantiates the :entity:`arm_spi` slave interface.
- **BLINKER_PRESENT:** When ``TRUE``, instantiates the :entity:`blinker` heartbeat LED module.
- **SIM:** When ``TRUE``, enables simulation-specific behaviour in all sub-modules to accelerate simulations.

Interface
=========

BSB control interface
---------------------

- ``s/m_axis_bsb_t*``: BSB (Byte-Stream Bus) command/reply stream interface. Commands are routed to the appropriate sub-module by an internal router.
- ``bsb_clk``/``bsb_rst``: BSB clock (125 MHz) and synchronous reset.

UDP networking configuration
----------------------------

- ``local_mac_addr``/``local_ip_addr``/``local_ip_port``: Local FPGA UDP network identity registers managed via GPIO.
- ``remote_mac_addr``/``remote_ip_addr``/``remote_ip_port0/1``: Remote UDP peer address configuration.
- ``host_frame_read_rate``: UDP output data rate throttle parameter.
- ``sfp_status_vector``/``sfp_config_vector``: SFP/SGMII bridge status and configuration.
- ``udp_tx_frame``/``udp_rx_frame``/``udp_tx_overflow``/``udp_rx_overflow``: UDP link health monitoring inputs.
- ``cmd_packet_counter``/``rply_packet_counter``: UDP packet counters for diagnostics.
- ``udp_stack_reset``/``ctrl_master_reset``: Software-triggered reset outputs.

ARM SPI interface
-----------------

- ``arm_spi_sck/miso/mosi/cs_n``: SPI bus to the ARM processor, forwarded to the internal :entity:`arm_spi` slave.

IceBoard I/O (bidirectional / tristate)
----------------------------------------

- ``arm_irq_in/out/oe``/``flash_cs_in/out/oe``/``gpio_irq_in/out/oe``/``gpio_rst_in/out/oe``/``uart_rx_in/out/oe``/``uart_tx_in/out/oe``: Tristate I/O signals for IceBoard-specific QC testing.

Backplane and buck regulator
----------------------------

- ``bp_gpio_int_in/out/oe``: Backplane open-drain interrupt line connecting all boards in a crate.
- ``bp_buck_sync``: Backplane buck SYNC (bidirectional open-drain).
- ``buck_sync``: Buck switching regulator SYNC outputs with individually programmable phase offsets.
- ``time_trig``: 2-bit external time/trigger input (e.g. backplane or SMA).

Event counter and PWM
---------------------

- ``event_ctr_clk``/``event_ctr_en``/``event_ctr_inc``/``event_ctr_reset``: 48-bit frame event counter interface.
- ``pwm_clk``/``pwm_ctr_en``/``pwm_reset``: PWM generator interface.
- ``user_mux_in``/``user_mux_out``/``user_mux_oe``: User-selectable output mux.
- ``pll_sync``: External PLL SYNC pulse output.

ADC control
-----------

- ``adc_rst``: ADC board reset outputs, one per mezzanine board.
- ``refclk_m2c_p/n``: LVDS 10 MHz reference clock received from FMC mezzanine boards.
- ``fmc_refclk``: Delayed and BUFG-buffered mezzanine reference clocks (output from :entity:`refclk`).
- ``adc_sync_p/n``: LVDS SYNC outputs to the ADC mezzanines.
- ``adc_pll_lock``: ADC mezzanine PLL lock status inputs.
- ``adc_cal_freeze``/``adc_cal_frozen``/``adc_cal_signal_detect``: RfSoC ADC calibration controls.
- ``adc_clear_or``/``adc_clear_ov``: Clear overrange/overvoltage sticky flags.
- ``adc_or``/``adc_ov``/``adc_cm_ov``/``adc_cm_uv``/``adc_ot1``/``adc_ot2``: ADC alarm status inputs.
- ``fan_pwm``/``fan_tach``: Fan PWM output and tachymeter input.
- ``lcd_db``/``lcd_e``/``lcd_rs``/``lcd_rw``: LCD display interface.
- ``gpio_led``: 8-bit LED output vector driven by :entity:`blinker`.

SPI interface
-------------

- ``spi_rst_n``: SPI reset, directly controlled by a register bit-field.
- ``spi_sck``/``spi_mosi``/``spi_miso``/``spi_cs_n``: SPI bus signals (``NUMBER_OF_SPI_PORTS`` MISO lines and chip-select lines, one shared MOSI and SCK).
- ``spi_addr``: 3-bit address driven alongside the SPI transaction.

I2C interface
-------------

- ``i2c_sck``/``i2c_sda``: Bidirectional I2C bus clock and data, ``NUMBER_OF_I2C_PORTS`` wide.

SYSMON analog inputs
--------------------

- ``vaux_curr_p/n``/``vaux_volt_p/n``: Differential XADC inputs for external 12 V current and voltage monitoring.
- ``vp``/``vn``: XADC dedicated analog inputs.

Clock monitoring
----------------

- ``adc_clk_div2``: Divide-by-2 ADC clock signals for the frequency counter.
- ``fmc_mgt_pll_refclk_div2``/``gpu_refclk_div2``/``gpu_txclk_div2``: MGT reference and TX clock divide-by-2 inputs for monitoring.
- ``bp_shuffle_refclk_div2``/``bp_shuffle_txclk_div2``/``ct_clk_div2``: Corner-turn and backplane shuffle clock monitoring inputs.
- ``corr_clk_div2``/``raw_clk10_div2``/``clk10_div2``/``clk200_div2``/``ctrl_clk_div2``/``chan_clk_div2``/``sysmon_clk_div2``/``mgt_clk100_div2``/``mgt_clk200_div2``/``mgt_clk125_div2``/``pll_oscout_div2``/``sfp_refclk_div2``: System clock monitoring inputs.

Clocks and resets
-----------------

- ``clk200``/``clk200_reset``: 200 MHz system clock and its synchronous reset.
- ``clk10``/``clk10_sel``: 10 MHz backplane reference clock and source selection output.
- ``sysmon_clk``/``sysmon_reset``: SYSMON/DNA clock (max 97 MHz) and reset.
- ``chan_clk``/``chan_reset``/``chan_clk_sel``/``chan_clk_reset_async``/``chan_reset_async``: Channelizer clock, reset, and control outputs.
- ``refclk_adcdaq_reset``/``adcdaq_reset_async``: ADC data-acquisition reset outputs.
- ``clk10_out``: Delayed or encoded 10 MHz reference output to external circuitry.
- ``corr_reset_async``/``ctrl_reset_pulse``/``user_reset``: Software-controlled system reset outputs.

Implementation details
======================

The :entity:`system` entity is a container that instantiates and interconnects all system-level infrastructure sub-modules. An internal BSB command router distributes incoming BSB frames to the appropriate sub-module address slot:

- Address offset ``0x00000``: :entity:`gpio`
- Address offset ``0x01000``: :entity:`sysmon`
- Address offset ``0x02000``: :entity:`freq_ctr`
- Address offset ``0x03000``: :entity:`spi`
- Address offset ``0x04000``: :entity:`refclk`
- Address offset ``0x05000``: :entity:`i2c`

Internal signals connect :entity:`gpio` (IRIG-B before-target flag, ADC SYNC) to :entity:`refclk`, and route the fan tachymeter debounced signal from :entity:`gpio` to :entity:`freq_ctr` for fan speed measurement.


Memory map
==========

.. include-docs:: system
    :start-after: SYSTEM Memory Map

