module UART_RX #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 9600
) (
    input clk,
    input areset_n,
    input rx,
    output reg [7:0] data_out,
    output reg rx_valid,
    output reg rx_error
);

    parameter integer BIT_PERIOD = CLK_FREQ / BAUD_RATE;

    reg [$clog2(BIT_PERIOD)-1:0] bcount;
    reg [3:0] dcount;

    parameter IDLE = 2'b00;
    parameter START = 2'b01;
    parameter DATA = 2'b10;
    parameter STOP = 2'b11;
    
    reg [1:0] state , next;
    reg [8:0] r_data;

    always @(posedge clk, negedge areset_n) begin
        if(!areset_n) begin
            state <= IDLE;
            bcount <= 0;
            dcount <= 0;
            data_out <= 0;
            r_data <= 0;
            rx_valid <= 0;
            rx_error <= 0;
            next <= 0;
        end
        else if (state == IDLE && rx == 0) begin
            state <= START;
            bcount <= 0;
        end
        else if (bcount == BIT_PERIOD-1) begin
            bcount <= 0;

            if(dcount >=1 && dcount <=8) begin
                r_data <= {1'b0,{r_data[8:1]}};
            end
            else begin
                r_data <= r_data;
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
                rx_valid = 0;
                rx_error = 0;
            end
            START: begin
                if((bcount == BIT_PERIOD/2) && rx == 1) begin
                    next = IDLE;
                    rx_valid = 0;
                    rx_error = 1;
                end
                else begin
                    next = DATA;
                end
            end
            DATA: begin
                if(dcount == 9) begin
                    next = STOP;
                end
                else if(bcount == BIT_PERIOD/2) begin
                    r_data[8] = rx;
                end
            end
            STOP: begin
                data_out = r_data[7:0];
                if (rx==0) begin
                    next = START;
                end
                else begin
                    next = IDLE;
                end
            end
        endcase
    end

endmodule