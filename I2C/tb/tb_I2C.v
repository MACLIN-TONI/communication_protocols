`timescale 1ns/1ps
module tb_I2C;

    reg clk;
    reg areset_n;

    reg master1_wr_en;
    reg master1_rd_en;
    reg [1:0] master1_mem_addr;
    reg start1;
    reg rw1;
    reg reg_read1;
    reg [6:0] slave_addr1;
    reg [7:0] register_addr1;
    reg [7:0] master1_data_in;
    wire [7:0] master1_data_out;
    wire busy1;
    wire done1;
    wire ack_error1;

    reg master2_wr_en;
    reg master2_rd_en;
    reg [1:0] master2_mem_addr;
    reg start2;
    reg rw2;
    reg reg_read2;
    reg [6:0] slave_addr2;
    reg [7:0] register_addr2;
    reg [7:0] master2_data_in;
    wire [7:0] master2_data_out;
    wire busy2;
    wire done2;
    wire ack_error2;

    reg slave1_wr_en;
    reg slave1_rd_en;
    reg [1:0] slave1_mem_addr;
    reg [7:0] slave1_data_in;
    wire [7:0] slave1_data_out;

    reg slave2_wr_en;
    reg slave2_rd_en;
    reg [1:0] slave2_mem_addr;
    reg [7:0] slave2_data_in;
    wire [7:0] slave2_data_out;


    wire SCL;
    wire SDA;

    pullup(SCL);
    pullup(SDA);

    I2C_master #(
        .BYTE_COUNT(4)
    ) Master_1 (
    .clk(clk),
    .areset_n(areset_n),
    .wr_en(master1_wr_en),
    .rd_en(master1_rd_en),
    .mem_addr(master1_mem_addr),
    .start(start1),
    .rw(rw1),
    .reg_read(reg_read1),
    .slave_addr(slave_addr1),
    .register_addr(register_addr1),
    .data_in(master1_data_in),
    .data_out(master1_data_out),
    .SCL(SCL),
    .SDA(SDA),
    .busy(busy1),
    .done(done1),
    .ack_error(ack_error1)
    );


    I2C_master #(
        .BYTE_COUNT(4)
    ) Master_2 (
    .clk(clk),
    .areset_n(areset_n),
    .wr_en(master2_wr_en),
    .rd_en(master2_rd_en),
    .mem_addr(master2_mem_addr),
    .start(start2),
    .rw(rw2),
    .reg_read(reg_read2),
    .slave_addr(slave_addr2),
    .register_addr(register_addr2),
    .data_in(master2_data_in),
    .data_out(master2_data_out),
    .SCL(SCL),
    .SDA(SDA),
    .busy(busy2),
    .done(done2),
    .ack_error(ack_error2)
    );


    I2C_slave #(
        .BYTE_COUNT (4)
    ) Slave_1 (
        .clk(clk),
        .areset_n(areset_n),
        .wr_en(slave1_wr_en),
        .rd_en(slave1_rd_en),
        .mem_addr(slave1_mem_addr),
        .SCL(SCL),
        .SDA(SDA),
        .data_in(slave1_data_in),
        .data_out(slave1_data_out)
    );


    I2C_slave_reg #(
        .BYTE_COUNT (4)
    ) Slave_2 (
        .clk(clk),
        .areset_n(areset_n),
        .wr_en(slave2_wr_en),
        .rd_en(slave2_rd_en),
        .mem_addr(slave2_mem_addr),
        .SCL(SCL),
        .SDA(SDA),
        .data_in(slave2_data_in),
        .data_out(slave2_data_out)
    );

    initial begin
        $dumpfile("waves/dump.vcd");
        $dumpvars(0,tb_I2C);
    end

    initial begin
        clk = 0;
        areset_n = 0;

        master1_wr_en = 0;
        master1_rd_en = 0;
        master1_mem_addr = 0;
        start1 = 0;
        rw1 = 0;
        reg_read1 = 0;
        slave_addr1 = 0;
        register_addr1 = 0;
        master1_data_in = 0;

        master2_wr_en = 0;
        master2_rd_en = 0;
        master2_mem_addr = 0;
        start2 = 0;
        rw2 = 0;
        reg_read2 = 0;
        slave_addr2 = 0;
        register_addr2 = 0;
        master2_data_in = 0;

        slave1_wr_en = 0;
        slave1_rd_en = 0;
        slave1_mem_addr = 0;
        slave1_data_in = 0;

        slave2_wr_en = 0;
        slave2_rd_en = 0;
        slave2_mem_addr = 0;
        slave2_data_in = 0;
        
        
        forever #0.025 clk = ~clk;
    end

    task master1_write;
        input [7:0] data;
        input [1:0] addr;
        begin
            @(negedge clk);
            master1_wr_en = 1;
            master1_data_in = data;
            master1_mem_addr = addr;
            @(posedge clk);
            #1 master1_wr_en = 0;
        end 
    endtask

    task master1_read;
        input [1:0] addr;
        begin
            @(negedge clk);
            master1_rd_en = 1;
            master1_mem_addr = addr;
            @(posedge clk);
            #1;
            $display("Master Memory| addr = %b | data_out = %b",addr,master1_data_out );
            master1_rd_en = 0;
        end
    endtask

    task master2_write;
        input [7:0] data;
        input [1:0] addr;
        begin
            @(negedge clk);
            master2_wr_en = 1;
            master2_data_in = data;
            master2_mem_addr = addr;
            @(posedge clk);
            #1 master2_wr_en = 0;
        end 
    endtask

    task master2_read;
        input [1:0] addr;
        begin
            @(negedge clk);
            master2_rd_en = 1;
            master2_mem_addr = addr;
            @(posedge clk);
            #1;
            $display("Master Memory| addr = %b | data_out = %b",addr,master2_data_out );
            master2_rd_en = 0;
        end
    endtask

    task slave1_write;
        input [7:0] data;
        input [1:0] addr;
        begin
            @(negedge clk);
            slave1_wr_en = 1;
            slave1_data_in = data;
            slave1_mem_addr = addr;
            @(posedge clk);
            #1 slave1_wr_en = 0;
        end 
    endtask

    task slave1_read;
        input [1:0] addr;
        begin
            @(negedge clk);
            slave1_rd_en = 1;
            slave1_mem_addr = addr;
            @(posedge clk);
            #1;
            $display("Slave Memory| addr = %b | data_out = %b",addr,slave1_data_out );
            slave1_rd_en = 0;
        end
    endtask


    task slave2_write;
        input [7:0] data;
        input [1:0] addr;
        begin
            @(negedge clk);
            slave2_wr_en = 1;
            slave2_data_in = data;
            slave2_mem_addr = addr;
            @(posedge clk);
            #1 slave2_wr_en = 0;
        end 
    endtask

    task slave2_read;
        input [1:0] addr;
        begin
            @(negedge clk);
            slave2_rd_en = 1;
            slave2_mem_addr = addr;
            @(posedge clk);
            #1;
            $display("Slave Memory| addr = %b | data_out = %b",addr,slave2_data_out );
            slave2_rd_en = 0;
        end
    endtask



    initial begin
        #1 areset_n = 1;
        $display("-------------------------------------------------");
        $display("-----------Master_1 writing to Slave_1----------");
        $display("-------------------------------------------------");
        $display("--------Slave_1 Memory Before Transmission-------");
        slave1_read(2'b00);
        slave1_read(2'b01);
        slave1_read(2'b10);
        slave1_read(2'b11);
        $display("-----------------------------------------------");

        master1_write(8'b11110000, 2'b00);
        master1_write(8'b00001111, 2'b01);
        master1_write(8'b10101010, 2'b10);
        master1_write(8'b10000001, 2'b11);
        
        #1;
        @(negedge clk);
        start1 = 1;
        rw1 = 0;
        reg_read1 = 0;
        slave_addr1 = 7'b1001011;
        register_addr1 = 0;

        #2; start1 = 0;

        #25;
        $display("----------Slave_1 Memory After Transmission--------");
        $display("-----------------------------------------------");
        $display("Slave_1 addr = %b",Slave_1.s_addr);
        $display("-----------------------------------------------");
        slave1_read(2'b00);
        slave1_read(2'b01);
        slave1_read(2'b10);
        slave1_read(2'b11);
        
        $display("-----------------------------------------------");

        $display("-------------------------------------------------");
        $display("-----------Master_1 reading from Slave_1----------");
        $display("-------------------------------------------------");

        $display("--------Master_1 Memory Before Transmission-------");
        master1_read(2'b00);
        master1_read(2'b01);
        master1_read(2'b10);
        master1_read(2'b11);
        $display("-----------------------------------------------");

        slave1_write(8'b11001100, 2'b00);
        slave1_write(8'b00110011, 2'b01);
        slave1_write(8'b10010001, 2'b10);
        slave1_write(8'b11101110, 2'b11);
        
        #1;
        @(negedge clk);
        start1 = 1;
        rw1 = 1;
        reg_read1 = 0;
        slave_addr1 = 7'b1001011;
        register_addr1 = 0;

        #2; start1 = 0;

        #25;

        $display("----------Master_1 Memory After Transmission--------");
        $display("-----------------------------------------------");
        $display("Slave_1 addr = %b",Slave_1.s_addr);
        $display("-----------------------------------------------");
        master1_read(2'b00);
        master1_read(2'b01);
        master1_read(2'b10);
        master1_read(2'b11);
        $display("-----------------------------------------------");

        

        $display("-------------------------------------------------");
        $display("------Master_2 reading from Slave_2 Register-----");
        $display("-------------------------------------------------");


        slave2_write(8'b10000001, 2'b00);
        slave2_write(8'b11111111, 2'b01);
        slave2_write(8'b00000000, 2'b10);
        slave2_write(8'b00100100, 2'b11);
        
        #1;
        @(negedge clk);
        #1;
        start2 = 1;
        rw2 = 0;
        reg_read2 = 1;
        slave_addr2 = 7'b1110011;
        register_addr2 = 8'b10010001;

        #5; start2 = 0;

        #30;

        $display("-------Master_2 Memory After Transmission------");
        $display("-----------------------------------------------");
        $display("Slave_2 addr = %b",Slave_2.s_addr);
        $display("Slave_2 Register addr = %b",Slave_2.reg_addr);
        $display("-----------------------------------------------");
        master2_read(2'b00);
        master2_read(2'b01);
        master2_read(2'b10);
        master2_read(2'b11);
        $display("-----------------------------------------------");
        
        
        #10;
        $display("-------Testing Bus Orbitration------");
        $display("--------------------------------------------");
        $display("-------Master_1 reading from Slave_1------");
        $display("--------------------AND-------------------");
        $display("-------Master_2 reading from Slave_2------");
        $display("--------------------------------------------");
        
        slave1_write(8'b00000001, 2'b00);
        slave1_write(8'b00000011, 2'b01);
        slave1_write(8'b00000111, 2'b10);
        slave1_write(8'b00001111, 2'b11);

        slave2_write(8'b00011111, 2'b00);
        slave2_write(8'b00111111, 2'b01);
        slave2_write(8'b01111111, 2'b10);
        slave2_write(8'b11111111, 2'b11);

        #1;
        @(negedge clk);
        start1 = 1;
        rw1 = 1;
        reg_read1 = 0;
        slave_addr1 = 7'b1001011;
        register_addr1 = 0;

        start2 = 1;
        rw2 = 0;
        reg_read2 = 1;
        slave_addr2 = 7'b1110011;
        register_addr2 = 8'b10010001;

        #5; start1 = 0; start2 = 0;

        #30;


        $display("----------Master_1 Memory After Transmission--------");
        $display("-----------------------------------------------");
        $display("Slave_1 addr = %b",Slave_1.s_addr);
        $display("-----------------------------------------------");
        master1_read(2'b00);
        master1_read(2'b01);
        master1_read(2'b10);
        master1_read(2'b11);
        $display("-----------------------------------------------");

        $display("-------Master_2 Loss Control------");
        $display("-----------------------------------------------");
        $display("Slave_2 addr = %b",Slave_2.s_addr);
        $display("Slave_2 Register addr = %b",Slave_2.reg_addr);
        $display("-----------------------------------------------");
        master2_read(2'b00);
        master2_read(2'b01);
        master2_read(2'b10);
        master2_read(2'b11);
        $display("-----------------------------------------------");

        #20;

        $display("----Master_2 Memory After Regaining Control-----");
        $display("-----------------------------------------------");
        $display("Slave_2 addr = %b",Slave_2.s_addr);
        $display("Slave_2 Register addr = %b",Slave_2.reg_addr);
        $display("-----------------------------------------------");
        master2_read(2'b00);
        master2_read(2'b01);
        master2_read(2'b10);
        master2_read(2'b11);
        $display("-----------------------------------------------");






        #200;
        $finish;
    end

endmodule