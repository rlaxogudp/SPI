`timescale 1ns / 1ps

module spi_slave (
    input              clk,
    input              reset,
    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    input  logic       SS,
    output logic [7:0] rx_data,
    output logic       done
);

    typedef enum {
        IDLE,
        DATA
    } state_t;

    state_t state, state_next;

    logic [2:0] bit_counter_reg, bit_counter_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic done_reg, done_next;
    logic sclk_sync0, sclk_sync1, sclk_sync2;

    assign rx_data = rx_data_reg;
    assign done    = done_reg;

    wire sclk_edge = sclk_sync1 & ~sclk_sync2;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            sclk_sync0 <= 0;
            sclk_sync1 <= 0;
        end else begin
            sclk_sync0 <= sclk;
            sclk_sync1 <= sclk_sync0;
            sclk_sync2 <= sclk_sync1;
        end
    end


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state           <= IDLE;
            rx_data_reg     <= 0;
            bit_counter_reg <= 0;
            done_reg        <= 1'b0;
        end else begin
            state           <= state_next;
            rx_data_reg     <= rx_data_next;
            bit_counter_reg <= bit_counter_next;
            done_reg        <= done_next;
        end
    end

    always_comb begin
        state_next       = state;
        bit_counter_next = bit_counter_reg;
        rx_data_next     = rx_data_reg;
        done_next        = done_reg;
        case (state)
            IDLE: begin
                if (SS == 1'b0) begin
                    state_next       = DATA;
                    bit_counter_next = 0;
                    rx_data_next     = 0;
                    done_next        = 1'b0;
                end
            end
            DATA: begin
                if (SS == 1'b1) begin
                    state_next = IDLE;
                end else if (sclk_edge) begin
                    rx_data_next = {rx_data_reg[6:0], mosi};
                    bit_counter_next = bit_counter_reg + 1;
                    if (bit_counter_reg == 7) begin
                        done_next  = 1'b1;
                        state_next = IDLE;
                    end
                end
            end
        endcase
    end

endmodule





module slave_cu (
    input  logic        clk,
    input  logic        reset,
    input  logic [ 7:0] rx_data,
    input  logic        done,
    output logic [15:0] fnd_data
);

    logic [7:0] fnd_data_reg1, fnd_data_next1;
    logic [7:0] fnd_data_reg2, fnd_data_next2;

    assign fnd_data = {fnd_data_reg1,fnd_data_reg2};

    typedef enum {
        IDLE,
        DATA1,
        DATA2
    } state_t;
    state_t state, state_next;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            fnd_data_reg1 <= 16'b0;
            fnd_data_reg2 <= 16'b0;
        end else begin
            state <= state_next;
            fnd_data_reg1 <= fnd_data_next1;
            fnd_data_reg2 <= fnd_data_next2;
        end
    end

    always_comb begin
        state_next = state;
        fnd_data_next1 = fnd_data_reg1;
        fnd_data_next2 = fnd_data_reg2;
        case (state)
            IDLE: begin
                state_next = DATA1;
            end
            DATA1: begin
                if (done) begin
                    fnd_data_next1 = rx_data;
                    state_next = DATA2;
                end
            end
            DATA2: begin
                if (done) begin
                    fnd_data_next2 = rx_data;
                    state_next = IDLE;
                end
            end
        endcase
    end

endmodule
