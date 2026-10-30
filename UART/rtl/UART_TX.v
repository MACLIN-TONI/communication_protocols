module UART_TX #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 9600
) (
    input clk,
    input areset_n,
    input t_ready,
    input [7:0] data_in,
    output reg t_busy,
    output reg tx
);

    localparam integer BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    localparam integer COUNT_BITS = (BIT_PERIOD <=1 ) ? 1 : $clog2(BIT_PERIOD);
    
    reg [COUNT_BITS-1:0] bcount;
    reg [3:0] dcount; 

    localparam IDLE = 3'b000;
    localparam START = 3'b001;
    localparam DATA = 3'b010;
    localparam PARITY = 3'b011;
    localparam STOP = 3'b100;

    reg [2:0] state;
    reg [7:0] t_data;

    always @(posedge clk, negedge areset_n) begin
        if(!areset_n) begin
            state <= IDLE;
            bcount <= 1'b0;
            dcount <= 1'b0;
            t_busy <= 1'b0;
            t_data <= 8'b0;
            tx <= 1'b1;
        end
        else begin
            case (state) 
                IDLE: begin
                    if(t_ready) begin
                        state <= START;
                        t_data <= data_in;
                        bcount <= 0;
                        
                    end
                    else begin
                        state <= IDLE;
                        t_data <= t_data;
                        bcount <= 0;
                        
                    end
                end

                START: begin
                    if(bcount == BIT_PERIOD-1) begin
                        state <= DATA;  
                        bcount <= 0;
                        dcount <= 1;
                    end
                    else begin
                        state <= START;
                        bcount <= bcount + 1;
                        dcount <= 0;
                    end
                end

                DATA: begin
                    
                    if(bcount == BIT_PERIOD-1) begin
                        if(dcount == 8) begin
                            t_data <= {t_data[0],t_data[7:1]};
                            state <= PARITY;
                            bcount <= 0;
                            dcount <= 0; 
                        end
                        else if(dcount >=1) begin
                            t_data <= {t_data[0],t_data[7:1]};
                            dcount <= dcount + 1;
                            bcount <= 0;
                        end
                        else begin
                            t_data <= t_data;
                            dcount <= dcount;
                            bcount <= 0;
                        end
                    end
                    else begin
                        bcount <= bcount + 1;
                    end
                end

                PARITY: begin
                    if(bcount == BIT_PERIOD-1) begin
                        state <= STOP;
                        bcount <= 0;
                    end
                    else begin
                        bcount <= bcount + 1;
                    end
                end

                STOP: begin
                    if(bcount == BIT_PERIOD-1) begin
                        if(t_ready) begin
                            state <= START;
                            t_data <= data_in;
                            bcount <= 0;
                        end
                        else begin
                            state <= IDLE;
                            bcount <= 0;
                        end
                    end
                    else begin
                        bcount <= bcount + 1;
                    end
                end
            endcase
        end 
    end

    always @(*) begin
        case (state) 
            IDLE: begin
                tx = 1'b1;
                t_busy = 1'b0;
            end
            START: begin
                tx = 1'b0;
                t_busy = 1'b1;
            end
            DATA: begin
                tx = t_data[0];
                t_busy = 1'b1;
            end
            PARITY: begin
                tx = ^t_data;
                t_busy = 1'b1;
            end
            STOP: begin
                tx = 1'b1;
                t_busy = 1'b1;
            end
        endcase
    end


endmodule