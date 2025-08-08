

connect_debug_port u_ila_0/probe17 [get_nets [list crc_ge/crc_enable]]

connect_debug_port u_ila_0/probe15 [get_nets [list {crc_ge/crc_reg[0]} {crc_ge/crc_reg[1]} {crc_ge/crc_reg[2]} {crc_ge/crc_reg[3]} {crc_ge/crc_reg[4]} {crc_ge/crc_reg[5]} {crc_ge/crc_reg[6]} {crc_ge/crc_reg[7]} {crc_ge/crc_reg[8]} {crc_ge/crc_reg[9]} {crc_ge/crc_reg[10]} {crc_ge/crc_reg[11]} {crc_ge/crc_reg[12]} {crc_ge/crc_reg[13]} {crc_ge/crc_reg[14]} {crc_ge/crc_reg[15]} {crc_ge/crc_reg[16]} {crc_ge/crc_reg[17]} {crc_ge/crc_reg[18]} {crc_ge/crc_reg[19]} {crc_ge/crc_reg[20]} {crc_ge/crc_reg[21]} {crc_ge/crc_reg[22]} {crc_ge/crc_reg[23]} {crc_ge/crc_reg[24]} {crc_ge/crc_reg[25]} {crc_ge/crc_reg[26]} {crc_ge/crc_reg[27]} {crc_ge/crc_reg[28]} {crc_ge/crc_reg[29]} {crc_ge/crc_reg[30]} {crc_ge/crc_reg[31]}]]

connect_debug_port u_ila_0/probe17 [get_nets [list crc_ge/crc_enable]]


connect_debug_port u_ila_0/probe1 [get_nets [list {crc_ge/lfsr_q[0]} {crc_ge/lfsr_q[1]} {crc_ge/lfsr_q[2]} {crc_ge/lfsr_q[3]} {crc_ge/lfsr_q[4]} {crc_ge/lfsr_q[5]} {crc_ge/lfsr_q[6]} {crc_ge/lfsr_q[7]} {crc_ge/lfsr_q[8]} {crc_ge/lfsr_q[9]} {crc_ge/lfsr_q[10]} {crc_ge/lfsr_q[11]} {crc_ge/lfsr_q[12]} {crc_ge/lfsr_q[13]} {crc_ge/lfsr_q[14]} {crc_ge/lfsr_q[15]} {crc_ge/lfsr_q[16]} {crc_ge/lfsr_q[17]} {crc_ge/lfsr_q[18]} {crc_ge/lfsr_q[19]} {crc_ge/lfsr_q[20]} {crc_ge/lfsr_q[21]} {crc_ge/lfsr_q[22]} {crc_ge/lfsr_q[23]} {crc_ge/lfsr_q[24]} {crc_ge/lfsr_q[25]} {crc_ge/lfsr_q[26]} {crc_ge/lfsr_q[27]} {crc_ge/lfsr_q[28]} {crc_ge/lfsr_q[29]} {crc_ge/lfsr_q[30]} {crc_ge/lfsr_q[31]}]]
connect_debug_port u_ila_0/probe17 [get_nets [list crc_ge/crc_enable]]








