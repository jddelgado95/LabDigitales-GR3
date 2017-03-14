module Proyecto1(   //Inicio del proyecto  
    input reset, clk, //Variables de entradas clk, reset y los switches de los colores
    input wire [2:0] rgbswitches,
    output reg [2:0] rgb_text,//salida las senales VGA que van a la FPGA
    output wire hsync, vsync //Salidas de sincronizacion h y v
    );
    //Generador de sincronizacion 
    
       wire video_on; //video on es un cable que se va a encargar de habiltar y deshabilitar ciertas entradas
       wire [9:0] pixel_x, pixel_y; //pixeles verticales y horizontales
       wire clk25MPX; //cable encargado del divisor de clock
       reg clk_divisor; //clk_d
       reg [1:0] contador; //contador
       wire clk_dv; //clk_div
       
       //DIVISOR DE CLOCK y generacion del pulso pixel_tick (clk divisor, luego asignado a clk_dv)
       always @(posedge (clk), posedge (reset)) //que siempre inicie en flanco positivo, igual el reset
           begin
               if (reset == 1)
               begin //si reset empieza en 1 entonces el contador y la variable divisor de clock se inicializa en 0
                   contador <= 'b0;
                   clk_divisor <= 0;
               end
               else if (contador == 3) //sino ya el contador conto hasta 4 (4 porque incluye el 0)
               begin
                   clk_divisor <= 1; //el pulso de clk divisor se va a poner en 1 cada vez que el contador se reinice, este serie 
                   //nuestro pixel_tick. 
                   contador <= 'b0;        
               end
               else 
               begin
                   clk_divisor <= 0; //cuando el "pixel_tick" vuelva al flanco negativo entonces el contador aumenta en 1
                   //su cuenta
                   contador <= contador +1;
               end
           end
           assign clk_dv= clk_divisor; //se le asignan a la variable clk_div el pulso de clk_divisor (pixel_tick)
           
           // Declaracion de constantes, parametros delimitadores de la pantalla
              // VGA 640-by-480 
          localparam HD = 640; // Display horizontal
          localparam BP = 48 ; // h. BackPorch
          localparam FP = 16 ; // h. FrontPorch
          localparam HR = 96 ; // h. retrace
          localparam VD = 480; // Display vertical
          localparam FPRCH = 10;  // v. frontporch (top) border 33
          localparam VB = 33;  // v. Backtop 10
          localparam VR = 2;   // v. retrace
          
          reg [9:0] h_contador, v_contador; //cable reg con un contador horizontal y vertical
          reg v_sync, h_sync; 
          wire v_sync_next , h_sync_next;
              
              always @ (posedge (clk), posedge (reset))//igualmente que arriba siempre que empiece en flanco positivo (el clk y el 
              //reset), hara que las variables declaradas anteriormente se inicializan en 0
              begin
                  if (reset == 1)
                  begin
                      h_contador <= 'b0;
                      v_contador <= 'b0;
                      v_sync <= 'b0;
                      h_sync <= 'b0;
                  end
                  else if (clk_dv == 1) //Cada vez que haya un pulso de clk_div (pixel_tick) entonces el contador empieza a entrar 
                  //en el area de despliegue
                  begin
                      if (h_contador == (HD + BP + FP + HR -1))//esto indica que el contador esta en los limites del area horizontal
                      begin
                          h_contador <= 'b0;//entonces debe de desplegar 0s
                          if (v_contador == (VD + VB + FPRCH + VR -1)) //Limites verticales
                              v_contador <= 'b0; //debe de pintar ceros
                          else 
                              v_contador <= v_contador + 1;//suma 1 cuando acabe cada linea y suma 1 espacio hacia abajo
                      end
                      else 
                          h_contador <= h_contador + 1;//suma 1 cuando acaba cada linea y vuelve a empezar otra 
                          
                  end
                  else 
                  begin
                      h_contador <= h_contador;
                      v_contador <= v_contador;
                      h_sync <= h_sync_next;
                      v_sync <= v_sync_next;
                  end
                  
              end
              //Evita un glitch que la senal genera
               assign h_sync_next = ((h_contador >= 'd659) && (h_contador <= 'd751));//AND que es 1 cuando se cumplen esas comdiciones
               //eso quiere decir que se encuentra en los bordes horizontales y puede pasar de fila
               assign v_sync_next = ((v_contador >= 'd490) && (v_contador <= 'd491));//AND que es 1 cuando se cumpplen esas condiciones
               //cuando se encuentra en los limites verticales (porches), entonces puede pasar de fila
               
               // vedeo on on/of
               assign video_on = ((h_contador < HD) && (v_contador < VD));//video on es una AND que se va a cumplir cuando 
               //el contador este contando dentro del area de display               
               
               
               
               //salidas
               //asignacion de variables
               assign pixel_x = h_contador;
               assign pixel_y = v_contador;
               assign hsync = ~h_sync;
               assign vsync = ~v_sync;
               assign clk25MPX = clk_divisor;
          
       
       //Generador de caracteres 
       //Generador de caracteres
            //wire [2:0] rgbswitches;
           //wire [9:0] pixelx, pixely; 
           //reg [2:0] rgbtext;
       
       wire [2:0] lsbx; //bits menos significativos X
       wire [3:0] lsby; //menos significativos Y
       assign lsbx = ~pixel_x[2:0]; //3 de los pixel x que vienen del codigo anterior
       assign lsby = pixel_y[3:0]; //4 del pixel y
       
       reg [2:0] letter_rgb; //cable que se asignara a variables posteriormente
       
       
       wire [7:0] Data; //dato, va a trabajar para ubicar
       reg [1:0] as; //adress, encargada de formar una direccion
       
       // Limites donde se van a ubicar nuestras letras
       localparam jdxl = 296; //limite en x a la izq de la letra J(Diego)
       localparam jdxr = 303;// limite en x a la derecha de la letra J(Diego)
       localparam jcxl = 312;//limite en x a la izq de la letra J (Jean Carlos)
       localparam jcxr = 319;//Limite a la derecha de la letra J (jean Carlos)
       localparam Lxl = 328; //Lmite izq de la letra L (Luis Diego)
       localparam Lxr = 335;//Limite derecho de la letra L 
       //Limites top y bottom de las letras en Y, el de todos va a ser el mismo ya que todas tienen la misma altura
       localparam yt = 224; 
       localparam yb = 239;
       
       
       // letter output signals
       wire jdon, ldon, jcon; //variables que se asignara a proximas coordenadas 
       
       
       // CUERPO
       
        
       assign jdon = //la letra J de JD se va a habilitar cuando pixel x y pixel y este en las coordenas en x right y x left, y los Ys 
       (jdxl<=pixel_x) && (pixel_x<=jdxr) &&
       (yt<=pixel_y) && (pixel_y<=yb);
       
       assign jcon = //la letra J de Jeanca se va a habilitar cuando pixel x y pixel y este en las coordenas en x right y x left, y los Ys 
       (jcxl<=pixel_x) && (pixel_x<=jcxr) &&
       (yt<=pixel_y) && (pixel_y<=yb);
       
       assign ldon =//la letra L de LDiego se va a habilitar cuando pixel x y pixel y este en las coordenas en x right y x left, y los Ys 
       (Lxl<=pixel_x) && (pixel_x<=Lxr) &&
       (yt<=pixel_y) && (pixel_y<=yb);
       
       //Para las entradas
       always @* begin//Si las entradas se encuentran en estas posiciones entonces 
        if (jdon)
            as <= 2'b01; 
       else if (jcon)
            as <= 2'b10;
       else if (ldon)
            as <= 2'b11;
       else
            as <= 2'b00;   
       end
        
       ROM_font instancia(as,lsby,Data); 
       
       reg pixelbit;
       
       always @*
       case (lsbx)
       3'h0: pixelbit <= Data[0];
       3'h1: pixelbit <= Data[1];
       3'h2: pixelbit <= Data[2];
       3'h3: pixelbit <= Data[3];
       3'h4: pixelbit <= Data[4];
       3'h5: pixelbit <= Data[5];
       3'h6: pixelbit <= Data[6];
       3'h7: pixelbit <= Data[7];
       endcase
       
       
       always @*
       if (pixelbit)
       letter_rgb <= rgbswitches;
       else
       letter_rgb <= 3'b000;
       
       // rgb multiplexing circuit
       always @*
       if (~video_on)
       rgb_text = 3'b000; // blank 
       else if (jcon|ldon|jdon)  
       rgb_text = letter_rgb; 
       else
       rgb_text = 3'b000; // black background
       
       endmodule
       
       
       //ROM FONT
       
       module ROM_font(
           //input clk,
           input wire [1:0]as,
           input wire [3:0]lsby,
           output reg [7:0]data 
           );
       
           reg [7:0]adress;
       
           always @*
           adress <= {as,lsby};
       
           always @*
           case (adress)
                //code x00
                8'h00: data = 8'b00000000; // 
                8'h01: data = 8'b00000000; // 
                8'h02: data = 8'b00000000; // 
                8'h03: data = 8'b00000000; // 
                8'h04: data = 8'b00000000; // 
                8'h05: data = 8'b00000000; // 
                8'h06: data = 8'b00000000; // 
                8'h07: data = 8'b00000000; // 
                8'h08: data = 8'b00000000; // 
                8'h09: data = 8'b00000000; // 
                8'h0a: data = 8'b00000000; // 
                8'h0b: data = 8'b00000000; // 
                8'h0c: data = 8'b00000000; // 
                8'h0d: data = 8'b00000000; // 
                8'h0e: data = 8'b00000000; // 
                8'h0f: data = 8'b00000000; // 
                
                //codigo x01 J
                
                8'h010: data = 8'b00000000; // 
                8'h011: data = 8'b00000000; // 
                8'h012: data = 8'b00011110; //    ****
                8'h013: data = 8'b00001100; //     **
                8'h014: data = 8'b00001100; //     **
                8'h015: data = 8'b00001100; //     **
                8'h016: data = 8'b00001100; //     **
                8'h017: data = 8'b00001100; //     **
                8'h018: data = 8'b11001100; // **  **
                8'h019: data = 8'b11001100; // **  **
                8'h01a: data = 8'b11001100; // **  **
                8'h01b: data = 8'b01111000; //  ****
                8'h01c: data = 8'b00000000; // 
                8'h01d: data = 8'b00000000; // 
                8'h01e: data = 8'b00000000; // 
                8'h01f: data = 8'b00000000; // 
             
                //codigo x02 J
             
                8'h020: data = 8'b00000000; // 
                8'h021: data = 8'b00000000; // 
                8'h022: data = 8'b00011110; //    ****
                8'h023: data = 8'b00001100; //     **
                8'h024: data = 8'b00001100; //     **
                8'h025: data = 8'b00001100; //     **
                8'h026: data = 8'b00001100; //     **
                8'h027: data = 8'b00001100; //     **
                8'h028: data = 8'b11001100; // **  **
                8'h029: data = 8'b11001100; // **  **
                8'h02a: data = 8'b11001100; // **  **
                8'h02b: data = 8'b01111000; //  ****
                8'h02c: data = 8'b00000000; // 
                8'h02d: data = 8'b00000000; // 
                8'h02e: data = 8'b00000000; // 
                8'h02f: data = 8'b00000000; // 
                
                
                //code x03    L   
                11'h030: data = 8'b00000000; // 
                11'h031: data = 8'b00000000; // 
                11'h032: data = 8'b11110000; // ****
                11'h033: data = 8'b01100000; //  **
                11'h034: data = 8'b01100000; //  **
                11'h035: data = 8'b01100000; //  **
                11'h036: data = 8'b01100000; //  **
                11'h037: data = 8'b01100000; //  **
                11'h038: data = 8'b01100000; //  **
                11'h039: data = 8'b01100010; //  **   *
                11'h03a: data = 8'b01100110; //  **  **
                11'h03b: data = 8'b11111110; // *******
                11'h03c: data = 8'b00000000; // 
                11'h03d: data = 8'b00000000; // 
                11'h03e: data = 8'b00000000; // 
                11'h03f: data = 8'b00000000; //   
                default :data = 8'b00000000;
                endcase
       endmodule

    
    