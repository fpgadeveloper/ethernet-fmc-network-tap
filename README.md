ethernet-fmc-axi-eth
====================

Hackable FPGA based network tap based on the [ZedBoard](http://zedboard.org "ZedBoard") and the [Quad Gigabit Ethernet FMC](http://ethernetfmc.com "Ethernet FMC").

### Supported boards

* Zynq-7000 [ZedBoard](http://zedboard.org "ZedBoard")
  * LPC connector (use zedboard.xdc)

### Description

This project will implement an FPGA based network tap which could be used to "listen" to the communications passing over
an Ethernet cable. It is a work that is still under development.

![Block diagram](http://www.fpgadeveloper.com/wp-content/uploads/2015/12/fpga_network_tap_4.jpg "FPGA Network Tap")

### Requirements

* Vivado 2016.2
* [Ethernet FMC](http://ethernetfmc.com "Ethernet FMC")
* One of the above listed evaluation boards

### Tutorials

The following tutorials explain the workings of the network tap:

* [FPGA Network Tap: Designing the Ethernet pass through](http://www.fpgadeveloper.com/2015/12/fpga-network-tap-designing-ethernet-pass-through.html "FPGA Network Tap: Designing the Ethernet pass through")


### For more information

If you need more information on whether the Ethernet FMC is compatible with your carrier, please contact me [here](http://ethernetfmc.com/contact/ "Ethernet FMC Contact form").
Just provide me with the pinout of your carrier and I'll be happy to check compatibility and generate a Vivado constraints file for you.

### License

Feel free to modify the code for your specific application.

### Fork and share

If you port this project to another hardware platform, please send me the
code or push it onto GitHub and send me the link so I can post it on my
website. The more people that benefit, the better.

### About the author

I'm an FPGA consultant and I provide FPGA design services to innovative
companies around the world. I believe in sharing knowledge and
I regularly contribute to the open source community.

Jeff Johnson
[FPGA Developer](http://www.fpgadeveloper.com "FPGA Developer")