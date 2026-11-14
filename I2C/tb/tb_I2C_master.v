`timescale 1ns/1ps
module tb_I2C_master;

    reg clk;
    reg areset_n;
    reg start;
    reg rw;
    reg reg_read;
    reg [6:0] slave_addr;
    reg [7:0] reg_addr;
    reg [7:0] tx_data_m [0:3];
    reg [7:0] tx_data_s [0:3];
    
    tri1 SCL;
    tri1 SDA;
    wire busy;
    wire done;
    wire ack_error;
    wire [7:0] data_out;
    wire [7:0] rx_data_m [0:3];
    wire [7:0] rx_data_s [0:3];

    I2C_master #(
        .BYTE_COUNT(4)
    ) dut (
    .clk(clk),
    .areset_n(areset_n),
    .start(start),
    .rw(rw),
    .reg_read(reg_read),
    .slave_addr(slave_addr),
    .r_addr(reg_addr),
    .tx_data(tx_data_m),
    .rx_data(rx_data_m),
    .SCL(SCL),
    .SDA(SDA),
    .busy(busy),
    .done(done),
    .ack_error(ack_error)
    );

    I2C_slave_reg #(
        .BYTE_COUNT (4)
    )dut2 (
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
        tx_data_m[0] = 0;
        tx_data_s[0] = 0;
        tx_data_m[1] = 0;
        tx_data_s[1] = 0;
        tx_data_m[2] = 0;
        tx_data_s[2] = 0;
        tx_data_m[3] = 0;
        tx_data_s[3] = 0;
        slave_addr = 0;
        reg_read = 0;
        reg_addr = 8'b10010000;
        
        forever #0.025 clk = ~clk;
    end

    initial begin
        #1 areset_n = 1;
        @(negedge clk);
        start = 1;
        rw = 1;
        reg_read = 1;
        slave_addr = 7'b1001011;
        tx_data_m[0] = 8'b10101011;
        tx_data_s[0] = 8'b11001111;

        tx_data_m[1] = 8'b11110000;
        tx_data_s[1] = 8'b00001111;

        tx_data_m[2] = 8'b10000001;
        tx_data_s[2] = 8'b01111110;

        tx_data_m[3] = 8'b00000000;
        tx_data_s[3] = 8'b11111111;



        #1000;
        $finish;
    end

endmodule