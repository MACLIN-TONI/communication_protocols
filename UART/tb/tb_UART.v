`timescale 1ns/1ps
module tb_UART;
    reg clk1;
    reg areset_n1;
    reg t_ready1;
    reg [7:0] data_in1;
    wire t_busy1;
    wire tx1;
    reg rx1;
    wire [7:0] data_out1;
    wire rx_valid1;
    wire rx_error1;

    reg clk2;
    reg areset_n2;
    reg t_ready2;
    reg [7:0] data_in2;
    wire t_busy2;
    wire tx2;
    reg rx2;
    wire [7:0] data_out2;
    wire rx_valid2;
    wire rx_error2;

    integer PASS = 0;
    integer FAIL = 0;

    UART #(
        .CLK_FREQ(100),
        .BAUD_RATE(5)
    ) dut1 (
        .clk(clk1),
        .areset_n(areset_n1),
        .t_ready(t_ready1),
        .data_in(data_in1),
        .t_busy(t_busy1),
        .tx(tx1),
        .rx(tx2),
        .data_out(data_out1),
        .rx_valid(rx_valid1),
        .rx_error(rx_error1)
    );

    UART #(
        .CLK_FREQ(50),
        .BAUD_RATE(5)
    ) dut2 (
        .clk(clk2),
        .areset_n(areset_n2),
        .t_ready(t_ready2),
        .data_in(data_in2),
        .t_busy(t_busy2),
        .tx(tx2),
        .rx(tx1),
        .data_out(data_out2),
        .rx_valid(rx_valid2),
        .rx_error(rx_error2)
    );

    initial begin
        $dumpfile("waves/dump.vcd");
        $dumpvars(0,tb_UART);
    end

    initial begin
        clk1 = 0;
        areset_n1 = 0;
        t_ready1 =0;
        data_in1 = 0;
        forever #0.5 clk1 = ~clk1; 
    end

    initial begin
        clk2 = 0;
        areset_n2 = 0;
        t_ready2 =0;
        data_in2 = 0;
        forever #1 clk2 = ~clk2; 
    end

    initial begin
        #10;
        areset_n1 = 1;
        areset_n2 = 1;
        #10;
        data_in1 = 8'b11110000;
        data_in2 = 8'b00001111;
        #2;
        @(negedge clk1) t_ready1=1;
        @(negedge clk2) t_ready2=1;
        #200;
        data_in1 = 8'b11111111;
        data_in2 = 8'b00000000;
        #200;
        data_in1 = 8'b11100000;
        data_in2 = 8'b00011111;

        #2000;

        $finish;
    end

endmodule