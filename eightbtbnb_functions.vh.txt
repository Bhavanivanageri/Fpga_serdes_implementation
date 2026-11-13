// rd = 0: RD-
// rd = 1: RD+

function [5:0] enc_5b6b;
    input [4:0] x;
    input rd;
    reg [5:0] base;
    begin
        case (x)
            0 : base = 6'b100111;  1 : base = 6'b011101;
            2 : base = 6'b101101;  3 : base = 6'b110001;
            4 : base = 6'b110101;  5 : base = 6'b101001;
            6 : base = 6'b011001;  7 : base = 6'b111000;
            8 : base = 6'b111001;  9 : base = 6'b100101;
            10: base = 6'b010101; 11: base = 6'b110100;
            12: base = 6'b001101; 13: base = 6'b101100;
            14: base = 6'b011100; 15: base = 6'b010111;
            16: base = 6'b011011; 17: base = 6'b100011;
            18: base = 6'b010011; 19: base = 6'b110010;
            20: base = 6'b001011; 21: base = 6'b101010;
            22: base = 6'b011010; 23: base = 6'b111010;
            24: base = 6'b110011; 25: base = 6'b100110;
            26: base = 6'b010110; 27: base = 6'b110110;
            28: base = 6'b001110; 29: base = 6'b101110;
            30: base = 6'b011110; 31: base = 6'b101011;
            default: base = 6'b000000;
        endcase

        if (rd)
            enc_5b6b = ~base;
        else
            enc_5b6b = base;
    end
endfunction

function rd_after_6b;
    input rd;
    input [5:0] code;
    integer i;
    integer ones;
    begin
        ones = 0;
        for (i = 0; i < 6; i = i + 1)
            ones = ones + code[i];

        if (ones > 3)
            rd_after_6b = 1'b1;
        else if (ones < 3)
            rd_after_6b = 1'b0;
        else
            rd_after_6b = rd;
    end
endfunction

function [3:0] enc_3b4b;
    input [2:0] y;
    input [4:0] x;
    input rd;
    reg [3:0] base;
    begin
        base = 4'b0000;

        case (y)
            0: base = 4'b1011;
            1: base = 4'b1001;
            2: base = 4'b0101;
            3: base = 4'b1100;
            4: base = 4'b1101;
            5: base = 4'b1010;
            6: base = 4'b0110;

            7: begin
                if (((rd == 1'b0) &&
                    ((x == 17) || (x == 18) || (x == 20))) ||
                    ((rd == 1'b1) &&
                    ((x == 11) || (x == 13) || (x == 14)))) begin
                    if (rd)
                        enc_3b4b = 4'b1000;
                    else
                        enc_3b4b = 4'b0111;
                end
                else begin
                    if (rd)
                        enc_3b4b = 4'b0001;
                    else
                        enc_3b4b = 4'b1110;
                end
            end
        endcase

        if (y != 7) begin
            if (rd)
                enc_3b4b = ~base;
            else
                enc_3b4b = base;
        end
    end
endfunction

function rd_after_4b;
    input rd;
    input [3:0] code;
    integer i;
    integer ones;
    begin
        ones = 0;
        for (i = 0; i < 4; i = i + 1)
            ones = ones + code[i];

        if (ones > 2)
            rd_after_4b = 1'b1;
        else if (ones < 2)
            rd_after_4b = 1'b0;
        else
            rd_after_4b = rd;
    end
endfunction

function [9:0] encode_8b10b;
    input [7:0] data;
    input rd;
    reg [5:0] six;
    reg [3:0] four;
    reg rd6;
    begin
        six  = enc_5b6b(data[4:0], rd);
        rd6  = rd_after_6b(rd, six);
        four = enc_3b4b(data[7:5], data[4:0], rd6);

        encode_8b10b = {six, four};
    end
endfunction

function rd_after_10b;
    input [9:0] symbol;
    input rd;
    reg rd6;
    begin
        rd6 = rd_after_6b(rd, symbol[9:4]);
        rd_after_10b = rd_after_4b(rd6, symbol[3:0]);
    end
endfunction

// Output: bit [5] is valid, [4:0] is decoded x value
function [5:0] dec_5b6b;
    input [5:0] code;
    input rd;
    integer i;
    reg [5:0] result;
    begin
        result = 6'b000000;

        for (i = 0; i < 32; i = i + 1) begin
            if (code == enc_5b6b(i[4:0], rd))
                result = {1'b1, i[4:0]};
        end

        dec_5b6b = result;
    end
endfunction

// Output: bit [3] is valid, [2:0] is decoded y value
function [3:0] dec_3b4b;
    input [3:0] code;
    input [4:0] x;
    input rd;
    integer i;
    reg [3:0] result;
    begin
        result = 4'b0000;

        for (i = 0; i < 8; i = i + 1) begin
            if (code == enc_3b4b(i[2:0], x, rd))
                result = {1'b1, i[2:0]};
        end

        dec_3b4b = result;
    end
endfunction

// Output: bit [8] is valid, [7:0] is decoded byte
function [8:0] decode_8b10b;
    input [9:0] symbol;
    input rd;
    reg [5:0] decoded_x;
    reg [3:0] decoded_y;
    reg rd6;
    begin
        decoded_x = dec_5b6b(symbol[9:4], rd);
        rd6 = rd_after_6b(rd, symbol[9:4]);

        if (decoded_x[5]) begin
            decoded_y = dec_3b4b(symbol[3:0], decoded_x[4:0], rd6);

            if (decoded_y[3])
                decode_8b10b = {1'b1, decoded_y[2:0], decoded_x[4:0]};
            else
                decode_8b10b = 9'b000000000;
        end
        else begin
            decode_8b10b = 9'b000000000;
        end
    end
endfunction