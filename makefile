

# Simulation Direcotry
DIR="sim"

# RTL directories
INCLUDE_RTL= ../rtl/counter_add.vhd \
			 ../rtl/edge_enhancement_1.0/hdl/edge_enhancement_v1_0.vhd \
			 ../rtl/edge_enhancement_1.0/src/dsp48_wrap.vhd \
			 ../rtl/edge_enhancement_1.0/src/kernel_matrix.vhd \
			 ../rtl/edge_enhancement_1.0/src/shift_register.vhd

# TB direcotry
INCLUDE_TB=../tb/tb_fpga.vhd

# Xilinx compiled lib directory
XILINX_LIB=~/workspace/compile_simlib

# Modelsim options
VSIM_OPT = -do myfile \
		   -wlf output.wlf

# Waveform Configuration
WAVE_DO=wave.do

#ifeq ($(WAVES), 1)
#	VSIM_OPT += -wlf output.wlf
#endif

ifneq ($(GUI), 1)
	VSIM_OPT += -batch
endif


ifneq (,$(wildcard ./sim/${WAVE_DO}))
	WAVE_OPT = "view signal list wave; radix hex; source wave.do"
else
	WAVE_OPT = "view signal list wave; radix hex"
endif

#==================
# Targets
#==================

setup :
	cd ${DIR}; \
	cp ${XILINX_LIB}/modelsim.ini .; \
	vlib work; \
	vmap work work

compile :
	cd ${DIR}; \
	vcom ${INCLUDE_RTL} ${INCLUDE_TB}

sim : compile
	cd ${DIR}; \
	vsim ${VSIM_OPT} tb_fpga

sim_gui : compile
	cd ${DIR}; \
	vsim -do myfile -wlf output.wlf tb_fpga

waves :
	cd ${DIR}; \
	vsim -view output.wlf -do ${WAVE_OPT}

clean :
	cd ${DIR}; \
	rm -rf work/;\
	rm -rf transcript;\
	rm -rf counter.lst;\
	rm -rf modelsim.ini;\
	rm -rf output.wlf


