module I2C_slave (
    input clk, 
    input areset_n,
    inout SCL,
    inout SDA,
    output reg [7:0] rx_data
);
    reg scl_low;
    reg sda_low;

    reg [6:0] s_addr;
    reg [7:0] data;

    assign SCL = (scl_low) ? 1'b0 : 1'bz;
    assign SDA = (sda_low) ? 1'b0 : 1'bz;

    parameter IDLE = 0;
    parameter SLAVE_ADDR_READ = 1;
    parameter RW_READ = 2;
    parameter SADDR_ACK = 3;
    parameter DATA_RX = 4;
    parameter SDATA_ACK = 5;
    parameter DATA_TX = 6;
    parameter MDATA_ACK =7;
    parameter MDATA_NACK =8;
    parameter STOP = 9;

    reg rw;
    reg check;
    reg [3:0] state;
    reg [3:0] count;
    reg [4:0] bcount;
    reg prev_scl;
    reg prev_sda;

    always @(posedge clk, negedge areset_n) begin
        if(!areset_n) begin
            prev_scl <= 0;
            prev_sda <= 0;
        end
        else begin
            prev_scl <= SCL;
            prev_sda <= SDA;
        end
    end

    always @(posedge clk, negedge areset_n) begin
        if(!areset_n) begin
            state <= IDLE;
            count <= 0;
            bcount <= 0;
            scl_low <= 0;
            sda_low <= 0;
            s_addr <= 0;
            check <= 0;
            rw <= 0;
            rx_data <= 0;
            data <= 0;
        end
        else begin
            case(state) 
                IDLE: begin
                    if(!SDA && prev_sda && SCL) begin
                        state <= SLAVE_ADDR_READ;
                    end
                    else begin
                        state <= IDLE;
                    end
                end

                SLAVE_ADDR_READ: begin
                    if(bcount == 7 && !SCL && prev_scl) begin
                        bcount <= 0;
                        state <= RW_READ;
                    end
                    else if(SCL && !prev_scl) begin
                        s_addr <= {s_addr[5:0],s_addr[6]};
                        s_addr[0] <= SDA;
                        bcount <= bcount + 1; 
                    end
                    else begin
                        state <= SLAVE_ADDR_READ;
                    end

                end

                RW_READ: begin
                    
                    if(SCL && !prev_scl) begin
                        rw <= SDA;
                        check <= 1;
                    end
                    else if (!SCL && prev_scl && check) begin
                        state <= SADDR_ACK;
                        scl_low <= 1;
                        check <= 0;
                    end
                    else begin
                        state <= RW_READ;
                    end
                end
                SADDR_ACK: begin
                    if(s_addr == 7'b1001011) begin
                        sda_low <= 1;
                        check <= 1;
                        if(check == 1) begin
                            scl_low <= 0;
                            if(!SCL && prev_scl) begin
                                sda_low <= 0;
                                if(rw) begin
                                    state <= DATA_TX;
                                end
                                else begin
                                    state <= DATA_RX;
                                end
                                check <= 0;
                            end
                            else begin
                                sda_low <= 1;
                                check <= 1;
                            end
                        end
                        else begin
                            scl_low <= 1;
                        end
                    end
                    else begin
                        sda_low <= 0;
                        check <= 1;
                        if(check == 1) begin
                            scl_low <= 0;
                            if(!SCL && prev_scl) begin
                                sda_low <= 0;
                                state <= IDLE;
                                check <= 0;
                            end
                            else begin
                                sda_low <= 0;
                                check <= 1;
                            end
                        end
                        else begin
                            scl_low <= 1;
                        end
                    end
                end
                DATA_RX: begin
                    if(bcount == 8 && !SCL && prev_scl) begin
                        bcount <= 0;
                        state <= SDATA_ACK;
                        scl_low <= 1;
                    end
                    else if(SCL && !prev_scl) begin
                        data <= {data[6:0],data[7]};
                        data[0] <= SDA;
                        bcount <= bcount + 1; 
                    end
                    else begin
                        state <= DATA_RX;
                    end

                end
                SDATA_ACK: begin
                    sda_low <= 1;
                    check <= 1;
                    if(check == 1) begin
                        rx_data <= data;
                        scl_low <= 0;
                        if(!SCL && prev_scl) begin
                            sda_low <= 0;
                            state <= IDLE;
                            check <= 0;
                        end
                        else begin
                            sda_low <= 1;
                            check <= 1;
                        end
                    end
                    else begin
                        scl_low <= 1;
                    end

                end

            endcase
        end
    end

endmodule