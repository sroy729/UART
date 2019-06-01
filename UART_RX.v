////////////////////////////////////////////////////
// This file contains the UART Receiver.  This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  
// When receive is complete o_rx_dv will be
// driven high for one clock cycle.
// 
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 25 MHz Clock, 115200 baud UART
// (25000000)/(115200) = 217
 
module UART_RX
  #( parameter CLKS_PER_BIT = 217 )
  (
    input i_Clock,
    input i_RX_Serial,
    output o_RX_DV,
    output o_RX_Byte,
    
  );
  
  //states 
  parameter IDLE		 = 3'b000;
  parameter RX_START_BIT = 3'b001;
  parameter RX_DATA_BITS = 3'b010;
  parameter RX_STOP_BIT  = 3'b011;
  parameter CLEAR 		 = 3'b100;
  
  //reg and signals
  
  reg [2:0] r_SM_Main     = 0;
  reg [7:0] r_Clock_Count = 0;
  reg [2:0] r_Bit_Index   = 0;
  reg [7:0] r_RX_Byte     = 0;
  reg 		r_RX_DV       = 0;
  
  // Purpose: Control RX state Machine
  always @(posedge i_Clock)
    begin
      
      case(r_SM_Main)
        IDLE:
          begin
            r_RX_DV 	  <= 0;
            r_Clock_Count <= 0;
            r_Bit_Index   <= 0;
            
            if(i_RX_Serial == 1'b0)
              r_SM_Main <= RX_START_BIT;
            else
              r_SM_Main <= IDLE;
          end
        
        // case start bit  check for middle bit
        
        RX_START_BIT:
          begin
           if(r_Clock_Count == (CLKS_PER_BIT-1)/2)
            begin
              if(i_RX_Serial == 1'b0)
                begin
                  r_Clock_Count <= 0;//reset the counter after finding the middle
                  r_SM_Main <= RX_DATA_BITS;
                end
              else
                r_SM_Main <= IDLE;
              end
            else
             begin
               r_Clock_Count <= r_Clock_Count + 1;
               r_SM_Main 	 <= RX_DATA_BITS;
             end
          end
        
        //sampeling at CLKS_PER_BIT-1 clock cycles i.e the middle of the data bit
        
        RX_DATA_BITS :
          begin
            if(r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= RX_DATA_BITS;
              end 
            else
              begin
                r_Clock_Count <= 0;
                r_RX_Byte[r_Bit_Index] <= i_RX_Serial;
                
                //update bit index and go to the state initial
                if(r_Bit_Index < 7)
                  begin
                    r_Bit_Index <= r_Bit_Index +1;
                    r_SM_Main   <= RX_DATA_BIT;
                  end
                else
                  begin
                    r_Bit_Index <= 0;
                    r_SM_Main   <= RX_STOP_BIT;
                  end
              end
          end
        //Receive Stop bit
        
        RX_STOP_BIT:
          begin
            //wait for CLKS_PER_BIT -1 clock cycles to finish stop bit
            if(r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main 	  <= RX_STOP_BITS;
              end
            else
              begin
                r_RX_DV 	  <= 1'b1;
                r_Clock_Count <= 0;
                r_SM_Main 	  <= CLEAR;
              end
          end
        
      CLEAR :
        begin
          r_SM_Main <= IDLE;
          r_RX_DV   <= 1'b0;
        end
      
      
      default :
        r_SM_Main <= IDLE;
      
    endcase
  end    
  
  assign o_RX_DV   = r_RX_DV;
  assign o_RX_Byte = r_RX_Byte;
  
endmodule // UART_RX
              
              