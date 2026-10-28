`timescale 1ns/1ps
module tb_UART_RX;
    reg clk;
    reg areset_n;
    wire [7:0] data_out;
    wire rx_valid;
    wire rx_erro;

    reg t_ready;
    reg [7:0] data_in;
    wire t_busy;
    wire tx;

    UART_TX #(
         .CLK_FREQ(25),
         .BAUD_RATE(5)
        ) dut1(
        .clk(clk),
        .areset_n(areset_n),
        .t_ready(t_ready),
        .data_in(data_in),
        .t_busy(t_busy),
        .tx(tx)
    );


    UART_RX #(
         .CLK_FREQ(25),
         .BAUD_RATE(5)
        ) dut2(
        .clk(clk),
        .areset_n(areset_n),
        .rx(tx),
        .data_out(data_out),
        .rx_valid(rx_valid),
        .rx_error(rx_error)
    );

    initial begin
        $dumpfile("waves/dump.vcd");
        $dumpvars(0,tb_UART_RX);
    end

    initial begin
        clk = 0;
        areset_n = 0;
        t_ready = 0;
        data_in = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        #7; areset_n = 1;
        #12; data_in = 8'b11100011;
        #6; t_ready = 1;
         



        #3000;
        $finish;
    end
endmodule