###############################################################################
 #  Copyright (c) 2016, Xilinx, Inc.
 #  All rights reserved.
 #
 #  Redistribution and use in source and binary forms, with or without
 #  modification, are permitted provided that the following conditions are met:
 #
 #  1.  Redistributions of source code must retain the above copyright notice,
 #     this list of conditions and the following disclaimer.
 #
 #  2.  Redistributions in binary form must reproduce the above copyright
 #      notice, this list of conditions and the following disclaimer in the
 #      documentation and/or other materials provided with the distribution.
 #
 #  3.  Neither the name of the copyright holder nor the names of its
 #      contributors may be used to endorse or promote products derived from
 #      this software without specific prior written permission.
 #
 #  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 #  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 #  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 #  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 #  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 #  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 #  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 #  OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 #  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 #  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 #  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 #
###############################################################################
###############################################################################
 #
 #
 # @file make-vivado-proj.tcl
 #
 # tcl script for block design and bitstream generation. Automatically 
 # launched by make-hw.sh. Tested with Vivado 2016.1
 #
 #
###############################################################################

# Creates a Vivado project ready for synthesis and launches bitstream generation
if {$argc != 4} {
  puts "Expected: <jam repo> <proj name> <proj dir> <xdc_dir>"
  exit
}

# Paths to donut and jam IP folders
set config_jam_repo [lindex $argv 0]

# Project name, target dir and FPGA part to use
set config_proj_name [lindex $argv 1]
set config_proj_dir [lindex $argv 2]
set config_proj_part "xc7vx690tffg1157-2"

# Other project config
set xdc_dir [lindex $argv 3]
set vhd_dir [lindex $argv 3]
set tcl_dir [lindex $argv 3]

# Define versions of dependencies in one convenient place
source "$tcl_dir/version.tcl"

# Set up project
create_project $config_proj_name $config_proj_dir -part $config_proj_part
set project [get_projects $config_proj_name]
set_property "default_lib" "xil_defaultlib" $project
set_property "part" $config_proj_part $project
set_property "simulator_language" "Mixed" $project
set_property "target_language" "Verilog" $project
set repo_paths [list \
  [file normalize "$config_jam_repo"] \
  [file normalize "/root/fpga/repo/vivado-2014.4"] \
]
set_property ip_repo_paths $repo_paths $project
set_property source_mgmt_mode None [current_project]
update_ip_catalog

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}
set source_set [get_filesets sources_1]

# Set source set properties
set_property "top" "two_layer_net" $source_set

# Add HDL source files
set hdl_files [list \
  [file normalize "${vhd_dir}/two_layer_net.vhd"] \
]
if { [llength $hdl_files] > 0 } {
  add_files -norecurse -fileset $source_set $hdl_files
}

# Create IPs
create_ip -vlnv "alphadata:user:adb3_admpcie7v3_x8_axi4_ipi:${bchi_ver}" -module_name adb3_admpcie7v3_m
set ip_adb3_admpcie7v3_m [get_ips adb3_admpcie7v3_m]
set_property -dict { \
  {CONFIG.bar2_size}                 {15} \
  {CONFIG.disable_model_io}          {false} \
  {CONFIG.dma_engine0_config}        {0} \
  {CONFIG.dma_engine1_config}        {0} \
  {CONFIG.dma_engine2_config}        {0} \
  {CONFIG.dma_engine3_config}        {0} \
  {CONFIG.enable_dma_abort}          {false} \
  {CONFIG.enable_interrupt}          {false} \
  {CONFIG.number_of_bar01_dm_ports}  {0} \
  {CONFIG.number_of_dma_engines}     {2} \
  {CONFIG.number_of_pcie_dm_ports}   {0} \
  {CONFIG.pcie_dm_port_id_width}     {1} \
  {CONFIG.use_axi4_pcie_legalizer}   {false} \
  {CONFIG.use_diff_ref_clock}        {true} \
  {CONFIG.use_icap}                  {true} \
} $ip_adb3_admpcie7v3_m

