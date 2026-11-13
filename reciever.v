`timescale 1ns / 1ps

module serdes_receiver (
    input  wire       rx_clk,
    input  wire       rst,

    input  wire       rx_serial,
    input  wire       rx_serial_valid,

    output reg [7:0]  rx_data,
    output reg [7:0]  rx_crc,

    output reg        rx_data_valid,
    output reg        rx_crc_ok,
    output reg        rx_frame_error,
    output reg        rx_busy,

    // LEDs stay ON until reset or next completed frame
    output reg        crc_pass_led,
    output reg        crc_fail_led
);

`include "eightbtenb_functions.vh"

    reg [19:0] shift_reg;
    reg [4:0]  bit_count;

    wire [19:0] next_shift;
    wire [8:0] decoded_data_symbol;
    wire        rd_after_data;
    wire [8:0] decoded_crc_symbol;

    assign next_shift = {shift_reg[18:0], rx_serial};

    assign decoded_data_symbol =
        decode_8b10b(next_shift[19:10], 1'b0);

    assign rd_after_data =
        rd_after_10b(next_shift[19:10], 1'b0);

    assign decoded_crc_symbol =
        decode_8b10b(next_shift[9:0], rd_after_data);

    function [7:0] crc8_atm;
        input [7:0] data;
        integer i;
        reg [7:0] crc;
        begin
            crc = 8'h00;

            for (i = 0; i < 8; i = i + 1) begin
                if (crc[7] ^ data[7-i])
                    crc = {crc[6:0], 1'b0} ^ 8'h07;
                else
                    crc = {crc[6:0], 1'b0};
            end

            crc8_atm = crc;
        end
    endfunction

    always @(posedge rx_clk) begin
        if (rst) begin
            shift_reg      <= 20'h00000;
            bit_count      <= 5'd0;
            rx_data        <= 8'h00;
            rx_crc         <= 8'h00;
            rx_data_valid  <= 1'b0;
            rx_crc_ok      <= 1'b0;
            rx_frame_error <= 1'b0;
            rx_busy        <= 1'b0;
            crc_pass_led   <= 1'b0;
            crc_fail_led   <= 1'b0;
        end
        else begin
            rx_data_valid  <= 1'b0;
            rx_crc_ok      <= 1'b0;
            rx_frame_error <= 1'b0;

            if (!rx_serial_valid) begin
                shift_reg <= 20'h00000;
                bit_count <= 5'd0;
                rx_busy   <= 1'b0;
            end
            else begin
                shift_reg <= next_shift;
                rx_busy   <= 1'b1;

                if (bit_count == 5'd19) begin
                    bit_count <= 5'd0;
                    rx_busy   <= 1'b0;

                    rx_data <= decoded_data_symbol[7:0];
                    rx_crc  <= decoded_crc_symbol[7:0];

                    // Invalid 8b/10b symbol
                    if (!decoded_data_symbol[8] ||
                        !decoded_crc_symbol[8]) begin

                        rx_frame_error <= 1'b1;
                        crc_pass_led   <= 1'b0;
                        crc_fail_led   <= 1'b1;
                    end

                    // Correct data and CRC
                    else if (crc8_atm(decoded_data_symbol[7:0]) ==
                             decoded_crc_symbol[7:0]) begin

                        rx_data_valid <= 1'b1;
                        rx_crc_ok     <= 1'b1;
                        crc_pass_led  <= 1'b1;
                        crc_fail_led  <= 1'b0;
                    end

                    // Correct 8b/10b symbols, but CRC mismatch
                    else begin
                        rx_frame_error <= 1'b1;
                        crc_pass_led   <= 1'b0;
                        crc_fail_led   <= 1'b1;
                    end
                end
                else begin
                    bit_count <= bit_count + 1'b1;
                end
            end
        end
    end

endmodule 