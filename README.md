# FPGA Image Enhancement

### Directories:
The following is a description of directories:
+ docs : Documents folder
+ rtl  : RTL Logic
+ tb   : Testbench
+ scripts: testbench scripts
+ sim  : Modelsim and verification files
+ video: Contains samples of video used as stimulus
+ c\_model: cpp module

## Getting Started

### Prerequisites
The following are list of tools required to run the project

+ Modelsim 2021.1
+ Vivado 2020.1
+ FFplay
+ FFmpeg
+ OpenCV
+ Make
+ Cmake


### Installing ModelSim

[ref] https://profile.iiita.ac.in/bibhas.ghoshal/COA\_2020/Lab/ModelSim%20Linux%20installation.html


1) Install Modelsim from the Intel website. you will require the following two files (NOTE: The version might be different):
    - modelsim\_part2-21.2.0.72-linux.qdz
    - ModelSimProSetup-21.2.0.72-linux.run

2) Run ````./ModelSimProSetup-21.2.0.72-linux.run```` and follow the steps to install the tools

3) Export the modelsim tool in your PATH environment variable. You can the following function in your .bashrc file:

```bash
# Add Modelsim to PATH
if [[ :$PATH: != *:"/tools/intelFPGA_pro/21.2/modelsim_ase/bin":* ]] ; then
    export PATH=$PATH:/tools/intelFPGA_pro/21.2/modelsim_ase/bin
fi
```

4) Modelsim Requires 32bit libraries. Add the following libraries to the system:

```console
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386
sudo apt-get install libxft2:i386
sudo apt-get install lib32z1 lib32ncurses6 libbz2-1.0
sudo apt-get install libxext6
```

Now you should be able to run ````vsim````.

** NOTE: ** Vivado is dependent on the modelsim version. You will need to acquire the correct modelsim version to be able to generate the simulation libraries with vivado.

### Cpp Model
The following are the steps to compile the opencv model:
1) Navigate to c\_model
2) Run cmake command: ````cmake .````
3) Run make command: ````make````
4) Execute program: ````./esharp -i foreman_128x144.yuv -s 128x144 -g 1.4````


### Simulation
Running the simulation:

1) Clone the git repo
2) Clean and setup the directory (```` make clean setup ````)
3) Run the simulation (```` make sim ````)

you can dispay the waveform by running ```` make waves ```` or run in GUI mode using the command ```` make sim GUI=1 ````



### NOTES:

Using FFplay to play raw video:
```console
ffplay -f rawvideo -pixel_format yuyv422 -video_size 128x144 -i foreman_128x144.yuv
```
