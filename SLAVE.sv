`timescale 1ns / 1ps

module SLAVE (
    input  logic       clk,
    input  logic       reset,
    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    input  logic       SS,
    output logic [7:0] fnd,
    output logic [3:0] fnd_com
);

    logic [15:0] fnd_data;
    logic [7:0] rx_data;
    logic done;

    spi_slave U_spi_slave (
        .clk(clk),
        .reset(reset),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .SS(SS),
        .rx_data(rx_data),
        .done(done)
    );

    slave_cu U_SLAVE_CU (
        .clk(clk),
        .reset(reset),
        .rx_data(rx_data),
        .done(done),
        .fnd_data(fnd_data)
    );

    fnd_controller U_FND_CR (
        .clk(clk),
        .reset(reset),
        .counter(fnd_data[13:0]),
        .fnd_com(fnd_com),
        .fnd(fnd)
    );
endmodule
