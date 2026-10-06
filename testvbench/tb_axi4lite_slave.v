`timescale 1ns / 1ps

module tb_axi4lite_slave;

    parameter ADDR_WIDTH = 8;
    parameter DATA_WIDTH = 32;

    //============================================================
    // CLOCK
    //============================================================

    reg ACLK;

    initial
    begin
        ACLK = 1'b0;
        forever #5 ACLK = ~ACLK;
    end


    //============================================================
    // RESET
    //============================================================

    reg ARESETn;


    //============================================================
    // AXI WRITE ADDRESS CHANNEL
    //============================================================

    reg  [ADDR_WIDTH-1:0] AWADDR;
    reg                   AWVALID;
    wire                  AWREADY;


    //============================================================
    // AXI WRITE DATA CHANNEL
    //============================================================

    reg  [DATA_WIDTH-1:0] WDATA;
    reg  [DATA_WIDTH/8-1:0] WSTRB;
    reg                   WVALID;
    wire                  WREADY;


    //============================================================
    // AXI WRITE RESPONSE CHANNEL
    //============================================================

    wire [1:0] BRESP;
    wire       BVALID;
    reg        BREADY;


    //============================================================
    // AXI READ ADDRESS CHANNEL
    //============================================================

    reg  [ADDR_WIDTH-1:0] ARADDR;
    reg                   ARVALID;
    wire                  ARREADY;


    //============================================================
    // AXI READ DATA CHANNEL
    //============================================================

    wire [DATA_WIDTH-1:0] RDATA;
    wire [1:0]            RRESP;
    wire                  RVALID;
    reg                   RREADY;


    //============================================================
    // INTERRUPT
    //============================================================

    wire IRQ;


    //============================================================
    // TEST VARIABLES
    //============================================================

    reg [DATA_WIDTH-1:0] READ_DATA;

    integer PASS_COUNT;
    integer FAIL_COUNT;


    //============================================================
    // DUT
    //============================================================

    axi4lite_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    )
    DUT
    (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),

        .WDATA(WDATA),
        .WSTRB(WSTRB),
        .WVALID(WVALID),
        .WREADY(WREADY),

        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),

        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),

        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RREADY(RREADY),

        .IRQ(IRQ)
    );


    //============================================================
    // INITIALIZATION AND RESET
    //============================================================

    initial
    begin

        ARESETn = 1'b0;

        AWADDR  = 8'h00;
        AWVALID = 1'b0;

        WDATA   = 32'h00000000;
        WSTRB   = 4'b0000;
        WVALID  = 1'b0;

        BREADY  = 1'b0;

        ARADDR  = 8'h00;
        ARVALID = 1'b0;

        RREADY  = 1'b0;

        PASS_COUNT = 0;
        FAIL_COUNT = 0;

        // Hold reset for 10 clock cycles
        repeat (10)
            @(negedge ACLK);

        // Release reset safely on negedge
        ARESETn = 1'b1;

    end


    //============================================================
    // NORMAL AXI WRITE
    //============================================================

    task AXI_WRITE;

        input [ADDR_WIDTH-1:0] ADDR;
        input [DATA_WIDTH-1:0] DATA;
        input [DATA_WIDTH/8-1:0] STRB;

        integer TIMEOUT;

        begin

            $display("");
            $display("----------------------------------------");
            $display("WRITE TRANSACTION");
            $display("ADDR = %h", ADDR);
            $display("DATA = %h", DATA);
            $display("STRB = %b", STRB);
            $display("----------------------------------------");


            //====================================================
            // WRITE ADDRESS
            //====================================================

            @(negedge ACLK);

            AWADDR  = ADDR;
            AWVALID = 1'b1;

            TIMEOUT = 0;

            while (!AWREADY && TIMEOUT < 100)
            begin
                @(negedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            if (TIMEOUT >= 100)
            begin
                $display("ERROR: AWREADY TIMEOUT");
                FAIL_COUNT = FAIL_COUNT + 1;
            end

            @(negedge ACLK);

            AWVALID = 1'b0;


            //====================================================
            // WRITE DATA
            //====================================================

            @(negedge ACLK);

            WDATA  = DATA;
            WSTRB  = STRB;
            WVALID = 1'b1;

            TIMEOUT = 0;

            while (!WREADY && TIMEOUT < 100)
            begin
                @(negedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            if (TIMEOUT >= 100)
            begin
                $display("ERROR: WREADY TIMEOUT");
                FAIL_COUNT = FAIL_COUNT + 1;
            end

            @(negedge ACLK);

            WVALID = 1'b0;


            //====================================================
            // WRITE RESPONSE
            //====================================================

            @(negedge ACLK);

            BREADY = 1'b1;

            TIMEOUT = 0;

            while (!BVALID && TIMEOUT < 100)
            begin
                @(posedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            if (TIMEOUT >= 100)
            begin
                $display("ERROR: BVALID TIMEOUT");
                FAIL_COUNT = FAIL_COUNT + 1;
            end
            else
            begin

                if (BRESP == 2'b00)
                    $display("WRITE RESPONSE = OKAY");
                else if (BRESP == 2'b10)
                    $display("WRITE RESPONSE = SLVERR");
                else
                    $display("WRITE RESPONSE = %b", BRESP);

            end

            @(negedge ACLK);

            BREADY = 1'b0;

        end

    endtask


    //============================================================
    // NORMAL AXI READ
    //============================================================

    task AXI_READ;

        input  [ADDR_WIDTH-1:0] ADDR;
        output [DATA_WIDTH-1:0] DATA;

        integer TIMEOUT;

        begin

            $display("");
            $display("----------------------------------------");
            $display("READ TRANSACTION");
            $display("ADDR = %h", ADDR);
            $display("----------------------------------------");


            //====================================================
            // READ ADDRESS
            //====================================================

            @(negedge ACLK);

            ARADDR  = ADDR;
            ARVALID = 1'b1;

            TIMEOUT = 0;

            while (!ARREADY && TIMEOUT < 100)
            begin
                @(negedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            if (TIMEOUT >= 100)
            begin
                $display("ERROR: ARREADY TIMEOUT");
                FAIL_COUNT = FAIL_COUNT + 1;
            end

            @(negedge ACLK);

            ARVALID = 1'b0;


            //====================================================
            // READ RESPONSE
            //====================================================

            @(negedge ACLK);

            RREADY = 1'b1;

            TIMEOUT = 0;

            while (!RVALID && TIMEOUT < 100)
            begin
                @(posedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            if (TIMEOUT >= 100)
            begin
                $display("ERROR: RVALID TIMEOUT");
                FAIL_COUNT = FAIL_COUNT + 1;
                DATA = 32'hXXXXXXXX;
            end
            else
            begin

                DATA = RDATA;

                if (RRESP == 2'b00)
                    $display("READ RESPONSE = OKAY");
                else if (RRESP == 2'b10)
                    $display("READ RESPONSE = SLVERR");
                else
                    $display("READ RESPONSE = %b", RRESP);

                $display("READ DATA = %h", RDATA);

            end

            @(negedge ACLK);

            RREADY = 1'b0;

        end

    endtask


    //============================================================
    // AW BEFORE W
    //============================================================

    task AXI_WRITE_AW_FIRST;

        input [ADDR_WIDTH-1:0] ADDR;
        input [DATA_WIDTH-1:0] DATA;
        input [DATA_WIDTH/8-1:0] STRB;

        integer TIMEOUT;

        begin

            $display("");
            $display("----------------------------------------");
            $display("AW BEFORE W TEST");
            $display("----------------------------------------");


            //====================================================
            // SEND AW FIRST
            //====================================================

            @(negedge ACLK);

            AWADDR  = ADDR;
            AWVALID = 1'b1;

            TIMEOUT = 0;

            while (!AWREADY && TIMEOUT < 100)
            begin
                @(negedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            @(negedge ACLK);

            AWVALID = 1'b0;

            $display("AW channel completed");


            //====================================================
            // WAIT
            //====================================================

            repeat (3)
                @(negedge ACLK);


            //====================================================
            // SEND W
            //====================================================

            WDATA  = DATA;
            WSTRB  = STRB;
            WVALID = 1'b1;

            TIMEOUT = 0;

            while (!WREADY && TIMEOUT < 100)
            begin
                @(negedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            @(negedge ACLK);

            WVALID = 1'b0;

            $display("W channel completed");


            //====================================================
            // RESPONSE
            //====================================================

            @(negedge ACLK);

            BREADY = 1'b1;

            TIMEOUT = 0;

            while (!BVALID && TIMEOUT < 100)
            begin
                @(posedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            if (BRESP == 2'b00)
            begin
                $display("AW BEFORE W : PASS");
                PASS_COUNT = PASS_COUNT + 1;
            end
            else
            begin
                $display("AW BEFORE W : FAIL");
                FAIL_COUNT = FAIL_COUNT + 1;
            end

            @(negedge ACLK);

            BREADY = 1'b0;

        end

    endtask


    //============================================================
    // W BEFORE AW
    //============================================================

    task AXI_WRITE_W_FIRST;

        input [ADDR_WIDTH-1:0] ADDR;
        input [DATA_WIDTH-1:0] DATA;
        input [DATA_WIDTH/8-1:0] STRB;

        integer TIMEOUT;

        begin

            $display("");
            $display("----------------------------------------");
            $display("W BEFORE AW TEST");
            $display("----------------------------------------");


            //====================================================
            // SEND W FIRST
            //====================================================

            @(negedge ACLK);

            WDATA  = DATA;
            WSTRB  = STRB;
            WVALID = 1'b1;

            TIMEOUT = 0;

            while (!WREADY && TIMEOUT < 100)
            begin
                @(negedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            @(negedge ACLK);

            WVALID = 1'b0;

            $display("W channel completed");


            //====================================================
            // WAIT
            //====================================================

            repeat (3)
                @(negedge ACLK);


            //====================================================
            // SEND AW
            //====================================================

            AWADDR  = ADDR;
            AWVALID = 1'b1;

            TIMEOUT = 0;

            while (!AWREADY && TIMEOUT < 100)
            begin
                @(negedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            @(negedge ACLK);

            AWVALID = 1'b0;

            $display("AW channel completed");


            //====================================================
            // RESPONSE
            //====================================================

            @(negedge ACLK);

            BREADY = 1'b1;

            TIMEOUT = 0;

            while (!BVALID && TIMEOUT < 100)
            begin
                @(posedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            if (BRESP == 2'b00)
            begin
                $display("W BEFORE AW : PASS");
                PASS_COUNT = PASS_COUNT + 1;
            end
            else
            begin
                $display("W BEFORE AW : FAIL");
                FAIL_COUNT = FAIL_COUNT + 1;
            end

            @(negedge ACLK);

            BREADY = 1'b0;

        end

    endtask


    //============================================================
    // DELAYED BREADY
    //============================================================

    task AXI_WRITE_DELAYED_BREADY;

        input [ADDR_WIDTH-1:0] ADDR;
        input [DATA_WIDTH-1:0] DATA;

        integer i;
        integer TIMEOUT;

        begin

            $display("");
            $display("----------------------------------------");
            $display("DELAYED BREADY TEST");
            $display("----------------------------------------");


            //====================================================
            // ADDRESS
            //====================================================

            @(negedge ACLK);

            AWADDR  = ADDR;
            AWVALID = 1'b1;

            TIMEOUT = 0;

            while (!AWREADY && TIMEOUT < 100)
            begin
                @(negedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            @(negedge ACLK);

            AWVALID = 1'b0;


            //====================================================
            // DATA
            //====================================================

            WDATA  = DATA;
            WSTRB  = 4'b1111;
            WVALID = 1'b1;

            TIMEOUT = 0;

            while (!WREADY && TIMEOUT < 100)
            begin
                @(negedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            @(negedge ACLK);

            WVALID = 1'b0;


            //====================================================
            // HOLD BREADY LOW
            //====================================================

            BREADY = 1'b0;

            TIMEOUT = 0;

            while (!BVALID && TIMEOUT < 100)
            begin
                @(posedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            if (!BVALID)
            begin
                $display("DELAYED BREADY : FAIL");
                FAIL_COUNT = FAIL_COUNT + 1;
            end
            else
            begin

                $display("BVALID asserted while BREADY = 0");

                // BVALID must remain asserted
                for (i = 0; i < 4; i = i + 1)
                begin
                    @(posedge ACLK);

                    if (!BVALID)
                    begin
                        $display("BVALID dropped unexpectedly");
                        FAIL_COUNT = FAIL_COUNT + 1;
                    end
                end

                @(negedge ACLK);

                BREADY = 1'b1;

                @(posedge ACLK);

                if (BVALID)
                begin
                    // Response is consumed on this edge.
                    // Check next edge for BVALID low.
                    @(posedge ACLK);

                    if (!BVALID)
                    begin
                        $display("DELAYED BREADY : PASS");
                        PASS_COUNT = PASS_COUNT + 1;
                    end
                    else
                    begin
                        $display("DELAYED BREADY : FAIL");
                        FAIL_COUNT = FAIL_COUNT + 1;
                    end
                end

            end

            @(negedge ACLK);

            BREADY = 1'b0;

        end

    endtask


    //============================================================
    // DELAYED RREADY
    //============================================================

    task AXI_READ_DELAYED_RREADY;

        input  [ADDR_WIDTH-1:0] ADDR;
        output [DATA_WIDTH-1:0] DATA;

        integer i;
        integer TIMEOUT;

        begin

            $display("");
            $display("----------------------------------------");
            $display("DELAYED RREADY TEST");
            $display("----------------------------------------");


            //====================================================
            // READ ADDRESS
            //====================================================

            @(negedge ACLK);

            ARADDR  = ADDR;
            ARVALID = 1'b1;

            TIMEOUT = 0;

            while (!ARREADY && TIMEOUT < 100)
            begin
                @(negedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            @(negedge ACLK);

            ARVALID = 1'b0;


            //====================================================
            // HOLD RREADY LOW
            //====================================================

            RREADY = 1'b0;

            TIMEOUT = 0;

            while (!RVALID && TIMEOUT < 100)
            begin
                @(posedge ACLK);
                TIMEOUT = TIMEOUT + 1;
            end

            if (!RVALID)
            begin
                $display("DELAYED RREADY : FAIL");
                FAIL_COUNT = FAIL_COUNT + 1;

                DATA = 32'hXXXXXXXX;
            end
            else
            begin

                DATA = RDATA;

                $display("RVALID asserted while RREADY = 0");
                $display("RDATA = %h", RDATA);


                //================================================
                // RVALID MUST REMAIN HIGH
                //================================================

                for (i = 0; i < 4; i = i + 1)
                begin
                    @(posedge ACLK);

                    if (!RVALID)
                    begin
                        $display("RVALID dropped unexpectedly");
                        FAIL_COUNT = FAIL_COUNT + 1;
                    end
                end


                //================================================
                // NOW ACCEPT RESPONSE
                //================================================

                @(negedge ACLK);

                RREADY = 1'b1;

                @(posedge ACLK);

                if (RVALID)
                begin
                    @(posedge ACLK);

                    if (!RVALID)
                    begin
                        $display("DELAYED RREADY : PASS");
                        PASS_COUNT = PASS_COUNT + 1;
                    end
                    else
                    begin
                        $display("DELAYED RREADY : FAIL");
                        FAIL_COUNT = FAIL_COUNT + 1;
                    end
                end

            end

            @(negedge ACLK);

            RREADY = 1'b0;

        end

    endtask


    //============================================================
    // MAIN TEST SEQUENCE
    //============================================================

    initial
    begin

        // Wait until reset is released
        wait (ARESETn == 1'b1);

        repeat (2)
            @(negedge ACLK);


        $display("");
        $display("==============================================");
        $display("       AXI4-LITE SLAVE VERIFICATION");
        $display("==============================================");


        //========================================================
        // TEST 1 : SCRATCH REGISTER
        //========================================================

        AXI_WRITE(
            8'h18,
            32'h1234_5678,
            4'b1111
        );

        AXI_READ(
            8'h18,
            READ_DATA
        );

        if (READ_DATA == 32'h1234_5678)
        begin
            $display("TEST 1 : SCRATCH REGISTER : PASS");
            PASS_COUNT = PASS_COUNT + 1;
        end
        else
        begin
            $display("TEST 1 : SCRATCH REGISTER : FAIL");
            $display("Expected = 12345678");
            $display("Actual   = %h", READ_DATA);
            FAIL_COUNT = FAIL_COUNT + 1;
        end


        //========================================================
        // TEST 2 : DATA OUT
        //========================================================

        AXI_WRITE(
            8'h0C,
            32'hDEAD_BEEF,
            4'b1111
        );

        AXI_READ(
            8'h0C,
            READ_DATA
        );

        if (READ_DATA == 32'hDEAD_BEEF)
        begin
            $display("TEST 2 : DATA OUT : PASS");
            PASS_COUNT = PASS_COUNT + 1;
        end
        else
        begin
            $display("TEST 2 : DATA OUT : FAIL");
            FAIL_COUNT = FAIL_COUNT + 1;
        end


        //========================================================
        // TEST 3 : CONTROL REGISTER
        //========================================================

        AXI_WRITE(
            8'h00,
            32'h0000_0001,
            4'b1111
        );

        AXI_READ(
            8'h00,
            READ_DATA
        );

        if (READ_DATA == 32'h0000_0001)
        begin
            $display("TEST 3 : CONTROL : PASS");
            PASS_COUNT = PASS_COUNT + 1;
        end
        else
        begin
            $display("TEST 3 : CONTROL : FAIL");
            FAIL_COUNT = FAIL_COUNT + 1;
        end


        //========================================================
        // TEST 4 : VERSION REGISTER
        //========================================================

        AXI_READ(
            8'h1C,
            READ_DATA
        );

        if (READ_DATA == 32'h0001_0000)
        begin
            $display("TEST 4 : VERSION : PASS");
            PASS_COUNT = PASS_COUNT + 1;
        end
        else
        begin
            $display("TEST 4 : VERSION : FAIL");
            FAIL_COUNT = FAIL_COUNT + 1;
        end


        //========================================================
        // TEST 5 : BYTE STROBE
        //========================================================

        AXI_WRITE(
            8'h18,
            32'hAAAA_BBBB,
            4'b1111
        );

        AXI_WRITE(
            8'h18,
            32'hCCCC_DDDD,
            4'b0011
        );

        AXI_READ(
            8'h18,
            READ_DATA
        );

        if (READ_DATA == 32'hAAAA_DDDD)
        begin
            $display("TEST 5 : BYTE STROBE : PASS");
            PASS_COUNT = PASS_COUNT + 1;
        end
        else
        begin
            $display("TEST 5 : BYTE STROBE : FAIL");
            $display("Expected = AAAA_DDDD");
            $display("Actual   = %h", READ_DATA);
            FAIL_COUNT = FAIL_COUNT + 1;
        end


        //========================================================
        // TEST 6 : INTERRUPT GENERATION
        //========================================================

        AXI_WRITE(
            8'h10,
            32'h0000_0001,
            4'b1111
        );

        AXI_WRITE(
            8'h08,
            32'h5555_AAAA,
            4'b1111
        );

        @(negedge ACLK);

        if (IRQ == 1'b1)
        begin
            $display("TEST 6 : INTERRUPT GENERATION : PASS");
            PASS_COUNT = PASS_COUNT + 1;
        end
        else
        begin
            $display("TEST 6 : INTERRUPT GENERATION : FAIL");
            FAIL_COUNT = FAIL_COUNT + 1;
        end


        //========================================================
        // TEST 7 : INTERRUPT CLEAR
        //========================================================

        AXI_WRITE(
            8'h14,
            32'h0000_0001,
            4'b0001
        );

        @(negedge ACLK);

        if (IRQ == 1'b0)
        begin
            $display("TEST 7 : INTERRUPT CLEAR : PASS");
            PASS_COUNT = PASS_COUNT + 1;
        end
        else
        begin
            $display("TEST 7 : INTERRUPT CLEAR : FAIL");
            FAIL_COUNT = FAIL_COUNT + 1;
        end


        //========================================================
        // TEST 8 : AW BEFORE W
        //========================================================

        AXI_WRITE_AW_FIRST(
            8'h18,
            32'h1111_2222,
            4'b1111
        );

        AXI_READ(
            8'h18,
            READ_DATA
        );

        if (READ_DATA == 32'h1111_2222)
        begin
            $display("TEST 8 : AW BEFORE W : PASS");
            PASS_COUNT = PASS_COUNT + 1;
        end
        else
        begin
            $display("TEST 8 : AW BEFORE W : FAIL");
            FAIL_COUNT = FAIL_COUNT + 1;
        end


        //========================================================
        // TEST 9 : W BEFORE AW
        //========================================================

        AXI_WRITE_W_FIRST(
            8'h18,
            32'h3333_4444,
            4'b1111
        );

        AXI_READ(
            8'h18,
            READ_DATA
        );

        if (READ_DATA == 32'h3333_4444)
        begin
            $display("TEST 9 : W BEFORE AW : PASS");
            PASS_COUNT = PASS_COUNT + 1;
        end
        else
        begin
            $display("TEST 9 : W BEFORE AW : FAIL");
            FAIL_COUNT = FAIL_COUNT + 1;
        end


        //========================================================
        // TEST 10 : DELAYED BREADY
        //========================================================

        AXI_WRITE_DELAYED_BREADY(
            8'h18,
            32'h5555_6666
        );


        //========================================================
        // TEST 11 : DELAYED RREADY
        //========================================================

        AXI_READ_DELAYED_RREADY(
            8'h18,
            READ_DATA
        );


        //========================================================
        // TEST 12 : INVALID ADDRESS
        //========================================================

        $display("");
        $display("----------------------------------------");
        $display("INVALID ADDRESS TEST");
        $display("----------------------------------------");


        //========================================================
        // ADDRESS
        //========================================================

        @(negedge ACLK);

        AWADDR  = 8'h40;
        AWVALID = 1'b1;

        while (!AWREADY)
            @(negedge ACLK);

        @(negedge ACLK);

        AWVALID = 1'b0;


        //========================================================
        // DATA
        //========================================================

        WDATA  = 32'hAAAA_BBBB;
        WSTRB  = 4'b1111;
        WVALID = 1'b1;

        while (!WREADY)
            @(negedge ACLK);

        @(negedge ACLK);

        WVALID = 1'b0;


        //========================================================
        // RESPONSE
        //========================================================

        @(negedge ACLK);

        BREADY = 1'b1;

        while (!BVALID)
            @(posedge ACLK);

        if (BRESP == 2'b10)
        begin
            $display("TEST 12 : INVALID ADDRESS : PASS");
            $display("BRESP = SLVERR");
            PASS_COUNT = PASS_COUNT + 1;
        end
        else
        begin
            $display("TEST 12 : INVALID ADDRESS : FAIL");
            $display("Expected BRESP = 10");
            $display("Actual BRESP   = %b", BRESP);
            FAIL_COUNT = FAIL_COUNT + 1;
        end

        @(negedge ACLK);

        BREADY = 1'b0;


        //========================================================
        // FINAL SUMMARY
        //========================================================

        repeat (5)
            @(negedge ACLK);


        $display("");
        $display("==============================================");
        $display("          VERIFICATION SUMMARY");
        $display("==============================================");

        $display("TOTAL PASSED = %0d", PASS_COUNT);
        $display("TOTAL FAILED = %0d", FAIL_COUNT);


        if (FAIL_COUNT == 0)
        begin
            $display("");
            $display("==============================================");
            $display("       ALL TESTS PASSED SUCCESSFULLY");
            $display("==============================================");
        end
        else
        begin
            $display("");
            $display("==============================================");
            $display("          VERIFICATION FAILED");
            $display("==============================================");
        end


        $finish;

    end

endmodule
