vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xpm  -incr -sv "+incdir+../../../../ethernet.gen/sources_1/ip/vio_reset/hdl/verilog" "+incdir+../../../../ethernet.gen/sources_1/ip/vio_reset/hdl" \
"C:/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm  -93 \
"C:/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xil_defaultlib  -93 \
"../../../../ethernet.gen/sources_1/ip/vio_reset/sim/vio_reset.vhd" \


vlog -work xil_defaultlib \
"glbl.v"

