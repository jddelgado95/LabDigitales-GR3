`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2017 10:29:57 PM
// Design Name: 
// Module Name: vga_sync
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


module vga_sync(
    input wire clk, reset, 
    output wire hsync, vsync, video_on, p_tick, 
    output wire [9:0] pixel_x, pixel_y // muestran la posición actual de los pixeles
   );
   // hsync es el tiempo necesario para todos los pixeles de una linea horizontal
   // vsync es el tiempo necesario para generar todas las líneas de una pantalla Entera

   // constant declaration
   // VGA 640-by-480 sync parameters
   localparam HD = 640; // horizontal display area
   localparam HF = 48 ; // h. front (left) border
   localparam HB = 16 ; // h. back (right) border
   localparam HR = 96 ; // h. retrace
   localparam VD = 480; // vertical display area
   localparam VF = 10;  // v. front (top) border
   localparam VB = 33;  // v. back (bottom) border
   localparam VR = 2;   // v. retrace

   // sync counters
   reg [9:0] h_count_reg, h_count_next; // registros para el contador horizontal
   reg [9:0] v_count_reg, v_count_next; // resgustros para el contador vertical
   // output buffer // buffer de salida para disminuir glitches y esto permite retrazar la señal de clk un ciclo 
   reg v_sync_reg, h_sync_reg;
   wire v_sync_next, h_sync_next;
   // status signal // Esto nos permite saber cuando la exploración horizontal y vertical se ha completado
   wire h_end, v_end;
   reg pixel_tick;// Almacena los 25MHz

   // body
   // registers
   
   always @(posedge clk, posedge reset) // siempre que haya un flanco positivo de reloj y un flaco positivo de reset
      if (reset)
         begin// me asigna valor por defecto de cero
            v_count_reg <= 0;
            h_count_reg <= 0;
            v_sync_reg <= 1'b0;
            h_sync_reg <= 1'b0;
         end
      else
         begin
          
            v_count_reg <= v_count_next;
            h_count_reg <= h_count_next;
            v_sync_reg <= v_sync_next;
            h_sync_reg <= h_sync_next;
         end



// Divisor de Frecuencia de 100 a 25 MHz

reg  divcounter = 0; // contador para el divisor de frecuencia 

//-- Contador módulo 4

always @(posedge clk, posedge reset)
  begin
    if (reset) pixel_tick <= 1'b0; 
    else if (divcounter == 1) 
        begin
        divcounter <= 0;
        pixel_tick <=~pixel_tick; // si el contador ha llehado a 1 entonces invierta la señal
        end
    else divcounter <= divcounter + 1;
    end

   // status signals // en estas lineas toman valores de 1 o 0, para indicar si la exploración se ha compltado
   // end of horizontal counter (799)
   assign h_end = (h_count_reg==(HD+HF+HB+HR-1));
   // end of vertical counter (524)
   assign v_end = (v_count_reg==(VD+VF+VB+VR-1));

   // next-state logic of mod-800 horizontal sync counter
   always @*
      if (pixel_tick)  // 25 MHz pulse
         if (h_end) // si la exploracion vertical se completó
            h_count_next = 0; //ponga el contador horizontal en cero
         else
            h_count_next = h_count_reg + 1; // si no siga contando
      else
         h_count_next = h_count_reg; 

   // next-state logic of mod-525 vertical sync counter
   always @* // si hay un pulso de reloj positivo y la exploración vertical ha terminado entonces ponga vcount next en cero
      if (pixel_tick & h_end)
         if (v_end)
            v_count_next = 0;
         else
            v_count_next = v_count_reg + 1;
      else
         v_count_next = v_count_reg;

   // horizontal and vertical sync, buffered to avoid glitch
   // h_sync_next asserted between 656 and 751
   assign h_sync_next = (h_count_reg>=(HD+HB) &&
                         h_count_reg<=(HD+HB+HR-1));
   // vh_sync_next asserted between 490 and 491
   assign v_sync_next = (v_count_reg>=(VD+VB) &&
                         v_count_reg<=(VD+VB+VR-1));

   // video on/off
   assign video_on = (h_count_reg<HD) && (v_count_reg<VD); // nos mantine la señal en alto si nos encontramos en la zona de display

   // output
   assign hsync = h_sync_reg;
   assign vsync = v_sync_reg;
   assign pixel_x = h_count_reg;
   assign pixel_y = v_count_reg;
   assign p_tick = pixel_tick;

endmodule