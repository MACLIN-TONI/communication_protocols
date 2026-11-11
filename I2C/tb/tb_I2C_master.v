`timescale 1ns/1ps
module tb_I2C_master;

    reg clk;
    reg areset_n;
    reg start;
    reg rw;
    reg [6:0] slave_addr;
    reg [7:0] tx_data_m;
    reg [7:0] tx_data_s;
    
    tri1 SCL;
    tri1 SDA;
    wire busy;
    wire done;
    wire ack_error;

    wire [7:0] rx_data_m;
    wire [7:0] rx_data_s;

    I2C_master dut (
    .clk(clk),
    .areset_n(areset_n),
    .start(start),
    .rw(rw),
    .slave_addr(slave_addr),
    .tx_data(tx_data_m),
    .rx_data(rx_data_m),
    .SCL(SCL),
    .SDA(SDA),
    .busy(busy),
    .done(done),
    .ack_error(ack_error)
    );

    I2C_slave dut2 (
        .clk(clk),
        .areset_n(areset_n),
        .SCL(SCL),
        .SDA(SDA),
        .tx_data(tx_data_s),
        .rx_data(rx_data_s)
    );

    initial begin
        $dumpfile("waves/dump.vcd");
        $dumpvars(0,tb_I2C_master);
    end

    initial begin
        clk = 0;
        areset_n = 0;
        start = 0;
        rw = 0;
        slave_addr = 0;
        tx_data_m = 0;
        tx_data_s = 0;
        
        forever #1 clk = ~clk;
    end

    initial begin
        #1 areset_n = 1;
        @(negedge clk);
        start = 1;
        rw = 1;
        slave_addr = 7'b1001011;
        tx_data_m = 8'b10101011;
        tx_data_s = 8'b11001111;



        #1000;
        $finish;
    end

endmodule