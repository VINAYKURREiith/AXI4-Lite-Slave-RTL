`timescale 1ns / 1ps

module axi4lite_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input  wire                     ACLK,
    input  wire                     ARESETn,

    //========================================================
    // AXI4-Lite Write Address Channel
    //========================================================
    input  wire [ADDR_WIDTH-1:0]    AWADDR,
    input  wire                     AWVALID,
    output wire                     AWREADY,

    //========================================================
    // AXI4-Lite Write Data Channel
    //========================================================
    input  wire [DATA_WIDTH-1:0]    WDATA,
    input  wire [DATA_WIDTH/8-1:0]  WSTRB,
    input  wire                     WVALID,
    output wire                     WREADY,

    //========================================================
    // AXI4-Lite Write Response Channel
    //========================================================
    output reg  [1:0]               BRESP,
    output reg                      BVALID,
    input  wire                     BREADY,

    //========================================================
    // AXI4-Lite Read Address Channel
    //========================================================
    input  wire [ADDR_WIDTH-1:0]    ARADDR,
    input  wire                     ARVALID,
    output wire                     ARREADY,

    //========================================================
    // AXI4-Lite Read Data Channel
    //========================================================
    output reg  [DATA_WIDTH-1:0]    RDATA,
    output reg  [1:0]               RRESP,
    output reg                      RVALID,
    input  wire                     RREADY,

    //========================================================
    // Interrupt
    //========================================================
    output wire                     IRQ
);

    //========================================================
    // AXI Response Codes
    //========================================================

    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;

    //========================================================
    // Register Addresses
    //========================================================

    localparam [ADDR_WIDTH-1:0] ADDR_CONTROL    = 8'h00;
    localparam [ADDR_WIDTH-1:0] ADDR_STATUS     = 8'h04;
    localparam [ADDR_WIDTH-1:0] ADDR_DATA_IN    = 8'h08;
    localparam [ADDR_WIDTH-1:0] ADDR_DATA_OUT   = 8'h0C;
    localparam [ADDR_WIDTH-1:0] ADDR_IRQ_ENABLE = 8'h10;
    localparam [ADDR_WIDTH-1:0] ADDR_IRQ_STATUS = 8'h14;
    localparam [ADDR_WIDTH-1:0] ADDR_SCRATCH    = 8'h18;
    localparam [ADDR_WIDTH-1:0] ADDR_VERSION    = 8'h1C;

    //========================================================
    // Register Bank
    //========================================================

    reg [DATA_WIDTH-1:0] CONTROL_REG;
    reg [DATA_WIDTH-1:0] DATA_IN_REG;
    reg [DATA_WIDTH-1:0] DATA_OUT_REG;
    reg [DATA_WIDTH-1:0] IRQ_ENABLE_REG;
    reg [DATA_WIDTH-1:0] IRQ_STATUS_REG;
    reg [DATA_WIDTH-1:0] SCRATCH_REG;

    //========================================================
    // AXI Write Storage
    //========================================================

    reg [ADDR_WIDTH-1:0]   AWADDR_REG;
    reg                    AWADDR_VALID;

    reg [DATA_WIDTH-1:0]   WDATA_REG;
    reg [DATA_WIDTH/8-1:0] WSTRB_REG;
    reg                    WDATA_VALID;

    integer i;

    //========================================================
    // AXI READY Signals
    //========================================================

    assign AWREADY = (~AWADDR_VALID) && (~BVALID);

    assign WREADY  = (~WDATA_VALID) && (~BVALID);

    assign ARREADY = (~RVALID);

    //========================================================
    // Interrupt
    //========================================================

    assign IRQ = IRQ_ENABLE_REG[0] && IRQ_STATUS_REG[0];

    //========================================================
    // Write Register Task
    //========================================================

    task WRITE_REGISTER;

        input [ADDR_WIDTH-1:0]   ADDR;
        input [DATA_WIDTH-1:0]   DATA;
        input [DATA_WIDTH/8-1:0] STRB;

        begin

            case (ADDR)

                //================================================
                // CONTROL REGISTER
                //================================================

                ADDR_CONTROL:
                begin

                    for (i = 0; i < DATA_WIDTH/8; i = i + 1)
                    begin
                        if (STRB[i])
                            CONTROL_REG[i*8 +: 8] <= DATA[i*8 +: 8];
                    end

                end

                //================================================
                // DATA IN
                //================================================

                ADDR_DATA_IN:
                begin

                    for (i = 0; i < DATA_WIDTH/8; i = i + 1)
                    begin
                        if (STRB[i])
                            DATA_IN_REG[i*8 +: 8] <= DATA[i*8 +: 8];
                    end

                    // Generate interrupt event
                    IRQ_STATUS_REG[0] <= 1'b1;

                end

                //================================================
                // DATA OUT
                //================================================

                ADDR_DATA_OUT:
                begin

                    for (i = 0; i < DATA_WIDTH/8; i = i + 1)
                    begin
                        if (STRB[i])
                            DATA_OUT_REG[i*8 +: 8] <= DATA[i*8 +: 8];
                    end

                end

                //================================================
                // IRQ ENABLE
                //================================================

                ADDR_IRQ_ENABLE:
                begin

                    for (i = 0; i < DATA_WIDTH/8; i = i + 1)
                    begin
                        if (STRB[i])
                            IRQ_ENABLE_REG[i*8 +: 8] <= DATA[i*8 +: 8];
                    end

                end

                //================================================
                // IRQ STATUS
                // Write 1 -> Clear
                //================================================

                ADDR_IRQ_STATUS:
                begin

                    if (STRB[0])
                    begin
                        if (DATA[0])
                            IRQ_STATUS_REG[0] <= 1'b0;
                    end

                end

                //================================================
                // SCRATCH
                //================================================

                ADDR_SCRATCH:
                begin

                    for (i = 0; i < DATA_WIDTH/8; i = i + 1)
                    begin
                        if (STRB[i])
                            SCRATCH_REG[i*8 +: 8] <= DATA[i*8 +: 8];
                    end

                end

                default:
                begin
                    // Invalid address
                end

            endcase

        end

    endtask

    //========================================================
    // Read Register Function
    //========================================================

    function [DATA_WIDTH-1:0] READ_REGISTER;

        input [ADDR_WIDTH-1:0] ADDR;

        begin

            case (ADDR)

                ADDR_CONTROL:
                    READ_REGISTER = CONTROL_REG;

                ADDR_STATUS:
                    READ_REGISTER = {
                        29'b0,
                        IRQ_STATUS_REG[0],
                        (DATA_IN_REG != 32'b0),
                        CONTROL_REG[0]
                    };

                ADDR_DATA_IN:
                    READ_REGISTER = DATA_IN_REG;

                ADDR_DATA_OUT:
                    READ_REGISTER = DATA_OUT_REG;

                ADDR_IRQ_ENABLE:
                    READ_REGISTER = IRQ_ENABLE_REG;

                ADDR_IRQ_STATUS:
                    READ_REGISTER = IRQ_STATUS_REG;

                ADDR_SCRATCH:
                    READ_REGISTER = SCRATCH_REG;

                ADDR_VERSION:
                    READ_REGISTER = 32'h0001_0000;

                default:
                    READ_REGISTER = 32'h0000_0000;

            endcase

        end

    endfunction

    //========================================================
    // Main Sequential Logic
    //========================================================

    always @(posedge ACLK or negedge ARESETn)
    begin

        if (!ARESETn)
        begin

            //==================================================
            // AXI Write State
            //==================================================

            AWADDR_REG   <= {ADDR_WIDTH{1'b0}};
            AWADDR_VALID <= 1'b0;

            WDATA_REG    <= {DATA_WIDTH{1'b0}};
            WSTRB_REG    <= {(DATA_WIDTH/8){1'b0}};
            WDATA_VALID  <= 1'b0;

            BVALID       <= 1'b0;
            BRESP        <= RESP_OKAY;

            //==================================================
            // AXI Read State
            //==================================================

            RDATA        <= {DATA_WIDTH{1'b0}};
            RRESP        <= RESP_OKAY;
            RVALID       <= 1'b0;

            //==================================================
            // Registers
            //==================================================

            CONTROL_REG     <= 32'b0;
            DATA_IN_REG     <= 32'b0;
            DATA_OUT_REG    <= 32'b0;
            IRQ_ENABLE_REG  <= 32'b0;
            IRQ_STATUS_REG  <= 32'b0;
            SCRATCH_REG     <= 32'b0;

        end

        else
        begin

            //==================================================
            // Capture Write Address
            //==================================================

            if (AWVALID && AWREADY)
            begin

                AWADDR_REG   <= AWADDR;
                AWADDR_VALID <= 1'b1;

            end

            //==================================================
            // Capture Write Data
            //==================================================

            if (WVALID && WREADY)
            begin

                WDATA_REG   <= WDATA;
                WSTRB_REG   <= WSTRB;
                WDATA_VALID <= 1'b1;

            end

            //==================================================
            // Execute Write
            //==================================================

            if (AWADDR_VALID && WDATA_VALID && !BVALID)
            begin

                WRITE_REGISTER(
                    AWADDR_REG,
                    WDATA_REG,
                    WSTRB_REG
                );

                //================================================
                // Generate Response
                //================================================

                case (AWADDR_REG)

                    ADDR_CONTROL,
                    ADDR_DATA_IN,
                    ADDR_DATA_OUT,
                    ADDR_IRQ_ENABLE,
                    ADDR_IRQ_STATUS,
                    ADDR_SCRATCH:
                    begin

                        BRESP <= RESP_OKAY;

                    end

                    default:
                    begin

                        BRESP <= RESP_SLVERR;

                    end

                endcase

                BVALID <= 1'b1;

                AWADDR_VALID <= 1'b0;
                WDATA_VALID  <= 1'b0;

            end

            //==================================================
            // Write Response Handshake
            //==================================================

            if (BVALID && BREADY)
            begin

                BVALID <= 1'b0;

            end

            //==================================================
            // Read Address Handshake
            //==================================================

            if (ARVALID && ARREADY)
            begin

                RDATA <= READ_REGISTER(ARADDR);

                case (ARADDR)

                    ADDR_CONTROL,
                    ADDR_STATUS,
                    ADDR_DATA_IN,
                    ADDR_DATA_OUT,
                    ADDR_IRQ_ENABLE,
                    ADDR_IRQ_STATUS,
                    ADDR_SCRATCH,
                    ADDR_VERSION:
                    begin

                        RRESP <= RESP_OKAY;

                    end

                    default:
                    begin

                        RRESP <= RESP_SLVERR;

                    end

                endcase

                RVALID <= 1'b1;

            end

            //==================================================
            // Read Response Handshake
            //==================================================

            if (RVALID && RREADY)
            begin

                RVALID <= 1'b0;

            end

        end

    end

endmodule
