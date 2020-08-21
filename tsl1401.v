/*
 MIT License

 Copyright (c) 2020 Mikio Osanai

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */


module tsl1401
    (
     // from upper layer
     input 	clk,
     input 	reset,
     // to TSL1401
     output reg sensor_clk,
     output reg sensor_si,
     // to MCU
     output reg mcu_ad_trig
     );

    // clock divider ratio
    localparam DIV_RATIO                = (8'D10);  // Depending on the system.

    // state of FSM
    localparam STATE_HIGH_Z             = 2'b00;
    localparam STATE_INTERNAL_RESET     = 2'b01;
    localparam STATE_PIXEL_INTEGRATING 	= 2'b10;
    localparam STATE_WAIT_TQT           = 2'b11;

    // event trigger count of FSM
    localparam CNT_SI_START             = 0;
    localparam CNT_INTERNAL_RESET_END   = (CNT_SI_START + 18);
    localparam CNT_INTEGRATION_END      = (CNT_SI_START + 129);
    localparam CNT_WAIT_TQT_END         = (CNT_INTEGRATION_END + 5); // min 20us, align even


    reg [7:0] clk_div;
    reg [7:0] state_count;
    reg [1:0] state;


    // Clock divider for TSL1401CL
    always @(posedge clk) begin
	if (reset == 1'b1) begin
	    clk_div   <= 8'b0;
	    state_count <= 8'b0;
	    sensor_clk   <= 1'b0;
	end
	else if (clk_div == DIV_RATIO - 1) begin
	    clk_div   <= 8'b0;
	    state_count <= state_count  + 8'b1;
	    sensor_clk <= ~state_count[0];
	end
	else begin
	    clk_div   <= clk_div + 8'b1;

	end
    end


    // shift phase 50%.
    // Analog output settling time typ 10ns (symbol: tqt)
    always @(posedge clk) begin
	if (reset == 1'b1) begin
	    mcu_ad_trig <= 1'b0;
	end else if (state  == STATE_INTERNAL_RESET || state == STATE_PIXEL_INTEGRATING) begin

	    if (sensor_si != 1'b1) begin
		mcu_ad_trig <= ~sensor_clk;
	    end
	end
    end

    // TSL1401CL FSM
    always @(posedge clk) begin
	if (reset == 1'b1) begin
	    sensor_si <= 1'b0;
	    state  <= STATE_HIGH_Z;
	end
	else begin
	    case (state)
		STATE_HIGH_Z: begin
		    if (state_count == CNT_SI_START) begin
			sensor_si <= 1'b1;
			state <= STATE_INTERNAL_RESET;
		    end
		end

		STATE_INTERNAL_RESET: begin
		    if (state_count == CNT_INTERNAL_RESET_END) begin
			state <= STATE_PIXEL_INTEGRATING;
		    end
		    else if (state_count == CNT_SI_START + 2) begin
			sensor_si <= 1'b0;
		    end
		end

		STATE_PIXEL_INTEGRATING: begin
		    if (state_count == CNT_INTEGRATION_END) begin
			state 	  <= STATE_WAIT_TQT;
		    end
		end

		STATE_WAIT_TQT: begin
		    if (state_count == CNT_WAIT_TQT_END) begin
			state_count <= 8'b0;
			sensor_si <= 1'b1;
			state 	  <= STATE_INTERNAL_RESET;
		    end
		end
	    endcase
	end
    end
endmodule
