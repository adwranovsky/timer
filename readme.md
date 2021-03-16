# timer
A simple timer module

## Parameters
### WIDTH
The width of the internal counter that backs the timer
### COVER
For testing use only. Set to 1 to include cover properties during formal verification

## Ports
### clk_i
The system clock
### rst_i
An active high, synchronous reset
### start_i
When high, the value of count_i is loaded and the module starts counting down
### count_i
The amount of time to wait for when start_i goes high
### done_o
Is high when the internal counter is expired and equals 0

## Description
The number of clock cycles between start_i going high and done_o going high is the value loaded into count_i when
start_i goes high. Setting start_i high before done_i goes high will abort any previous operation and reload the
counter. Setting rst_i high is equivalent to setting start_i with count_i equal to 0.

## FuseSoC
Use [FuseSoc](https://github.com/olofk/fusesoc) to simplify integrating this core into your project. If you're
interested in more cores by me, take a peek at my [FuseSoC core library](https://github.com/adwranovsky/CoreOrchard).

## License
This project is licensed under the [OHDL](http://juliusbaxter.net/ohdl/ohdl.txt), which is a weak, copyleft license for HDL.
