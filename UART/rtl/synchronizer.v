module synchronizer (
    input clk,
    input areset_n,
    input syn_in,
    output reg syn_out
);
    reg syn_out1;
    always @(posedge clk, negedge areset_n) begin
        if(!areset_n) begin
            syn_out1 <= 0;
            syn_out <= 0;
        end
        else begin
            syn_out1 <= syn_in;
            syn_out <= syn_out1;
        end
    end
endmodule