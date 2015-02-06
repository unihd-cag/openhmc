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

`default_nettype none
`timescale 100ps/10ps


`include "config.h"


module dut #(
    //*************************Don't touch! Control the design in config.h and with arguments when executing run.sh
    parameter LOG_NUM_LANES             = `LOG_NUM_LANES,
    parameter NUM_LANES                 = 2**LOG_NUM_LANES,
    parameter LOG_FPW                   = `LOG_FPW,
    parameter FPW                       = `FPW,
    parameter DWIDTH                    = 128*FPW,
    parameter NUM_DATA_BYTES            = 16*FPW,
    parameter LANE_WIDTH                = DWIDTH / NUM_LANES
    //*************************
    )
    (
    //AXI4 user clock
    input wire clk_user,
    //125MHz reference clock
    input wire clk_hmc_refclk,
    //Global reset
    input wire res_n,

    //AXI4 interface ports
    axi4_stream_if axi4_req,
    axi4_stream_if axi4_rsp,

    //Register File interface
    cag_rgm_rfs_if rfs_hmc
);

//----------------------------- Configuration and Debug
bit disable_lane_delays   = 1;
bit disable_lane_polarity = 1;
bit disable_scramblers    = 0;
//Lane Reversal
localparam LANE_REVERSAL_TX = 0;
localparam LANE_REVERSAL_RX = 0;

//Lane delays
localparam LOG_DELAY = 5;
typedef bit [LOG_DELAY-1:0] delay_t;
delay_t [NUM_LANES-1:0]     delays_Rx;
delay_t [NUM_LANES-1:0]     delays_Tx;
//Polarity
bit [NUM_LANES-1:0]         polarity_Rx;

//----------------------------- Wiring openHMC controller
wire [DWIDTH-1:0]       to_serializers;
wire [DWIDTH-1:0]       from_deserializers;
wire [NUM_LANES-1:0]    bit_slip;
bit                     P_RST_N;

// Wire the HMC BFM model
wire            LxRXPS; // HMC input
wire            LxTXPS; // HMC output
wire            FERR_N; // HMC output
wire            hmc_refclkp;
wire            hmc_refclkn;
wire [16-1:0]   LxRXP;
wire [16-1:0]   LxRXN;
wire [16-1:0]   LxTXP;
wire [16-1:0]   LxTXN;

//----------------------------- Signal Routing from SerDes to HMC
wire [NUM_LANES-1:0] serial_Rx;
wire [NUM_LANES-1:0] serial_Rx_routed;
wire [NUM_LANES-1:0] serial_Txn;
wire [NUM_LANES-1:0] serial_Txp;
wire [NUM_LANES-1:0] serial_Tx_routed;

assign LxRXP        = {serial_Tx_routed};
assign LxRXN        = ~LxRXP;
assign serial_Rx    = LxTXP[NUM_LANES-1:0];

//----------------------------- Define the Clocks
bit clk_10G;
bit clk_hmc;
assign hmc_refclkp = clk_hmc_refclk;
assign hmc_refclkn = ~hmc_refclkp;

//----------------------------- Attach the Register File System interface
assign rfs_hmc_if.clk = clk_hmc;
assign rfs_hmc_if.res_n = res_n;

