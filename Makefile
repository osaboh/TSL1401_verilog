all: a.out wave.vcd

a.out: tsl1401.v
	iverilog -o a.out *.v

wave.vcd:
	vvp ./a.out
clean:
	rm -f a.out
	rm -f *.vcd

