`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2017 10:01:37 PM
// Design Name: 
// Module Name: Generador_FONT
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Generador_FONT(//declara las variables de entrada y salida
   input wire clk,//reloj del proyecto
   input wire video_on,//señal que indica cuando pintar
   input wire [9:0] pixel_x, pixel_y,//coordenadas
   output reg [2:0] rgb_text //salida del generador
  );

  // signal declaration
  wire [10:0] rom_addr;
  wire [6:0] char_addr;
  wire [3:0] row_addr;
  wire [2:0] bit_addr;
  wire [7:0] font_word;
  wire font_bit, text_bit_on;

  // body
  // instantiate font ROM
  ROM_font font_unit
     (.clk(clk), .addr(rom_addr), .data(font_word)); //aca la direccion de la ROM es formada por los 5 LSB del pixel x, y los 2 pixeles LSB de Y
  //data es lo que se va a desplegar en pantalla, 0 o 1
  // font ROM interface
  assign char_addr = {pixel_y[5:4], pixel_x[7:3]};// 7 MSB para localizar coordenadas en la ROM
  assign row_addr = pixel_y[3:0];//bits menos significativos de Y
  assign rom_addr = {char_addr, row_addr};//esta es la direccion del FONT ROM
  assign bit_addr = pixel_x[2:0];//3 LSB del pixel x, recorre los bits que conforma data
  assign font_bit = font_word[~bit_addr];
  // "on" region limited to top-left corner
  assign text_bit_on = (pixel_x[9:8]==0 && pixel_y[9:6]==0) ?//este cumple la condicion de pintar, por eso esa AND, ya que si alguna de esas coordenadas
  //no cumple, entonces pinta un cero 
                       font_bit : 1'b0;
  // rgb multiplexing circuit
  always @*//permite asegurar o "darle paso" a las lineas de que pinten
     if (~video_on)//si video on es cero pinte negro
        rgb_text = 3'b000; // blank
     else
        if (text_bit_on) // y si no, pinte 
           rgb_text = 3'b010;  // green
         else
           rgb_text = 3'b000;  // black

endmodule