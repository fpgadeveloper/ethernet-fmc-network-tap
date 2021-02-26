################################################################
# Block diagram build script for Zynq MP designs
################################################################

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

create_bd_design $design_name

current_bd_design $design_name

set parentCell [get_bd_cells /]

# Get object for parentCell
set parentObj [get_bd_cells $parentCell]
if { $parentObj == "" } {
   puts "ERROR: Unable to find parent cell <$parentCell>!"
   return
}

# Make sure parentObj is hier blk
set parentType [get_property TYPE $parentObj]
if { $parentType ne "hier" } {
   puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
   return
}

# Save current instance; Restore later
set oldCurInst [current_bd_instance .]

# Set parent object as current
current_bd_instance $parentObj

# Add the Processor System and apply board preset
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]

# Disable all of the GP ports
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP0 {0} \
CONFIG.PSU__USE__M_AXI_GP1 {0} \
CONFIG.PSU__USE__M_AXI_GP2 {0}] [get_bd_cells zynq_ultra_ps_e_0]

# Configure the PS: Enable GEM0 for EMIO, GEM3 for MIO (on-board Ethernet)
set_property -dict [list CONFIG.PSU__ENET0__GRP_MDIO__ENABLE {1} \
CONFIG.PSU__ENET0__GRP_MDIO__IO {EMIO} \
CONFIG.PSU__ENET0__PERIPHERAL__ENABLE {1} \
CONFIG.PSU__ENET0__PERIPHERAL__IO {EMIO}] [get_bd_cells zynq_ultra_ps_e_0]

# Add the NOT gate for reset signal
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_0
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not}] [get_bd_cells util_vector_logic_0]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins util_vector_logic_0/Op1]

# Add the GMII-to-RGMIIs
create_bd_cell -type ip -vlnv xilinx.com:ip:gmii_to_rgmii gmii_to_rgmii_0
create_bd_cell -type ip -vlnv xilinx.com:ip:gmii_to_rgmii gmii_to_rgmii_1

# GMII-to-RGMII0 set with PHY address 7 and shared logic
set_property -dict [list CONFIG.C_USE_IDELAY_CTRL {true} CONFIG.C_PHYADDR {7} CONFIG.SupportLevel {Include_Shared_Logic_in_Core}] [get_bd_cells gmii_to_rgmii_0]
# GMII-to-RGMII1 set with PHY address 8 and no shared logic, no IDELAY_CTRL
set_property -dict [list CONFIG.C_PHYADDR {8} CONFIG.C_USE_IDELAY_CTRL {false}] [get_bd_cells gmii_to_rgmii_1]
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/MDIO_ENET0] [get_bd_intf_pins gmii_to_rgmii_1/MDIO_GEM]
connect_bd_intf_net [get_bd_intf_pins gmii_to_rgmii_1/MDIO_PHY] [get_bd_intf_pins gmii_to_rgmii_0/MDIO_GEM]

# Make GMII-to-RGMII ports external: RGMII and RESET
# RGMII
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii_port_0
connect_bd_intf_net [get_bd_intf_pins gmii_to_rgmii_0/RGMII] [get_bd_intf_ports rgmii_port_0]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii_port_1
connect_bd_intf_net [get_bd_intf_pins gmii_to_rgmii_1/RGMII] [get_bd_intf_ports rgmii_port_1]

# PHY RESETs
create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic util_reduced_logic_0
set_property -dict [list CONFIG.C_SIZE {1}] [get_bd_cells util_reduced_logic_0]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins util_reduced_logic_0/Op1]
create_bd_port -dir O reset_port_0
connect_bd_net [get_bd_pins /util_reduced_logic_0/Res] [get_bd_ports reset_port_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic util_reduced_logic_1
set_property -dict [list CONFIG.C_SIZE {1}] [get_bd_cells util_reduced_logic_1]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins util_reduced_logic_1/Op1]
create_bd_port -dir O reset_port_1
connect_bd_net [get_bd_pins /util_reduced_logic_1/Res] [get_bd_ports reset_port_1]

# Connect the clocks
connect_bd_net [get_bd_pins gmii_to_rgmii_0/ref_clk_out] [get_bd_pins gmii_to_rgmii_1/ref_clk_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/mmcm_locked_out] [get_bd_pins gmii_to_rgmii_1/mmcm_locked_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/gmii_clk_125m_out] [get_bd_pins gmii_to_rgmii_1/gmii_clk_125m_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/gmii_clk_25m_out] [get_bd_pins gmii_to_rgmii_1/gmii_clk_25m_in]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/gmii_clk_2_5m_out] [get_bd_pins gmii_to_rgmii_1/gmii_clk_2_5m_in]

