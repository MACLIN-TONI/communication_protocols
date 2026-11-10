`timescale 1ns/1ps
module tb_I2C;

    tri1 SDA;
    tri1 SCL;
    reg clk;
    reg areset_n = 0;
    reg start;
    reg [6:0] slave_addr;
    reg rw;


    reg master_sda_low;
    reg slave_sda_low;

    reg master_scl_low;
    reg slave_scl_low;

    assign SDA = (master_sda_low) ? 1'b0: 1'bz;
    assign SDA = (slave_sda_low) ? 1'b0: 1'bz;

    assign SCL = (master_scl_low) ? 1'b0: 1'bz;
    assign SCL = (slave_scl_low) ? 1'b0: 1'bz;

    initial begin
        $dumpfile("waves/dump.vcd");
        $dumpvars(0,tb_I2C);
    end

    initial begin
        clk = 0;
        start = 0;
        slave_addr = 0;
        rw = 0;
        master_sda_low = 0;
        master_scl_low =0;
        slave_sda_low = 0;
        slave_scl_low = 0;
        forever #5 clk = ~clk;
    end

    parameter IDLE = 0;
    parameter START = 1;
    parameter SLAVE_ADDR = 2;
    parameter RW = 3;
    parameter ACK_WAIT = 4;


    reg [2:0] state;
    reg [2:0] count;
    reg [2:0] dcount;
    reg prev;

    initial begin
        state = IDLE;
    end
    always @(posedge clk, negedge areset_n) begin
        if(!areset_n) begin
            prev <= 0;
        end
        else begin
            prev <= SCL;
        end
    end

    



    always @(posedge clk, negedge areset_n) begin
        if(!areset_n) begin
            state <= IDLE;
            master_scl_low <= 0;
            master_sda_low <= 0;
            count <= 0;
            dcount <= 0;
        end
        else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        master_sda_low <= 1;
                        state <= START;
                        count <= 0;
                        dcount <= 0;
                    end
                    else begin
                        master_sda_low <= 0;
                        master_scl_low <= 0;
                        state <= IDLE;
                        count <= 0;
                        dcount <= 0;
                    end
                end

                START: begin
                    state <= SLAVE_ADDR;
                    master_scl_low <= 1;
                    count <= 0;
                    dcount <= 0;
                end

                SLAVE_ADDR: begin
                    if(count == 2) begin
                        count <= 0;
                        master_scl_low <= ~master_scl_low;
                    end
                    else begin
                        count <= count + 1;
                    end

                    if(dcount == 7 && (~SCL && prev)) begin
                        state <=RW;
                        dcount <= 0;
                        count <= 0;
                        master_sda_low <= (rw)? 1'b0 : 1'b1;
                    end

                    else if((~SCL && prev)) begin
                        master_sda_low <= (slave_addr[6])? 1'b0 : 1'b1;
                        slave_addr <= {slave_addr[5:0],slave_addr[6]}; 
                        dcount <= dcount + 1;
                    end
                    else begin
                        state <= SLAVE_ADDR;
                    end
                end

                RW: begin
                    if(count == 2) begin
                        count <= 0;
                        master_scl_low <= ~master_scl_low;
                    end
                    else begin
                        count <= count + 1;
                    end

                end

                ACK_WAIT: begin
                    
                end

            endcase
        end
    end

    initial begin
        areset_n= 0;
    end

    initial begin
        #1;
        areset_n = 1;
        #16;
        @(negedge clk);
        rw = 0;
        slave_addr = 7'b1101001;
        @(negedge clk);
        start = 1;
        

        #500;
        $finish;
    end
    initial begin
        #125;
        // master_sda_low = 0;
        
    end
    

endmodule