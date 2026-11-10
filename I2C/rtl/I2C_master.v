module I2C_master (
    input clk,
    input areset_n,
    input start,
    input rw,
    input  [6:0] slave_addr,
    input  [7:0] tx_data,
    inout SCL,
    inout SDA,
    output reg busy,
    output reg done, 
    output reg ack_error
);

    reg scl_low;
    reg sda_low;

    reg [6:0] s_addr;
    reg [7:0] data;


    assign SCL = (scl_low) ? 1'b0 : 1'bz;
    assign SDA = (sda_low) ? 1'b0 : 1'bz;

    parameter IDLE = 0;
    parameter START = 1;
    parameter SLAVE_ADDR = 2;
    parameter RW =3;
    parameter SADDR_ACK = 4;
    parameter DATA_TX = 5;
    parameter SDATA_ACK = 6;
    parameter DATA_RX = 7;
    parameter MDATA_ACK =8;
    parameter MDATA_NACK =9;
    parameter STOP = 10;

    reg ack_check;
    reg [3:0] state;
    reg [3:0] count;
    reg [4:0] bcount;
    reg [3:0] tbuf;
    reg prev_scl;

    always @(posedge clk, negedge areset_n) begin
        if(!areset_n) begin
            prev_scl <= 0;
        end
        else begin
            prev_scl <= SCL;
        end
    end

    always @(posedge clk, negedge areset_n) begin
        if(!areset_n) begin
            state <= IDLE;
            count <= 0;
            bcount <= 0;
            tbuf <= 0;
            scl_low <= 0;
            sda_low <= 0;
            s_addr <= 0;
            data <= 0;
            busy <= 0;
            done <= 0;
            ack_error <= 0;
            ack_check <= 0;
        end
        else begin
            case(state) 
                IDLE: begin
                    if(SDA && SCL && start) begin
                        if(tbuf == 5) begin
                            state <= START;
                            sda_low <= 1;
                            tbuf <= 0;
                            busy <= 1;
                            s_addr <= slave_addr;
                            data <= tx_data;
                            
                        end
                        else begin
                            tbuf <= tbuf + 1;
                            
                        end
                    end
                    else begin
                        state <= IDLE;
                        tbuf <= 0;
                        sda_low <= 0;
                        scl_low <= 0;
                        busy <= 0;
                    end
                end

                START: begin
                    scl_low <= 1;
                    state <= SLAVE_ADDR;
                    count <= 0;
                    busy <= 1;
                end

                SLAVE_ADDR : begin
                    if(count == 5) begin
                        scl_low <= ~scl_low;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end

                    if((bcount == 7) && (~SCL && prev_scl)) begin
                        state <= RW;
                        count <= 0;
                        bcount <= 0;
                        sda_low <= (rw) ? 1'b0 : 1'b1;
                    end
                    else if (~SCL && prev_scl) begin
                        sda_low <= (s_addr[6]) ? 1'b0: 1'b1;
                        s_addr <= {s_addr[5:0],s_addr[6]};
                        bcount <= bcount + 1;
                    end
                    else begin
                        state <= SLAVE_ADDR;
                    end
                end
                RW: begin
                    if(count == 5) begin
                        scl_low <= ~scl_low;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end

                    if(~SCL && prev_scl) begin
                        state <= SADDR_ACK;
                        sda_low <= 0;
                    end
                    else begin
                        state <= RW;
                    end
                end
                
                SADDR_ACK: begin
                    //scl_low <= 0;
                    if(count == 5) begin
                        scl_low <= ~scl_low;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end

                    if(SCL && !prev_scl) begin
                        if(SDA) begin
                            ack_check <= 0;
                            ack_error <= 1;
                        end
                        else begin
                            ack_check <= 1;
                            ack_error <= 0;
                        end
                    end
                    else if (!SCL && prev_scl) begin
                        if(ack_check) begin
                            state <= DATA_TX;

    
                            sda_low <= (data[7]) ? 1'b0: 1'b1;
                            data <= {data[6:0],data[7]};
                            bcount <= bcount + 1;
            
                            count <= 1;
                        end
                        else begin
                            state <= STOP;
                            count <= 0;
                        end
                    end
                    else begin
                        state <= SADDR_ACK;
                    end
                    
                end

                DATA_TX: begin
                    if(count == 5) begin
                        scl_low <= ~scl_low;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end

                    if((bcount == 8) && (~SCL && prev_scl)) begin
                        state <= SDATA_ACK;
                        sda_low <= 0;
                        count <= 1;
                        bcount <= 0;
                    end
                    else if (~SCL && prev_scl) begin
                        sda_low <= (data[7]) ? 1'b0: 1'b1;
                        data <= {data[6:0],data[7]};
                        bcount <= bcount + 1;
                    end
                    else begin
                        state <= DATA_TX;
                    end
                end

                SDATA_ACK: begin
                    //scl_low <= 0;
                    if(count == 5) begin
                        scl_low <= ~scl_low;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end

                    if(SCL && !prev_scl) begin
                        if(SDA) begin
                            ack_check <= 0;
                            ack_error <= 1;
                        end
                        else begin
                            ack_check <= 1;
                            ack_error <= 0;
                        end
                    end
                    else if (!SCL && prev_scl) begin
                        if(ack_check) begin
                            state <= STOP;
                            sda_low <= 1;
                            done <= 1;
                        end
                        else begin
                            state <= STOP;
                        end
                    end
                    else begin
                        state <= SDATA_ACK;
                    end
                end

                STOP: begin
                    scl_low <= 0;
                    if(!scl_low) begin
                        sda_low <= 0;
                        state <= IDLE;
                        done <= 0;
                    end
                    else begin
                        state <= STOP;
                    end
                end



            endcase
        end
    end


endmodule