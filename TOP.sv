`timescale 1ns / 1ps

module TOP (
    input logic clk,
    input logic reset,
    input logic runstop,
    input logic clear,
    input logic spi_slave_sclk,
    input logic spi_slave_mosi,
    output logic spi_slave_miso,
    input logic spi_slave_ss,
    output logic spi_master_sclk,
    output logic spi_master_mosi,
    input logic spi_master_miso,
    output logic spi_master_ss,
    output logic [7:0] fnd,
    output logic [3:0] fnd_com
);

    logic runstop_bd, clear_bd;

    // button_debounce U_button_debounce1 (
    //     .clk  (clk),
    //     .rst  (reset),
    //     .i_btn(runstop),
    //     .o_btn(runstop_bd)
    // );

    // button_debounce U_button_debounce2 (
    //     .clk  (clk),
    //     .rst  (reset),
    //     .i_btn(clear),
    //     .o_btn(clear_bd)
    // );

    MASTER U_MASTER (
        .clk(clk),
        .reset(reset),
        .runstop(runstop),
        .clear(clear),
        .sclk(spi_master_sclk),
        .mosi(spi_master_mosi),
        .miso(spi_master_miso),
        .SS(spi_master_ss)
    );

    SLAVE U_SLAVE (
        .clk(clk),
        .reset(reset),
        .sclk(spi_slave_sclk),
        .mosi(spi_slave_mosi),
        .miso(spi_slave_miso),
        .SS(spi_slave_ss),
        .fnd(fnd),
        .fnd_com(fnd_com)
    );
endmodule


module button_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);

    reg [$clog2(100)-1:0] counter_reg;
    reg clk_reg;
    reg [7:0] q_reg, q_next;
    reg  edge_reg;
    wire debounce;

    //clock divider
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            clk_reg <= 1'b0;
        end else begin
            if (counter_reg == 99) begin
                counter_reg <= 0;
                clk_reg <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                clk_reg <= 1'b0;
            end
        end
    end

    //debounce, shift register
    always @(posedge clk_reg, posedge rst) begin
        if (rst) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end
    // serial input, paraller output shift register
    always @(*) begin
        q_next = {i_btn, q_reg[7:1]};
    end
    // 4input AND
    assign debounce = &q_reg;
    //Q5 output
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end
    //edge output
    assign o_btn = ~edge_reg & debounce;

endmodule

