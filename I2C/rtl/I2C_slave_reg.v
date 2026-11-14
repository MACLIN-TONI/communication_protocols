module I2C_slave_reg #(
    parameter BYTE_COUNT = 4
)(
    input clk, 
    input areset_n,
    inout SCL,
    inout SDA,
    input [7:0] tx_data [0:BYTE_COUNT-1],
    output reg [7:0] rx_data [0:BYTE_COUNT-1]
);
    reg scl_low;
    reg sda_low;
    reg [6:0] s_addr;
    reg [7:0] rdata;
    reg [7:0] tdata;

    reg [7:0] reg_addr;

    reg [2:0] tx_count;
    reg [2:0] rx_count;

    assign SCL = (scl_low) ? 1'b0 : 1'bz;
    assign SDA = (sda_low) ? 1'b0 : 1'bz;

    parameter IDLE = 0;
    parameter SLAVE_ADDR_READ = 1;
    parameter RW_READ = 2;
    parameter SADDR_ACK = 3;
    parameter REG_RX = 4;
    parameter SREG_ACK = 5;
    parameter RSTART = 6;
    parameter DATA_TX = 7;
    parameter MDATA_ACK =8;
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
            rx_data[0] = 0;
            rx_data[1] = 0;
            rx_data[2] = 0;
            rx_data[3] = 0;
            tdata <= 0;
            rdata <= 0;
            tx_count <= 0;
            rx_count <= 0;
            reg_addr <= 0;
        end
        else begin
            case(state) 
                IDLE: begin
                    if(!SDA && prev_sda && SCL) begin
                        state <= SLAVE_ADDR_READ;
                        tx_count <= 0;
                        tdata <= tx_data[tx_count];
                    end
                    else begin
                        state <= IDLE;
                        reg_addr <= 0;
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
                                    tdata <= {tdata[6:0],tdata[7]};
                                    sda_low <= (tdata[7]) ? 1'b0: 1'b1;
                                    bcount <= bcount + 1;
                                end
                                else begin
                                    state <= REG_RX;
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
                
                REG_RX: begin
                    if(bcount == 8 && !SCL && prev_scl) begin
                        bcount <= 0;
                        state <= SREG_ACK;
                        scl_low <= 1;
                    end
                    else if(SCL && !prev_scl) begin
                        reg_addr <= {reg_addr[6:0],reg_addr[7]};
                        reg_addr[0] <= SDA;
                        bcount <= bcount + 1; 
                    end
                    else begin
                        state <= REG_RX;
                    end
                end

                SREG_ACK: begin
                    if(reg_addr == 8'b10010001) begin
                        sda_low <= 1;
                        check <= 1;
                        if(check == 1) begin
                            scl_low <= 0;
                            if(!SCL && prev_scl) begin
                                sda_low <= 0;
                                state <= RSTART;
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

                RSTART: begin
                    if(!SCL && prev_scl) begin
                        state <= SLAVE_ADDR_READ;
                    end
                    else begin
                        state <= RSTART;
                    end
                end

                DATA_TX: begin
                    if((bcount == 8) && (~SCL && prev_scl)) begin
                        state <= MDATA_ACK;
                        sda_low <= 0;
                        bcount <= 0;
                    end
                    else if (~SCL && prev_scl) begin
                        sda_low <= (tdata[7]) ? 1'b0: 1'b1;
                        tdata <= {tdata[6:0],tdata[7]};
                        bcount <= bcount + 1;
                    end
                    else begin
                        state <= DATA_TX;
                    end
                end

                MDATA_ACK: begin
                    if(SCL && !prev_scl) begin
                        if(SDA) begin
                            check <= 0;
                        end
                        else begin
                            check <= 1;
                            tx_count <= tx_count + 1;
                            tdata <= tx_data[tx_count + 1];
                        end
                    end
                    else if (!SCL && prev_scl) begin
                        if(check) begin
                            state <= DATA_TX;
                            sda_low <= (tdata[7]) ? 1'b0: 1'b1;
                            tdata <= {tdata[6:0],tdata[7]};
                            bcount <= bcount + 1;
                        end
                        else begin
                            state <= IDLE;
                            tx_count <= 0;
                        end
                    end
                end

            endcase
        end
    end

endmodule