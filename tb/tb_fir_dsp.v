`timescale 1ns/1ps

module tb_fir_dsp;

    parameter DATA_WIDTH = 16;
    parameter COEFF_WIDTH = 16;
    parameter ACC_WIDTH = 40;
    parameter NUM_TAPS = 32;

    reg clk;
    reg rst_n;

    reg [DATA_WIDTH-1:0] sample0;
    reg [DATA_WIDTH-1:0] sample1;
    reg [DATA_WIDTH-1:0] sample2;
    reg [DATA_WIDTH-1:0] sample3;
    reg [DATA_WIDTH-1:0] sample4;
    reg [DATA_WIDTH-1:0] sample5;
    reg [DATA_WIDTH-1:0] sample6;
    reg [DATA_WIDTH-1:0] sample7;
    reg [DATA_WIDTH-1:0] sample8;
    reg [DATA_WIDTH-1:0] sample9;
    reg [DATA_WIDTH-1:0] sample10;
    reg [DATA_WIDTH-1:0] sample11;
    reg [DATA_WIDTH-1:0] sample12;
    reg [DATA_WIDTH-1:0] sample13;
    reg [DATA_WIDTH-1:0] sample14;
    reg [DATA_WIDTH-1:0] sample15;
    reg [DATA_WIDTH-1:0] sample16;
    reg [DATA_WIDTH-1:0] sample17;
    reg [DATA_WIDTH-1:0] sample18;
    reg [DATA_WIDTH-1:0] sample19;
    reg [DATA_WIDTH-1:0] sample20;
    reg [DATA_WIDTH-1:0] sample21;
    reg [DATA_WIDTH-1:0] sample22;
    reg [DATA_WIDTH-1:0] sample23;
    reg [DATA_WIDTH-1:0] sample24;
    reg [DATA_WIDTH-1:0] sample25;
    reg [DATA_WIDTH-1:0] sample26;
    reg [DATA_WIDTH-1:0] sample27;
    reg [DATA_WIDTH-1:0] sample28;
    reg [DATA_WIDTH-1:0] sample29;
    reg [DATA_WIDTH-1:0] sample30;
    reg [DATA_WIDTH-1:0] sample31;

    reg samples_valid;
    wire samples_ready;

    reg [COEFF_WIDTH*NUM_TAPS-1:0] coeff_packed;

    wire [ACC_WIDTH-1:0] result;
    wire result_valid;

    reg result_ready;

    wire output_fifo_empty;

    integer i;
    integer errors;

    fir_dsp #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .NUM_TAPS(NUM_TAPS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .sample0(sample0),
        .sample1(sample1),
        .sample2(sample2),
        .sample3(sample3),
        .sample4(sample4),
        .sample5(sample5),
        .sample6(sample6),
        .sample7(sample7),
        .sample8(sample8),
        .sample9(sample9),
        .sample10(sample10),
        .sample11(sample11),
        .sample12(sample12),
        .sample13(sample13),
        .sample14(sample14),
        .sample15(sample15),
        .sample16(sample16),
        .sample17(sample17),
        .sample18(sample18),
        .sample19(sample19),
        .sample20(sample20),
        .sample21(sample21),
        .sample22(sample22),
        .sample23(sample23),
        .sample24(sample24),
        .sample25(sample25),
        .sample26(sample26),
        .sample27(sample27),
        .sample28(sample28),
        .sample29(sample29),
        .sample30(sample30),
        .sample31(sample31),

        .samples_valid(samples_valid),
        .samples_ready(samples_ready),

        .coeff_packed(coeff_packed),

        .result(result),
        .result_valid(result_valid),
        .result_ready(result_ready),

        .output_fifo_empty(output_fifo_empty)
    );

    always #5 clk = ~clk;

    task clear_samples;
        begin
            sample0  = 0;
            sample1  = 0;
            sample2  = 0;
            sample3  = 0;
            sample4  = 0;
            sample5  = 0;
            sample6  = 0;
            sample7  = 0;
            sample8  = 0;
            sample9  = 0;
            sample10 = 0;
            sample11 = 0;
            sample12 = 0;
            sample13 = 0;
            sample14 = 0;
            sample15 = 0;
            sample16 = 0;
            sample17 = 0;
            sample18 = 0;
            sample19 = 0;
            sample20 = 0;
            sample21 = 0;
            sample22 = 0;
            sample23 = 0;
            sample24 = 0;
            sample25 = 0;
            sample26 = 0;
            sample27 = 0;
            sample28 = 0;
            sample29 = 0;
            sample30 = 0;
            sample31 = 0;
        end
    endtask

    task send_vector_ones;
        begin
            sample0  = 1;
            sample1  = 1;
            sample2  = 1;
            sample3  = 1;
            sample4  = 1;
            sample5  = 1;
            sample6  = 1;
            sample7  = 1;
            sample8  = 1;
            sample9  = 1;
            sample10 = 1;
            sample11 = 1;
            sample12 = 1;
            sample13 = 1;
            sample14 = 1;
            sample15 = 1;
            sample16 = 1;
            sample17 = 1;
            sample18 = 1;
            sample19 = 1;
            sample20 = 1;
            sample21 = 1;
            sample22 = 1;
            sample23 = 1;
            sample24 = 1;
            sample25 = 1;
            sample26 = 1;
            sample27 = 1;
            sample28 = 1;
            sample29 = 1;
            sample30 = 1;
            sample31 = 1;
        end
    endtask

    task send_vector_1_to_32;
        begin
            sample0  = 1;
            sample1  = 2;
            sample2  = 3;
            sample3  = 4;
            sample4  = 5;
            sample5  = 6;
            sample6  = 7;
            sample7  = 8;
            sample8  = 9;
            sample9  = 10;
            sample10 = 11;
            sample11 = 12;
            sample12 = 13;
            sample13 = 14;
            sample14 = 15;
            sample15 = 16;
            sample16 = 17;
            sample17 = 18;
            sample18 = 19;
            sample19 = 20;
            sample20 = 21;
            sample21 = 22;
            sample22 = 23;
            sample23 = 24;
            sample24 = 25;
            sample25 = 26;
            sample26 = 27;
            sample27 = 28;
            sample28 = 29;
            sample29 = 30;
            sample30 = 31;
            sample31 = 32;
        end
    endtask

    task check_result;
        input signed [ACC_WIDTH-1:0] expected;
        begin
            wait(result_valid);
            #1;

            if ($signed(result) !== expected) begin
                $display(
                    "ERROR: Expected %0d, Got %0d",
                    expected,
                    $signed(result)
                );
                errors = errors + 1;
            end else begin
                $display(
                    "PASS: Expected %0d, Got %0d",
                    expected,
                    $signed(result)
                );
            end

            @(posedge clk);
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        samples_valid = 0;
        result_ready = 1;

        coeff_packed = 0;

        errors = 0;

        clear_samples();

        /*
         * All 32 coefficients = 1
         */
        for (i = 0; i < NUM_TAPS; i = i + 1)
            coeff_packed[i*COEFF_WIDTH +: COEFF_WIDTH] = 1;

        $display("====================================");
        $display(" FIR DSP UNIT TEST");
        $display("====================================");

        /*
         * Reset
         */
        repeat (4)
            @(posedge clk);

        rst_n = 1;

        /*
         * TEST 1
         *
         * All samples = 1
         * All coefficients = 1
         *
         * Expected:
         *
         * 32 * 1 * 1 = 32
         */
        $display("");
        $display("TEST 1: 32 samples of 1");

        send_vector_ones();

        @(posedge clk);
        samples_valid <= 1;

        @(posedge clk);
        samples_valid <= 0;

        check_result(32);

        /*
         * TEST 2
         *
         * samples = 1..32
         * coefficients = 1
         *
         * Expected:
         *
         * 1 + 2 + ... + 32 = 528
         */
        $display("");
        $display("TEST 2: samples 1 through 32");

        send_vector_1_to_32();

        @(posedge clk);
        samples_valid <= 1;

        @(posedge clk);
        samples_valid <= 0;

        check_result(528);

        /*
         * TEST 3
         *
         * Only sample0 = 10.
         * Everything else = 0.
         *
         * Expected = 10.
         */
        $display("");
        $display("TEST 3: impulse input");

        clear_samples();
        sample0 = 10;

        @(posedge clk);
        samples_valid <= 1;

        @(posedge clk);
        samples_valid <= 0;

        check_result(10);

        /*
         * TEST 4
         *
         * Only sample31 = 25.
         *
         * Expected = 25.
         */
        $display("");
        $display("TEST 4: sample31 only");

        clear_samples();
        sample31 = 25;

        @(posedge clk);
        samples_valid <= 1;

        @(posedge clk);
        samples_valid <= 0;

        check_result(25);
        
        

        /*
         * Final result
         */
        $display("");
        $display("====================================");

        if (errors == 0) begin
            $display(" FIR DSP UNIT TEST PASSED");
        end else begin
            $display(" FIR DSP UNIT TEST FAILED");
            $display(" Errors = %0d", errors);
        end

        $display("====================================");

        $finish;
    end

endmodule
