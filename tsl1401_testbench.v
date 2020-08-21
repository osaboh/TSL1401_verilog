`timescale 1ns / 1ps

module tsl1401_testbench;

    parameter STEP = 100; // 1000ns:1MHz
    parameter TICKS  = 5000;
    parameter INTERNAL_RESET_TICKS = 500;

    reg clk;
    reg reset;
    wire sensor_clk;
    wire sensor_si;
    wire mcu_ad_trig;

    initial begin
	$dumpfile("wave.vcd");
	$dumpvars(0, tsl1401_inst);
	$dumpvars(0);
	$monitor("clk: %d, reset: %d sensor_clk: %d sensor_si: %d, mcu_ad_trig: %d, state: %d, state_count: %d",
		 tsl1401_inst.clk,
		 tsl1401_inst.reset,
		 tsl1401_inst.sensor_clk,
		 tsl1401_inst.sensor_si,
		 tsl1401_inst.mcu_ad_trig,
		 tsl1401_inst.state,
		 tsl1401_inst.state_count);
    end

    // clock
    initial begin
	#1 clk = 1'b1;
	forever
	begin
	    #(STEP / 2) clk = ~clk;
	end
    end

    // synchronous reset
    initial begin
	#1 reset  = 1'b1;
	// 100 clock
	repeat (100) @(posedge clk) reset <= 1'b1;
	@(posedge clk) reset <= 1'b0;
    end


    initial begin
	#1 repeat (TICKS) @(posedge clk);
	$finish;
    end

    tsl1401 tsl1401_inst
	(
	 .clk (clk),
	 .reset	  (reset),
	 .sensor_clk  (sensor_clk),
	 .sensor_si (sensor_si),
	 .mcu_ad_trig (mcu_ad_trig)
	 );

endmodule
