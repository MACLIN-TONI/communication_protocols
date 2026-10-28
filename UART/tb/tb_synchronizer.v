`timescale 1ns/1ps
module tb_synchronizer;
    reg clk;
    reg areset_n;
    reg syn_in;
    wire syn_out;

    synchronizer dut(
        .clk(clk),
        .areset_n(areset_n),
        .syn_in(syn_in),
        .syn_out(syn_out)
    );

    initial begin
        $dumpfile("waves/dump.vcd");
        $dumpvars(0,tb_synchronizer);
    end

    initial begin
        clk = 0;
        areset_n = 0;
        syn_in = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        #12;
        areset_n = 1;
        syn_in = 1;
        #14;
        syn_in = 0;
        #14;
        syn_in = 1;
    end


endmodule