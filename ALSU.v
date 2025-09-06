module ALSU (
    input [2:0] A,B,opcode,
    input cin,serial_in,direction,
    input red_op_A,red_op_B,bypass_A,bypass_B,
    input clk,rst,
    output reg [5:0] out,
    output reg [15:0] leds
);

parameter INPUT_PRIORITY = "A";  
parameter FULL_ADDER     = "ON"; 

reg [2:0] A_reg,B_reg,opcode_reg;
reg cin_reg,serial_in_reg,direction_reg;
reg red_op_A_reg,red_op_B_reg,bypass_A_reg,bypass_B_reg;

reg [5:0] out_shifted,out_rotated;
reg invalid_cases;

reg [24:0] blink_cnt;  
reg blink;

// ---------- REGISTER INPUTS ----------
always @(posedge clk or posedge rst) begin
    if(rst) begin
        A_reg <= 0;
        B_reg <= 0;
        opcode_reg <= 0;
        cin_reg <= 0;
        serial_in_reg <= 0;
        direction_reg <= 0;
        red_op_A_reg <= 0;
        red_op_B_reg <= 0;
        bypass_A_reg <= 0;
        bypass_B_reg <= 0;
    end else begin
        A_reg <= A;
        B_reg <= B;
        opcode_reg   <= opcode;  
        cin_reg      <= cin;
        serial_in_reg <= serial_in;
        direction_reg <= direction;
        red_op_A_reg <= red_op_A;
        red_op_B_reg <= red_op_B;
        bypass_A_reg <= bypass_A;
        bypass_B_reg <= bypass_B;
    end
end

// ---------- SHIFT / ROTATE ----------
always @(posedge clk) begin
    if(direction_reg) begin // left
        out_shifted <= {out[4:0], serial_in_reg};
        out_rotated <= {out[4:0], out[5]};
    end else begin          // right
        out_shifted <= {serial_in_reg, out[5:1]};
        out_rotated <= {out[0], out[5:1]};
    end
end
// ---------- MAIN ALSU (COMBINATIONAL) ----------
always @(*) begin
    out = 0;
    invalid_cases = 0;

    // FULL ADDER control
    if(FULL_ADDER == "ON")
        cin_reg = 1;
    else
        cin_reg = 0;

    if(INPUT_PRIORITY == "A") begin
        if(bypass_A_reg && bypass_B_reg)
            out = {3'b000, A_reg};
        else begin
            case(opcode_reg)
                3'b000: out = red_op_A_reg ? {5'b00000,^A_reg} :
                               red_op_B_reg ? {5'b00000,^B_reg} :
                               {3'b000,(A_reg & B_reg)};
                3'b001: out = red_op_A_reg ? {5'b00000,^A_reg} :
                               red_op_B_reg ? {5'b00000,^B_reg} :
                               {3'b000,(A_reg ^ B_reg)};
                3'b010: out = A_reg + B_reg + cin_reg;
                3'b011: out = A_reg * B_reg;
                3'b100: out = out_shifted;
                3'b101: out = out_rotated;
                3'b110,3'b111: invalid_cases = 1;
            endcase
        end
    end else begin // PRIORITY = B
        if(bypass_A_reg && bypass_B_reg)
            out = {3'b000, B_reg};
        else begin
            case(opcode_reg)
                3'b000: out = red_op_A_reg ? {5'b00000,^A_reg} :
                               red_op_B_reg ? {5'b00000,^B_reg} :
                               {3'b000,(A_reg & B_reg)};
                3'b001: out = red_op_A_reg ? {5'b00000,^A_reg} :
                               red_op_B_reg ? {5'b00000,^B_reg} :
                               {3'b000,(A_reg ^ B_reg)};
                3'b010: out = A_reg + B_reg + cin_reg;
                3'b011: out = A_reg * B_reg;
                3'b100: out = out_shifted;
                3'b101: out = out_rotated;
                3'b110,3'b111: invalid_cases = 1;
            endcase
        end
    end

    if((red_op_A_reg || red_op_B_reg) && !(opcode_reg==3'b000 || opcode_reg==3'b001))
        invalid_cases = 1;
end

// ---------- BLINK LEDs WHEN INVALID ----------
always @(posedge clk or posedge rst) begin
    if(rst) begin
        leds <= 0;
        blink_cnt <= 0;
        blink <= 0;
    end else if(invalid_cases) begin
        blink_cnt <= blink_cnt + 1;
        if(blink_cnt == 25_000_000) begin
            blink_cnt <= 0;
            blink <= ~blink;
        end
        leds <= {16{blink}};
    end else begin
        blink_cnt <= 0;
        blink <= 0;
        leds <= 16'b0;
    end
end


endmodule //ALSU
/**/