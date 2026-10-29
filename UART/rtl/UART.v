module UART #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 9600
) (
    input clk,
    input areset_n,
    input t_ready,
    input [7:0] data_in,
    output t_busy,
    output tx,
    input rx,
    output [7:0] data_out,
    output rx_valid,
    output rx_error
);
    //wire syn_rx;

    UART_TX #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) TX (
        .clk(clk),
        .areset_n(areset_n),
        .t_ready(t_ready),
        .data_in(data_in),
        .t_busy(t_busy),
        .tx(tx)
    );

    synchronizer syn(
        .clk(clk),
        .areset_n(areset_n),
        .syn_in(rx),
        .syn_out(syn_rx)
    );

    UART_RX #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) RX (
        .clk(clk),
        .areset_n(areset_n),
        .rx(syn_rx),
        .data_out(data_out),
        .rx_valid(rx_valid),
        .rx_error(rx_error)
    );



endmodule