create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
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
connect_debug_port u_ila_0/probe1 [get_nets [list {crc_ge/data_in[0]} {crc_ge/data_in[1]} {crc_ge/data_in[2]} {crc_ge/data_in[3]} {crc_ge/data_in[4]} {crc_ge/data_in[5]} {crc_ge/data_in[6]} {crc_ge/data_in[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 8 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {header_ctrl/fifo_in[0]} {header_ctrl/fifo_in[1]} {header_ctrl/fifo_in[2]} {header_ctrl/fifo_in[3]} {header_ctrl/fifo_in[4]} {header_ctrl/fifo_in[5]} {header_ctrl/fifo_in[6]} {header_ctrl/fifo_in[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {header_ctrl/udp_head/pay_count[0]} {header_ctrl/udp_head/pay_count[1]} {header_ctrl/udp_head/pay_count[2]} {header_ctrl/udp_head/pay_count[3]} {header_ctrl/udp_head/pay_count[4]} {header_ctrl/udp_head/pay_count[5]} {header_ctrl/udp_head/pay_count[6]} {header_ctrl/udp_head/pay_count[7]} {header_ctrl/udp_head/pay_count[8]} {header_ctrl/udp_head/pay_count[9]} {header_ctrl/udp_head/pay_count[10]} {header_ctrl/udp_head/pay_count[11]} {header_ctrl/udp_head/pay_count[12]} {header_ctrl/udp_head/pay_count[13]} {header_ctrl/udp_head/pay_count[14]} {header_ctrl/udp_head/pay_count[15]} {header_ctrl/udp_head/pay_count[16]} {header_ctrl/udp_head/pay_count[17]} {header_ctrl/udp_head/pay_count[18]} {header_ctrl/udp_head/pay_count[19]} {header_ctrl/udp_head/pay_count[20]} {header_ctrl/udp_head/pay_count[21]} {header_ctrl/udp_head/pay_count[22]} {header_ctrl/udp_head/pay_count[23]} {header_ctrl/udp_head/pay_count[24]} {header_ctrl/udp_head/pay_count[25]} {header_ctrl/udp_head/pay_count[26]} {header_ctrl/udp_head/pay_count[27]} {header_ctrl/udp_head/pay_count[28]} {header_ctrl/udp_head/pay_count[29]} {header_ctrl/udp_head/pay_count[30]} {header_ctrl/udp_head/pay_count[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 368 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {header_ctrl/udp_head/payload_fin[0]} {header_ctrl/udp_head/payload_fin[1]} {header_ctrl/udp_head/payload_fin[2]} {header_ctrl/udp_head/payload_fin[3]} {header_ctrl/udp_head/payload_fin[4]} {header_ctrl/udp_head/payload_fin[5]} {header_ctrl/udp_head/payload_fin[6]} {header_ctrl/udp_head/payload_fin[7]} {header_ctrl/udp_head/payload_fin[8]} {header_ctrl/udp_head/payload_fin[9]} {header_ctrl/udp_head/payload_fin[10]} {header_ctrl/udp_head/payload_fin[11]} {header_ctrl/udp_head/payload_fin[12]} {header_ctrl/udp_head/payload_fin[13]} {header_ctrl/udp_head/payload_fin[14]} {header_ctrl/udp_head/payload_fin[15]} {header_ctrl/udp_head/payload_fin[16]} {header_ctrl/udp_head/payload_fin[17]} {header_ctrl/udp_head/payload_fin[18]} {header_ctrl/udp_head/payload_fin[19]} {header_ctrl/udp_head/payload_fin[20]} {header_ctrl/udp_head/payload_fin[21]} {header_ctrl/udp_head/payload_fin[22]} {header_ctrl/udp_head/payload_fin[23]} {header_ctrl/udp_head/payload_fin[24]} {header_ctrl/udp_head/payload_fin[25]} {header_ctrl/udp_head/payload_fin[26]} {header_ctrl/udp_head/payload_fin[27]} {header_ctrl/udp_head/payload_fin[28]} {header_ctrl/udp_head/payload_fin[29]} {header_ctrl/udp_head/payload_fin[30]} {header_ctrl/udp_head/payload_fin[31]} {header_ctrl/udp_head/payload_fin[32]} {header_ctrl/udp_head/payload_fin[33]} {header_ctrl/udp_head/payload_fin[34]} {header_ctrl/udp_head/payload_fin[35]} {header_ctrl/udp_head/payload_fin[36]} {header_ctrl/udp_head/payload_fin[37]} {header_ctrl/udp_head/payload_fin[38]} {header_ctrl/udp_head/payload_fin[39]} {header_ctrl/udp_head/payload_fin[40]} {header_ctrl/udp_head/payload_fin[41]} {header_ctrl/udp_head/payload_fin[42]} {header_ctrl/udp_head/payload_fin[43]} {header_ctrl/udp_head/payload_fin[44]} {header_ctrl/udp_head/payload_fin[45]} {header_ctrl/udp_head/payload_fin[46]} {header_ctrl/udp_head/payload_fin[47]} {header_ctrl/udp_head/payload_fin[48]} {header_ctrl/udp_head/payload_fin[49]} {header_ctrl/udp_head/payload_fin[50]} {header_ctrl/udp_head/payload_fin[51]} {header_ctrl/udp_head/payload_fin[52]} {header_ctrl/udp_head/payload_fin[53]} {header_ctrl/udp_head/payload_fin[54]} {header_ctrl/udp_head/payload_fin[55]} {header_ctrl/udp_head/payload_fin[56]} {header_ctrl/udp_head/payload_fin[57]} {header_ctrl/udp_head/payload_fin[58]} {header_ctrl/udp_head/payload_fin[59]} {header_ctrl/udp_head/payload_fin[60]} {header_ctrl/udp_head/payload_fin[61]} {header_ctrl/udp_head/payload_fin[62]} {header_ctrl/udp_head/payload_fin[63]} {header_ctrl/udp_head/payload_fin[64]} {header_ctrl/udp_head/payload_fin[65]} {header_ctrl/udp_head/payload_fin[66]} {header_ctrl/udp_head/payload_fin[67]} {header_ctrl/udp_head/payload_fin[68]} {header_ctrl/udp_head/payload_fin[69]} {header_ctrl/udp_head/payload_fin[70]} {header_ctrl/udp_head/payload_fin[71]} {header_ctrl/udp_head/payload_fin[72]} {header_ctrl/udp_head/payload_fin[73]} {header_ctrl/udp_head/payload_fin[74]} {header_ctrl/udp_head/payload_fin[75]} {header_ctrl/udp_head/payload_fin[76]} {header_ctrl/udp_head/payload_fin[77]} {header_ctrl/udp_head/payload_fin[78]} {header_ctrl/udp_head/payload_fin[79]} {header_ctrl/udp_head/payload_fin[80]} {header_ctrl/udp_head/payload_fin[81]} {header_ctrl/udp_head/payload_fin[82]} {header_ctrl/udp_head/payload_fin[83]} {header_ctrl/udp_head/payload_fin[84]} {header_ctrl/udp_head/payload_fin[85]} {header_ctrl/udp_head/payload_fin[86]} {header_ctrl/udp_head/payload_fin[87]} {header_ctrl/udp_head/payload_fin[88]} {header_ctrl/udp_head/payload_fin[89]} {header_ctrl/udp_head/payload_fin[90]} {header_ctrl/udp_head/payload_fin[91]} {header_ctrl/udp_head/payload_fin[92]} {header_ctrl/udp_head/payload_fin[93]} {header_ctrl/udp_head/payload_fin[94]} {header_ctrl/udp_head/payload_fin[95]} {header_ctrl/udp_head/payload_fin[96]} {header_ctrl/udp_head/payload_fin[97]} {header_ctrl/udp_head/payload_fin[98]} {header_ctrl/udp_head/payload_fin[99]} {header_ctrl/udp_head/payload_fin[100]} {header_ctrl/udp_head/payload_fin[101]} {header_ctrl/udp_head/payload_fin[102]} {header_ctrl/udp_head/payload_fin[103]} {header_ctrl/udp_head/payload_fin[104]} {header_ctrl/udp_head/payload_fin[105]} {header_ctrl/udp_head/payload_fin[106]} {header_ctrl/udp_head/payload_fin[107]} {header_ctrl/udp_head/payload_fin[108]} {header_ctrl/udp_head/payload_fin[109]} {header_ctrl/udp_head/payload_fin[110]} {header_ctrl/udp_head/payload_fin[111]} {header_ctrl/udp_head/payload_fin[112]} {header_ctrl/udp_head/payload_fin[113]} {header_ctrl/udp_head/payload_fin[114]} {header_ctrl/udp_head/payload_fin[115]} {header_ctrl/udp_head/payload_fin[116]} {header_ctrl/udp_head/payload_fin[117]} {header_ctrl/udp_head/payload_fin[118]} {header_ctrl/udp_head/payload_fin[119]} {header_ctrl/udp_head/payload_fin[120]} {header_ctrl/udp_head/payload_fin[121]} {header_ctrl/udp_head/payload_fin[122]} {header_ctrl/udp_head/payload_fin[123]} {header_ctrl/udp_head/payload_fin[124]} {header_ctrl/udp_head/payload_fin[125]} {header_ctrl/udp_head/payload_fin[126]} {header_ctrl/udp_head/payload_fin[127]} {header_ctrl/udp_head/payload_fin[128]} {header_ctrl/udp_head/payload_fin[129]} {header_ctrl/udp_head/payload_fin[130]} {header_ctrl/udp_head/payload_fin[131]} {header_ctrl/udp_head/payload_fin[132]} {header_ctrl/udp_head/payload_fin[133]} {header_ctrl/udp_head/payload_fin[134]} {header_ctrl/udp_head/payload_fin[135]} {header_ctrl/udp_head/payload_fin[136]} {header_ctrl/udp_head/payload_fin[137]} {header_ctrl/udp_head/payload_fin[138]} {header_ctrl/udp_head/payload_fin[139]} {header_ctrl/udp_head/payload_fin[140]} {header_ctrl/udp_head/payload_fin[141]} {header_ctrl/udp_head/payload_fin[142]} {header_ctrl/udp_head/payload_fin[143]} {header_ctrl/udp_head/payload_fin[144]} {header_ctrl/udp_head/payload_fin[145]} {header_ctrl/udp_head/payload_fin[146]} {header_ctrl/udp_head/payload_fin[147]} {header_ctrl/udp_head/payload_fin[148]} {header_ctrl/udp_head/payload_fin[149]} {header_ctrl/udp_head/payload_fin[150]} {header_ctrl/udp_head/payload_fin[151]} {header_ctrl/udp_head/payload_fin[152]} {header_ctrl/udp_head/payload_fin[153]} {header_ctrl/udp_head/payload_fin[154]} {header_ctrl/udp_head/payload_fin[155]} {header_ctrl/udp_head/payload_fin[156]} {header_ctrl/udp_head/payload_fin[157]} {header_ctrl/udp_head/payload_fin[158]} {header_ctrl/udp_head/payload_fin[159]} {header_ctrl/udp_head/payload_fin[160]} {header_ctrl/udp_head/payload_fin[161]} {header_ctrl/udp_head/payload_fin[162]} {header_ctrl/udp_head/payload_fin[163]} {header_ctrl/udp_head/payload_fin[164]} {header_ctrl/udp_head/payload_fin[165]} {header_ctrl/udp_head/payload_fin[166]} {header_ctrl/udp_head/payload_fin[167]} {header_ctrl/udp_head/payload_fin[168]} {header_ctrl/udp_head/payload_fin[169]} {header_ctrl/udp_head/payload_fin[170]} {header_ctrl/udp_head/payload_fin[171]} {header_ctrl/udp_head/payload_fin[172]} {header_ctrl/udp_head/payload_fin[173]} {header_ctrl/udp_head/payload_fin[174]} {header_ctrl/udp_head/payload_fin[175]} {header_ctrl/udp_head/payload_fin[176]} {header_ctrl/udp_head/payload_fin[177]} {header_ctrl/udp_head/payload_fin[178]} {header_ctrl/udp_head/payload_fin[179]} {header_ctrl/udp_head/payload_fin[180]} {header_ctrl/udp_head/payload_fin[181]} {header_ctrl/udp_head/payload_fin[182]} {header_ctrl/udp_head/payload_fin[183]} {header_ctrl/udp_head/payload_fin[184]} {header_ctrl/udp_head/payload_fin[185]} {header_ctrl/udp_head/payload_fin[186]} {header_ctrl/udp_head/payload_fin[187]} {header_ctrl/udp_head/payload_fin[188]} {header_ctrl/udp_head/payload_fin[189]} {header_ctrl/udp_head/payload_fin[190]} {header_ctrl/udp_head/payload_fin[191]} {header_ctrl/udp_head/payload_fin[192]} {header_ctrl/udp_head/payload_fin[193]} {header_ctrl/udp_head/payload_fin[194]} {header_ctrl/udp_head/payload_fin[195]} {header_ctrl/udp_head/payload_fin[196]} {header_ctrl/udp_head/payload_fin[197]} {header_ctrl/udp_head/payload_fin[198]} {header_ctrl/udp_head/payload_fin[199]} {header_ctrl/udp_head/payload_fin[200]} {header_ctrl/udp_head/payload_fin[201]} {header_ctrl/udp_head/payload_fin[202]} {header_ctrl/udp_head/payload_fin[203]} {header_ctrl/udp_head/payload_fin[204]} {header_ctrl/udp_head/payload_fin[205]} {header_ctrl/udp_head/payload_fin[206]} {header_ctrl/udp_head/payload_fin[207]} {header_ctrl/udp_head/payload_fin[208]} {header_ctrl/udp_head/payload_fin[209]} {header_ctrl/udp_head/payload_fin[210]} {header_ctrl/udp_head/payload_fin[211]} {header_ctrl/udp_head/payload_fin[212]} {header_ctrl/udp_head/payload_fin[213]} {header_ctrl/udp_head/payload_fin[214]} {header_ctrl/udp_head/payload_fin[215]} {header_ctrl/udp_head/payload_fin[216]} {header_ctrl/udp_head/payload_fin[217]} {header_ctrl/udp_head/payload_fin[218]} {header_ctrl/udp_head/payload_fin[219]} {header_ctrl/udp_head/payload_fin[220]} {header_ctrl/udp_head/payload_fin[221]} {header_ctrl/udp_head/payload_fin[222]} {header_ctrl/udp_head/payload_fin[223]} {header_ctrl/udp_head/payload_fin[224]} {header_ctrl/udp_head/payload_fin[225]} {header_ctrl/udp_head/payload_fin[226]} {header_ctrl/udp_head/payload_fin[227]} {header_ctrl/udp_head/payload_fin[228]} {header_ctrl/udp_head/payload_fin[229]} {header_ctrl/udp_head/payload_fin[230]} {header_ctrl/udp_head/payload_fin[231]} {header_ctrl/udp_head/payload_fin[232]} {header_ctrl/udp_head/payload_fin[233]} {header_ctrl/udp_head/payload_fin[234]} {header_ctrl/udp_head/payload_fin[235]} {header_ctrl/udp_head/payload_fin[236]} {header_ctrl/udp_head/payload_fin[237]} {header_ctrl/udp_head/payload_fin[238]} {header_ctrl/udp_head/payload_fin[239]} {header_ctrl/udp_head/payload_fin[240]} {header_ctrl/udp_head/payload_fin[241]} {header_ctrl/udp_head/payload_fin[242]} {header_ctrl/udp_head/payload_fin[243]} {header_ctrl/udp_head/payload_fin[244]} {header_ctrl/udp_head/payload_fin[245]} {header_ctrl/udp_head/payload_fin[246]} {header_ctrl/udp_head/payload_fin[247]} {header_ctrl/udp_head/payload_fin[248]} {header_ctrl/udp_head/payload_fin[249]} {header_ctrl/udp_head/payload_fin[250]} {header_ctrl/udp_head/payload_fin[251]} {header_ctrl/udp_head/payload_fin[252]} {header_ctrl/udp_head/payload_fin[253]} {header_ctrl/udp_head/payload_fin[254]} {header_ctrl/udp_head/payload_fin[255]} {header_ctrl/udp_head/payload_fin[256]} {header_ctrl/udp_head/payload_fin[257]} {header_ctrl/udp_head/payload_fin[258]} {header_ctrl/udp_head/payload_fin[259]} {header_ctrl/udp_head/payload_fin[260]} {header_ctrl/udp_head/payload_fin[261]} {header_ctrl/udp_head/payload_fin[262]} {header_ctrl/udp_head/payload_fin[263]} {header_ctrl/udp_head/payload_fin[264]} {header_ctrl/udp_head/payload_fin[265]} {header_ctrl/udp_head/payload_fin[266]} {header_ctrl/udp_head/payload_fin[267]} {header_ctrl/udp_head/payload_fin[268]} {header_ctrl/udp_head/payload_fin[269]} {header_ctrl/udp_head/payload_fin[270]} {header_ctrl/udp_head/payload_fin[271]} {header_ctrl/udp_head/payload_fin[272]} {header_ctrl/udp_head/payload_fin[273]} {header_ctrl/udp_head/payload_fin[274]} {header_ctrl/udp_head/payload_fin[275]} {header_ctrl/udp_head/payload_fin[276]} {header_ctrl/udp_head/payload_fin[277]} {header_ctrl/udp_head/payload_fin[278]} {header_ctrl/udp_head/payload_fin[279]} {header_ctrl/udp_head/payload_fin[280]} {header_ctrl/udp_head/payload_fin[281]} {header_ctrl/udp_head/payload_fin[282]} {header_ctrl/udp_head/payload_fin[283]} {header_ctrl/udp_head/payload_fin[284]} {header_ctrl/udp_head/payload_fin[285]} {header_ctrl/udp_head/payload_fin[286]} {header_ctrl/udp_head/payload_fin[287]} {header_ctrl/udp_head/payload_fin[288]} {header_ctrl/udp_head/payload_fin[289]} {header_ctrl/udp_head/payload_fin[290]} {header_ctrl/udp_head/payload_fin[291]} {header_ctrl/udp_head/payload_fin[292]} {header_ctrl/udp_head/payload_fin[293]} {header_ctrl/udp_head/payload_fin[294]} {header_ctrl/udp_head/payload_fin[295]} {header_ctrl/udp_head/payload_fin[296]} {header_ctrl/udp_head/payload_fin[297]} {header_ctrl/udp_head/payload_fin[298]} {header_ctrl/udp_head/payload_fin[299]} {header_ctrl/udp_head/payload_fin[300]} {header_ctrl/udp_head/payload_fin[301]} {header_ctrl/udp_head/payload_fin[302]} {header_ctrl/udp_head/payload_fin[303]} {header_ctrl/udp_head/payload_fin[304]} {header_ctrl/udp_head/payload_fin[305]} {header_ctrl/udp_head/payload_fin[306]} {header_ctrl/udp_head/payload_fin[307]} {header_ctrl/udp_head/payload_fin[308]} {header_ctrl/udp_head/payload_fin[309]} {header_ctrl/udp_head/payload_fin[310]} {header_ctrl/udp_head/payload_fin[311]} {header_ctrl/udp_head/payload_fin[312]} {header_ctrl/udp_head/payload_fin[313]} {header_ctrl/udp_head/payload_fin[314]} {header_ctrl/udp_head/payload_fin[315]} {header_ctrl/udp_head/payload_fin[316]} {header_ctrl/udp_head/payload_fin[317]} {header_ctrl/udp_head/payload_fin[318]} {header_ctrl/udp_head/payload_fin[319]} {header_ctrl/udp_head/payload_fin[320]} {header_ctrl/udp_head/payload_fin[321]} {header_ctrl/udp_head/payload_fin[322]} {header_ctrl/udp_head/payload_fin[323]} {header_ctrl/udp_head/payload_fin[324]} {header_ctrl/udp_head/payload_fin[325]} {header_ctrl/udp_head/payload_fin[326]} {header_ctrl/udp_head/payload_fin[327]} {header_ctrl/udp_head/payload_fin[328]} {header_ctrl/udp_head/payload_fin[329]} {header_ctrl/udp_head/payload_fin[330]} {header_ctrl/udp_head/payload_fin[331]} {header_ctrl/udp_head/payload_fin[332]} {header_ctrl/udp_head/payload_fin[333]} {header_ctrl/udp_head/payload_fin[334]} {header_ctrl/udp_head/payload_fin[335]} {header_ctrl/udp_head/payload_fin[336]} {header_ctrl/udp_head/payload_fin[337]} {header_ctrl/udp_head/payload_fin[338]} {header_ctrl/udp_head/payload_fin[339]} {header_ctrl/udp_head/payload_fin[340]} {header_ctrl/udp_head/payload_fin[341]} {header_ctrl/udp_head/payload_fin[342]} {header_ctrl/udp_head/payload_fin[343]} {header_ctrl/udp_head/payload_fin[344]} {header_ctrl/udp_head/payload_fin[345]} {header_ctrl/udp_head/payload_fin[346]} {header_ctrl/udp_head/payload_fin[347]} {header_ctrl/udp_head/payload_fin[348]} {header_ctrl/udp_head/payload_fin[349]} {header_ctrl/udp_head/payload_fin[350]} {header_ctrl/udp_head/payload_fin[351]} {header_ctrl/udp_head/payload_fin[352]} {header_ctrl/udp_head/payload_fin[353]} {header_ctrl/udp_head/payload_fin[354]} {header_ctrl/udp_head/payload_fin[355]} {header_ctrl/udp_head/payload_fin[356]} {header_ctrl/udp_head/payload_fin[357]} {header_ctrl/udp_head/payload_fin[358]} {header_ctrl/udp_head/payload_fin[359]} {header_ctrl/udp_head/payload_fin[360]} {header_ctrl/udp_head/payload_fin[361]} {header_ctrl/udp_head/payload_fin[362]} {header_ctrl/udp_head/payload_fin[363]} {header_ctrl/udp_head/payload_fin[364]} {header_ctrl/udp_head/payload_fin[365]} {header_ctrl/udp_head/payload_fin[366]} {header_ctrl/udp_head/payload_fin[367]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 3 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {eth_phy/p_state[0]} {eth_phy/p_state[1]} {eth_phy/p_state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 8 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {eth_phy/head_buffer[0]} {eth_phy/head_buffer[1]} {eth_phy/head_buffer[2]} {eth_phy/head_buffer[3]} {eth_phy/head_buffer[4]} {eth_phy/head_buffer[5]} {eth_phy/head_buffer[6]} {eth_phy/head_buffer[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 5 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {eth_phy/preamble_cnt_1[0]} {eth_phy/preamble_cnt_1[1]} {eth_phy/preamble_cnt_1[2]} {eth_phy/preamble_cnt_1[3]} {eth_phy/preamble_cnt_1[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 3 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {eth_phy/p_state_1[0]} {eth_phy/p_state_1[1]} {eth_phy/p_state_1[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 2 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {header_ctrl/p_state[0]} {header_ctrl/p_state[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 8 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {eth_phy/assembled_byte[0]} {eth_phy/assembled_byte[1]} {eth_phy/assembled_byte[2]} {eth_phy/assembled_byte[3]} {eth_phy/assembled_byte[4]} {eth_phy/assembled_byte[5]} {eth_phy/assembled_byte[6]} {eth_phy/assembled_byte[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 32 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {crc_tx[0]} {crc_tx[1]} {crc_tx[2]} {crc_tx[3]} {crc_tx[4]} {crc_tx[5]} {crc_tx[6]} {crc_tx[7]} {crc_tx[8]} {crc_tx[9]} {crc_tx[10]} {crc_tx[11]} {crc_tx[12]} {crc_tx[13]} {crc_tx[14]} {crc_tx[15]} {crc_tx[16]} {crc_tx[17]} {crc_tx[18]} {crc_tx[19]} {crc_tx[20]} {crc_tx[21]} {crc_tx[22]} {crc_tx[23]} {crc_tx[24]} {crc_tx[25]} {crc_tx[26]} {crc_tx[27]} {crc_tx[28]} {crc_tx[29]} {crc_tx[30]} {crc_tx[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 4 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {eth_phy/nibble_cnt[0]} {eth_phy/nibble_cnt[1]} {eth_phy/nibble_cnt[2]} {eth_phy/nibble_cnt[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 8 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {eth_phy/byte_buffer[0]} {eth_phy/byte_buffer[1]} {eth_phy/byte_buffer[2]} {eth_phy/byte_buffer[3]} {eth_phy/byte_buffer[4]} {eth_phy/byte_buffer[5]} {eth_phy/byte_buffer[6]} {eth_phy/byte_buffer[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 8 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {crc_gen_data[0]} {crc_gen_data[1]} {crc_gen_data[2]} {crc_gen_data[3]} {crc_gen_data[4]} {crc_gen_data[5]} {crc_gen_data[6]} {crc_gen_data[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 8 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {mac_byte[0]} {mac_byte[1]} {mac_byte[2]} {mac_byte[3]} {mac_byte[4]} {mac_byte[5]} {mac_byte[6]} {mac_byte[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 2 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {phy_txd_sig[0]} {phy_txd_sig[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 8 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {mac_rx_byte[0]} {mac_rx_byte[1]} {mac_rx_byte[2]} {mac_rx_byte[3]} {mac_rx_byte[4]} {mac_rx_byte[5]} {mac_rx_byte[6]} {mac_rx_byte[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 8 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {mac_tx[0]} {mac_tx[1]} {mac_tx[2]} {mac_tx[3]} {mac_tx[4]} {mac_tx[5]} {mac_tx[6]} {mac_tx[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 2 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {phy_rxd_sig[0]} {phy_rxd_sig[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 1 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list eth_phy/byte_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 1 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list crc_check/crc_enable]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
set_property port_width 1 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list crc_gen_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
set_property port_width 1 [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list header_ctrl/fifo_wr_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe24]
set_property port_width 1 [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list head_fifo_empty]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe25]
set_property port_width 1 [get_debug_ports u_ila_0/probe25]
connect_debug_port u_ila_0/probe25 [get_nets [list head_rd_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe26]
set_property port_width 1 [get_debug_ports u_ila_0/probe26]
connect_debug_port u_ila_0/probe26 [get_nets [list mac_rd_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe27]
set_property port_width 1 [get_debug_ports u_ila_0/probe27]
connect_debug_port u_ila_0/probe27 [get_nets [list mac_wr_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe28]
set_property port_width 1 [get_debug_ports u_ila_0/probe28]
connect_debug_port u_ila_0/probe28 [get_nets [list phy_crs_dv_sig]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe29]
set_property port_width 1 [get_debug_ports u_ila_0/probe29]
connect_debug_port u_ila_0/probe29 [get_nets [list phy_tx_en_sig]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe30]
set_property port_width 1 [get_debug_ports u_ila_0/probe30]
connect_debug_port u_ila_0/probe30 [get_nets [list phy_wr_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe31]
set_property port_width 1 [get_debug_ports u_ila_0/probe31]
connect_debug_port u_ila_0/probe31 [get_nets [list start_frame]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe32]
set_property port_width 1 [get_debug_ports u_ila_0/probe32]
connect_debug_port u_ila_0/probe32 [get_nets [list tx_fifo_empty]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk_IBUF]
