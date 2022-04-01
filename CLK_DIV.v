// Clock divider
// use a switch to select cpu clock speed

`timescale 1ns / 1ps

module CLK_DIV(
  input clk,
  input rst,
  input SW15,
  output Clk_CPU
);
  reg[31:0]clkdiv;

  always @(posedge clk or posedge rst) begin 
    if (rst)
      clkdiv <= 0;
    else
      clkdiv <= clkdiv + 1'b1;
  end

  assign Clk_CPU=(SW15)? clkdiv[23] : clkdiv;  // SW15 to select slow cpu clock or fast cpu clk

endmodule
