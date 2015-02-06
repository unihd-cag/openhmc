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
// simple_test sequence
//
//

`ifndef simple_test_SEQ_SV
`define simple_test_SEQ_SV

`include "config.h"

class simple_test_seq extends hmc_base_seq;

	function new(string name="simple_test_seq");
		super.new(name);
	endfunction : new

	hmc_init_seq init;
	hmc_check_seq check;

	`uvm_object_utils(simple_test_seq)
	`uvm_declare_p_sequencer(hmc_vseqr)

	hmc_2_axi4_sequence #(.DATA_BYTES(`AXI4BYTES), .TUSER_WIDTH(`AXI4BYTES)) requests;
	int np_tag;
	rand bit hmc_command_np;
	rand int flit_count;

	virtual task body();

		`uvm_info(get_type_name(), "starting simple_test_seq", UVM_NONE)

		//-- write your test here

		#1us;
        `uvm_do(init)
        #1us;


 		`uvm_create_on(requests, p_sequencer.axi4_req_seqr)	//-- create a new sequence item 'requests' on sequencer
 		requests.num_packets = `NUM_PACKETS;				//-- HMC packets to send 
 		requests.max_pkts_per_cycle = `FPW;					//-- Set the maximum number of complete packets per AXI4 cycle
 		`uvm_rand_send(requests)							//-- randomize and send the parametrize sequence item

		#1us;
		`uvm_info(get_type_name(), "simple_test_seq done", UVM_NONE)
		`uvm_do(check)

	endtask : body

endclass : simple_test_seq

`endif // simple_test_SEQ_SV
