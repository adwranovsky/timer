`default_nettype none

module timer #(
    parameter WIDTH = 8
) (
    input wire clk_i,
    input wire rst_i,
    input wire start,
    input wire [WIDTH-1:0] count,
    output wire done
);
    reg [WIDTH-1:0] counter = 0;
    assign done = counter == 0;
    always @(posedge clk_i)
        if (rst_i)
            counter <= 0;
        else if (start)
            counter <= count;
        else if (done)
            counter <= 0;
        else
            counter <= counter - 1;

`ifdef FORMAL
    reg f_past_valid = 0;
    always @(posedge clk_i)
        f_past_valid <= 1;

    // Remember the number of cycles from "start" to "done", and what the last value of "count" was
    reg [WIDTH:0] f_num_cycles;
    reg [WIDTH-1:0] f_last_count;
    always @(posedge clk_i)
        if (start) begin
            f_num_cycles <= 0;
            f_last_count <= count;
        end else begin
            f_num_cycles = f_num_cycles + 1;
            f_last_count <= f_last_count;
        end

    // Keep track of whether or not the timer is running
    reg f_timer_running = 0;
    always @(posedge clk_i)
        if (rst_i)
            f_timer_running <= 0;
        else if (start)
            f_timer_running <= 1;
        else if (done)
            f_timer_running <= 0;
        else
            f_timer_running <= f_timer_running;

    // Verify that the number of cycles from "start" to "done" matches what was requested
    always @(*)
        if (done && f_timer_running)
            assert(f_num_cycles == f_last_count);

    // Make sure that the timer can run to completion
    always @(*)
        cover(f_timer_running && done);

    // Ensure that the timer is actively counting down if we've started it and it hasn't completed
    always @(*)
        if (f_timer_running)
            assert(counter > 0);

    // Ensure that done is only asserted if the counter is empty
    always @(*)
        if (done)
            assert(counter == 0);

    // Generate a testbench that runs the timer for 25 cycles
    generate if (WIDTH >= 5)
        always @(*)
            cover(f_num_cycles==25 && done);
    endgenerate
`endif

endmodule

`default_nettype wire