create_ip -vlnv "xilinx.com:ip:axi_dwidth_converter:2.1" -module_name axi_dwidth_converter_dma_m
set ip_axi_dwidth_converter_dma_m [get_ips axi_dwidth_converter_dma_m]
set_property -dict { \
  {CONFIG.MI_CLK.FREQ_HZ} {250000000} \
  {CONFIG.SI_CLK.FREQ_HZ} {250000000} \
  {CONFIG.ACLK_RATIO} {1:1} \
  {CONFIG.ADDR_WIDTH} {33} \
  {CONFIG.MI_DATA_WIDTH} {512} \
  {CONFIG.SI_DATA_WIDTH} {256} \
} $ip_axi_dwidth_converter_dma_m

create_ip -vlnv "xilinx.com:ip:axi_dwidth_converter:2.1" -module_name axi_dwidth_converter_pre_hls_m
set ip_axi_dwidth_converter_pre_hls_m [get_ips axi_dwidth_converter_pre_hls_m]
set_property -dict { \
  {CONFIG.MI_CLK.FREQ_HZ} {250000000} \
  {CONFIG.SI_CLK.FREQ_HZ} {250000000} \
  {CONFIG.ACLK_RATIO} {1:1} \
  {CONFIG.ADDR_WIDTH} {12} \
  {CONFIG.MI_DATA_WIDTH} {32} \
  {CONFIG.SI_DATA_WIDTH} {256} \
} $ip_axi_dwidth_converter_pre_hls_m

create_ip -vlnv "xilinx.com:ip:axi_protocol_converter:2.1" -module_name axi_protocol_converter_hls_m
set ip_axi_protocol_converter_hls_m [get_ips axi_protocol_converter_hls_m]
set_property -dict { \
  {CONFIG.CLK.FREQ_HZ} {250000000} \
  {CONFIG.DATA_WIDTH}  {32} \
  {CONFIG.ADDR_WIDTH}  {12} \
  {CONFIG.MI_PROTOCOL} {AXI4LITE} \
  {CONFIG.SI_PROTOCOL} {AXI4} \
} $ip_axi_protocol_converter_hls_m

create_ip -vlnv "xilinx.com:hls:BlackBoxJam:1.0" -module_name two_layer_net_m

create_ip -vlnv "xilinx.com:ip:axi_dwidth_converter:2.1" -module_name axi_dwidth_converter_post_hls_m
set ip_axi_dwidth_converter_post_hls_m [get_ips axi_dwidth_converter_post_hls_m]
set_property -dict { \
  {CONFIG.MI_CLK.FREQ_HZ} {250000000} \
  {CONFIG.SI_CLK.FREQ_HZ} {250000000} \
  {CONFIG.ACLK_RATIO} {1:1} \
  {CONFIG.ADDR_WIDTH} {33} \
  {CONFIG.MI_DATA_WIDTH} {512} \
  {CONFIG.SI_DATA_WIDTH} {32} \
} $ip_axi_dwidth_converter_post_hls_m

create_ip -vlnv "xilinx.com:ip:axi_crossbar:2.1" -module_name axi_crossbar_c0_m
set ip_axi_crossbar_c0_m [get_ips axi_crossbar_c0_m]
set_property -dict { \
  {CONFIG.NUM_MI} {1} \
  {CONFIG.NUM_SI} {2} \
  {CONFIG.CLKIF.FREQ_HZ} {250000000} \
  {CONFIG.ADDR_WIDTH} {33} \
  {CONFIG.DATA_WIDTH} {512} \
  {CONFIG.STRATEGY} {2} \
  {CONFIG.CONNECTIVITY_MODE} {SAMD} \
  {CONFIG.M00_A00_BASE_ADDR} {0x0000000000000000} \
  {CONFIG.M00_A00_ADDR_WIDTH} {33} \
  {CONFIG.M00_READ_ISSUING} {16} \
  {CONFIG.M00_WRITE_ISSUING} {16} \
  {CONFIG.S00_BASE_ID} {0x00000000} \
  {CONFIG.S00_READ_ACCEPTANCE} {16} \
  {CONFIG.S00_WRITE_ACCEPTANCE} {16} \
  {CONFIG.S01_BASE_ID} {0x00000001} \
  {CONFIG.S01_READ_ACCEPTANCE} {16} \
  {CONFIG.S01_WRITE_ACCEPTANCE} {16} \
} $ip_axi_crossbar_c0_m

