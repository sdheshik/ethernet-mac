
set_property MARK_DEBUG false [get_nets {eth_phy/phy_rxd[0]}]
set_property MARK_DEBUG false [get_nets {eth_phy/phy_rxd[1]}]









connect_debug_port u_ila_0/probe0 [get_nets [list {crc_gen/lfsr_q[0]} {crc_gen/lfsr_q[1]} {crc_gen/lfsr_q[2]} {crc_gen/lfsr_q[3]} {crc_gen/lfsr_q[4]} {crc_gen/lfsr_q[5]} {crc_gen/lfsr_q[6]} {crc_gen/lfsr_q[7]} {crc_gen/lfsr_q[8]} {crc_gen/lfsr_q[9]} {crc_gen/lfsr_q[10]} {crc_gen/lfsr_q[11]} {crc_gen/lfsr_q[12]} {crc_gen/lfsr_q[13]} {crc_gen/lfsr_q[14]} {crc_gen/lfsr_q[15]} {crc_gen/lfsr_q[16]} {crc_gen/lfsr_q[17]} {crc_gen/lfsr_q[18]} {crc_gen/lfsr_q[19]} {crc_gen/lfsr_q[20]} {crc_gen/lfsr_q[21]} {crc_gen/lfsr_q[22]} {crc_gen/lfsr_q[23]} {crc_gen/lfsr_q[24]} {crc_gen/lfsr_q[25]} {crc_gen/lfsr_q[26]} {crc_gen/lfsr_q[27]} {crc_gen/lfsr_q[28]} {crc_gen/lfsr_q[29]} {crc_gen/lfsr_q[30]} {crc_gen/lfsr_q[31]}]]
connect_debug_port u_ila_0/probe15 [get_nets [list crc_gen/crc_enable]]





create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_50m/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {crc_check/lfsr_q[0]} {crc_check/lfsr_q[1]} {crc_check/lfsr_q[2]} {crc_check/lfsr_q[3]} {crc_check/lfsr_q[4]} {crc_check/lfsr_q[5]} {crc_check/lfsr_q[6]} {crc_check/lfsr_q[7]} {crc_check/lfsr_q[8]} {crc_check/lfsr_q[9]} {crc_check/lfsr_q[10]} {crc_check/lfsr_q[11]} {crc_check/lfsr_q[12]} {crc_check/lfsr_q[13]} {crc_check/lfsr_q[14]} {crc_check/lfsr_q[15]} {crc_check/lfsr_q[16]} {crc_check/lfsr_q[17]} {crc_check/lfsr_q[18]} {crc_check/lfsr_q[19]} {crc_check/lfsr_q[20]} {crc_check/lfsr_q[21]} {crc_check/lfsr_q[22]} {crc_check/lfsr_q[23]} {crc_check/lfsr_q[24]} {crc_check/lfsr_q[25]} {crc_check/lfsr_q[26]} {crc_check/lfsr_q[27]} {crc_check/lfsr_q[28]} {crc_check/lfsr_q[29]} {crc_check/lfsr_q[30]} {crc_check/lfsr_q[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 8 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {eth_phy/byte_buffer[0]} {eth_phy/byte_buffer[1]} {eth_phy/byte_buffer[2]} {eth_phy/byte_buffer[3]} {eth_phy/byte_buffer[4]} {eth_phy/byte_buffer[5]} {eth_phy/byte_buffer[6]} {eth_phy/byte_buffer[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 8 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {eth_phy/assembled_byte[0]} {eth_phy/assembled_byte[1]} {eth_phy/assembled_byte[2]} {eth_phy/assembled_byte[3]} {eth_phy/assembled_byte[4]} {eth_phy/assembled_byte[5]} {eth_phy/assembled_byte[6]} {eth_phy/assembled_byte[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 8 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {crc_gen_data[0]} {crc_gen_data[1]} {crc_gen_data[2]} {crc_gen_data[3]} {crc_gen_data[4]} {crc_gen_data[5]} {crc_gen_data[6]} {crc_gen_data[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 2 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {phy_txd_sig[0]} {phy_txd_sig[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 8 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {mac_rx_byte[0]} {mac_rx_byte[1]} {mac_rx_byte[2]} {mac_rx_byte[3]} {mac_rx_byte[4]} {mac_rx_byte[5]} {mac_rx_byte[6]} {mac_rx_byte[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 4 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {eth_phy/nibble_cnt[0]} {eth_phy/nibble_cnt[1]} {eth_phy/nibble_cnt[2]} {eth_phy/nibble_cnt[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 2 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {eth_phy/p_state_1[0]} {eth_phy/p_state_1[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 5 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {eth_phy/preamble_cnt_1[0]} {eth_phy/preamble_cnt_1[1]} {eth_phy/preamble_cnt_1[2]} {eth_phy/preamble_cnt_1[3]} {eth_phy/preamble_cnt_1[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 32 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {crc_tx[0]} {crc_tx[1]} {crc_tx[2]} {crc_tx[3]} {crc_tx[4]} {crc_tx[5]} {crc_tx[6]} {crc_tx[7]} {crc_tx[8]} {crc_tx[9]} {crc_tx[10]} {crc_tx[11]} {crc_tx[12]} {crc_tx[13]} {crc_tx[14]} {crc_tx[15]} {crc_tx[16]} {crc_tx[17]} {crc_tx[18]} {crc_tx[19]} {crc_tx[20]} {crc_tx[21]} {crc_tx[22]} {crc_tx[23]} {crc_tx[24]} {crc_tx[25]} {crc_tx[26]} {crc_tx[27]} {crc_tx[28]} {crc_tx[29]} {crc_tx[30]} {crc_tx[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 3 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {eth_phy/p_state[0]} {eth_phy/p_state[1]} {eth_phy/p_state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 8 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {mac_byte[0]} {mac_byte[1]} {mac_byte[2]} {mac_byte[3]} {mac_byte[4]} {mac_byte[5]} {mac_byte[6]} {mac_byte[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 2 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {phy_rxd_sig[0]} {phy_rxd_sig[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list eth_phy/byte_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list crc_check/crc_enable]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list crc_ge/crc_enable]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list init]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list mac_rd_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 1 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list phy_crs_dv_sig]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 1 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list phy_tx_en_sig]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 1 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list phy_wr_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 1 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list tx_fifo_empty]]
set_property C_CLK_INPUT_FREQ_HZ 50000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk_IBUF]
