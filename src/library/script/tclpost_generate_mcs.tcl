# TCL hook script for STEPS.WRITE_BITSTREAM.TCL.POST
# NOTE: This script cannot be sourced in Vivado TCL console because it expects its environment to be that of a TCL hook script.

proc tclpost_generate_mcs { } {
  set top_name {two_layer_net}
  write_cfgmem \
    -force \
    -format mcs \
    -size 128 \
    -interface BPIx16 \
    -loadbit "up 0x1000000 ${top_name}.bit" \
    "${top_name}"
}

tclpost_generate_mcs
