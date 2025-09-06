module ALSU_tb ();

reg [2:0] A,B,opcode;
reg cin,serial_in,direction;
reg red_op_A,red_op_B,bypass_A,bypass_B;
reg clk,rst;
wire [5:0] out;
wire [15:0] leds;

ALSU DUT(
    .A(A),
    .B(B),
    .opcode(opcode),
    .cin(cin),
    .serial_in(serial_in),
    .direction(direction),
    .red_op_A(red_op_A),
    .red_op_B(red_op_B),
    .bypass_A(bypass_A),
    .bypass_B(bypass_B),
    .clk(clk),
    .rst(rst),
    .out(out),
    .leds(leds)
);

integer i;
reg [5:0] expected;

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    //-------------------- 2.1 Verify Asynchronous rst Functionality --------------------
    rst = 1;
    A = 0; 
    B = 0;
    opcode = 0;
    cin = 0; 
    serial_in = 0; 
    direction = 0;
    red_op_A = 0; 
    red_op_B = 0;
    bypass_A = 0; 
    bypass_B = 0;

    @(negedge clk);

    if(out===6'b0 && leds===16'b0)
        $display("Async Reset Test -- PASS");
    else
        $display("Async Reset Test -- FAIL (out=%b leds=%b)",out,leds);
    $display("----------------------------------------------------------------");

    //-------------------- 2.2 Verify Bypass Functionality --------------------
    rst = 0;
    bypass_A=1;
    bypass_B=1;

    for(i=0;i<10;i=i+1) begin
        A=$random;
         B=$random;
        opcode=$urandom_range(3'b000,3'b101);

        @(negedge clk);

        expected = {3'b000,A};  // INPUT_PRIORITY = "A"

        if(out===expected && leds===16'b0)
             $display("Bypass %0d PASS : out=%b",i,out);
        else
             $display("Bypass %0d FAIL : out=%b expected=%b",i,out,expected);
    end
    $display("----------------------------------------------------------------");

    //-------------------- 2.3 Verify opcode 0 (AND & Reduction) --------------------
    bypass_A=0;
    bypass_B=0;
    opcode=3'b000;

    for(i=0;i<10;i=i+1) begin
        A = $random; 
        B = $random;
        red_op_A=$urandom_range(0,1);
        red_op_B=$urandom_range(0,1);

        repeat(2)@(negedge clk);

        if(red_op_A)     
          expected={5'b00000,^A};
        else if(red_op_B)
          expected={5'b00000,^B};
        else             
          expected={3'b000,(A&B)};

        if(out===expected && leds===16'b0)
          $display("OPCODE0 %0d PASS : out=%b",i,out);
        else
          $display("OPCODE0 %0d FAIL : out=%b expected=%b",i,out,expected);
    end
    $display("----------------------------------------------------------------");

    //-------------------- 2.4 Verify opcode 1 (XOR & Reduction) --------------------
    opcode=3'b001;

    for(i=0;i<10;i=i+1) begin
        A = $random; 
        B = $random;
        red_op_A = $urandom_range(0,1);
        red_op_B = $urandom_range(0,1);

        @(negedge clk);

        if(red_op_A)     
          expected={5'b00000,^A};
        else if(red_op_B)
          expected={5'b00000,^B};
        else             
          expected={3'b000,(A^B)};

        if(out===expected && leds===16'b0)
          $display("OPCODE1 %0d PASS : out=%b",i,out);
        else
          $display("OPCODE1 %0d FAIL : out=%b expected=%b",i,out,expected);
    end
    $display("----------------------------------------------------------------");

    //-------------------- 2.5 Verify opcode 2 (ADD) --------------------
    opcode=3'b010;
    red_op_A=0; 
    red_op_B=0;

    for(i=0;i<10;i=i+1) begin
        A = $random; 
        B = $random;
        cin = $urandom_range(0,1);

        @(negedge clk);

        expected = {3'b000,A} + {3'b000,B} + cin;

        if(out===expected && leds===16'b0)
          $display("OPCODE2 %0d PASS : out=%b",i,out);
        else
          $display("OPCODE2 %0d FAIL : out=%b expected=%b",i,out,expected);
    end
    $display("----------------------------------------------------------------");

    //-------------------- 2.6 Verify opcode 3 (MULTIPLY) --------------------
    opcode=3'b011;

    for(i=0;i<10;i=i+1) begin
        A = $random; 
        B = $random;

        @(negedge clk);

        expected = A * B;

        if(out===expected && leds===16'b0)
          $display("OPCODE3 %0d PASS : out=%b",i,out);
        else
          $display("OPCODE3 %0d FAIL : out=%b expected=%b",i,out,expected);
    end
    $display("----------------------------------------------------------------");

    //-------------------- 2.7 Verify opcode 4 (SHIFT) --------------------
    opcode=3'b100;

    for(i=0;i<5;i=i+1) begin
        A = $random;
        B = $random;
        direction = $urandom_range(0,1);
        serial_in = $urandom_range(0,1);

        @(negedge clk);

        $display("OPCODE4 Shift %0d : dir=%b serial=%b  out=%b",i,direction,serial_in,out);
    end
    $display("----------------------------------------------------------------");

    //-------------------- 2.8 Verify opcode 5 (ROTATE) --------------------
    opcode=3'b101;

    for(i=0;i<5;i=i+1) begin
        A = $random; 
        B = $random;
        direction = $urandom_range(0,1);
        serial_in = $urandom_range(0,1);

        @(negedge clk);

        $display("OPCODE5 Rotate %0d : dir=%b  out=%b",i,direction,out);
    end
    $display("----------------------------------------------------------------");

    $stop;
end

endmodule //ALSU_tb
