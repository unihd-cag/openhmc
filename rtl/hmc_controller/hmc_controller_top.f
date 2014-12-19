### Make sure to source the path variable first.
#use: export OPENHMC_PATH=path_to_openhmc_main_folder

####HEADER
-incdir ${OPENHMC_PATH}/rtl/include/

####Top
${OPENHMC_PATH}/rtl/hmc_controller/hmc_controller_top.v

####Controller TX
${OPENHMC_PATH}/rtl/hmc_controller/tx/tx_link.v
${OPENHMC_PATH}/rtl/hmc_controller/tx/tx_run_length_limiter.v
${OPENHMC_PATH}/rtl/hmc_controller/tx/tx_scrambler.v
${OPENHMC_PATH}/rtl/hmc_controller/tx/tx_crc_combine.v

####Controller RX
${OPENHMC_PATH}/rtl/hmc_controller/rx/rx_link.v
${OPENHMC_PATH}/rtl/hmc_controller/rx/rx_lane_logic.v
${OPENHMC_PATH}/rtl/hmc_controller/rx/rx_descrambler.v
${OPENHMC_PATH}/rtl/hmc_controller/rx/rx_crc_compare.v

####CRC
${OPENHMC_PATH}/rtl/hmc_controller/crc/crc_128_init.v
${OPENHMC_PATH}/rtl/hmc_controller/crc/crc_accu.v

####Register File
${OPENHMC_PATH}/rtl/hmc_controller/register_file/hmc_controller_8x_rf.v
${OPENHMC_PATH}/rtl/hmc_controller/register_file/hmc_controller_16x_rf.v

####Building blocks
-f ${OPENHMC_PATH}/rtl/building_blocks/fifos/sync/sync_fifos.f
${OPENHMC_PATH}/rtl/building_blocks/fifos/async/hmc_async_fifo.v
${OPENHMC_PATH}/rtl/building_blocks/counter/counter48.v
${OPENHMC_PATH}/rtl/building_blocks/rams/hmc_ram.v