create_ip -vlnv "xilinx.com:ip:axi_bram_ctrl:4.0" -module_name axi_bram_ctrl_m
# NOTE(wtakase): DATA_WIDTH / 8 * MEM_DEPTH = MEM_SIZE [Byte]
set ip_axi_bram_ctrl_m [get_ips axi_bram_ctrl_m]
set_property -dict { \
  {CONFIG.CLKIF.FREQ_HZ}      {250000000} \
  {CONFIG.DATA_WIDTH}         {512} \
  {CONFIG.MEM_DEPTH}          {16384} \
  {CONFIG.SINGLE_PORT_BRAM}   {1} \
} $ip_axi_bram_ctrl_m

create_ip -vlnv "xilinx.com:ip:blk_mem_gen:8.3" -module_name blk_mem_gen_m
set ip_blk_mem_gen_m [get_ips blk_mem_gen_m]
set_property -dict { \
  {CONFIG.Port_A_Clock}   {250} \
  {CONFIG.Read_Width_A}   {512} \
  {CONFIG.Write_Width_A}  {512} \
  {CONFIG.Memory_Type}    {Single_Port_RAM} \
  {CONFIG.use_bram_block} {BRAM_Controller} \
} $ip_blk_mem_gen_m

upgrade_ip [get_ips]

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}
set constraint_set [get_filesets constrs_1]

# Add constraints files
# Put target .xdc as first in list
set constraint_files [list \
  [file normalize "$xdc_dir/two_layer_net.xdc"] \
  [file normalize "$xdc_dir/bitstream.xdc"] \
  [file normalize "$xdc_dir/adb3_admpcie7v3-pcie_x0y2.xdc"] \
  [file normalize "$xdc_dir/refclk200.xdc"] \
]
if { [llength $constraint_files] > 0 } {
  add_files -norecurse -fileset $constraint_set $constraint_files
  set_property "target_constrs_file" [lindex $constraint_files 0] $constraint_set
}

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part $config_proj_part -flow {Vivado Synthesis 2017} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
}
set synth_run [get_runs synth_1]
set_property "needs_refresh" "1" $synth_run
set_property "part" $config_proj_part $synth_run
current_run -synthesis $synth_run

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part $config_proj_part -flow {Vivado Implementation 2017} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
}
set impl_run [get_runs impl_1]
set_property "needs_refresh" "1" $impl_run
set_property "part" $config_proj_part $impl_run
set_property {STEPS.PHYS_OPT_DESIGN.IS_ENABLED} true $impl_run
set_property {STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED} true $impl_run
set_property {STEPS.WRITE_BITSTREAM.TCL.POST} {/root/fpga/two_layer_net/src/library/script/tclpost_generate_mcs.tcl} $impl_run
current_run -implementation $impl_run

# Launch bitstream generation
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# Program
#set device {xc7vx690t_0}
#open_hw
#connect_hw_server
#open_hw_target
#current_hw_device [get_hw_devices $device]
#refresh_hw_device -update_hw_probes false [lindex [get_hw_devices $device] 0]
#set_property FULL_PROBES.FILE {} [get_hw_devices $device]
#set_property PROGRAM.FILE {${config_proj_dir}/${config_proj_name}.runs/impl_1/two_layer_net.bit} [get_hw_devices $device]
#program_hw_devices [get_hw_devices $device]
#refresh_hw_device [lindex [get_hw_devices $device] 0]
