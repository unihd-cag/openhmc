database -open waves -into waves.shm -default

probe -create tb_top.dut_I -depth all -tasks -functions -all -database waves
probe -create tb_top.dut_I.hmc_controller_instance.hmc_rx_link_I -all -database waves -memories
probe -create tb_top.dut_I.hmc_controller_instance.hmc_tx_link_I -all -database waves -memories

probe -create tb_top.axi4_hmc_req_if -all -database waves
probe -create tb_top.axi4_hmc_rsp_if -all -database waves

set assert_output_stop_level failed
set assert_report_incompletes 0

run