# Create clock wizard for the 375MHz clock

create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_0
set_property -dict [list CONFIG.PRIM_IN_FREQ.VALUE_SRC USER] [get_bd_cells clk_wiz_0]
set_property -dict [list CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
CONFIG.PRIM_IN_FREQ {125} \
CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {375} \
CONFIG.USE_LOCKED {false} \
CONFIG.USE_RESET {false} \
CONFIG.CLKIN1_JITTER_PS {80.0} \
CONFIG.MMCM_DIVCLK_DIVIDE {1} \
CONFIG.MMCM_CLKFBOUT_MULT_F {9.750} \
CONFIG.MMCM_CLKOUT0_DIVIDE_F {3.250} \
CONFIG.CLKOUT1_JITTER {86.562} \
CONFIG.CLKOUT1_PHASE_ERROR {84.521}] [get_bd_cells clk_wiz_0]

connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins gmii_to_rgmii_0/clkin]

# Connect ports for the Ethernet FMC 125MHz clock
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk
set_property -dict [list CONFIG.FREQ_HZ {125000000}] [get_bd_intf_ports ref_clk]
connect_bd_intf_net [get_bd_intf_ports ref_clk] [get_bd_intf_pins clk_wiz_0/CLK_IN1_D]

# Create Ethernet FMC reference clock output enable and frequency select
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant ref_clk_oe
create_bd_port -dir O -from 0 -to 0 ref_clk_oe
connect_bd_net [get_bd_pins /ref_clk_oe/dout] [get_bd_ports ref_clk_oe]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant ref_clk_fsel
create_bd_port -dir O -from 0 -to 0 ref_clk_fsel
connect_bd_net [get_bd_pins /ref_clk_fsel/dout] [get_bd_ports ref_clk_fsel]

# Connect GMII-to-RGMII resets

connect_bd_net [get_bd_pins util_vector_logic_0/Res] [get_bd_pins gmii_to_rgmii_0/tx_reset]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/rx_reset] [get_bd_pins util_vector_logic_0/Res]
connect_bd_net [get_bd_pins gmii_to_rgmii_1/tx_reset] [get_bd_pins util_vector_logic_0/Res]
connect_bd_net [get_bd_pins gmii_to_rgmii_1/rx_reset] [get_bd_pins util_vector_logic_0/Res]

# FIFOs for GMII loopback
create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator fifo_generator_0
set_property -dict [list CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} CONFIG.Input_Data_Width {10} CONFIG.Valid_Flag {true} CONFIG.Write_Acknowledge_Flag {false} CONFIG.Output_Data_Width {10} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Full_Flags_Reset_Value {1} CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} CONFIG.Full_Threshold_Assert_Value {600} CONFIG.Full_Threshold_Negate_Value {599} CONFIG.Programmable_Empty_Type {Single_Programmable_Empty_Threshold_Constant} CONFIG.Empty_Threshold_Assert_Value {400} CONFIG.Empty_Threshold_Negate_Value {401}] [get_bd_cells fifo_generator_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator fifo_generator_1
set_property -dict [list CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} CONFIG.Input_Data_Width {10} CONFIG.Valid_Flag {true} CONFIG.Write_Acknowledge_Flag {false} CONFIG.Output_Data_Width {10} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Full_Flags_Reset_Value {1} CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} CONFIG.Full_Threshold_Assert_Value {600} CONFIG.Full_Threshold_Negate_Value {599} CONFIG.Programmable_Empty_Type {Single_Programmable_Empty_Threshold_Constant} CONFIG.Empty_Threshold_Assert_Value {400} CONFIG.Empty_Threshold_Negate_Value {401}] [get_bd_cells fifo_generator_1]

# FIFO resets (connected to link status of both GMII-to-RGMII blocks)
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic link_status_and_gate
set_property -dict [list CONFIG.C_SIZE {1}] [get_bd_cells link_status_and_gate]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/link_status] [get_bd_pins link_status_and_gate/Op1]
connect_bd_net [get_bd_pins gmii_to_rgmii_1/link_status] [get_bd_pins link_status_and_gate/Op2]

create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic link_status_not_gate
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not}] [get_bd_cells link_status_not_gate]
connect_bd_net [get_bd_pins link_status_and_gate/Res] [get_bd_pins link_status_not_gate/Op1]

