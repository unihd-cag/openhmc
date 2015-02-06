/*
 *                              .--------------. .----------------. .------------.
 *                             | .------------. | .--------------. | .----------. |
 *                             | | ____  ____ | | | ____    ____ | | |   ______ | |
 *                             | ||_   ||   _|| | ||_   \  /   _|| | | .' ___  || |
 *       ___  _ __   ___ _ __  | |  | |__| |  | | |  |   \/   |  | | |/ .'   \_|| |
 *      / _ \| '_ \ / _ \ '_ \ | |  |  __  |  | | |  | |\  /| |  | | || |       | |
 *       (_) | |_) |  __/ | | || | _| |  | |_ | | | _| |_\/_| |_ | | |\ `.___.'\| |
 *      \___/| .__/ \___|_| |_|| ||____||____|| | ||_____||_____|| | | `._____.'| |
 *           | |               | |            | | |              | | |          | |
 *           |_|               | '------------' | '--------------' | '----------' |
 *                              '--------------' '----------------' '------------'
 *
 *  openHMC - An Open Source Hybrid Memory Cube Controller
 *  (C) Copyright 2014 Computer Architecture Group - University of Heidelberg
 *  www.ziti.uni-heidelberg.de
 *  B6, 26
 *  68159 Mannheim
 *  Germany
 *
 *  Contact: openhmc@ziti.uni-heidelberg.de
 *  http://ra.ziti.uni-heidelberg.de/openhmc
 *
 *   This source file is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Lesser General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This source file is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Lesser General Public License for more details.
 *
 *   You should have received a copy of the GNU Lesser General Public License
 *   along with this source file.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 */

`ifndef BFM_2_HMC
`define BFM_2_HMC
class bfm_2_hmc_mon extends hmc_module_mon;

	pkt_analysis_port#()    mb_pkt;
	cls_pkt pkt;
	hmc_packet hmc_pkt;
	
	bit bitstream[];
	
	int phit_size = 64;
	bit [64:0] header;	//-- phit size
	bit [64:0] tail ;	//-- phit size
	int data_phit_count;
	
	int flit_size = 128;
	
	`uvm_component_utils(bfm_2_hmc_mon)
	
	function new ( string name="bfm_2_hmc_mon", uvm_component parent );
		super.new(name, parent);
	endfunction : new
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(uvm_config_db#(pkt_analysis_port#())::get(this, "", "mb_pkt",mb_pkt) ) begin
		end else 
			`uvm_fatal(get_type_name(),"pkt_analysis_port#() is not set")	
	endfunction : build_phase
	
	task run();
		`uvm_info(get_type_name(),$psprintf("starting BFM_2_HMC converter"), UVM_MEDIUM)
		forever begin
			mb_pkt.get(pkt);

			header				= pkt.get_header();
			tail 				= pkt.get_tail();
			data_phit_count 	= pkt.data.size(); //-- 7 flits->14 phits --> 14-2 =12 data_phits
			
			bitstream 			= new [2*phit_size + data_phit_count*phit_size];	
			
			
			//-- generate Bitstream
			
			
			if (header >64'b0) begin
			
				for (int b = 0; b < 64; b++) begin								//-- read header to bitmap
					bitstream[b]=header[b];
				end
				
				if (data_phit_count > 0)	
					for (int phit = 0; phit < data_phit_count; phit++) 		//-- read data to bitmap
						for (int b = 0; b < phit_size; b++) 
							bitstream[(phit + 1) * phit_size + b] = pkt.data[phit][b];
				
				for (int b = 0; b < 64; b++) begin								//-- read tail to bitmap
					bitstream[(data_phit_count+1)*phit_size+b]=tail[b];
				end
				
				//-- create hmc packet
				
				hmc_pkt = hmc_packet::type_id::create("packet", this);
				void'(hmc_pkt.unpack(bitstream));
				
				`uvm_info(get_type_name(),$psprintf("Got a BFM Packet:  %s",pkt.convert2string()), UVM_HIGH)
				
				//-- write to HMC Monitor / Scoreboard
				
				if (hmc_pkt.get_command_type() == HMC_FLOW_TYPE )begin  //-- do not write if Flow Control Packet
					`uvm_info(get_type_name(),$psprintf("receiving non request/response packet"), UVM_HIGH)
					`uvm_info(get_type_name(),$psprintf("hmc_packet: \n%s", hmc_pkt.sprint()), UVM_HIGH)
				end else begin
					`uvm_info(get_type_name(),$psprintf("commiting translated packet"), UVM_MEDIUM)
					`uvm_info(get_type_name(),$psprintf("hmc_packet: \n%s", hmc_pkt.sprint()), UVM_HIGH)
					
					item_collected_port.write(hmc_pkt);	
				end
			end
		end
		
	endtask

endclass


`endif