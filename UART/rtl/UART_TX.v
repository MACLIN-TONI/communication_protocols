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
    
    parameter integer BIT_PERIOD = CLK_FREQ / BAUD_RATE;

    reg [$clog2(BIT_PERIOD)-1:0] bcount;
    reg [3:0] dcount; 

    parameter IDLE = 3'b000;
    parameter START = 3'b001;
    parameter DATA = 3'b010;
    parameter PARITY = 3'b011;
    parameter STOP = 3'b100;

    reg [2:0] state , next;
    reg [7:0] t_data;
    
    
    
    always @(posedge clk, negedge areset_n) begin
        if(!areset_n) begin
            state <= IDLE;
            bcount <= 0;
            dcount <= 0;
        end

        else if (state == IDLE && t_ready == 1) begin
            state <= START;
            t_data = data_in;
            bcount <= 0;
        end

        else if(bcount == BIT_PERIOD-1) begin
            bcount <= 0;

            if(dcount>=1) begin
                t_data <= {t_data[0],t_data[7:1]};
            end
            else begin
                t_data <= t_data;
            end

            if(next == DATA) begin
                dcount <= dcount + 1;
            end
            else if (next != DATA) begin
                dcount <= 0;
            end
            else begin
                dcount <= dcount;
            end

            state <= next;
        end
        else begin
            bcount <= bcount + 1;
        end
    end


    always @(*) begin
        case (state) 
            IDLE: begin
                tx = 1;
                t_busy = 0;
            end
            START: begin
                tx = 0;
                t_busy = 1;
                next = DATA;
            end
            DATA: begin
                tx = t_data[0];
                if(dcount == 8) begin
                    next = PARITY;
                end
            end
            PARITY: begin
                tx = ^t_data;
                next = STOP;
            end
            STOP: begin
                tx = 1;
                if(t_ready) begin
                    next = START;
                    t_data = data_in;
                end
                else begin
                    next = IDLE;
                end
            end
        endcase
    end 

endmodule