connect_bd_net [get_bd_pins fifo_generator_0/rst] [get_bd_pins link_status_not_gate/Res]
connect_bd_net [get_bd_pins fifo_generator_1/rst] [get_bd_pins link_status_not_gate/Res]

# Concats to combine GMII data, GMII valid and GMII error signals on the receive side
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0
set_property -dict [list CONFIG.IN0_WIDTH.VALUE_SRC USER CONFIG.IN1_WIDTH.VALUE_SRC USER] [get_bd_cells xlconcat_0]
set_property -dict [list CONFIG.IN0_WIDTH {8}] [get_bd_cells xlconcat_0]
set_property -dict [list CONFIG.NUM_PORTS {3}] [get_bd_cells xlconcat_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_1
set_property -dict [list CONFIG.IN0_WIDTH.VALUE_SRC USER CONFIG.IN1_WIDTH.VALUE_SRC USER] [get_bd_cells xlconcat_1]
set_property -dict [list CONFIG.IN0_WIDTH {8}] [get_bd_cells xlconcat_1]
set_property -dict [list CONFIG.NUM_PORTS {3}] [get_bd_cells xlconcat_1]

# Slices to split GMII data, GMII valid and GMII error signals on the transmit side
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_data_0
set_property -dict [list CONFIG.DIN_WIDTH {10} CONFIG.DIN_TO {0} CONFIG.DIN_FROM {7} CONFIG.DOUT_WIDTH {8}] [get_bd_cells xlslice_data_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_error_0
set_property -dict [list CONFIG.DIN_WIDTH {10} CONFIG.DIN_TO {8} CONFIG.DIN_FROM {8} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_error_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_valid_0
set_property -dict [list CONFIG.DIN_WIDTH {10} CONFIG.DIN_TO {9} CONFIG.DIN_FROM {9} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_valid_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_data_1
set_property -dict [list CONFIG.DIN_WIDTH {10} CONFIG.DIN_TO {0} CONFIG.DIN_FROM {7} CONFIG.DOUT_WIDTH {8}] [get_bd_cells xlslice_data_1]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_error_1
set_property -dict [list CONFIG.DIN_WIDTH {10} CONFIG.DIN_TO {8} CONFIG.DIN_FROM {8} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_error_1]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_valid_1
set_property -dict [list CONFIG.DIN_WIDTH {10} CONFIG.DIN_TO {9} CONFIG.DIN_FROM {9} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_valid_1]

connect_bd_net [get_bd_pins fifo_generator_0/dout] [get_bd_pins xlslice_data_0/Din]
connect_bd_net [get_bd_pins xlslice_error_0/Din] [get_bd_pins fifo_generator_0/dout]
connect_bd_net [get_bd_pins xlslice_valid_0/Din] [get_bd_pins fifo_generator_0/dout]
connect_bd_net [get_bd_pins fifo_generator_1/dout] [get_bd_pins xlslice_data_1/Din]
connect_bd_net [get_bd_pins xlslice_error_1/Din] [get_bd_pins fifo_generator_1/dout]
connect_bd_net [get_bd_pins xlslice_valid_1/Din] [get_bd_pins fifo_generator_1/dout]

# Connect GMII loopback receive side
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins fifo_generator_0/din]
connect_bd_net [get_bd_pins xlconcat_1/dout] [get_bd_pins fifo_generator_1/din]

connect_bd_net [get_bd_pins gmii_to_rgmii_0/gmii_rxd] [get_bd_pins xlconcat_0/In0]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/gmii_rx_er] [get_bd_pins xlconcat_0/In1]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/gmii_rx_dv] [get_bd_pins xlconcat_0/In2]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/gmii_rx_clk] [get_bd_pins fifo_generator_0/wr_clk]
connect_bd_net [get_bd_pins gmii_to_rgmii_1/gmii_rxd] [get_bd_pins xlconcat_1/In0]
connect_bd_net [get_bd_pins gmii_to_rgmii_1/gmii_rx_er] [get_bd_pins xlconcat_1/In1]
connect_bd_net [get_bd_pins gmii_to_rgmii_1/gmii_rx_dv] [get_bd_pins xlconcat_1/In2]
connect_bd_net [get_bd_pins gmii_to_rgmii_1/gmii_rx_clk] [get_bd_pins fifo_generator_1/wr_clk]

