

# Simulation Direcotry
SIM_DIR="sim"
TB_DIR="tb"

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

.DEFAULT_GOAL := help
.PHONY: help


## setup: Copies xilinx simulation library and configure simulation directory
setup : stim
	cd ${SIM_DIR}; \
	cp ${XILINX_LIB}/modelsim.ini .; \
	vlib work; \
	vmap work work

## compile: compiles the RTL code (NOTE: The files are recompiled before every simulation run)
compile :
	cd ${SIM_DIR}; \
	vcom ${INCLUDE_RTL} ${INCLUDE_TB}

## sim: run simulation
sim : compile
	cd ${SIM_DIR}; \
	vsim ${VSIM_OPT} tb_fpga

## waves: Open wave files
waves :
	cd ${SIM_DIR}; \
	vsim -view output.wlf -do ${WAVE_OPT}

## stim: generate stimulus input video file
stim :
	cd ${TB_DIR}; \
	python2 generate_stimulus.py -o ../${SIM_DIR}/video_in_sim.txt

## conv: generate yuv file
conv :
	cd ${SIM_DIR}; \
	rm video_out.yuv; \
	cat ./video_out_sim.txt | tr -d "\n" >> ./video_out.yuv

## play: play the generated video
play : conv
	cd ${SIM_DIR}; \
	ffplay -f rawvideo -pixel_format yuyv422  -video_size 128x144 video_out.yuv

## clean: remove all generated files in /sim directory
clean :
	cd ${SIM_DIR}; \
	rm -rf !("myfile"|"stim.do");

help: makefile
	@echo "------------------------------------------------------------\n"
	@echo "Make Options:"
	@echo ""
	@sed -n 's/^##/ -/p' $<
	@echo ""
	@echo "------------------------------------------------------------\n"
