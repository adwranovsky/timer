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


    // Count how many cycles are left until the timer has expired
    reg [WIDTH-1:0] counter = 0;
    always @(posedge clk_i)
        if (start)
            counter <= count;
        else
            counter <= counter - 1;

    // Check when the timer has expired
    wire counter_expired = counter == 0;

    // Remember whether or not the timer is currently running. This is used to mask counter_expired, and thus lets us avoid
    // having a large mux on the input of "counter" to prevent overflow.
    reg timer_running = 0;
    always @(posedge clk_i)
        if (rst_i)
            timer_running <= 0;
        else if (timer_running)
            timer_running <= ~counter_expired;
        else
            timer_running <= start;

    // Register the done output
    reg done_reg = 0;
    assign done = done_reg;
    always @(posedge clk_i)
        if (rst_i)
            done_reg <= 0;
        else
            done_reg <= timer_running & counter_expired;

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

    // Verify that the number of cycles from "start" to "done" matches what was requested
    always @(*)
        if (done)
            assert(f_num_cycles == f_last_count+1);

    // Check that done is only asserted if the timer was running the previous cycle
    always @(posedge clk_i)
        if (done)
            assert(f_past_valid && $past(timer_running));

    // Make sure that the timer can run to completion
    reg f_timer_started = 0;
    always @(posedge clk_i)
        if (rst_i)
            f_timer_started <= 0;
        else
            f_timer_started <= start;
    always @(*)
        cover(f_timer_started && done);
`endif

endmodule

`default_nettype wire
