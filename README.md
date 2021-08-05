# FPGA Image Enhance

### Directories:
+ rtl: RTL Logic
+ tb : Testbench
+ sim: Modelsim and verification files

## Getting Started

### Prerequisites
The following are list of tools required to run the project

+ Modelsim 2021.1
+ Vivado 2020.1
+ FFplay
+ Make
+ Cmake


### Simulation
Running the simulation:

1) Clone the git repo
2) Clean and setup the directory (```` make clean setup ````)
3) Run the simulation (```` make sim ````)

you can dispay the waveform by running ```` make waves ```` or run in GUI mode using the command ```` make sim GUI=1 ````



### NOTES:

Using FFplay to play raw video:
````
ffplay -f rawvideo -pixel\_format yuyv422 -video\_size 128x144 -i foreman\_128x144.yuv
````
