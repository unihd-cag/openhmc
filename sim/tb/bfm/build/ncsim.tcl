database -open waves -into waves.shm -default

probe -create tb_top.dut_I -depth all -tasks -functions -all -database waves
probe -create tb_top.dut_I.openhmc_instance.rx_link_I -all -database waves -memories
probe -create tb_top.dut_I.openhmc_instance.tx_link_I -all -database waves -memories

probe -create tb_top.axi4_hmc_rsp_if -all -database waves
probe -create tb_top.axi4_hmc_req_if -all -database waves
probe -create tb_top.hmc_if -all -database waves

set assert_output_stop_level failed
set assert_report_incompletes 0

#-- enable IDA probes
#ida_database -open -name=ida.db -compress
#ida_probe -log=on
#ida_probe -wave=on
#ida_probe -sv_flow=on

run

