`default_nettype none

/*
 * timer - A simple timer module
 *
 * Parameters:
 *  WIDTH - The width of the internal counter that backs the timer
 *
 * Ports:
 *  clk_i - The system clock
 *  rst_i - An active high, synchronous reset
 *  start_i - When high, the value of count_i is loaded and the module starts counting down
 *  count_i - The amount of time to wait for when start_i goes high
 *  done_o - Is high when the internal counter is expired and equals 0
 *
 * Description:
 *  The number of clock cycles between start_i going high and done_o going high is the value loaded into count_i when
 *  start_i goes high. Setting start_i high before done_i goes high will abort any previous operation and reload the
 *  counter. Setting rst_i high is equivalent to setting start_i with count_i equal to 0.
 */
module timer #(
    parameter WIDTH = 8,
    parameter COVER = 0
) (
    input wire clk_i,
    input wire rst_i,
    input wire start_i,
    input wire [WIDTH-1:0] count_i,
    output wire done_o
);
    reg [WIDTH-1:0] counter = 0;
    assign done_o = counter == 0;
    always @(posedge clk_i)
        if (rst_i)
            counter <= 0;
        else if (start_i)
            counter <= count_i;
        else if (done_o)
            counter <= 0;
        else
            counter <= counter - 1;

`ifdef FORMAL
    // Keep track of whether or not $past() is valid
    reg f_past_valid = 0;
    always @(posedge clk_i)
        f_past_valid <= 1;

    // Remember the number of cycles from "start_i" to "done_o", and what the last value of "count_i" was
    reg [WIDTH:0] f_num_cycles = 0;
    reg [WIDTH-1:0] f_last_count = 0;
    always @(posedge clk_i)
        if (rst_i) begin
            f_num_cycles <= 0;
            f_last_count <= 0;
        end else if (start_i) begin
            f_num_cycles <= 0;
            f_last_count <= count_i;
        end else if (!done_o) begin
            f_num_cycles = f_num_cycles + 1;
            f_last_count <= f_last_count;
        end else begin
            f_num_cycles = f_num_cycles;
            f_last_count <= f_last_count;
        end

    // Keep track of whether or not the timer is running
    reg f_timer_running = 0;
    always @(posedge clk_i)
        if (rst_i)
            f_timer_running <= 0;
        else if (start_i)
            f_timer_running <= 1;
        else if (done_o)
            f_timer_running <= 0;
        else
            f_timer_running <= f_timer_running;

    // Verify that the number of cycles from "start_i" to "done_o" matches what was requested
    always @(*)
        assert(f_num_cycles == f_last_count-counter);

    // Make sure that the timer can run to completion
    generate if (COVER == 1) begin
        always @(*)
            cover(f_timer_running && done_o);
    end endgenerate

    // Ensure that the timer is actively counting down if we've started it and it hasn't completed
    always @(*)
        if (f_timer_running && !done_o)
            assert(counter > 0);

    // Ensure that done_o is only asserted if the counter is empty
    always @(*)
        if (done_o)
            assert(counter == 0);

    // Generate a testbench that runs the timer for 25 cycles
    generate if (COVER == 1 && WIDTH >= 5) begin
        always @(*)
            cover(f_num_cycles==25 && done_o);
    end endgenerate
`endif

endmodule

`default_nettype wire
