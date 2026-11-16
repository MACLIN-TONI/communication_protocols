`timescale 1ns/1ps
module tb_I2C_master;

    reg clk;
    reg areset_n;
    reg master_wr_en;
    reg master_rd_en;
    reg [1:0] master_mem_addr;
    reg start;
    reg rw;
    reg reg_read;
    reg [6:0] slave_addr;
    reg [7:0] register_addr;
    reg [7:0] master_data_in;
    wire [7:0] master_data_out;
    
    wire SCL;
    wire SDA;
    wire busy;
    wire done;
    wire ack_error;

    reg slave_wr_en;
    reg slave_rd_en;
    reg [1:0] slave_mem_addr;
    reg [7:0] slave_data_in;
    wire [7:0] slave_data_out;


    pullup(SCL);
    pullup(SDA);

    I2C_master #(
        .BYTE_COUNT(4)
    ) Master_1 (
    .clk(clk),
    .areset_n(areset_n),
    .wr_en(master_wr_en),
    .rd_en(master_rd_en),
    .mem_addr(master_mem_addr),
    .start(start),
    .rw(rw),
    .reg_read(reg_read),
    .slave_addr(slave_addr),
    .register_addr(register_addr),
    .data_in(master_data_in),
    .data_out(master_data_out),
    .SCL(SCL),
    .SDA(SDA),
    .busy(busy),
    .done(done),
    .ack_error(ack_error)
    );

    I2C_slave #(
        .BYTE_COUNT (4)
    ) Slave_1 (
        .clk(clk),
        .areset_n(areset_n),
        .wr_en(slave_wr_en),
        .rd_en(slave_rd_en),
        .mem_addr(slave_mem_addr),
        .SCL(SCL),
        .SDA(SDA),
        .data_in(slave_data_in),
        .data_out(slave_data_out)
    );

    initial begin
        $dumpfile("waves/dump.vcd");
        $dumpvars(0,tb_I2C_master);
    end

    initial begin
        clk = 0;
        areset_n = 0;
        master_wr_en = 0;
        master_rd_en = 0;
        master_mem_addr = 0;
        start = 0;
        rw = 0;
        reg_read = 0;
        slave_addr = 0;
        register_addr = 8'b10010001;
        master_data_in = 0;

        slave_wr_en = 0;
        slave_rd_en = 0;
        slave_mem_addr = 0;
        slave_data_in = 0;
        
        
        forever #0.025 clk = ~clk;
    end

    task master_write;
        input [7:0] data;
        input [1:0] addr;
        begin
            @(negedge clk);
            master_wr_en = 1;
            master_data_in = data;
            master_mem_addr = addr;
            @(posedge clk);
            #1 master_wr_en = 0;
        end 
    endtask

    task master_read;
        input [1:0] addr;
        begin
            @(negedge clk);
            master_rd_en = 1;
            master_mem_addr = addr;
            @(posedge clk);
            #1;
            $display("Master Memory| addr = %b | data_out = %b",addr,master_data_out );
            master_rd_en = 0;
        end
    endtask

    task slave_write;
        input [7:0] data;
        input [1:0] addr;
        begin
            @(negedge clk);
            slave_wr_en = 1;
            slave_data_in = data;
            slave_mem_addr = addr;
            @(posedge clk);
            #1 slave_wr_en = 0;
        end 
    endtask

    task slave_read;
        input [1:0] addr;
        begin
            @(negedge clk);
            slave_rd_en = 1;
            slave_mem_addr = addr;
            @(posedge clk);
            #1;
            $display("Slave Memory| addr = %b | data_out = %b",addr,slave_data_out );
            slave_rd_en = 0;
        end
    endtask



    initial begin
        #1 areset_n = 1;
        $display("-------------------------------------------------");
        $display("-----------Master_1 writing to Slave_1----------");
        $display("-------------------------------------------------");

        $display("--------Slave_1 Memory Before Transmission-------");
        slave_read(2'b00);
        slave_read(2'b01);
        slave_read(2'b10);
        slave_read(2'b11);
        $display("-----------------------------------------------");

        master_write(8'b11110000, 2'b00);
        master_write(8'b00001111, 2'b01);
        master_write(8'b10101010, 2'b10);
        master_write(8'b10000001, 2'b11);
        
        #1;
        @(negedge clk);
        start = 1;
        rw = 0;
        reg_read = 0;
        slave_addr = 7'b1001011;
        register_addr = 0;

        #2; start = 0;

        #25;
        $display("----------Slave_1 Memory After Transmission--------");
        slave_read(2'b00);
        slave_read(2'b01);
        slave_read(2'b10);
        slave_read(2'b11);
        $display("-----------------------------------------------");


        $display("-------------------------------------------------");
        $display("-----------Master_1 reading from Slave_1----------");
        $display("-------------------------------------------------");

        $display("--------Master_1 Memory Before Transmission-------");
        master_read(2'b00);
        master_read(2'b01);
        master_read(2'b10);
        master_read(2'b11);
        $display("-----------------------------------------------");

        slave_write(8'b11001100, 2'b00);
        slave_write(8'b00110011, 2'b01);
        slave_write(8'b10010001, 2'b10);
        slave_write(8'b11101110, 2'b11);
        
        #1;
        @(negedge clk);
        start = 1;
        rw = 1;
        reg_read = 0;
        slave_addr = 7'b1001011;
        register_addr = 0;

        #2; start = 0;

        #25;

        $display("----------Master_1 Memory After Transmission--------");
        master_read(2'b00);
        master_read(2'b01);
        master_read(2'b10);
        master_read(2'b11);
        $display("-----------------------------------------------");

        




        #200;
        $finish;
    end

endmodule