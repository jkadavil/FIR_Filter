`timescale 1ns/1ps

module tb_fir_top;
    localparam DATA_WIDTH=16, COEFF_WIDTH=16, ACC_WIDTH=40;
    localparam NUM_TAPS=32, FIFO_DEPTH=8, NUM_SAMPLES=80;
    reg clk=0, rst_n=0;
    always #5 clk=~clk;

    reg s_axis_tvalid; wire s_axis_tready; reg [15:0] s_axis_tdata;
    wire m_axis_tvalid; reg m_axis_tready; wire [39:0] m_axis_tdata;
    reg [31:0] s_axi_awaddr; reg s_axi_awvalid; wire s_axi_awready;
    reg [31:0] s_axi_wdata; reg [3:0] s_axi_wstrb; reg s_axi_wvalid; wire s_axi_wready;
    wire s_axi_bvalid; wire [1:0] s_axi_bresp; reg s_axi_bready;
    reg [31:0] s_axi_araddr; reg s_axi_arvalid; wire s_axi_arready;
    wire [31:0] s_axi_rdata; wire s_axi_rvalid; wire [1:0] s_axi_rresp; reg s_axi_rready;
    wire input_fifo_full, input_fifo_empty, output_fifo_empty;

    reg signed [15:0] ref_delay [0:31];
    reg signed [15:0] ref_coeff [0:31];
    reg signed [39:0] expected [0:NUM_SAMPLES-1];
    integer sent, received, errors, cycles, i;
    reg random_ready_enable;

    fir_top #(.DATA_WIDTH(DATA_WIDTH),.COEFF_WIDTH(COEFF_WIDTH),.ACC_WIDTH(ACC_WIDTH),
              .NUM_TAPS(NUM_TAPS),.FIFO_DEPTH(FIFO_DEPTH)) dut (
        .clk(clk),.rst_n(rst_n),
        .s_axis_tvalid(s_axis_tvalid),.s_axis_tready(s_axis_tready),.s_axis_tdata(s_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),.m_axis_tready(m_axis_tready),.m_axis_tdata(m_axis_tdata),
        .s_axi_awaddr(s_axi_awaddr),.s_axi_awvalid(s_axi_awvalid),.s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),.s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),.s_axi_wready(s_axi_wready),
        .s_axi_bvalid(s_axi_bvalid),.s_axi_bresp(s_axi_bresp),.s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),.s_axi_arvalid(s_axi_arvalid),.s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),.s_axi_rvalid(s_axi_rvalid),
        .s_axi_rresp(s_axi_rresp),.s_axi_rready(s_axi_rready),
        .input_fifo_full(input_fifo_full),.input_fifo_empty(input_fifo_empty),
        .output_fifo_empty(output_fifo_empty));

    task axi_write;
        input [31:0] addr, data;
        begin
            @(negedge clk); s_axi_awaddr=addr; s_axi_awvalid=1;
            s_axi_wdata=data; s_axi_wstrb=4'hf; s_axi_wvalid=1;
            while (!(s_axi_awready && s_axi_wready)) @(negedge clk);
            @(negedge clk); s_axi_awvalid=0; s_axi_wvalid=0; s_axi_bready=1;
            while (!s_axi_bvalid) @(negedge clk);
            if (s_axi_bresp != 0) errors=errors+1;
            @(negedge clk); s_axi_bready=0;
        end
    endtask

    task axi_read_check;
        input [31:0] addr, expected_data;
        begin
            @(negedge clk); s_axi_araddr=addr; s_axi_arvalid=1; s_axi_rready=1;
            while (!s_axi_arready) @(negedge clk);
            @(negedge clk); s_axi_arvalid=0;
            while (!s_axi_rvalid) @(negedge clk);
            if (s_axi_rdata !== expected_data || s_axi_rresp != 0) begin
                $display("AXI READ ERROR addr=%h got=%h expected=%h",addr,s_axi_rdata,expected_data);
                errors=errors+1;
            end
            @(negedge clk); s_axi_rready=0;
        end
    endtask

    task send_sample;
        input signed [15:0] value;
        integer j; reg signed [39:0] sum;
        begin
            @(negedge clk); s_axis_tdata=value; s_axis_tvalid=1;
            while (!s_axis_tready) @(negedge clk);
            sum=$signed(value)*$signed(ref_coeff[0]);
            for(j=1;j<NUM_TAPS;j=j+1)
                sum=sum+$signed(ref_delay[j-1])*$signed(ref_coeff[j]);
            expected[sent]=sum;
            for(j=NUM_TAPS-1;j>0;j=j-1) ref_delay[j]=ref_delay[j-1];
            ref_delay[0]=value; sent=sent+1;
            @(negedge clk); s_axis_tvalid=0;
        end
    endtask

    always @(negedge clk) begin
        if(!rst_n) m_axis_tready<=0;
        else if(random_ready_enable) m_axis_tready<=($urandom_range(0,3)!=0);
    end

    always @(posedge clk) begin
        if(rst_n && m_axis_tvalid && m_axis_tready) begin
            if($signed(m_axis_tdata)!==expected[received]) begin
                $display("OUTPUT ERROR index=%0d got=%0d expected=%0d",received,$signed(m_axis_tdata),expected[received]);
                errors=errors+1;
            end
            received=received+1;
        end
    end

    initial begin
        s_axis_tvalid=0;s_axis_tdata=0;m_axis_tready=0;
        s_axi_awaddr=0;s_axi_awvalid=0;s_axi_wdata=0;s_axi_wstrb=0;s_axi_wvalid=0;s_axi_bready=0;
        s_axi_araddr=0;s_axi_arvalid=0;s_axi_rready=0;
        sent=0;received=0;errors=0;random_ready_enable=0;
        for(i=0;i<NUM_TAPS;i=i+1) begin ref_delay[i]=0; ref_coeff[i]=(i%5)-2; end
        repeat(4) @(posedge clk); rst_n=1; repeat(2) @(posedge clk);
        if(s_axis_tready!==0) begin $display("ERROR: ready high while disabled"); errors=errors+1; end

        for(i=0;i<NUM_TAPS;i=i+1) axi_write(32'h10+i*4,{{16{ref_coeff[i][15]}},ref_coeff[i]});
        for(i=0;i<NUM_TAPS;i=i+1) axi_read_check(32'h10+i*4,{16'b0,ref_coeff[i]});
        axi_write(32'h04,1);
        axi_write(32'h10,16'h7fff); // shadow write must not change active coefficients
        axi_write(32'h00,1);
        random_ready_enable=1;
        for(i=0;i<NUM_SAMPLES;i=i+1) send_sample((i%19)-9);

        cycles=0;
        while(received<NUM_SAMPLES && cycles<5000) begin @(posedge clk); cycles=cycles+1; end
        if(received!=NUM_SAMPLES) begin
            $display("TIMEOUT: received %0d of %0d",received,NUM_SAMPLES); errors=errors+1;
        end
        if(errors==0) $display("PASS: FIR top-level tests passed");
        else $display("FAIL: FIR top-level tests had %0d errors",errors);
        $finish;
    end
endmodule
