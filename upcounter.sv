`timescale 1ns / 1ps

module upcounter (
    input  logic       clk,
    input  logic       reset,
    input  logic       runstop,
    input  logic       clear,
    input  logic       ready,
    input  logic       done,
    output logic [7:0] tx_data,
    output logic       start,
    output logic       SS
);
    logic [15:0] count;
    logic o_tick_100hz;

    up_counter U_up_counter (
        .clk(clk),
        .reset(reset),
        .runstop(runstop),
        .clear(clear),
        .o_tick_100hz(o_tick_100hz),
        .count(count)
    );

    up_counter_cr U_up_counter_cr (
        .clk(clk),
        .reset(reset),
        .count(count),
        .ready(ready),
        .done(done),
        .tx_data(tx_data),
        .start(start),
        .SS(SS)
    );

    tick_gen_100hz U_tick_gen_100hz(
    .clk(clk),
    .rst(reset),
    .o_tick_100hz(o_tick_100hz)
);

endmodule


module up_counter (
    input  logic        clk,
    input  logic        reset,
    input  logic        runstop,
    input  logic        clear,
    input  logic        o_tick_100hz,
    output logic [15:0] count
);
    logic [15:0] count_reg, count_next;


    assign count = count_reg;

    typedef enum {
        STOP,
        RUN,
        CLEAR
    } state_t;

    state_t state, state_next;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state    <= STOP;
            count_reg <= 0;
        end else begin
            state <= state_next;
            count_reg <= count_next;
        end
    end

    always_comb begin
        count_next = count_reg;
        state_next = state;
        case (state)
            STOP: begin
                if (runstop) begin
                    state_next = RUN;
                end else if (clear) begin
                    state_next = CLEAR;
                end
            end
            RUN: begin
                if (o_tick_100hz) begin
                    count_next = count_reg + 1;
                end
                if (runstop) begin
                    state_next = STOP;
                end
            end
            CLEAR: begin
                count_next = 16'b0;
                state_next = STOP;
            end
        endcase
    end

endmodule

module up_counter_cr (
    input  logic        clk,
    input  logic        reset,
    input  logic [15:0] count,
    //spi signal
    input  logic        ready,
    input  logic        done,
    output logic [ 7:0] tx_data,
    output logic        start,
    output logic        SS
);

    logic [7:0] tx_data_reg, tx_data_next;
    logic start_reg, start_next;
    logic SS_reg, SS_next;

    assign tx_data = tx_data_reg;
    assign start   = start_reg;
    assign SS      = SS_reg;

    typedef enum {
        IDLE,
        START_UPBIT,
        WAIT_UPBIT_DONE,
        START_DOWNBIT,
        WAIT_DOWNBIT_DONE
    } state_t;

    state_t state, state_next;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            tx_data_reg <= 0;
            SS_reg      <= 1'b1;
            start_reg   <= 1'b0;
        end else begin
            state       <= state_next;
            tx_data_reg <= tx_data_next;
            SS_reg      <= SS_next;
            start_reg   <= start_next;
        end
    end

    always_comb begin
        state_next   = state;
        SS_next      = SS_reg;
        tx_data_next = tx_data_reg;
        start_next   = 1'b0;

        case (state)
            IDLE: begin
                SS_next = 1'b1;
                if (ready) begin
                    state_next = START_UPBIT;
                end
            end

            START_UPBIT: begin
                SS_next = 1'b0;
                tx_data_next = {count[15:8]};
                start_next = 1'b1;
                state_next = WAIT_UPBIT_DONE;
            end

            WAIT_UPBIT_DONE: begin
                if (done) begin
                    state_next = START_DOWNBIT;
                end
            end

            START_DOWNBIT: begin
                tx_data_next = {count[7:0]};
                start_next   = 1'b1;
                state_next   = WAIT_DOWNBIT_DONE;
            end

            WAIT_DOWNBIT_DONE: begin
                if (done) begin
                    state_next = IDLE;
                end
            end

        endcase
    end
endmodule



module tick_gen_100hz (
    input   clk,
    input   rst,
    output  o_tick_100hz
);

    parameter FCOUNT = 100_000_000 / 100;
    reg [$clog2(FCOUNT)-1:0] r_counter;
    reg r_tick;
    assign o_tick_100hz = r_tick;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter <= 0;
            r_tick <= 1'b0;
        end else begin
            if (r_counter == FCOUNT - 1) begin
                r_counter <= 0;
                r_tick <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_tick <= 1'b0;
            end
        end
    end
endmodule
