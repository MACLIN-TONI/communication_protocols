module I2C_master #(
    parameter BYTE_COUNT = 4
) (
    input clk,
    input areset_n,
    input wr_en,
    input rd_en,
    input [1:0] mem_addr,
    input start,
    input rw,
    input reg_read,
    input  [6:0] slave_addr,
    input  [7:0] register_addr,
    input  [7:0] data_in,
    output reg [7:0] data_out,
    inout SCL,
    inout SDA,
    output reg busy,
    output reg done, 
    output reg ack_error
);
    reg r_w;
    reg scl_low;
    reg sda_low;
    reg reg_check;

    reg [6:0] s_addr;
    reg [7:0] reg_addr;
    reg [7:0] tdata;
    reg [7:0] rdata;

    reg [2:0] tx_count;
    reg [2:0] rx_count;


    assign SCL = (scl_low) ? 1'b0 : 1'bz;
    assign SDA = (sda_low) ? 1'b0 : 1'bz;

    localparam IDLE = 0; 
    localparam START = 1;
    localparam SLAVE_ADDR = 2;
    localparam RW = 3;
    localparam SADDR_ACK = 4;
    localparam DATA_TX = 5;
    localparam SDATA_ACK = 6;
    localparam DATA_RX = 7;
    localparam MDATA_ACK = 8;
    localparam MDATA_NACK = 9;
    localparam STOP = 10;
    localparam REG_TX = 11;
    localparam SREG_ACK = 12;
    localparam RSTART = 13;
    localparam WAIT = 14;

    reg check;
    reg [3:0] state;
    reg [3:0] count;
    reg [4:0] bcount;
    reg [3:0] tbuf;
    reg prev_scl;
    reg prev_sda;

    reg [7:0] tx_data [0:BYTE_COUNT-1];
    reg [7:0] rx_data [0:BYTE_COUNT-1];

    always @(posedge clk , negedge areset_n) begin
        if(!areset_n) begin
            data_out <= 0;
        end
        else begin
            if(wr_en) begin
                tx_data[mem_addr] <= data_in;
            end
            else if (rd_en) begin
                data_out <= rx_data[mem_addr];
            end
            else begin
                data_out <= data_out;
            end
        end
    end

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
            tbuf <= 0;
            scl_low <= 0;
            sda_low <= 0;
            s_addr <= 0;
            tdata <= 0;
            rdata <= 0;
            busy <= 0;
            done <= 0;
            ack_error <= 0;
            check <= 0;
            tx_count <= 0;
            rx_count <= 0;
            reg_check <= 0;
            reg_addr <= register_addr;
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
                            tx_count <= 0;
                            tdata <= tx_data[tx_count];
                            
                            
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
                    reg_addr <= register_addr;
                    state <= SLAVE_ADDR;
                    r_w <= (reg_read) ? 1'b0 : rw;
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
                    if (SCL && ~prev_scl) begin
                        if(SDA != s_addr[0]) begin
                            state <= WAIT;
                            bcount <= 0;
                            scl_low <= 0;
                            sda_low <= 0;
                        end
                        else begin
                            state <= SLAVE_ADDR;
                        end
                    end
                    else if((bcount == 7) && (~SCL && prev_scl)) begin
                        state <= RW;
                        count <= 1;
                        bcount <= 0;
                        sda_low <= (r_w) ? 1'b0 : 1'b1;
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

                    if (SCL && ~prev_scl) begin
                        if(SDA != r_w) begin
                            state <= WAIT;
                            bcount <= 0;
                            scl_low <= 0;
                            sda_low <= 0;
                        end
                        else begin
                            state <= RW;
                        end
                    end

                    else if(~SCL && prev_scl) begin
                        state <= SADDR_ACK;
                        sda_low <= 1;
                    end
                    else begin
                        state <= RW;
                    end
                end
                
                SADDR_ACK: begin
                    
                    sda_low <= 0;
                    if(count == 5) begin
                        scl_low <= ~scl_low;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end


                    if(SCL && !prev_scl) begin
                        if(SDA) begin
                            check <= 0;
                            ack_error <= 1;
                        end
                        else begin
                            check <= 1;
                            ack_error <= 0;
                        end
                    end
                    else if (!SCL && prev_scl) begin
                        if(check) begin
                            check <= 0;
                            if(reg_read && !r_w) begin
                                state <= REG_TX;
                                sda_low <= (reg_addr[7]) ? 1'b0: 1'b1;
                                reg_addr <= {reg_addr[6:0],reg_addr[7]};
                                bcount <= bcount + 1;
                                count <= 1;
                                
                            end
                            else if (r_w) begin
                                state <= DATA_RX;
                                count <= 1;
                            end
                            else begin
                                state <= DATA_TX;
                                sda_low <= (tdata[7]) ? 1'b0: 1'b1;
                                tdata <= {tdata[6:0],tdata[7]};
                                bcount <= bcount + 1;
                                count <= 1;
                            end
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

                REG_TX: begin
                    if(count == 5) begin
                        scl_low <= ~scl_low;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end

                    if (SCL && ~prev_scl) begin
                        if(SDA != reg_addr[0]) begin
                            state <= WAIT;
                            bcount <= 0;
                            scl_low <= 0;
                            sda_low <= 0;
                        end
                        else begin
                            state <= REG_TX;
                        end
                    end

                    else if((bcount == 8) && (~SCL && prev_scl)) begin
                        state <= SREG_ACK;
                        sda_low <= 1;
                        count <= 1;
                        bcount <= 0;
                    end
                    else if (~SCL && prev_scl) begin
                        sda_low <= (reg_addr[7]) ? 1'b0: 1'b1;
                        reg_addr <= {reg_addr[6:0],reg_addr[7]};
                        bcount <= bcount + 1;
                    end
                    else begin
                        state <= REG_TX;
                    end
                end

                SREG_ACK: begin
                    sda_low <= 0;
                    
                    if(count == 5) begin
                        scl_low <= ~scl_low;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end

                    if(SCL && !prev_scl) begin
                        if(SDA) begin
                            check <= 0;
                            ack_error <= 1;
                        end
                        else begin
                            check <= 1;
                            ack_error <= 0;
                        end
                    end
                    else if (!SCL && prev_scl) begin
                        check <= 0;
                        if(check) begin
                            state <= RSTART;
                            sda_low <= 0;
                            count <= 1;
                        end
                        else begin
                            state <= STOP;
                        end
                    end
                    else begin
                        state <= SREG_ACK;
                    end
                end

                RSTART: begin
                    //scl_low <= 0;
                    if(count == 5) begin
                        scl_low <= ~scl_low;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end

                    if(SCL && !prev_scl) begin
                        sda_low <= 1;
                        s_addr <= slave_addr;
                        r_w <= 1;
                    end 

                    else if (!SCL && prev_scl) begin
                        state <= SLAVE_ADDR;
                        sda_low <= (s_addr[6]) ? 1'b0: 1'b1;
                        s_addr <= {s_addr[5:0],s_addr[6]};
                        bcount <= bcount + 1;
                        count <= 1;
                    end

                    else begin
                        state <= RSTART;
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
                    
                    if (SCL && ~prev_scl) begin
                        if(SDA != tdata[0]) begin
                            state <= WAIT;
                            bcount <= 0;
                            scl_low <= 0;
                            sda_low <= 0;
                        end
                        else begin
                            state <= DATA_TX;
                        end
                    end

                    else if((bcount == 8) && (~SCL && prev_scl)) begin
                        state <= SDATA_ACK;
                        sda_low <= 1;
                        count <= 1;
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

                SDATA_ACK: begin
                    sda_low <= 0;
                    if(count == 5) begin
                        scl_low <= ~scl_low;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end

                    if(SCL && !prev_scl) begin
                        if(SDA) begin
                            check <= 0;
                            ack_error <= 1;
                        end
                        else begin
                            check <= 1;
                            tx_count <= tx_count + 1;
                            tdata <= tx_data[tx_count + 1];
                            ack_error <= 0;
                        end
                    end
                    else if (!SCL && prev_scl) begin
                        if(check) begin
                            if(tx_count == BYTE_COUNT) begin
                                state <= STOP;
                                sda_low <= 1;
                                tdata <= 0;
                                done <= 1;
                                tx_count <= 0;
                            end
                            else begin
                                state <= DATA_TX;
                                sda_low <= (tdata[7]) ? 1'b0 : 1'b1;
                                tdata <= {tdata[6:0],tdata[7]};
                                bcount <= bcount + 1;
                                count <= 1;
                            end
                        end
                        else begin
                            state <= STOP;
                        end
                    end
                    else begin
                        state <= SDATA_ACK;
                    end
                end

                DATA_RX: begin
                    if(count == 5) begin
                        scl_low <= ~scl_low;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end

                    if(bcount == 8 && !SCL && prev_scl) begin
                        bcount <= 0;
                        state <= MDATA_ACK;
                        sda_low <= 1;
                        count <= 1;
                        scl_low <=1;
                    end
                    else if (SCL && !prev_scl) begin
                        rdata <= {rdata[6:0],rdata[7]};
                        rdata[0] <= SDA;
                        bcount <= bcount + 1;
                    end
                    else begin
                        state <= DATA_RX;
                    end
                

                end

                MDATA_ACK: begin
                    if(count == 5) begin
                        scl_low <= ~scl_low;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end


                    if(rx_count == BYTE_COUNT-1) begin
                        sda_low <= 0;
                    end
                    else begin
                        sda_low <= 1;
                    end

                    if(rx_count == BYTE_COUNT-1 && !SCL && prev_scl) begin
                        rx_count <= 0;
                        state <= STOP;
                        sda_low <= 1;
                        done <= 1;
                        count <= 0;
                    end
                    else if (SCL && !prev_scl) begin
                        rx_data[rx_count] <= rdata;
                    end
                    else if (!SCL && prev_scl) begin
                        state <= DATA_RX;
                        sda_low <= 0;
                        rx_count <= rx_count + 1;
                        count <= 1;
                    end

                    else begin
                        state <= MDATA_ACK;
                    end

                end

                WAIT: begin
                    if(SCL && !prev_sda && SDA) begin
                        state <= START;
                        sda_low <= 1;
                        busy <= 1;
                        s_addr <= slave_addr;
                        tx_count <= 0;
                        tdata <= tx_data[tx_count];
                    end
                    else begin
                        state <= WAIT;
                    end
                end

                STOP: begin
                    scl_low <= 0;
                    if(!scl_low) begin
                        sda_low <= 0;
                        state <= IDLE;
                        tx_count <= 0;
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