//----------------------------- Randomize configuration and Load HMC Link Config
int n = 0;
    initial begin
        var cls_link_cfg link_cfg;      // declare configuration object

        //Randomize lane delays, polarity, and reversal
        repeat(NUM_LANES) begin
            delays_Rx[n]     = disable_lane_delays   ? 0 : $urandom_range(0,8);
            delays_Tx[n]     = disable_lane_delays   ? 0 : $urandom_range(0,8);
            polarity_Rx[n]   = disable_lane_polarity ? 0 : $urandom_range(0,1);
            n++;
        end

        #(5us);

        //Create a new HMC link config
        link_cfg = new();

        link_cfg.cfg_cid                = `HMC_CUBID;
        link_cfg.cfg_lane_auto_correct  = 1;
        link_cfg.cfg_rsp_open_loop      = 0;

        // These are set to match the design
        link_cfg.cfg_rx_clk_ratio       = 40;
        link_cfg.cfg_half_link_mode_rx  = (NUM_LANES==8);

        link_cfg.cfg_tx_clk_ratio       = 40;
        link_cfg.cfg_half_link_mode_tx  = (NUM_LANES==8);

        link_cfg.cfg_descram_enb        = !disable_scramblers;
        link_cfg.cfg_scram_enb          = !disable_scramblers;

        link_cfg.cfg_tokens             = `HMC_TOKENS;
        link_cfg.cfg_init_retry_rxcnt   = 16;
        link_cfg.cfg_init_retry_txcnt   = 16;

        //***Enable Errors - Dont touch
        //link_cfg.cfg_rsp_dln   = 5;
        //link_cfg.cfg_rsp_lng   = 5;
        //link_cfg.cfg_rsp_crc   = 5;
        //link_cfg.cfg_rsp_seq   = 5;
        //link_cfg.cfg_rsp_poison= 5;
        //

        link_cfg.cfg_retry_enb          = 1;

        if(!disable_scramblers)
            link_cfg.cfg_tx_rl_lim      = 85;

        tb_top.dut_I.hmc_bfm0.set_config(link_cfg,0);
        //link_cfg.display(); //uncomment for full link configuration output      

        $display("***** HMC BFM CONFIGURATION IS COMPLETE *****");
    end

//----------------------------- Generate Clocks
generate
    begin : clocking_gen
        initial clk_10G = 1'b1;
        always #0.05ns clk_10G = ~clk_10G;

        initial clk_hmc = 1'bZ;
        always begin
            if (clk_hmc == 1'bZ )
            begin
                @(posedge clk_hmc_refclk);
                clk_hmc = 1'b1;
            end
            //Clock frequency depends on the link-width and datapath-width. Lane speed is fixed to 10Gbit
            case(FPW)
                2: begin
                    if(NUM_LANES==8)
                        #1.6ns clk_hmc = !clk_hmc;
                    else begin
                        $display("*******************************************************");
                        $display("***** Sorry - This configuration is not supported *****");
                        $display("***** Please use FPW=2 only with 8 lanes          *****");
                        $display("*******************************************************");
                        $finish;
                    end
                end
                4: begin
                    if(NUM_LANES==8)
                        #3.2ns clk_hmc = !clk_hmc;
                    else
                        #1.6ns clk_hmc = !clk_hmc;
                end
                6: begin
                    if(NUM_LANES==8)
                        #4.8ns clk_hmc = !clk_hmc;
                    else
                        #2.4ns clk_hmc = !clk_hmc;
                end
                8: begin
                    if(NUM_LANES==8)
                        #6.4ns clk_hmc = !clk_hmc;
                    else
                        #3.2ns clk_hmc = !clk_hmc;
                end
            endcase
        end
    end
endgenerate

//----------------------------- Signal Routing
genvar lane;
generate
    for (lane=0; lane<NUM_LANES; lane++) begin : delay_lanes_gen
        routing #(
            .LOG_DELAY(LOG_DELAY)
        ) routing_Tx (
            .clk(clk_10G),
            .data_in(serial_Txp[lane]),
            .delay_in(delays_Tx[lane]),
            .polarity_reverse_in(1'b0),
            .data_out(serial_Tx_routed[(LANE_REVERSAL_TX ? NUM_LANES-1-lane : lane)])
        );
        routing #(
            .LOG_DELAY(LOG_DELAY)
        ) routing_Rx (
            .clk(clk_10G),
            .data_in(serial_Rx[lane]),
            .delay_in(delays_Rx[lane]),
            .polarity_reverse_in(polarity_Rx[lane]),
            .data_out(serial_Rx_routed[(LANE_REVERSAL_RX ? NUM_LANES-1-lane : lane)])
        );
    end
endgenerate

