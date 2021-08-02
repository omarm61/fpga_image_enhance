# Copyright 1991-2016 Mentor Graphics Corporation
#
# All Rights Reserved.
#
# THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY INFORMATION WHICH IS THE PROPERTY OF
# MENTOR GRAPHICS CORPORATION OR ITS LICENSORS AND IS SUBJECT TO LICENSE TERMS.


#-- set default radix to symbolic
radix symbolic

when -label a {counter == x"64"} {puts "Counter = 100"}

# Functions
proc wait_for_signal {signal} {
    puts "Wait for signal"
        while {[expr [examine -decimal $signal] != 100]} {
            run 100
        }
    puts "Counter: Counting to 100 failed. COUNT is [examine -decimal $signal]."
}

proc verify_test {err msg} {
    set RED   "\033\[0;31m"
    set GREEN "\033\[0;32m"
    set NC    "\033\[0m"
    if {!$err} {
        puts "------------------------------"
        puts "$GREEN PASSED $NC: $msg"
        puts "------------------------------"
    } else {
        puts "------------------------------"
        puts "$RED FAILED $NC: Test Passed $msg"
        puts "------------------------------"
    }
}

# setup an oscillator on the CLK input
force i_sim_clk 1 50  -r 100
force i_sim_clk 0 100 -r 100

# reset the clock and then counter to 100
force i_sim_aresetn 0
run 100
if {[examine counter] != 0} {
	echo "!!! Error: Reset failed. COUNT is [examine counter]."
} else {
	echo "Reset OK. COUNT is [examine counter]."
}

puts ""
puts "------------------------------------------"
puts " Simulation START"
puts "------------------------------------------"
puts ""
force i_sim_aresetn 1


#run 10000
wait_for_signal counter
if {[expr [examine -decimal counter] != 100]} {
	puts "!!! Error: Counting to 100 failed. COUNT is [examine -decimal counter]."
} else {
	puts "Test passed. COUNT is [examine -decimal counter]."
    verify_test 0 "Counter reached 100"
}

puts ""
puts "------------------------------------------"
puts " Simulation DONE"
puts "------------------------------------------"
puts ""

exit