# Connect GMII loopback transmit side
connect_bd_net [get_bd_pins xlslice_data_1/Dout] [get_bd_pins gmii_to_rgmii_0/gmii_txd]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/gmii_tx_er] [get_bd_pins xlslice_error_1/Dout]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/gmii_tx_en] [get_bd_pins xlslice_valid_1/Dout]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/gmii_tx_clk] [get_bd_pins fifo_generator_1/rd_clk]

connect_bd_net [get_bd_pins xlslice_data_0/Dout] [get_bd_pins gmii_to_rgmii_1/gmii_txd]
connect_bd_net [get_bd_pins gmii_to_rgmii_1/gmii_tx_er] [get_bd_pins xlslice_error_0/Dout]
connect_bd_net [get_bd_pins gmii_to_rgmii_1/gmii_tx_en] [get_bd_pins xlslice_valid_0/Dout]
connect_bd_net [get_bd_pins gmii_to_rgmii_1/gmii_tx_clk] [get_bd_pins fifo_generator_0/rd_clk]

# Logic for elastic buffers: OR gates
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic or_gate_wr_en_fifo_0
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {or}] [get_bd_cells or_gate_wr_en_fifo_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic or_gate_rd_en_fifo_0
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {or}] [get_bd_cells or_gate_rd_en_fifo_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic or_gate_wr_en_fifo_1
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {or}] [get_bd_cells or_gate_wr_en_fifo_1]
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic or_gate_rd_en_fifo_1
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {or}] [get_bd_cells or_gate_rd_en_fifo_1]

# Logic for elastic buffers: NOT gates
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic not_gate_full_fifo_0
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not}] [get_bd_cells not_gate_full_fifo_0]
connect_bd_net [get_bd_pins fifo_generator_0/prog_full] [get_bd_pins not_gate_full_fifo_0/Op1]
connect_bd_net [get_bd_pins not_gate_full_fifo_0/Res] [get_bd_pins or_gate_wr_en_fifo_0/Op1]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/gmii_rx_dv] [get_bd_pins or_gate_wr_en_fifo_0/Op2]
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic not_gate_full_fifo_1
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not}] [get_bd_cells not_gate_full_fifo_1]
connect_bd_net [get_bd_pins fifo_generator_1/prog_full] [get_bd_pins not_gate_full_fifo_1/Op1]
connect_bd_net [get_bd_pins not_gate_full_fifo_1/Res] [get_bd_pins or_gate_wr_en_fifo_1/Op1]
connect_bd_net [get_bd_pins gmii_to_rgmii_1/gmii_rx_dv] [get_bd_pins or_gate_wr_en_fifo_1/Op2]
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic not_gate_empty_fifo_0
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not}] [get_bd_cells not_gate_empty_fifo_0]
connect_bd_net [get_bd_pins fifo_generator_0/prog_empty] [get_bd_pins not_gate_empty_fifo_0/Op1]
connect_bd_net [get_bd_pins not_gate_empty_fifo_0/Res] [get_bd_pins or_gate_rd_en_fifo_0/Op1]
connect_bd_net [get_bd_pins gmii_to_rgmii_1/gmii_tx_en] [get_bd_pins or_gate_rd_en_fifo_0/Op2]
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic not_gate_empty_fifo_1
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not}] [get_bd_cells not_gate_empty_fifo_1]
connect_bd_net [get_bd_pins fifo_generator_1/prog_empty] [get_bd_pins not_gate_empty_fifo_1/Op1]
connect_bd_net [get_bd_pins not_gate_empty_fifo_1/Res] [get_bd_pins or_gate_rd_en_fifo_1/Op1]
connect_bd_net [get_bd_pins gmii_to_rgmii_0/gmii_tx_en] [get_bd_pins or_gate_rd_en_fifo_1/Op2]

# Logic for elastic buffers: Connections to WR_EN and RD_EN
connect_bd_net [get_bd_pins or_gate_rd_en_fifo_0/Res] [get_bd_pins fifo_generator_0/rd_en]
connect_bd_net [get_bd_pins or_gate_rd_en_fifo_1/Res] [get_bd_pins fifo_generator_1/rd_en]
connect_bd_net [get_bd_pins or_gate_wr_en_fifo_0/Res] [get_bd_pins fifo_generator_0/wr_en]
connect_bd_net [get_bd_pins or_gate_wr_en_fifo_1/Res] [get_bd_pins fifo_generator_1/wr_en]

# Rename the 125MHz clock net name so that the Xilinx generated constraints will work
set_property name gmii_clk_125m_out [get_bd_nets gmii_to_rgmii_0_gmii_clk_125m_out]

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design