//----------------------------- Behavioral SerDes
generate
    begin : serializers_gen
        assign serial_Txn = ~serial_Txp;

        for (lane=0; lane<NUM_LANES; lane++) begin : behavioral_gen
            serializer #(
                .DWIDTH(LANE_WIDTH)
            ) serializer_I (
                .clk(clk_hmc),
                .fast_clk(clk_10G),
                .data_in(to_serializers[lane*LANE_WIDTH+LANE_WIDTH-1:lane*LANE_WIDTH]),
                .data_out(serial_Txp[lane])
            );
            deserializer #(
                .DWIDTH(LANE_WIDTH)
            ) deserializer_I (
                .clk(clk_hmc),
                .fast_clk(clk_10G),
                .bit_slip(bit_slip[lane]),
                .data_in(serial_Rx_routed[lane]),
                .data_out(from_deserializers[lane*LANE_WIDTH+LANE_WIDTH-1:lane*LANE_WIDTH])
            );
        end
    end
endgenerate

//=====================================================================================================
//-----------------------------------------------------------------------------------------------------
//---------INSTANTIATIONS HERE-------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------
//=====================================================================================================
hmc_controller_top #(
    .DWIDTH(DWIDTH),
    .LOG_FPW(LOG_FPW),
    .FPW(FPW),
    .LOG_NUM_LANES(LOG_NUM_LANES),
    .NUM_LANES(NUM_LANES),
    .NUM_DATA_BYTES(NUM_DATA_BYTES)
 )
hmc_controller_instance
 (

    //----------------------------------
    //----SYSTEM INTERFACES
    //----------------------------------
    .clk_user(clk_user),
    .clk_hmc(clk_hmc),
    .res_n_user(res_n),
    .res_n_hmc(res_n),

    //----------------------------------
    //----Connect HMC Controller
    //----------------------------------
    //to TX
    .s_axis_tx_TVALID(axi4_req.TVALID),
    .s_axis_tx_TREADY(axi4_req.TREADY),
    .s_axis_tx_TDATA(axi4_req.TDATA),
    .s_axis_tx_TUSER(axi4_req.TUSER),
    //from RX
    .m_axis_rx_TVALID(axi4_rsp.TVALID),
    .m_axis_rx_TREADY(axi4_rsp.TREADY),
    .m_axis_rx_TDATA(axi4_rsp.TDATA),
    .m_axis_rx_TUSER(axi4_rsp.TUSER),

    //----------------------------------
    //----Connect Physical Link
    //----------------------------------
    .phy_data_tx_link2phy(to_serializers),
    .phy_data_rx_phy2link(from_deserializers),
    .phy_bit_slip(bit_slip),
    .phy_ready(res_n),

    //----------------------------------
    //----Connect HMC
    //----------------------------------
    .P_RST_N(P_RST_N),
    .hmc_LxRXPS(LxRXPS),
    .hmc_LxTXPS(LxTXPS),
    .FERR_N(FERR_N),

    //----------------------------------
    //----Connect RF
    //----------------------------------
    .rf_address(rfs_hmc.address),
    .rf_read_data(rfs_hmc.read_data),
    .rf_invalid_address(rfs_hmc.invalid_address),
    .rf_access_complete(rfs_hmc.access_done),
    .rf_read_en(rfs_hmc.ren),
    .rf_write_en(rfs_hmc.wen),
    .rf_write_data(rfs_hmc.write_data)

    );


    //********************************************************************************
    //   From MICRON's hmc_bfm_tb.sv
    //******************************************
    //BFM
    hmc_bfm #(
        .num_links_c    (1)
    )
    hmc_bfm0 (
        .LxRXP          (LxRXP),
        .LxRXN          (LxRXN),
        .LxTXP          (LxTXP),
        .LxTXN          (LxTXN),
        .LxRXPS         (LxRXPS),
        .LxTXPS         (LxTXPS),
        .FERR_N         (FERR_N),

        .REFCLKP        (hmc_refclkp),
        .REFCLKN        (hmc_refclkn),
        .REFCLKSEL      (1'b0),
        .P_RST_N        (P_RST_N),

        .TRST_N         (1'b0),
        .TCK            (1'b0),
        .TMS            (1'b0),
        .TDI            (1'b0),
        .TDO            (),

        .SCL            (1'b0),
        .SDA            (),

        .CUB            (3'b0),
        .REFCLK_BOOT    (2'b0),

        .EXTRESTP       (),
        .EXTRESTN       (),
        .EXTRESBP       (),
        .EXTRESBN       ()
    );

endmodule : dut

`default_nettype wire

