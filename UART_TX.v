// This file contains UART Transmitter.
// This file is able to 
// transmit 8 bits of serial data, one start bit , one stop bit
// ans no parity bit 
// when the transmit is complete o+TX_Done will be 
//driven high for one clock cycle

// Set Parameter CLKS_PER_BIT(cpb) as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 25 MHz Clock, 115200 baud UART
// (25000000)/(115200) = 217
 
module UART_TX 
  #( parameter CLKS_PER_BIT = 217)
  (
    input      i_Clock ;
    input      i_TX_DV;
    input      i_TX_Byte;
    output 	   o_TX_Active;
    output reg o_TX_Serial;
    output	   o_TX_Done;
  );
  
  //states
  parameter IDLE 		  <= 3'b000;
  parameter TX_START_BIT  <= 3'b001;
  parameter TX_DATA_BITS  <= 3'b010;
  parameter TX_STOP_BIT   <= 3'b011;
  parameter CLEANUP       <= 3'b100;
  
  //internal connection and signals
  reg [2:0] r_SM_Main;
  reg [7:0] r_Clock_Count;
  reg [2:0] r_Bit_Index;
  reg [7:0] r_TX_Data;
  reg		r_TX_Done;
  reg		r_TX_Active;
  
  
  always @(posedge i_Clock)
    begin 
      case(r_SM_Main)
        IDLE:
          begin
            o_TX_Serial    <= 1'b1;
            r_TX_Done      <= 0;
            r_Bit_Index    <= 0;
            r_Clocck_Count <= 0;
            
            if(i_TX_DV == 1'b1)
              begin
                r_TX_Active <= 1'b1;
                r_TX_Data   <= i_TX_Byte;
                r_SM_Main   <= TX_START_BIT;
              end
            else
              r_SM_Main <= IDLE;
          end
        
        TX_STAR_BIT:
          begin
            o_TX_Serial <= 1'b0
            
            //wait for the start bit for cpb-1 clock cycle
            if(r_Clock_Count < CLKS_PER_BIT - 1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= TX_START_BIT;
              end
            
            else
              begin
                r_Clock_Count <= 0;
                r_SM_Main     <= TX_DATA_BITS;
              end
          end
        
        TX_DATA_BITS:
          begin
            o_TX_Serial <= r_TX_Data[r_bit_Index];
            
            if(r_Clock_Count < CLKS_PER_BIT - 1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= TX_DATA_BITS;
              end
            
            else
              begin
                r_Clock_Count <= 0;
                
                //Check if we recieve all the bits
                if(r_Bit_Index < 7)
                  begin 
                    r_Bit_Index <= r_Bit_Index + 1;
                    r_SM_Main   <= TX_DATA_BITS
                  end
                else
                  begin
                    r_Bit_Index <= 0;                    
                    r_SM_Main   <= TX_STOP_BIT;
                  end
              end
          end
        
        TX_STOP_BIT:
          begin

            o_TX_Serial <= 1'b1;
            
            if(r_Clock_Count < CLKS_PER_BIT)
              begin 
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= CLEANUP;
              end
            else 
              begin
                r_TX_Done     <= 1'b0;
                r_Clock_Count <= 0;
                r_SM_Main     <= CLEANUP;
                r_TX_Active   <= 1'b0;
              end            
              
          end
        
        CLEANUP:
          begin
            r_TX_Done <= 1'b0;
            r_SM_MAIN <= IDLE;
          end
        
        default:
          r_SM_MAIN <= IDLE;
        
      endcase
    end
  
  assign o_TX_Done   = r_TX_Done    ;
  assign o_TX_Active = r_TX_Active  ;
  
endmodule
            
          
                
        
            
            