
DIR="sim"
RTL="../rtl/*"
TB="../tb/*"


#==================
# Targets
#==================

setup :
	cd ${DIR}; \
	vlib work; \
	vmap work work

compile :
	cd ${DIR}; \
	vcom ${RTL} ${TB}

sim : compile
	cd ${DIR}; \
	vsim -batch -do myfile -wlf output.wlf tb_fpga

sim_gui : compile
	cd ${DIR}; \
	vsim -do myfile -wlf output.wlf tb_fpga

waves :
	cd ${DIR}; \
	vsim -view output.wlf -do "view signals list wave"

clean :
	cd ${DIR}; \
	rm -rf work/;\
	rm -rf modelsim.ini;\
	rm -rf output.wlf


