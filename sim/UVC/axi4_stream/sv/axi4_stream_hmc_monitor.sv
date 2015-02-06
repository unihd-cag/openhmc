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

//
//
// axi4_stream_packet hmc_monitor
//
//

`ifndef AXI4_STREAM_HMC_MONITOR_SV
`define AXI4_STREAM_HMC_MONITOR_SV

class axi4_stream_hmc_monitor #(parameter DATA_BYTES = 16, parameter TUSER_WIDTH = 16) extends  hmc_module_mon ;


	int FPW ;
	int HEADERS ;
	int TAILS ;
	int VALIDS ;
	int valids_per_cycle 	= 0;
	int packet_length 		= 0;


	//-- uvm_analysis_port #(hmc_packet) item_collected_port;
	uvm_analysis_imp #(
	  axi4_stream_valid_cycle #(.DATA_BYTES(DATA_BYTES), .TUSER_WIDTH(TUSER_WIDTH)),
	  axi4_stream_hmc_monitor  #(.DATA_BYTES(DATA_BYTES), .TUSER_WIDTH(TUSER_WIDTH))
	  ) axi4_port;
	
	int n_valids 				= 0;
	int n_valids_after_tail 	= 0;
	int n_valids_in_packet 		= 0;
	
	int headers_seen 	= 0;
	int tails_seen 	 	= 0;

	
	typedef bit [127:0] flit_t;
	flit_t flit_queue[$];

	int packets_per_cycle = 0;
	
	hmc_packet packet;
	hmc_packet packet_queue[$];
	
	//-- covergroup definition
	covergroup axi4_cg;
		HMC_PACKET_LENGTH : coverpoint packet_length;
	endgroup
	
	covergroup non_valids_cg;
		BETWEEN_PACKETS : coverpoint n_valids_after_tail;
		IN_PACKETS : coverpoint n_valids_in_packet;
	endgroup
	
	covergroup overlap_cg;
		PACKETS_WITH_2_CYCLES: coverpoint headers_seen>tails_seen; //-- boolean condition
		VALIDS_PER_CYCLE: coverpoint valids_per_cycle;
	endgroup
	
	
	`uvm_component_param_utils(axi4_stream_hmc_monitor #(.DATA_BYTES(DATA_BYTES), .TUSER_WIDTH(TUSER_WIDTH)))


	function new ( string name="axi4_stream_hmc_monitor", uvm_component parent );
		super.new(name, parent);
		
		axi4_port = new("axi4_port",this);
		
		axi4_cg 		= new();
		non_valids_cg  	= new();
		overlap_cg  	= new();
		
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		FPW 	= DATA_BYTES/16;//-- convert to variables!
		HEADERS = FPW;
		TAILS 	= 2*FPW;
		VALIDS 	= 0;
	endfunction : build_phase

	//-- Stuff FLITs into a FIFO, separate control signals
	function void collect_flits(input axi4_stream_valid_cycle #(.DATA_BYTES(DATA_BYTES), .TUSER_WIDTH(TUSER_WIDTH)) vc);
		//-- read tuser flags for valid flags
		flit_t tmp_flit;
		flit_t current_flit;
		packets_per_cycle = 0;
		valids_per_cycle =0;
		for (int i = 0; i<FPW; i++) begin //-- Check bitvektor
		//-- Check if valid
			if (vc.tuser[VALIDS+i] == 1) begin
				valids_per_cycle ++;
				
				//-- Cover not valid flits
				if (n_valids > 0) begin 
					//-- Check if between packets
					if (tails_seen == headers_seen)	//-- non valids after packet tail
						n_valids_after_tail =n_valids;
					else							//-- non valids between header and tail
						n_valids_in_packet = n_valids;
					non_valids_cg.sample();
					n_valids =0;
					n_valids_after_tail = 0;
					n_valids_in_packet= 0;
				end
		
				//-- Write 2 flit queue
				for (int b=0; b<128; b++)
					tmp_flit[b] = vc.tdata[128*i+b];
				flit_queue.push_back(tmp_flit);
			
				if (vc.tuser[HEADERS+i] == 1) begin
					headers_seen++; //-- Complete hmc_packets to assemble
					packets_per_cycle ++;
				end
				//-- Check if tail for complete hmc packet
				if (vc.tuser[TAILS+i] == 1) begin
					tails_seen++; //-- Complete hmc_packets to assemble
				end
				
				//-- Check complete hmc packets
				`uvm_info(get_type_name(),$psprintf("Seen %d header and %d tails", headers_seen, tails_seen)  ,UVM_HIGH)
				assert (tails_seen<= headers_seen) 
				else  `uvm_fatal(get_type_name(), $psprintf("packet is null"))
				
			end
			else begin
				n_valids ++;
			end
			
		end
		//-- Sample covergroup
		overlap_cg.sample(); 
		
	endfunction : collect_flits

	//-- Use FLITs to form packets
	function void collect_packet();
		int current_packet_length;
		
		flit_t current_flit;
		bit bitstream[];
		packet_length = 0;
		//-- Assemble 1 hmc packet
		flit_queue_underflow : assert (flit_queue.size() > 0);
		
		//-- First flit is always header
		current_flit = flit_queue.pop_front();
		no_length_mismatches_allowed : assert (current_flit[14:11] == current_flit[10:7]); 	//--check internal hmc_packet length
		current_packet_length = current_flit[10:7];
		flit_queue_underflow2 : assert (flit_queue.size() >= current_packet_length - 1);		//--check check hmc_packet complete received
		
		
		//-- pack flits 2 bitstream
		bitstream = new[current_packet_length*128];
		
		//-- Pack first flit
		for (int i=0; i<128; i=i+1)
			bitstream[i] = current_flit[i];
		
		//-- Get and pack the remaining flits
		for (int flit=1; flit < current_packet_length; flit ++) begin
			current_flit = flit_queue.pop_front();
			`uvm_info(get_type_name(),$psprintf("pop flit %0d (%0x)", flit, current_flit), UVM_HIGH)
			for (int i=0; i<128; i=i+1) begin
				bitstream[flit*128+i] = current_flit[i];
			end
		end
		packet_length =current_packet_length;
 		axi4_cg.sample(); 
		
		packet = hmc_packet::type_id::create("packet", this);
		void'(packet.unpack(bitstream));
		
		tails_seen--;
		if (packet == null) begin
		  `uvm_fatal(get_type_name(), $psprintf("packet is null"))
		end
			
		packet_queue.push_back(packet);
		
		if(packet.get_command_type() == HMC_RESPONSE_TYPE)begin
		`uvm_info("RESPONSE collected",$psprintf("Rsp %0d : %s",rsp_rcvd, packet.command.name()), UVM_LOW)
		rsp_rcvd++;
		end else begin
		`uvm_info("REQUEST collected",$psprintf("Req %0d : %s",req_rcvd, packet.command.name()), UVM_LOW)
		req_rcvd++;
		end
		`uvm_info("AXI4 to HMC Monitor",$psprintf("\n%s", packet.sprint()), UVM_HIGH)
	endfunction : collect_packet

	function void write(input axi4_stream_valid_cycle #(.DATA_BYTES(DATA_BYTES), .TUSER_WIDTH(TUSER_WIDTH)) vc);
		hmc_packet expected;
		
		hmc_packet packet;
		
		
		`uvm_info(get_type_name(),$psprintf("got valid cycle"), UVM_HIGH)
		
		collect_flits(vc);
		
			  
		`uvm_info(get_type_name(),$psprintf("got %0d tails and %0d flits",tails_seen, flit_queue.size() ), UVM_HIGH)
		
		
		//-- Convert flit_queue to hmc_packets
		while (tails_seen >0) begin
			collect_packet();		
		end
		//-- If flit queue is not empty -> hmc packet striped over 2 axi cycles
		
		
		while (packet_queue.size()>0) begin
			item_collected_port.write(packet_queue.pop_front());
		end
	endfunction

	function void check_phase(uvm_phase phase);
		if (flit_queue.size() >0)
			`uvm_fatal(get_type_name(),$psprintf("flit_queue is not empty: %0d", flit_queue.size()))
	endfunction : check_phase
endclass : axi4_stream_hmc_monitor

`endif // AXI4_STREAM_HMC_MONITOR_SV
