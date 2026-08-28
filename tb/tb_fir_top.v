`timescale 1ns/1ps

module tb_fir_top;

    parameter DATA_WIDTH = 16;
    parameter ACC_WIDTH = 40;
    parameter FIFO_DEPTH = 16;

    reg clk;
    reg rst_n;

    reg s_axis_tvalid;
    wire s_axis_tready;
    reg [DATA_WIDTH-1:0] s_axis_tdata;

    wire m_axis_tvalid;
    reg m_axis_tready;
    wire [ACC_WIDTH-1:0] m_axis_tdata;

    reg [31:0] s_axi_awaddr;
    reg s_axi_awvalid;
    wire s_axi_awready;

    reg [31:0] s_axi_wdata;
    reg s_axi_wvalid;
    wire s_axi_wready;

    wire s_axi_bvalid;
    reg s_axi_bready;

    reg [31:0] s_axi_araddr;
    reg s_axi_arvalid;
    wire s_axi_arready;

    wire [31:0] s_axi_rdata;
    wire s_axi_rvalid;
    reg s_axi_rready;

    wire input_fifo_full;
    wire input_fifo_empty;
    wire output_fifo_empty;

    integer errors;
    integer i;
    integer sample_count;
    integer output_count;
    integer expected_queue [0:199];
    integer queue_write;
    integer queue_read;
    integer readback;

    fir_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF_WIDTH(16),
        .ACC_WIDTH(ACC_WIDTH),
        .NUM_TAPS(32),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),

        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata(s_axi_rdata),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),

        .input_fifo_full(input_fifo_full),
        .input_fifo_empty(input_fifo_empty),
        .output_fifo_empty(output_fifo_empty)
    );

    always #5 clk = ~clk;

    // Reference Model
    reg [DATA_WIDTH-1:0] ref_delay [0:31];
    
    function [ACC_WIDTH-1:0] calc;
        input [DATA_WIDTH-1:0] new_sample;
        integer idx;
        reg [ACC_WIDTH-1:0] sum;
        begin
            for (idx = 31; idx > 0; idx = idx - 1)
                ref_delay[idx] = ref_delay[idx-1];
            ref_delay[0] = new_sample;
            
            sum = 0;
            for (idx = 0; idx < 32; idx = idx + 1)
                sum = sum + ref_delay[idx] * (idx + 1);
            
            calc = sum;
        end
    endfunction

    // AXI Write - FIXED
    task axi_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);

            s_axi_awaddr = addr;
            s_axi_awvalid = 1'b1;

            s_axi_wdata = data;
            s_axi_wvalid = 1'b1;

            s_axi_bready = 1'b1;

            while (!(s_axi_awready && s_axi_wready))
                @(posedge clk);

            @(posedge clk);

            @(negedge clk);

            s_axi_awvalid = 1'b0;
            s_axi_wvalid = 1'b0;

            while (!s_axi_bvalid)
                @(posedge clk);

            @(posedge clk);

            @(negedge clk);

            s_axi_bready = 1'b0;
            
            // Extra delay to ensure write completes
            @(negedge clk);
        end
    endtask

    // AXI Read
    task axi_read;
        input [31:0] addr;
        output [31:0] data;
        begin
            @(negedge clk);

            s_axi_araddr = addr;
            s_axi_arvalid = 1'b1;
            s_axi_rready = 1'b1;

            while (!s_axi_arready)
                @(posedge clk);

            @(posedge clk);

            @(negedge clk);

            s_axi_arvalid = 1'b0;

            while (!s_axi_rvalid)
                @(posedge clk);

            data = s_axi_rdata;

            @(posedge clk);

            @(negedge clk);

            s_axi_rready = 1'b0;
        end
    endtask

    // Send Sample
    task send_sample;
        input [DATA_WIDTH-1:0] value;
        reg [ACC_WIDTH-1:0] exp;
        begin
            exp = calc(value);
            
            if ($urandom_range(0,3) == 0) begin
                @(negedge clk);
                s_axis_tvalid = 1'b0;
                s_axis_tdata = 0;
                $display("  [INPUT GAP]");
                @(posedge clk);
            end

            @(negedge clk);
            s_axis_tdata = value;
            s_axis_tvalid = 1'b1;
            $display("  Sending sample: %0d", value);

            while (!(s_axis_tvalid && s_axis_tready)) begin
                @(posedge clk);
            end

            if (sample_count == 0) begin
                expected_queue[queue_write] = 0;
                queue_write = queue_write + 1;
                $display("    Expected[0]: 0");
            end
            
            expected_queue[queue_write] = exp;
            queue_write = queue_write + 1;
            $display("    Expected[%0d]: %0d", sample_count + 1, exp);

            @(posedge clk);
            @(negedge clk);
            
            s_axis_tvalid = 1'b0;
            s_axis_tdata = 0;
            sample_count = sample_count + 1;
        end
    endtask

    // Output Checker
    always @(posedge clk) begin
        if (rst_n && m_axis_tvalid && m_axis_tready) begin
            if (m_axis_tdata !== expected_queue[queue_read]) begin
                $display("  FAIL: Output %0d | Got %0d Expected %0d", 
                         output_count, m_axis_tdata, expected_queue[queue_read]);
                errors = errors + 1;
            end else begin
                $display("  PASS: Output %0d | Got %0d Expected %0d", 
                         output_count, m_axis_tdata, expected_queue[queue_read]);
            end
            queue_read = queue_read + 1;
            output_count = output_count + 1;
            
            if (output_count == sample_count) begin
                $display("");
                $display("============================================");
                $display(" TEST COMPLETE");
                $display("============================================");
                $display("Samples sent: %0d", sample_count);
                $display("Outputs received: %0d", output_count);
                $display("Errors: %0d", errors);
                $display("============================================");

                if (errors == 0) begin
                    $display(" PASS: ALL TESTS PASSED");
                end else begin
                    $display(" FAIL: %0d errors", errors);
                end
                $display("============================================");
                $finish;
            end
        end
    end

    // Main Test
    initial begin
        clk = 0;
        rst_n = 0;

        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        m_axis_tready = 0;

        s_axi_awaddr = 0;
        s_axi_awvalid = 0;
        s_axi_wdata = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 0;
        s_axi_araddr = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 0;

        errors = 0;
        sample_count = 0;
        output_count = 0;
        queue_write = 0;
        queue_read = 0;

        for (i = 0; i < 32; i = i + 1)
            ref_delay[i] = 0;

        $display("============================================");
        $display(" FIR TEST WITH AXI4-LITE CONTROL");
        $display("============================================");

        repeat (4) @(posedge clk);
        rst_n = 1;

        // ============================================================
        // STEP 1: PROGRAM COEFFICIENTS
        // ============================================================
        
        $display("");
        $display("PROGRAMMING COEFFICIENTS");
        $display("--------------------------------------------");

        for (i = 0; i < 32; i = i + 1) begin
            axi_write(32'h10 + i*4, i + 1);
        end

        // ============================================================
        // STEP 2: VERIFY COEFFICIENTS
        // ============================================================
        
        $display("");
        $display("VERIFYING COEFFICIENTS");
        $display("--------------------------------------------");

        for (i = 0; i < 32; i = i + 1) begin
            axi_read(32'h10 + i*4, readback);
            if (readback == i + 1) begin
                $display("  PASS: Coeff[%0d] = %0d", i, readback);
            end else begin
                $display("  FAIL: Coeff[%0d] = %0d (expected %0d)", i, readback, i + 1);
                errors = errors + 1;
            end
        end

        // ============================================================
        // STEP 3: LOAD COEFFICIENTS
        // ============================================================
        
        $display("");
        $display("LOADING COEFFICIENTS");
        $display("--------------------------------------------");
        axi_write(32'h04, 32'h00000001);
        
        // FIXED: Add delay after LOAD write
        repeat (5) @(posedge clk);

        // ============================================================
        // STEP 4: ENABLE THE FILTER
        // ============================================================
        
        $display("");
        $display("ENABLING FILTER");
        $display("--------------------------------------------");

        axi_write(32'h00, 32'h00000001);
        repeat (2) @(posedge clk);

        // DEBUG: Read back control register
        axi_read(32'h00, readback);
        $display("DEBUG: CONTROL = 0x%h (bit0 should be 1)", readback);

        // ============================================================
        // STEP 5: RUN FIR TESTS
        // ============================================================
        
        m_axis_tready = 1'b1;

        $display("");
        $display("TEST: Send 32 samples");
        $display("--------------------------------------------");
        for (i = 1; i <= 32; i = i + 1)
            send_sample(i);

        $display("");
        $display("Waiting for outputs... (auto-finish when done)");
        
        while (output_count < sample_count) begin
            @(posedge clk);
        end
        
        $finish;
    end

endmodule
