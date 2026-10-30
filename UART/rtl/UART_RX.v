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

    localparam integer BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    localparam integer COUNT_BITS = (BIT_PERIOD <=1 ) ? 1 : $clog2(BIT_PERIOD);
    reg [COUNT_BITS-1:0] bcount;
    reg [3:0] dcount;

    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;

    reg [1:0] state;
    reg [8:0] r_data;

    always @(posedge clk, negedge areset_n) begin
        if(!areset_n) begin
            state <= IDLE;
            data_out <= 0;
            rx_valid <= 0;
            rx_error <= 0;
            bcount <= 0;
            dcount <= 0;
            r_data <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    if(rx == 0) begin
                        state <= START;
                        bcount <= 0;
                        dcount <=0;
                    end
                    else begin
                        state <= IDLE;
                        bcount <= 0;
                        dcount <= 0;
                    end
                end
                START: begin
                    if (bcount == BIT_PERIOD-1) begin
                        state <= DATA;
                        bcount <= 0;
                        dcount <= 1;
                    end
                    else if(bcount == (BIT_PERIOD)/2 && rx==1) begin
                        state <= IDLE;
                        bcount <= 0;
                        dcount <= 0;
                    end
                    else begin
                        bcount <= bcount + 1;
                    end
                end
                DATA: begin
                    if(bcount == BIT_PERIOD-1) begin
                        if(dcount==9) begin
                            state <= STOP;
                            bcount <= 0;
                            dcount <= 0;
                        end
                        else if (dcount>=1) begin
                            r_data <= {r_data[0],r_data[8:1]};
                            bcount <= 0;
                            dcount <= dcount + 1;
                            state <= DATA;
                        end
                        else begin
                            bcount <= bcount;
                            dcount <= dcount;
                            r_data <= r_data;
                            state <= DATA;
                        end
                    end
                    else if (bcount == BIT_PERIOD/2) begin
                        r_data[8] <= rx;
                        bcount <= bcount + 1;
                    end
                    else begin
                        bcount <= bcount + 1;
                    end
                end
                STOP: begin
                    if(bcount == BIT_PERIOD-1) begin
                        if(rx==0) begin
                            state <= START;
                            bcount <= 0;
                        end
                        else begin
                            state <= IDLE;
                            bcount <= 0;
                        end
                    end
                    else if (bcount == BIT_PERIOD/2 && rx==0) begin
                        state <= IDLE;
                        bcount <= 0;
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
                data_out = data_out;
                rx_valid = 1'b0;
                rx_error = 1'b0;
            end
            START: begin
                if((bcount == BIT_PERIOD/2 && rx==1)) begin
                    rx_valid = 1'b0;
                    rx_error = 1'b1;
                end
                else begin
                    rx_valid = 1'b0;
                    rx_error = 1'b0;
                end
            end
            DATA: begin
                rx_valid = 1'b0;
                rx_error = 1'b0;
            end
            STOP: begin
                if (^r_data) begin
                    rx_valid = 1'b0;
                    rx_error = 1'b1;
                end
                else begin
                    data_out = r_data[7:0];
                    rx_valid = 1'b1;
                    rx_error = 1'b0;
                end
            end
        endcase
    end 


endmodule