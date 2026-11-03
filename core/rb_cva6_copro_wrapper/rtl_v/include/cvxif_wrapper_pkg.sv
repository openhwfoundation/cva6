
package cvxif_wrapper_pkg;

  localparam int unsigned COPRO_NBR = 2;  //number of coprocessor
  localparam int unsigned COPRO_BITS_NBR = $clog2(
      COPRO_NBR
  );  //minimal number of bits for the number of coprocessor
  localparam int unsigned SAME_COPRO_NBR  = 0; // number of identical or same coprocessor, 0 or [2:COPRO_NBR]
  localparam int unsigned SCT_SIZE  = (SAME_COPRO_NBR == 0) ? 0 : SAME_COPRO_NBR-1; //

  localparam logic [COPRO_BITS_NBR:0] SAME_COPRO_TABLE[0:SCT_SIZE] = {'0};  // table containing index of the same coprocessor, not needed to parametrize if not using coprocessor

  localparam int unsigned DECODING_TYPE = 1;
  // 0 : using only opcode, by default if wrong value for DECODING_TYPE
  // 1 : using opcode and func2
  // 2 : using opcode and func3
  // 3 : using opcode, func3 and func2

  localparam int unsigned deco_LUT_size =   (DECODING_TYPE == 0) ? 2**2
                                          :  ((DECODING_TYPE == 1) ? 2**4
                                          :  ((DECODING_TYPE == 2) ? 2**5
                                          :  ((DECODING_TYPE == 3) ? 2**7 : 2**2)));

  // INDEX : It is the position where you have implemented your coprocessor.

  // Decoding look-up table : 
  // This LUT will be used by the decoder to give a index for an instruction, to fill this table do the following :
  // they are 8 position by opcode, because it also use func3, so first position (decoding_lookup_table[0][00000]) is for custom0 and func3 = 000, second for custom0 and func3 = 001
  // and it goes on until custom3 and func3 = 111
  // So if a coprocessor can process an instruction put it index in the corresponding position
  // if an instruction is not supoported by any coprocessor, put COPRO_NBR (or numerical value) in it.
  // if an instruction is supported by same coprocessors, put SAME_COPRO_TABLE[0] (or the numerical value) in it
  // custom0  |  custom1  |  custom2  |  custom3  
  localparam logic [COPRO_BITS_NBR:0] decoding_LUT[0:deco_LUT_size-1] = {
    1, 2, 2, 2, 2, 0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2
  };

  // Lookup table to handle issue_resp
  //This LUT use coprocessor index to know which value will be used
  //                                                 { copro2  ,  copro1  }
  localparam logic [5:0] i_resp_LUT[COPRO_NBR-1:0] = {6'b110000, 6'b110000};

endpackage
