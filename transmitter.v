`timescale 1ns / 1ps

module serdes_transmitter (
    input  wire       clk,
    input  wire       rst,
    input  wire       data_valid,
    input  wire [7:0] data_in,

    // 0 = normal CRC, 1 = deliberately corrupt one CRC bit
    input  wire       force_crc_error,

    output reg        tx_serial,
    output reg        tx_serial_valid,
    output reg        tx_busy,
    output wire       tx_bit_clk,

    // Debug outputs
    output reg [7:0]  tx_crc,
    output reg [9:0]  tx_encoded
);

`include "eightbtenb_functions.vh"

    reg [19:0] shift_reg;
    reg [4:0]  bit_count;
    reg        sending;
    reg        data_valid_d;

    reg [7:0] crc_value;
    reg [7:0] crc_to_send;
    reg [9:0] data_symbol;
    reg [9:0] crc_symbol;
    reg       rd_after_data;

    assign tx_bit_clk = clk;

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

    // TX updates serial data at falling edge.
    // RX samples serial data at next rising edge.
    always @(negedge clk) begin
        if (rst) begin
            tx_serial       <= 1'b0;
            tx_serial_valid <= 1'b0;
            tx_busy         <= 1'b0;
            tx_crc          <= 8'h00;
            tx_encoded      <= 10'h000;
            shift_reg       <= 20'h00000;
            bit_count       <= 5'd0;
            sending         <= 1'b0;
            data_valid_d    <= 1'b0;
        end
        else begin
            data_valid_d <= data_valid;

            if (!sending) begin
                tx_serial       <= 1'b0;
                tx_serial_valid <= 1'b0;
                tx_busy         <= 1'b0;

                // Rising edge of data_valid starts one 20-bit frame.
                if (data_valid && !data_valid_d) begin
                    // Real CRC, displayed on transmitter LEDs.
                    crc_value = crc8_atm(data_in);
                    tx_crc <= crc_value;

                    // Optional deliberate CRC corruption.
                    if (force_crc_error)
                        crc_to_send = crc_value ^ 8'h01;
                    else
                        crc_to_send = crc_value;

                    // Every frame begins with RD-.
                    data_symbol   = encode_8b10b(data_in, 1'b0);
                    rd_after_data = rd_after_10b(data_symbol, 1'b0);
                    crc_symbol    = encode_8b10b(crc_to_send, rd_after_data);

                    tx_encoded <= data_symbol;

                    // Data symbol first, CRC symbol second.
                    shift_reg <= {data_symbol, crc_symbol};
                    bit_count <= 5'd0;
                    sending   <= 1'b1;
                    tx_busy   <= 1'b1;
                end
            end
            else begin
                tx_serial       <= shift_reg[19];
                tx_serial_valid <= 1'b1;
                shift_reg       <= {shift_reg[18:0], 1'b0};

                if (bit_count == 5'd19) begin
                    bit_count <= 5'd0;
                    sending   <= 1'b0;
                    tx_busy   <= 1'b0;
                end
                else begin
                    bit_count <= bit_count + 1'b1;
                end
            end
        end
    end

endmodule