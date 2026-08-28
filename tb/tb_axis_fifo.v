`timescale 1ns/1ps

module tb_axis_fifo;

    parameter DATA_WIDTH = 40;
    parameter FIFO_DEPTH = 16;

    reg clk;
    reg rst_n;

    reg [DATA_WIDTH-1:0] s_axis_tdata;
    reg s_axis_tvalid;
    wire s_axis_tready;

    wire [DATA_WIDTH-1:0] m_axis_tdata;
    wire m_axis_tvalid;
    reg m_axis_tready;

    integer errors;
    integer i;

    axis_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready)
    );

    always #5 clk = ~clk;

    task write_data;
        input [DATA_WIDTH-1:0] value;
        begin
            @(negedge clk);

            s_axis_tdata = value;
            s_axis_tvalid = 1'b1;

            while (!s_axis_tready)
                @(negedge clk);

            @(negedge clk);

            s_axis_tvalid = 1'b0;
            s_axis_tdata = 0;
        end
    endtask

    task read_data;
        input [DATA_WIDTH-1:0] expected;
        begin
            m_axis_tready = 1'b1;

            while (!m_axis_tvalid)
                @(posedge clk);

            #1;

            if (m_axis_tdata !== expected) begin
                $display(
                    "ERROR: Expected %0d, Got %0d",
                    expected,
                    m_axis_tdata
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: Expected %0d, Got %0d",
                    expected,
                    m_axis_tdata
                );
            end

            @(posedge clk);

            m_axis_tready = 1'b0;
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;

        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        m_axis_tready = 0;

        errors = 0;

        $display("===================================");
        $display(" AXI4-STREAM FIFO UNIT TEST");
        $display("===================================");

        repeat (4)
            @(posedge clk);

        rst_n = 1;

        $display("");
        $display("TEST 1: Single value");

        write_data(123);
        read_data(123);

        $display("");
        $display("TEST 2: FIFO ordering");

        for (i = 0; i < 8; i = i + 1)
            write_data(i + 1);

        for (i = 0; i < 8; i = i + 1)
            read_data(i + 1);

        $display("");
        $display("TEST 3: Back-to-back values");

        for (i = 0; i < 8; i = i + 1)
            write_data(100 + i);

        for (i = 0; i < 8; i = i + 1)
            read_data(100 + i);

        $display("");
        $display("TEST 4: FIFO fill");

        for (i = 0; i < FIFO_DEPTH; i = i + 1)
            write_data(1000 + i);

        for (i = 0; i < FIFO_DEPTH; i = i + 1)
            read_data(1000 + i);

        $display("");
        $display("===================================");

        if (errors == 0) begin
            $display(" AXI4-STREAM FIFO UNIT TEST PASSED");
        end
        else begin
            $display(" AXI4-STREAM FIFO UNIT TEST FAILED");
            $display(" Errors = %0d", errors);
        end

        $display("===================================");

        $finish;
    end

endmodule
