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
// HMC controller status
//
class reg_hmc_controller_rf_16x_status_general_c extends cag_rgm_register;

   typedef struct packed {
       bit [15:0] lane_polarity_reversed_;
       bit [5:0] rsvd_status_general_3_;
       bit [9:0] rx_tokens_remaining_;
       bit [5:0] rsvd_status_general_2_;
       bit [9:0] hmc_tokens_remaining_;
       bit [6:0] rsvd_status_general_1_;
       bit [0:0] phy_ready_;
       bit [3:0] rsvd_status_general_0_;
       bit [0:0] lanes_reversed_;
       bit [0:0] sleep_mode_;
       bit [0:0] link_training_;
       bit [0:0] link_up_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_hmc_controller_rf_16x_status_general_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_hmc_controller_rf_16x_status_general_c");
       super.new(name);
       this.name = name;
       set_address('h0);
   endfunction : new

endclass : reg_hmc_controller_rf_16x_status_general_c

//
// HMC controller initialization status
//
class reg_hmc_controller_rf_16x_status_init_c extends cag_rgm_register;

   typedef struct packed {
       bit [0:0] hmc_init_TS1_;
       bit [1:0] tx_init_status_;
       bit [0:0] all_descramblers_aligned_;
       bit [15:0] descrambler_aligned_;
       bit [15:0] descrambler_part_aligned_;
       bit [15:0] lane_descramblers_locked_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_hmc_controller_rf_16x_status_init_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_hmc_controller_rf_16x_status_init_c");
       super.new(name);
       this.name = name;
       set_address('h8);
   endfunction : new

endclass : reg_hmc_controller_rf_16x_status_init_c

//
// HMC controller control
//
class reg_hmc_controller_rf_16x_control_c extends cag_rgm_register;

   typedef struct packed {
       bit [7:0] bit_slip_time_;
       bit [2:0] rsvd_control_3_;
       bit [4:0] irtry_to_send_;
       bit [2:0] rsvd_control_2_;
       bit [4:0] irtry_received_threshold_;
       bit [5:0] rsvd_control_1_;
       bit [9:0] rx_token_count_;
       bit [6:0] rsvd_control_0_;
       bit [0:0] debug_dont_send_tret_;
       bit [2:0] first_cube_ID_;
       bit [0:0] run_length_enable_;
       bit [0:0] scrambler_disable_;
       bit [0:0] set_hmc_sleep_;
       bit [0:0] hmc_init_cont_set_;
       bit [0:0] p_rst_n_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_hmc_controller_rf_16x_control_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_hmc_controller_rf_16x_control_c");
       super.new(name);
       this.name = name;
       set_address('h10);
   endfunction : new

endclass : reg_hmc_controller_rf_16x_control_c

//
// Count of packets that had data errors but valid flow information
//
class reg_hmc_controller_rf_16x_poisoned_packets_c extends cag_rgm_register;

   typedef struct packed {
       bit [63:0] cnt_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_hmc_controller_rf_16x_poisoned_packets_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_hmc_controller_rf_16x_poisoned_packets_c");
       super.new(name);
       this.name = name;
       set_address('h18);
   endfunction : new

endclass : reg_hmc_controller_rf_16x_poisoned_packets_c

//
// Nonposted requests sent to the HMC
//
class reg_hmc_controller_rf_16x_sent_np_c extends cag_rgm_register;

   typedef struct packed {
       bit [63:0] cnt_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_hmc_controller_rf_16x_sent_np_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_hmc_controller_rf_16x_sent_np_c");
       super.new(name);
       this.name = name;
       set_address('h20);
   endfunction : new

endclass : reg_hmc_controller_rf_16x_sent_np_c

//
// Posted requests sent to the HMC
//
class reg_hmc_controller_rf_16x_sent_p_c extends cag_rgm_register;

   typedef struct packed {
       bit [63:0] cnt_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_hmc_controller_rf_16x_sent_p_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_hmc_controller_rf_16x_sent_p_c");
       super.new(name);
       this.name = name;
       set_address('h28);
   endfunction : new

endclass : reg_hmc_controller_rf_16x_sent_p_c

//
// Read requests sent to the HMC
//
class reg_hmc_controller_rf_16x_sent_r_c extends cag_rgm_register;

   typedef struct packed {
       bit [63:0] cnt_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_hmc_controller_rf_16x_sent_r_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_hmc_controller_rf_16x_sent_r_c");
       super.new(name);
       this.name = name;
       set_address('h30);
   endfunction : new

endclass : reg_hmc_controller_rf_16x_sent_r_c

//
// Responses received from the HMC
//
class reg_hmc_controller_rf_16x_rcvd_rsp_c extends cag_rgm_register;

   typedef struct packed {
       bit [63:0] cnt_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_hmc_controller_rf_16x_rcvd_rsp_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_hmc_controller_rf_16x_rcvd_rsp_c");
       super.new(name);
       this.name = name;
       set_address('h38);
   endfunction : new

endclass : reg_hmc_controller_rf_16x_rcvd_rsp_c

//
// Reset performance counters
//
class reg_hmc_controller_rf_16x_counter_reset_c extends cag_rgm_register;

   typedef struct packed {
       bit rreinit_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_hmc_controller_rf_16x_counter_reset_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_hmc_controller_rf_16x_counter_reset_c");
       super.new(name);
       this.name = name;
       set_address('h40);
   endfunction : new

endclass : reg_hmc_controller_rf_16x_counter_reset_c

//
// Count of re-transmit requests (seq num and bit errors)
//
class reg_hmc_controller_rf_16x_link_retries_c extends cag_rgm_register;

   typedef struct packed {
       bit [31:0] count_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_hmc_controller_rf_16x_link_retries_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_hmc_controller_rf_16x_link_retries_c");
       super.new(name);
       this.name = name;
       set_address('h48);
   endfunction : new

endclass : reg_hmc_controller_rf_16x_link_retries_c

//
// The number of bit_flips forced by the run length limiter
//
class reg_hmc_controller_rf_16x_run_length_bit_flip_c extends cag_rgm_register;

   typedef struct packed {
       bit [31:0] count_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_hmc_controller_rf_16x_run_length_bit_flip_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_hmc_controller_rf_16x_run_length_bit_flip_c");
       super.new(name);
       this.name = name;
       set_address('h50);
   endfunction : new

endclass : reg_hmc_controller_rf_16x_run_length_bit_flip_c

class rf_hmc_controller_rf_16x_c extends cag_rgm_register_file;

   rand reg_hmc_controller_rf_16x_status_general_c status_general;
   rand reg_hmc_controller_rf_16x_status_init_c status_init;
   rand reg_hmc_controller_rf_16x_control_c control;
   rand reg_hmc_controller_rf_16x_poisoned_packets_c poisoned_packets;
   rand reg_hmc_controller_rf_16x_sent_np_c sent_np;
   rand reg_hmc_controller_rf_16x_sent_p_c sent_p;
   rand reg_hmc_controller_rf_16x_sent_r_c sent_r;
   rand reg_hmc_controller_rf_16x_rcvd_rsp_c rcvd_rsp;
   rand reg_hmc_controller_rf_16x_counter_reset_c counter_reset;
   rand reg_hmc_controller_rf_16x_link_retries_c link_retries;
   rand reg_hmc_controller_rf_16x_run_length_bit_flip_c run_length_bit_flip;

   `uvm_object_utils(rf_hmc_controller_rf_16x_c)

   function new(string name="rf_hmc_controller_rf_16x_c");
       super.new(name);
       this.name = name;
       set_address('h0);
       status_general = reg_hmc_controller_rf_16x_status_general_c::type_id::create("status_general");
       status_general.set_address('h0);
       add_register(status_general);
       status_init = reg_hmc_controller_rf_16x_status_init_c::type_id::create("status_init");
       status_init.set_address('h8);
       add_register(status_init);
       control = reg_hmc_controller_rf_16x_control_c::type_id::create("control");
       control.set_address('h10);
       add_register(control);
       poisoned_packets = reg_hmc_controller_rf_16x_poisoned_packets_c::type_id::create("poisoned_packets");
       poisoned_packets.set_address('h18);
       add_register(poisoned_packets);
       sent_np = reg_hmc_controller_rf_16x_sent_np_c::type_id::create("sent_np");
       sent_np.set_address('h20);
       add_register(sent_np);
       sent_p = reg_hmc_controller_rf_16x_sent_p_c::type_id::create("sent_p");
       sent_p.set_address('h28);
       add_register(sent_p);
       sent_r = reg_hmc_controller_rf_16x_sent_r_c::type_id::create("sent_r");
       sent_r.set_address('h30);
       add_register(sent_r);
       rcvd_rsp = reg_hmc_controller_rf_16x_rcvd_rsp_c::type_id::create("rcvd_rsp");
       rcvd_rsp.set_address('h38);
       add_register(rcvd_rsp);
       counter_reset = reg_hmc_controller_rf_16x_counter_reset_c::type_id::create("counter_reset");
       counter_reset.set_address('h40);
       add_register(counter_reset);
       link_retries = reg_hmc_controller_rf_16x_link_retries_c::type_id::create("link_retries");
       link_retries.set_address('h48);
       add_register(link_retries);
       run_length_bit_flip = reg_hmc_controller_rf_16x_run_length_bit_flip_c::type_id::create("run_length_bit_flip");
       run_length_bit_flip.set_address('h50);
       add_register(run_length_bit_flip);
   endfunction : new

endclass : rf_hmc_controller_rf_16x_c

//
// Pattern Generator Control Register
//
class reg_pattern_gen_rf_control_c extends cag_rgm_register;

   typedef struct packed {
       bit [2:0] cubID_size_;
       bit [2:0] first_cube_ID_;
       bit [0:0] hmc_gen_running_;
       bit [0:0] hmc_gen_enable_;
       bit [6:0] hmc_gen_read_ratio_;
       bit [3:0] hmc_gen_write_size_;
       bit [3:0] hmc_gen_read_size_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_pattern_gen_rf_control_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_pattern_gen_rf_control_c");
       super.new(name);
       this.name = name;
       set_address('h80);
   endfunction : new

endclass : reg_pattern_gen_rf_control_c

//
// dummy
//
class reg_pattern_gen_rf_dummy_c extends cag_rgm_register;

   typedef struct packed {
       bit [3:0] dummy_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_pattern_gen_rf_dummy_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_pattern_gen_rf_dummy_c");
       super.new(name);
       this.name = name;
       set_address('h88);
   endfunction : new

endclass : reg_pattern_gen_rf_dummy_c

class rf_pattern_gen_rf_c extends cag_rgm_register_file;

   rand reg_pattern_gen_rf_control_c control;
   rand reg_pattern_gen_rf_dummy_c dummy;

   `uvm_object_utils(rf_pattern_gen_rf_c)

   function new(string name="rf_pattern_gen_rf_c");
       super.new(name);
       this.name = name;
       set_address('h80);
       control = reg_pattern_gen_rf_control_c::type_id::create("control");
       control.set_address('h80);
       add_register(control);
       dummy = reg_pattern_gen_rf_dummy_c::type_id::create("dummy");
       dummy.set_address('h88);
       add_register(dummy);
   endfunction : new

endclass : rf_pattern_gen_rf_c

//
// General Reset controlable via i2c
//
class reg_res_rf_control_c extends cag_rgm_register;

   typedef struct packed {
       bit [0:0] res_n_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_res_rf_control_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_res_rf_control_c");
       super.new(name);
       this.name = name;
       set_address('h90);
   endfunction : new

endclass : reg_res_rf_control_c

//
// dummy
//
class reg_res_rf_dummy_c extends cag_rgm_register;

   typedef struct packed {
       bit [0:0] dummy_;
   } pkd_flds_s;

   `cag_rgm_register_fields(pkd_flds_s)

   `uvm_object_utils_begin(reg_res_rf_dummy_c)
       `uvm_field_int(fields,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="reg_res_rf_dummy_c");
       super.new(name);
       this.name = name;
       set_address('h98);
   endfunction : new

endclass : reg_res_rf_dummy_c

class rf_res_rf_c extends cag_rgm_register_file;

   rand reg_res_rf_control_c control;
   rand reg_res_rf_dummy_c dummy;

   `uvm_object_utils(rf_res_rf_c)

   function new(string name="rf_res_rf_c");
       super.new(name);
       this.name = name;
       set_address('h90);
       control = reg_res_rf_control_c::type_id::create("control");
       control.set_address('h90);
       add_register(control);
       dummy = reg_res_rf_dummy_c::type_id::create("dummy");
       dummy.set_address('h98);
       add_register(dummy);
   endfunction : new

endclass : rf_res_rf_c

class rf_vc107_1hmc_16lane_top_rf_c extends cag_rgm_register_file;

   rand rf_hmc_controller_rf_16x_c hmc_controller_rf_16x;
   rand rf_pattern_gen_rf_c pattern_gen_rf;
   rand rf_res_rf_c res_rf;

   `uvm_object_utils(rf_vc107_1hmc_16lane_top_rf_c)

   function new(string name="rf_vc107_1hmc_16lane_top_rf_c");
       super.new(name);
       this.name = name;
       set_address('h0);
       hmc_controller_rf_16x = rf_hmc_controller_rf_16x_c::type_id::create("hmc_controller_rf_16x");
       add_register_file(hmc_controller_rf_16x);
       pattern_gen_rf = rf_pattern_gen_rf_c::type_id::create("pattern_gen_rf");
       add_register_file(pattern_gen_rf);
       res_rf = rf_res_rf_c::type_id::create("res_rf");
       add_register_file(res_rf);
   endfunction : new

endclass : rf_vc107_1hmc_16lane_top_rf_c

