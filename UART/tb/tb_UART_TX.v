`timescale 1ns/1ps
module tb_UART_TX;
    reg clk;
    reg areset_n;
    reg t_ready;
    reg [7:0] data_in;
    wire t_busy;
    wire tx;

    UART_TX #(
         .CLK_FREQ(25),
         .BAUD_RATE(5)
        ) dut(
        .clk(clk),
        .areset_n(areset_n),
        .t_ready(t_ready),
        .data_in(data_in),
        .t_busy(t_busy),
        .tx(tx)
    );

    initial begin
        $dumpfile("waves/dump.vcd");
        $dumpvars(0,tb_UART_TX);
    end

    initial begin
        clk = 0;
        areset_n = 0;
        t_ready = 0;
        data_in = 0;
        forever #1 clk = ~clk;
    end

    initial begin
        #7; areset_n = 1;
        #20; data_in = 8'b01010101;
        #26; t_ready = 1; 
        #5; t_ready = 0;
        #12; data_in = 8'b11100011;
        #6; t_ready = 1;
         



        #1000;
        $finish;
    end
endmodule