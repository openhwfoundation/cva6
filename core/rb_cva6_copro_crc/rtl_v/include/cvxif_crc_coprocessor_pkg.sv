// CRC definition

package cvxif_crc_coprocessor_pkg;
  parameter int unsigned MAX_CRC_SIZE = 32;
  parameter bit CRC_ENDIAN_SWAP = 1;
  // supported CRC sizes : 8, 16 ,32
  // --------------------
  typedef enum logic [1:0] {
    CRC8  = 2'b01,
    CRC16 = 2'b10,
    CRC32 = 2'b11
  } crc_size_e;

  typedef enum logic [1:0] {
    MASK0 = 2'b00,  // ......NN
    MASK1 = 2'b01,  // ....NNNN
    MASK2 = 2'b10,  // ..NNNNNN
    MASK3 = 2'b11   // NNNNNNNN
  } crc_mask_e;

  typedef enum logic [2:0] {
    IDLE,
    CRC8_1,
    CRC8_2,
    CRC16_1,
    CRC16_2,
    CRC32_1,
    CRC32_2
  } crc_coprocessor_state_e;


endpackage

