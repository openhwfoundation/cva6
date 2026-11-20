// Copyright (c) 2024 PlanV Technologies
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Description: Intel FPGA top-level based on the existing Xilinx top-level designed by ETH Zurich and University of Bologna.
// Author: Angela Gonzalez, PlanV Technology

`include "rvfi_types.svh"
`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "src/agilex7.svh"


module cva6_altera (
// WARNING: Do not define input parameters. This causes the FPGA build to fail.
 input wire           pll_ref_clk_p , // 33.333 MHz on Agilex 7
 input wire           pll_ref_clk_n ,
 input  logic         cpu_resetn  ,

 input  wire          clk_ddr4_ch0_p,
 input  wire          clk_ddr4_ch0_n,
 inout  wire  [71:0]  ddr4_dq     , //data
 inout  wire  [ 8:0]  ddr4_dqs_n  , //data strobe
 inout  wire  [ 8:0]  ddr4_dqs_p  ,
 inout  wire  [ 8:0]  ddr4_dbi_n  , //bus inversion / data mask
 output logic [ 1:0]  ddr4_ba     , //bank address
 output logic [ 1:0]  ddr4_bg     , //bank group
 output logic         ddr4_reset_n,
 output logic [ 0:0]  ddr4_ck_p   ,
 output logic [ 0:0]  ddr4_ck_n   ,
 output logic [ 16:0] ddr4_a      , //address
 output logic [ 0:0]  ddr4_act_n  , //activation command
 output logic [ 0:0]  ddr4_cke    ,
 output logic [ 0:0]  ddr4_cs_n   , //chip select
 output logic [ 0:0]  ddr4_odt    , //on die termination
 output logic [ 0:0]  ddr4_par    , //parity
 input  logic [ 0:0]  ddr4_alert_n,
 input  logic         oct_rzqin   ,
 
 output logic [ 3:0]  led ,
 //HPS
// HPS EMIF
output   wire [0:0]    emif_hps_mem_mem_ck,
output   wire [0:0]    emif_hps_mem_mem_ck_n,
output   wire [16:0]   emif_hps_mem_mem_a,
output   wire [0:0]    emif_hps_mem_mem_act_n,
output   wire [1:0]    emif_hps_mem_mem_ba,
output   wire [1:0]    emif_hps_mem_mem_bg,
output   wire [0:0]    emif_hps_mem_mem_cke,
output   wire [0:0]    emif_hps_mem_mem_cs_n,
output   wire [0:0]    emif_hps_mem_mem_odt,
output   wire [0:0]    emif_hps_mem_mem_reset_n,
output   wire [0:0]    emif_hps_mem_mem_par,
input    wire [0:0]    emif_hps_mem_mem_alert_n,
input    wire          emif_hps_oct_oct_rzqin,
input    wire          emif_hps_pll_ref_clk_p,
inout    wire [8-1:0]  emif_hps_mem_mem_dbi_n,
inout    wire [64-1:0] emif_hps_mem_mem_dq,
inout    wire [8-1:0]  emif_hps_mem_mem_dqs,
inout    wire [8-1:0]  emif_hps_mem_mem_dqs_n,
input    wire          hps_jtag_tck,
input    wire          hps_jtag_tms,
output   wire          hps_jtag_tdo,
input    wire          hps_jtag_tdi,
output   wire          hps_sdmmc_CCLK, 
inout    wire          hps_sdmmc_CMD,          
inout    wire          hps_sdmmc_D0,          
inout    wire          hps_sdmmc_D1,          
inout    wire          hps_sdmmc_D2,        
inout    wire          hps_sdmmc_D3,        
output   wire          hps_emac0_TX_CLK,       
input    wire          hps_emac0_RX_CLK,      
output   wire          hps_emac0_TX_CTL,
input    wire          hps_emac0_RX_CTL,      
output   wire          hps_emac0_TXD0,       
output   wire          hps_emac0_TXD1,
input    wire          hps_emac0_RXD0,     
input    wire          hps_emac0_RXD1,                
output   wire          hps_emac0_TXD2,        
output   wire          hps_emac0_TXD3,
input    wire          hps_emac0_RXD2,        
input    wire          hps_emac0_RXD3, 
inout    wire          hps_emac0_MDIO,         
output   wire          hps_emac0_MDC,
input    wire          hps_uart0_RX,       
output   wire          hps_uart0_TX, 
inout    wire          hps_i2c1_SDA,        
inout    wire          hps_i2c1_SCL,
inout    wire          hps_gpio1_io0,
input    wire          hps_ref_clk        
);

// CVA6 Intel configuration
function automatic config_pkg::cva6_cfg_t build_fpga_config(config_pkg::cva6_user_cfg_t CVA6UserCfg);
  config_pkg::cva6_user_cfg_t cfg = CVA6UserCfg;
  cfg.RVZiCond = bit'(0);
  cfg.NrNonIdempotentRules = unsigned'(1);
  cfg.NonIdempotentAddrBase = 1024'({64'b0});
  cfg.NonIdempotentLength = 1024'({ariane_soc::DRAMBase});
  return build_config_pkg::build_config(cfg);
endfunction

// CVA6 Intel configuration
localparam config_pkg::cva6_cfg_t CVA6Cfg = build_fpga_config(cva6_config_pkg::cva6_cfg);

localparam type rvfi_probes_instr_t = `RVFI_PROBES_INSTR_T(CVA6Cfg);
localparam type rvfi_probes_csr_t = `RVFI_PROBES_CSR_T(CVA6Cfg);
localparam type rvfi_probes_t = struct packed {
  logic csr;
  rvfi_probes_instr_t instr;
};
  
// WARNING: If NBSlave is modified, Xilinx's IPs under fpga/xilinx need to be updated with the new AXI id width and regenerated.
// Otherwise reads and writes to DRAM may be returned to the wrong master and the crossbar will freeze. See issue #568.
localparam NBSlave = 2; // debug, ariane
localparam AxiAddrWidth = 64;
localparam AxiDataWidth = 64;
localparam AxiIdWidthMaster = 5;
localparam AxiIdWidthSlaves = AxiIdWidthMaster + $clog2(NBSlave); // 5
localparam AxiUserWidth = CVA6Cfg.AxiUserWidth;

// 64 kByte 
localparam NumWords = (32 * 1024 * 8) / AxiDataWidth;
localparam USE_SRAM = 0; // By default the design uses the DDR, set this parameter to use internal SRAM instead

`AXI_TYPEDEF_ALL(axi_slave,
                 logic [    AxiAddrWidth-1:0],
                 logic [AxiIdWidthSlaves-1:0],
                 logic [    AxiDataWidth-1:0],
                 logic [(AxiDataWidth/8)-1:0],
                 logic [    AxiUserWidth-1:0])

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_ID_WIDTH   ( AxiIdWidthMaster ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) slave[NBSlave-1:0]();

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) master[ariane_soc::NB_PERIPHERALS:0]();

AXI_BUS #(
    .AXI_ADDR_WIDTH ( CVA6Cfg.XLEN      ),
    .AXI_DATA_WIDTH ( CVA6Cfg.XLEN      ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) master_to_dm[0:0]();

// disable test-enable
logic test_en;
logic ndmreset;
logic ndmreset_n;
logic debug_req_irq;
logic timer_irq;
logic ipi;

logic clk;
logic eth_clk;
logic spi_clk_i;
logic phy_tx_clk;
logic sd_clk_sys;

logic ddr_sync_reset;
logic ddr_clock_out;

logic rst_n, rst;
logic rtc;

// we need to switch reset polarity 
logic cpu_reset;
assign cpu_reset  = ~cpu_resetn;

logic pll_locked;

// ROM
logic                    rom_req;
logic [AxiAddrWidth-1:0] rom_addr;
logic [AxiDataWidth-1:0] rom_rdata;

// Debug
logic          debug_req_valid;
logic          debug_req_ready;
dm::dmi_req_t  debug_req;
logic          debug_resp_valid;
logic          debug_resp_ready;
dm::dmi_resp_t debug_resp;

logic dmactive;

// IRQ
logic [1:0] irq;
assign test_en    = 1'b0;

logic [NBSlave-1:0] pc_asserted;

rstgen i_rstgen_main (
    .clk_i        ( clk                      ),
    .rst_ni       ( pll_locked & cal_success & (~ndmreset) ),
    .test_mode_i  ( test_en                  ),
    .rst_no       ( ndmreset_n               ),
    .init_no      (                          ) // keep open
);

assign rst_n = ddr_sync_reset;
assign rst = ~ddr_sync_reset;

// ---------------
// AXI Xbar
// ---------------

axi_pkg::xbar_rule_64_t [ariane_soc::NB_PERIPHERALS:0] addr_map;

assign addr_map = '{
  '{ idx: ariane_soc::Debug,    start_addr: ariane_soc::DebugBase,    end_addr: ariane_soc::DebugBase + ariane_soc::DebugLength       },
  '{ idx: ariane_soc::ROM,      start_addr: ariane_soc::ROMBase,      end_addr: ariane_soc::ROMBase + ariane_soc::ROMLength           },
  '{ idx: ariane_soc::CLINT,    start_addr: ariane_soc::CLINTBase,    end_addr: ariane_soc::CLINTBase + ariane_soc::CLINTLength       },
  '{ idx: ariane_soc::PLIC,     start_addr: ariane_soc::PLICBase,     end_addr: ariane_soc::PLICBase + ariane_soc::PLICLength         },
  '{ idx: ariane_soc::UART,     start_addr: ariane_soc::UARTBase,     end_addr: ariane_soc::UARTBase + ariane_soc::UARTLength         },
  '{ idx: ariane_soc::Timer,    start_addr: ariane_soc::TimerBase,    end_addr: ariane_soc::TimerBase + ariane_soc::TimerLength       },
  '{ idx: ariane_soc::SPI,      start_addr: ariane_soc::SPIBase,      end_addr: ariane_soc::SPIBase + ariane_soc::SPILength           },
  '{ idx: ariane_soc::Ethernet, start_addr: ariane_soc::EthernetBase, end_addr: ariane_soc::EthernetBase + ariane_soc::EthernetLength },
  '{ idx: ariane_soc::GPIO,     start_addr: ariane_soc::GPIOBase,     end_addr: ariane_soc::GPIOBase + ariane_soc::GPIOLength         },
  '{ idx: ariane_soc::DRAM,     start_addr: ariane_soc::DRAMBase,     end_addr: ariane_soc::DRAMBase + ariane_soc::DRAMLength         },
  '{ idx: ariane_soc::HPS,      start_addr: ariane_soc::HPSBase,      end_addr: ariane_soc::HPSBase + ariane_soc::HPSLength           }
};

localparam axi_pkg::xbar_cfg_t AXI_XBAR_CFG = '{
  NoSlvPorts:         ariane_soc::NrSlaves,
  NoMstPorts:         ariane_soc::NB_PERIPHERALS+1,
  MaxMstTrans:        1, // Probably requires update
  MaxSlvTrans:        1, // Probably requires update
  FallThrough:        1'b0,
  LatencyMode:        axi_pkg::CUT_ALL_PORTS,
  AxiIdWidthSlvPorts: AxiIdWidthMaster,
  AxiIdUsedSlvPorts:  AxiIdWidthMaster,
  UniqueIds:          1'b0,
  AxiAddrWidth:       AxiAddrWidth,
  AxiDataWidth:       AxiDataWidth,
  NoAddrRules:        ariane_soc::NB_PERIPHERALS+1
};

axi_xbar_intf #(
  .AXI_USER_WIDTH ( AxiUserWidth            ),
  .Cfg            ( AXI_XBAR_CFG            ),
  .rule_t         ( axi_pkg::xbar_rule_64_t )
) i_axi_xbar (
  .clk_i                 ( clk        ),
  .rst_ni                ( ndmreset_n ),
  .test_i                ( test_en    ),
  .slv_ports             ( slave      ),
  .mst_ports             ( master     ),
  .addr_map_i            ( addr_map   ),
  .en_default_mst_port_i ( '0         ),
  .default_mst_port_i    ( '0         )
);

// ---------------
// Debug Module
// ---------------

logic vjtag_tdi, vjtag_tdo, vjtag_tck, vjtag_tms, vjtag_tlr, vjtag_cdr, vjtag_sdr, vjtag_udr;
logic [9:0] vjtag_ir_i;

vJTAG vJTAG_inst (
    .tdi                (vjtag_tdi),                //  output,  width = 1, jtag.tdi
    .tdo                (vjtag_tdo),                //   input,  width = 1,     .tdo
    .ir_in              (vjtag_ir_i),              //  output,  width = 5,     .ir_in
    .ir_out             ('0),             //   input,  width = 5,     .ir_out
    .virtual_state_cdr  (vjtag_cdr),  //  output,  width = 1,     .virtual_state_cdr
    .virtual_state_sdr  (vjtag_sdr),  //  output,  width = 1,     .virtual_state_sdr
    .virtual_state_udr  (vjtag_udr),  //  output,  width = 1,     .virtual_state_udr
    .tms                (vjtag_tms),                //  output,  width = 1,     .tms
    .jtag_state_tlr     (vjtag_tlr),     //  output,  width = 1,     .jtag_state_tlr
    .tck                (vjtag_tck)                 //  output,  width = 1,  tck.clk
);

dmi_vjtag #(
    .IrLength ( 10 ),
    // .IdcodeValue ( 32'hC341A0DD)
    .IdcodeValue ( 32'h249511C3)
  ) i_dmi_jtag (
    .clk_i             (clk),
    .rst_ni            (rst_n),
    .testmode_i        (1'b0),
    // JTAG
    .tck_i                (vjtag_tck),
    .trst_ni              (1'b1),
    .td_i                 (vjtag_tdi),
    .td_o                 (vjtag_tdo),
    .tdo_oe_o             (),
    .ir_in_i              (vjtag_ir_i),
    .jtag_state_tlr_i     (vjtag_tlr),
    .virtual_state_cdr_i  (vjtag_cdr),
    .virtual_state_sdr_i  (vjtag_sdr),
    .virtual_state_udr_i  (vjtag_udr),
    // DMI
    .dmi_rst_no        (),
    .dmi_req_o         (debug_req),
    .dmi_req_valid_o   (debug_req_valid),
    .dmi_req_ready_i   (debug_req_ready),
    .dmi_resp_i        (debug_resp),
    .dmi_resp_ready_o  (debug_resp_ready),
    .dmi_resp_valid_i  (debug_resp_valid)
  );


ariane_axi::req_t    dm_axi_m_req;
ariane_axi::resp_t   dm_axi_m_resp;


logic                      dm_slave_req;
logic                      dm_slave_we;
logic [CVA6Cfg.XLEN-1:0]    dm_slave_addr;
logic [CVA6Cfg.XLEN/8-1:0]  dm_slave_be;
logic [CVA6Cfg.XLEN-1:0]    dm_slave_wdata;
logic [CVA6Cfg.XLEN-1:0]    dm_slave_rdata;

logic                      dm_master_req;
logic [CVA6Cfg.XLEN-1:0]    dm_master_add;
logic                      dm_master_we;
logic [CVA6Cfg.XLEN-1:0]    dm_master_wdata;
logic [CVA6Cfg.XLEN/8-1:0]  dm_master_be;
logic                      dm_master_gnt;
logic                      dm_master_r_valid;
logic [CVA6Cfg.XLEN-1:0]    dm_master_r_rdata;

// debug module
dm_top #(
    .NrHarts          ( 1                 ),
    .BusWidth         ( CVA6Cfg.XLEN      ),
    .SelectableHarts  ( 1'b1              )
) i_dm_top (
    .clk_i            ( clk               ),
    .rst_ni           ( rst_n             ), // PoR
    .testmode_i       ( test_en           ),
    .ndmreset_o       ( ndmreset          ),
    .dmactive_o       ( dmactive          ), // active debug session
    .debug_req_o      ( debug_req_irq     ),
    .unavailable_i    ( '0                ),
    .hartinfo_i       ( {ariane_pkg::DebugHartInfo} ),
    .slave_req_i      ( dm_slave_req      ),
    .slave_we_i       ( dm_slave_we       ),
    .slave_addr_i     ( dm_slave_addr     ),
    .slave_be_i       ( dm_slave_be       ),
    .slave_wdata_i    ( dm_slave_wdata    ),
    .slave_rdata_o    ( dm_slave_rdata    ),
    .master_req_o     ( dm_master_req     ),
    .master_add_o     ( dm_master_add     ),
    .master_we_o      ( dm_master_we      ),
    .master_wdata_o   ( dm_master_wdata   ),
    .master_be_o      ( dm_master_be      ),
    .master_gnt_i     ( dm_master_gnt     ),
    .master_r_valid_i ( dm_master_r_valid ),
    .master_r_rdata_i ( dm_master_r_rdata ),
    .dmi_rst_ni       ( rst_n             ),
    .dmi_req_valid_i  ( debug_req_valid   ),
    .dmi_req_ready_o  ( debug_req_ready   ),
    .dmi_req_i        ( debug_req         ),
    .dmi_resp_valid_o ( debug_resp_valid  ),
    .dmi_resp_ready_i ( debug_resp_ready  ),
    .dmi_resp_o       ( debug_resp        )
);

axi2mem #(
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves    ),
    .AXI_ADDR_WIDTH ( CVA6Cfg.XLEN        ),
    .AXI_DATA_WIDTH ( CVA6Cfg.XLEN        ),
    .AXI_USER_WIDTH ( AxiUserWidth        )
) i_dm_axi2mem (
    .clk_i      ( clk                       ),
    .rst_ni     ( rst_n                     ),
    .slave      ( master_to_dm[0]           ),
    .req_o      ( dm_slave_req              ),
    .we_o       ( dm_slave_we               ),
    .addr_o     ( dm_slave_addr             ),
    .be_o       ( dm_slave_be               ),
    .data_o     ( dm_slave_wdata            ),
    .data_i     ( dm_slave_rdata            )
);

if (CVA6Cfg.IS_XLEN32) begin

    assign master_to_dm[0].aw_user = '0;
    assign master_to_dm[0].w_user = '0;
    assign master_to_dm[0].ar_user = '0;

    assign master_to_dm[0].aw_id = dm_axi_m_req.aw.id;
    assign master_to_dm[0].ar_id = dm_axi_m_req.ar.id;

    assign master[ariane_soc::Debug].r_user ='0;
    assign master[ariane_soc::Debug].b_user ='0;

   axi_dw_adapter  #(
    .ADDR_WIDTH            (CVA6Cfg.XLEN),
    .S_DATA_WIDTH          (AxiAddrWidth),
    .M_DATA_WIDTH          (CVA6Cfg.XLEN),
    .ID_WIDTH              (AxiIdWidthSlaves)
    )i_axi_dwidth_converter_dm_slave(
       .clk(clk),
       .rst(~ndmreset_n),
       .s_axi_awid(master[ariane_soc::Debug].aw_id),
       .s_axi_awaddr(master[ariane_soc::Debug].aw_addr[31:0]),
       .s_axi_awlen(master[ariane_soc::Debug].aw_len),
       .s_axi_awsize(master[ariane_soc::Debug].aw_size),
       .s_axi_awburst(master[ariane_soc::Debug].aw_burst),
       .s_axi_awlock(master[ariane_soc::Debug].aw_lock),
       .s_axi_awcache(master[ariane_soc::Debug].aw_cache),
       .s_axi_awprot(master[ariane_soc::Debug].aw_prot),
       .s_axi_awregion(master[ariane_soc::Debug].aw_region),
       .s_axi_awqos(master[ariane_soc::Debug].aw_qos),
       .s_axi_awvalid(master[ariane_soc::Debug].aw_valid),
       .s_axi_awready(master[ariane_soc::Debug].aw_ready),
       .s_axi_wdata(master[ariane_soc::Debug].w_data),
       .s_axi_wstrb(master[ariane_soc::Debug].w_strb),
       .s_axi_wlast(master[ariane_soc::Debug].w_last),
       .s_axi_wvalid(master[ariane_soc::Debug].w_valid),
       .s_axi_wready(master[ariane_soc::Debug].w_ready),
       .s_axi_bid(master[ariane_soc::Debug].b_id),
       .s_axi_bresp(master[ariane_soc::Debug].b_resp),
       .s_axi_bvalid(master[ariane_soc::Debug].b_valid),
       .s_axi_bready(master[ariane_soc::Debug].b_ready),
       .s_axi_arid(master[ariane_soc::Debug].ar_id),
       .s_axi_araddr(master[ariane_soc::Debug].ar_addr[31:0]),
       .s_axi_arlen(master[ariane_soc::Debug].ar_len),
       .s_axi_arsize(master[ariane_soc::Debug].ar_size),
       .s_axi_arburst(master[ariane_soc::Debug].ar_burst),
       .s_axi_arlock(master[ariane_soc::Debug].ar_lock),
       .s_axi_arcache(master[ariane_soc::Debug].ar_cache),
       .s_axi_arprot(master[ariane_soc::Debug].ar_prot),
       .s_axi_arregion(master[ariane_soc::Debug].ar_region),
       .s_axi_arqos(master[ariane_soc::Debug].ar_qos),
       .s_axi_arvalid(master[ariane_soc::Debug].ar_valid),
       .s_axi_arready(master[ariane_soc::Debug].ar_ready),
       .s_axi_rid(master[ariane_soc::Debug].r_id),
       .s_axi_rdata(master[ariane_soc::Debug].r_data),
       .s_axi_rresp(master[ariane_soc::Debug].r_resp),
       .s_axi_rlast(master[ariane_soc::Debug].r_last),
       .s_axi_rvalid(master[ariane_soc::Debug].r_valid),
       .s_axi_rready(master[ariane_soc::Debug].r_ready),
       .m_axi_awaddr(master_to_dm[0].aw_addr),
       .m_axi_awlen(master_to_dm[0].aw_len),
       .m_axi_awsize(master_to_dm[0].aw_size),
       .m_axi_awburst(master_to_dm[0].aw_burst),
       .m_axi_awlock(master_to_dm[0].aw_lock),
       .m_axi_awcache(master_to_dm[0].aw_cache),
       .m_axi_awprot(master_to_dm[0].aw_prot),
       .m_axi_awregion(master_to_dm[0].aw_region),
       .m_axi_awqos(master_to_dm[0].aw_qos),
       .m_axi_awvalid(master_to_dm[0].aw_valid),
       .m_axi_awready(master_to_dm[0].aw_ready),
       .m_axi_wdata(master_to_dm[0].w_data ),
       .m_axi_wstrb(master_to_dm[0].w_strb),
       .m_axi_wlast(master_to_dm[0].w_last),
       .m_axi_wvalid(master_to_dm[0].w_valid),
       .m_axi_wready(master_to_dm[0].w_ready),
       .m_axi_bresp(master_to_dm[0].b_resp),
       .m_axi_bvalid(master_to_dm[0].b_valid),
       .m_axi_bready(master_to_dm[0].b_ready),
       .m_axi_araddr(master_to_dm[0].ar_addr),
       .m_axi_arlen(master_to_dm[0].ar_len),
       .m_axi_arsize(master_to_dm[0].ar_size),
       .m_axi_arburst(master_to_dm[0].ar_burst),
       .m_axi_arlock(master_to_dm[0].ar_lock),
       .m_axi_arcache(master_to_dm[0].ar_cache),
       .m_axi_arprot(master_to_dm[0].ar_prot),
       .m_axi_arregion(master_to_dm[0].ar_region),
       .m_axi_arqos(master_to_dm[0].ar_qos),
       .m_axi_arvalid(master_to_dm[0].ar_valid),
       .m_axi_arready(master_to_dm[0].ar_ready),
       .m_axi_rdata(master_to_dm[0].r_data),
       .m_axi_rresp(master_to_dm[0].r_resp),
       .m_axi_rlast(master_to_dm[0].r_last),
       .m_axi_rvalid(master_to_dm[0].r_valid),
       .m_axi_rready(master_to_dm[0].r_ready)
   );

end else begin

    assign master_to_dm[0].aw_id   = master[ariane_soc::Debug].aw_id;
    assign master_to_dm[0].aw_addr = master[ariane_soc::Debug].aw_addr;
    assign master_to_dm[0].aw_len  = master[ariane_soc::Debug].aw_len;
    assign master_to_dm[0].aw_size = master[ariane_soc::Debug].aw_size;
    assign master_to_dm[0].aw_burst= master[ariane_soc::Debug].aw_burst;
    assign master_to_dm[0].aw_lock = master[ariane_soc::Debug].aw_lock;
    assign master_to_dm[0].aw_cache= master[ariane_soc::Debug].aw_cache;
    assign master_to_dm[0].aw_prot = master[ariane_soc::Debug].aw_prot;
    assign master_to_dm[0].aw_qos  = master[ariane_soc::Debug].aw_qos;
    assign master_to_dm[0].aw_atop = master[ariane_soc::Debug].aw_atop;
    assign master_to_dm[0].aw_region = master[ariane_soc::Debug].aw_region;
    assign master_to_dm[0].aw_user = master[ariane_soc::Debug].aw_user;
    assign master_to_dm[0].aw_valid= master[ariane_soc::Debug].aw_valid;

    assign master[ariane_soc::Debug].aw_ready = master_to_dm[0].aw_ready;

    assign master_to_dm[0].w_data = master[ariane_soc::Debug].w_data;
    assign master_to_dm[0].w_strb = master[ariane_soc::Debug].w_strb;
    assign master_to_dm[0].w_last = master[ariane_soc::Debug].w_last;
    assign master_to_dm[0].w_user = master[ariane_soc::Debug].w_user;
    assign master_to_dm[0].w_valid= master[ariane_soc::Debug].w_valid;

    assign master[ariane_soc::Debug].w_ready = master_to_dm[0].w_ready;

    assign master[ariane_soc::Debug].b_id = master_to_dm[0].b_id;
    assign master[ariane_soc::Debug].b_resp = master_to_dm[0].b_resp;
    assign master[ariane_soc::Debug].b_user = master_to_dm[0].b_user;
    assign master[ariane_soc::Debug].b_valid= master_to_dm[0].b_valid;

    assign master_to_dm[0].b_ready = master[ariane_soc::Debug].b_ready;

    assign master_to_dm[0].ar_id = master[ariane_soc::Debug].ar_id;
    assign master_to_dm[0].ar_addr = master[ariane_soc::Debug].ar_addr;
    assign master_to_dm[0].ar_len = master[ariane_soc::Debug].ar_len;
    assign master_to_dm[0].ar_size = master[ariane_soc::Debug].ar_size;
    assign master_to_dm[0].ar_burst = master[ariane_soc::Debug].ar_burst;
    assign master_to_dm[0].ar_lock = master[ariane_soc::Debug].ar_lock;
    assign master_to_dm[0].ar_cache = master[ariane_soc::Debug].ar_cache;
    assign master_to_dm[0].ar_prot = master[ariane_soc::Debug].ar_prot;
    assign master_to_dm[0].ar_qos = master[ariane_soc::Debug].ar_qos;
    assign master_to_dm[0].ar_region = master[ariane_soc::Debug].ar_region;
    assign master_to_dm[0].ar_user = master[ariane_soc::Debug].ar_user;
    assign master_to_dm[0].ar_valid = master[ariane_soc::Debug].ar_valid;

    assign master[ariane_soc::Debug].ar_ready = master_to_dm[0].ar_ready;

    assign master[ariane_soc::Debug].r_id = master_to_dm[0].r_id;
    assign master[ariane_soc::Debug].r_data = master_to_dm[0].r_data;
    assign master[ariane_soc::Debug].r_resp = master_to_dm[0].r_resp;
    assign master[ariane_soc::Debug].r_last = master_to_dm[0].r_last;
    assign master[ariane_soc::Debug].r_user = master_to_dm[0].r_user;
    assign master[ariane_soc::Debug].r_valid = master_to_dm[0].r_valid;

    assign master_to_dm[0].r_ready = master[ariane_soc::Debug].r_ready;

end



logic [1:0]    axi_adapter_size;

assign axi_adapter_size = CVA6Cfg.IS_XLEN64 ? 2'b11 : 2'b10;

axi_adapter #(
    .CVA6Cfg               ( CVA6Cfg                  ),
    .DATA_WIDTH            ( CVA6Cfg.XLEN              ),
    .axi_req_t             ( ariane_axi::req_t        ),
    .axi_rsp_t             ( ariane_axi::resp_t       )
) i_dm_axi_master (
    .clk_i                 ( clk                       ),
    .rst_ni                ( rst_n                     ),
    .req_i                 ( dm_master_req             ),
    .type_i                ( ariane_pkg::SINGLE_REQ    ),
    .amo_i                 ( ariane_pkg::AMO_NONE      ),
    .gnt_o                 ( dm_master_gnt             ),
    .addr_i                ( dm_master_add             ),
    .we_i                  ( dm_master_we              ),
    .wdata_i               ( dm_master_wdata           ),
    .be_i                  ( dm_master_be              ),
    .size_i                ( axi_adapter_size          ),
    .id_i                  ( '0                        ),
    .valid_o               ( dm_master_r_valid         ),
    .rdata_o               ( dm_master_r_rdata         ),
    .id_o                  (                           ),
    .critical_word_o       (                           ),
    .critical_word_valid_o (                           ),
    .axi_req_o             ( dm_axi_m_req              ),
    .axi_resp_i            ( dm_axi_m_resp             )
);

if (CVA6Cfg.IS_XLEN32) begin
    logic [31 : 0] dm_master_m_awaddr;
    logic [31 : 0] dm_master_m_araddr;

    assign slave[1].aw_addr = {32'h0000_0000, dm_master_m_awaddr};
    assign slave[1].ar_addr = {32'h0000_0000, dm_master_m_araddr};

    logic [31 : 0] dm_master_s_rdata;

    assign dm_axi_m_resp.r.data = {32'h0000_0000, dm_master_s_rdata};

    assign slave[1].aw_user = '0;
    assign slave[1].w_user = '0;
    assign slave[1].ar_user = '0;

    assign slave[1].aw_id = dm_axi_m_req.aw.id;
    assign slave[1].ar_id = dm_axi_m_req.ar.id;
    assign slave[1].aw_atop = dm_axi_m_req.aw.atop;

   axi_dw_adapter #(
    .ADDR_WIDTH            (CVA6Cfg.XLEN),
    .S_DATA_WIDTH          (CVA6Cfg.XLEN),
    .M_DATA_WIDTH          (AxiAddrWidth),
    .ID_WIDTH              (AxiIdWidthMaster)
    ) i_axi_dwidth_converter_dm_master(
       .clk(clk),
       .rst(~ndmreset_n),
       .s_axi_awid(dm_axi_m_req.aw.id),
       .s_axi_awaddr(dm_axi_m_req.aw.addr[31:0]),
       .s_axi_awlen(dm_axi_m_req.aw.len),
       .s_axi_awsize(dm_axi_m_req.aw.size),
       .s_axi_awburst(dm_axi_m_req.aw.burst),
       .s_axi_awlock(dm_axi_m_req.aw.lock),
       .s_axi_awcache(dm_axi_m_req.aw.cache),
       .s_axi_awprot(dm_axi_m_req.aw.prot),
       .s_axi_awregion(dm_axi_m_req.aw.region),
       .s_axi_awqos(dm_axi_m_req.aw.qos),
       .s_axi_awvalid(dm_axi_m_req.aw_valid),
       .s_axi_awready(dm_axi_m_resp.aw_ready),
       .s_axi_wdata(dm_axi_m_req.w.data[31:0]),
       .s_axi_wstrb(dm_axi_m_req.w.strb[3:0]),
       .s_axi_wlast(dm_axi_m_req.w.last),
       .s_axi_wvalid(dm_axi_m_req.w_valid),
       .s_axi_wready(dm_axi_m_resp.w_ready),
       .s_axi_bid(dm_axi_m_resp.b.id),
       .s_axi_bresp(dm_axi_m_resp.b.resp),
       .s_axi_bvalid(dm_axi_m_resp.b_valid),
       .s_axi_bready(dm_axi_m_req.b_ready),
       .s_axi_arid(dm_axi_m_req.ar.id),
       .s_axi_araddr(dm_axi_m_req.ar.addr[31:0]),
       .s_axi_arlen(dm_axi_m_req.ar.len),
       .s_axi_arsize(dm_axi_m_req.ar.size),
       .s_axi_arburst(dm_axi_m_req.ar.burst),
       .s_axi_arlock(dm_axi_m_req.ar.lock),
       .s_axi_arcache(dm_axi_m_req.ar.cache),
       .s_axi_arprot(dm_axi_m_req.ar.prot),
       .s_axi_arregion(dm_axi_m_req.ar.region),
       .s_axi_arqos(dm_axi_m_req.ar.qos),
       .s_axi_arvalid(dm_axi_m_req.ar_valid),
       .s_axi_arready(dm_axi_m_resp.ar_ready),
       .s_axi_rid(dm_axi_m_resp.r.id),
       .s_axi_rdata(dm_master_s_rdata),
       .s_axi_rresp(dm_axi_m_resp.r.resp),
       .s_axi_rlast(dm_axi_m_resp.r.last),
       .s_axi_rvalid(dm_axi_m_resp.r_valid),
       .s_axi_rready(dm_axi_m_req.r_ready),
       .m_axi_awaddr(dm_master_m_awaddr),
       .m_axi_awlen(slave[1].aw_len),
       .m_axi_awsize(slave[1].aw_size),
       .m_axi_awburst(slave[1].aw_burst),
       .m_axi_awlock(slave[1].aw_lock),
       .m_axi_awcache(slave[1].aw_cache),
       .m_axi_awprot(slave[1].aw_prot),
       .m_axi_awregion(slave[1].aw_region),
       .m_axi_awqos(slave[1].aw_qos),
       .m_axi_awvalid(slave[1].aw_valid),
       .m_axi_awready(slave[1].aw_ready),
       .m_axi_wdata(slave[1].w_data ),
       .m_axi_wstrb(slave[1].w_strb),
       .m_axi_wlast(slave[1].w_last),
       .m_axi_wvalid(slave[1].w_valid),
       .m_axi_wready(slave[1].w_ready),
       .m_axi_bresp(slave[1].b_resp),
       .m_axi_bvalid(slave[1].b_valid),
       .m_axi_bready(slave[1].b_ready),
       .m_axi_araddr(dm_master_m_araddr),
       .m_axi_arlen(slave[1].ar_len),
       .m_axi_arsize(slave[1].ar_size),
       .m_axi_arburst(slave[1].ar_burst),
       .m_axi_arlock(slave[1].ar_lock),
       .m_axi_arcache(slave[1].ar_cache),
       .m_axi_arprot(slave[1].ar_prot),
       .m_axi_arregion(slave[1].ar_region),
       .m_axi_arqos(slave[1].ar_qos),
       .m_axi_arvalid(slave[1].ar_valid),
       .m_axi_arready(slave[1].ar_ready),
       .m_axi_rdata(slave[1].r_data),
       .m_axi_rresp(slave[1].r_resp),
       .m_axi_rlast(slave[1].r_last),
       .m_axi_rvalid(slave[1].r_valid),
       .m_axi_rready(slave[1].r_ready)
     );
end else begin
    `AXI_ASSIGN_FROM_REQ(slave[1], dm_axi_m_req)
    `AXI_ASSIGN_TO_RESP(dm_axi_m_resp, slave[1])
end


// ---------------
// Core
// ---------------
ariane_axi::req_t    axi_ariane_req;
ariane_axi::resp_t   axi_ariane_resp;

ariane #(
    .CVA6Cfg ( CVA6Cfg ),
    .rvfi_probes_t ( rvfi_probes_t )
) i_ariane (
    .clk_i        ( clk                 ),
    .rst_ni       ( ndmreset_n          ),
    .boot_addr_i  ( ariane_soc::ROMBase ), // start fetching from ROM
    .hart_id_i    ( '0                  ),
    .irq_i        ( irq                 ),
    .ipi_i        ( ipi                 ),
    .time_irq_i   ( timer_irq           ),
    .rvfi_probes_o( /* open */          ),
    .debug_req_i  ( debug_req_irq       ),
    .noc_req_o    ( axi_ariane_req      ),
    .noc_resp_i   ( axi_ariane_resp     )
);

`AXI_ASSIGN_FROM_REQ(slave[0], axi_ariane_req)
`AXI_ASSIGN_TO_RESP(axi_ariane_resp, slave[0])

// ---------------
// CLINT
// ---------------
// divide clock by two
always_ff @(posedge clk or negedge ndmreset_n) begin
  if (~ndmreset_n) begin
    rtc <= 0;
  end else begin
    rtc <= rtc ^ 1'b1;
  end
end

axi_slave_req_t  axi_clint_req;
axi_slave_resp_t axi_clint_resp;

clint #(
    .CVA6Cfg        ( CVA6Cfg          ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .NR_CORES       ( 1                ),
    .axi_req_t      ( axi_slave_req_t  ),
    .axi_resp_t     ( axi_slave_resp_t )
) i_clint (
    .clk_i       ( clk            ),
    .rst_ni      ( ndmreset_n     ),
    .testmode_i  ( test_en        ),
    .axi_req_i   ( axi_clint_req  ),
    .axi_resp_o  ( axi_clint_resp ),
    .rtc_i       ( rtc            ),
    .timer_irq_o ( timer_irq      ),
    .ipi_o       ( ipi            )
);

`AXI_ASSIGN_TO_REQ(axi_clint_req, master[ariane_soc::CLINT])
`AXI_ASSIGN_FROM_RESP(master[ariane_soc::CLINT], axi_clint_resp)

// ---------------
// ROM
// ---------------
axi2mem #(
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) i_axi2rom (
    .clk_i  ( clk                     ),
    .rst_ni ( ndmreset_n              ),
    .slave  ( master[ariane_soc::ROM] ),
    .req_o  ( rom_req                 ),
    .we_o   (                         ),
    .addr_o ( rom_addr                ),
    .be_o   (                         ),
    .data_o (                         ),
    .data_i ( rom_rdata               )
);

if (CVA6Cfg.IS_XLEN32) begin
    bootrom_32 i_bootrom (
        .clk_i   ( clk       ),
        .req_i   ( rom_req   ),
        .addr_i  ( rom_addr  ),
        .rdata_o ( rom_rdata )
    );
end else begin
    bootrom_64 i_bootrom (
        .clk_i   ( clk       ),
        .req_i   ( rom_req   ),
        .addr_i  ( rom_addr  ),
        .rdata_o ( rom_rdata )
    );
end

// ---------------
// Peripherals
// ---------------

  logic [7:0] unused_led;


logic clk_200MHz_ref;

cva6_peripherals #(
    .AxiAddrWidth ( AxiAddrWidth     ),
    .AxiDataWidth ( AxiDataWidth     ),
    .AxiIdWidth   ( AxiIdWidthSlaves ),
    .AxiUserWidth ( AxiUserWidth     ),
    .InclUART     ( 1'b1             ),
    .InclGPIO     ( 1'b1             ),
	.InclSPI      ( 1'b0         ),
    .InclEthernet ( 1'b0         )
) i_ariane_peripherals (
    .clk_i        ( clk                          ),
    .clk_200MHz_i ( clk_200MHz_ref               ),
    .rst_ni       ( ndmreset_n                   ),
    .plic         ( master[ariane_soc::PLIC]     ),
    .uart         ( master[ariane_soc::UART]     ),
    .spi          ( master[ariane_soc::SPI]      ),
    .gpio         ( master[ariane_soc::GPIO]     ),
    .eth_clk_i    ( eth_clk                      ),
    .ethernet     ( master[ariane_soc::Ethernet] ),
    .timer        ( master[ariane_soc::Timer]    ),
    .irq_o        ( irq                          ),
    // .rx_i         ( rx                           ),
    // .tx_o         ( tx                           ),
//    .eth_txck,
//    .eth_rxck,
//    .eth_rxctl,
//    .eth_rxd,
//    .eth_rst_n,
//    .eth_txctl,
//    .eth_txd,
//    .eth_mdio,
//    .eth_mdc,
    .phy_tx_clk_i   ( phy_tx_clk                  ),
    .sd_irq       ( sd_irq                  ),
//    .spi_clk_o      ( spi_clk_o                   ),
//    .spi_mosi       ( spi_mosi                    ),
//    .spi_miso       ( spi_miso                    ),
//    .spi_ss         ( spi_ss                      ),
	 .leds_o         ( {led[3:1], unused_led[7:5]}),
    .dip_switches_i ( '0     )
);





// ---------------------
// Board peripherals
// ---------------------
// ---------------
// DDR
// ---------------

logic ddr_amm_ready;
logic ddr_amm_read;
logic ddr_amm_write;
logic [26:0] ddr_amm_address;
logic [511:0] ddr_amm_rdata;
logic [511:0] ddr_amm_wdata;
logic [6:0]   ddr_amm_burstcount;
logic [63:0]  ddr_amm_byteenable;
logic ddr_amm_readdatavalid;

logic ddr_sc_amm_ready;
logic ddr_sc_amm_read;
logic ddr_sc_amm_write;
logic [26:0] ddr_sc_amm_address;
logic [511:0] ddr_sc_amm_rdata;
logic [511:0] ddr_sc_amm_wdata;
logic [6:0]   ddr_sc_amm_burstcount;
logic [63:0]  ddr_sc_amm_byteenable;
logic ddr_sc_amm_readdatavalid;

logic calbus_read, calbus_write, calbus_clk, calbus_read1, calbus_write1, calbus_clk1, ddr_pll_locked, ddr_rst_req, ddr_rst_done;
logic [19:0] calbus_addr,calbus_addr1;
logic [31:0] calbus_wdata, calbus_wdata1;
logic [31:0] calbus_rdata, calbus_rdata1;
logic [4095:0] calbus_seq_param_tbl, calbus_seq_param_tbl1;
logic cal_success;
logic ddr_amm_wait_request;
logic sd_irq;

assign ddr_amm_wait_request = ~ddr_amm_ready;

AXI_BUS #(
   .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
   .AXI_DATA_WIDTH ( AxiDataWidth     ),
   .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
   .AXI_USER_WIDTH ( AxiUserWidth     )
) dram();

axi_riscv_atomics_wrap #(
   .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
   .AXI_DATA_WIDTH ( AxiDataWidth     ),
   .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
   .AXI_USER_WIDTH ( AxiUserWidth     ),
   .AXI_MAX_WRITE_TXNS ( 1  ),
   .RISCV_WORD_WIDTH   ( 64 )
) i_axi_riscv_atomics (
   .clk_i  ( clk                      ),
   .rst_ni ( ndmreset_n               ),
   .slv    ( master[ariane_soc::DRAM] ),
   .mst    ( dram                     )
);

// the main memory can be internal SRAM or an external DDR
generate
    if (USE_SRAM) begin

        logic                       sram_req;
        logic                       sram_we;
        logic [AxiAddrWidth-1:0]    sram_addr;
        logic [AxiDataWidth/8-1:0]  sram_be;
        logic [AxiDataWidth-1:0]    sram_wdata;
        logic [AxiDataWidth-1:0]    sram_rdata;
        logic [AxiUserWidth-1:0]    sram_wuser;
        logic [AxiUserWidth-1:0]    sram_ruser;

        axi2mem #(
            .AXI_ID_WIDTH   ( ariane_axi_soc::IdWidthSlave ),
            .AXI_ADDR_WIDTH ( AxiAddrWidth            ),
            .AXI_DATA_WIDTH ( AxiDataWidth               ),
            .AXI_USER_WIDTH ( AxiUserWidth               )
            ) i_axi2mem (
            .clk_i  ( clk               ),
            .rst_ni ( ndmreset_n        ),
            .slave  ( dram          ),
            .req_o  ( sram_req          ),
            .we_o   ( sram_we           ),
            .addr_o ( sram_addr         ),
            .be_o   ( sram_be           ),
            .user_o ( sram_wuser        ),
            .data_o ( sram_wdata        ),
            .user_i ( sram_ruser        ),
            .data_i ( sram_rdata        )
        );

        sram #(
            .DATA_WIDTH ( AxiDataWidth ),
            .USER_WIDTH ( AxiUserWidth ),
            .USER_EN    ( 0    ),
            .NUM_WORDS  ( NumWords     )
            ) i_sram (
            .clk_i      ( clk                                                                              ),
            .rst_ni     ( ndmreset_n                                                                       ),
            .req_i      ( sram_req                                                                         ),
            .we_i       ( sram_we                                                                          ),
            .addr_i     ( sram_addr[$clog2(NumWords)-1+$clog2(AxiDataWidth/8):$clog2(AxiDataWidth/8)] ),
            .wuser_i    ( sram_wuser                                                                       ),
            .wdata_i    ( sram_wdata                                                                       ),
            .be_i       ( sram_be                                                                          ),
            .ruser_o    ( sram_ruser                                                                       ),
            .rdata_o    ( sram_rdata                                                                       )
        );
    end else begin
        //axi4 to avalon converter
        interconnect_altera_mm_interconnect_1920_otvf3ky axi_to_avalon_ddr (
            .axi_bridge_0_m0_awid                                                      (axi_cdc_src_req.aw.id),                                 //   input,    width = 8,                                                     axi_bridge_0_m0.awid
            .axi_bridge_0_m0_awaddr                                                    (axi_cdc_src_req.aw.addr),                               //   input,   width = 64,                                                                    .awaddr
            .axi_bridge_0_m0_awlen                                                     (axi_cdc_src_req.aw.len),                                //   input,    width = 8,                                                                    .awlen
            .axi_bridge_0_m0_awsize                                                    (axi_cdc_src_req.aw.size),                               //   input,    width = 3,                                                                    .awsize
            .axi_bridge_0_m0_awburst                                                   (axi_cdc_src_req.aw.burst),                              //   input,    width = 2,                                                                    .awburst
            .axi_bridge_0_m0_awlock                                                    (axi_cdc_src_req.aw.lock),                               //   input,    width = 1,                                                                    .awlock
            .axi_bridge_0_m0_awcache                                                   (axi_cdc_src_req.aw.cache),                              //   input,    width = 4,                                                                    .awcache
            .axi_bridge_0_m0_awprot                                                    (axi_cdc_src_req.aw.prot),                               //   input,    width = 3,                                                                    .awprot
            .axi_bridge_0_m0_awvalid                                                   (axi_cdc_src_req.aw_valid),                              //   input,    width = 1,                                                                    .awvalid
            .axi_bridge_0_m0_awready                                                   (axi_cdc_src_resp.aw_ready),                              //  output,    width = 1,                                                                    .awready
            .axi_bridge_0_m0_wdata                                                     (axi_cdc_src_req.w.data),                                //   input,   width = 64,                                                                    .wdata
            .axi_bridge_0_m0_wstrb                                                     (axi_cdc_src_req.w.strb),                                //   input,    width = 8,                                                                    .wstrb
            .axi_bridge_0_m0_wlast                                                     (axi_cdc_src_req.w.last),                                //   input,    width = 1,                                                                    .wlast
            .axi_bridge_0_m0_wvalid                                                    (axi_cdc_src_req.w_valid),                               //   input,    width = 1,                                                                    .wvalid
            .axi_bridge_0_m0_wready                                                    (axi_cdc_src_resp.w_ready),                               //  output,    width = 1,                                                                    .wready
            .axi_bridge_0_m0_bid                                                       (axi_cdc_src_resp.b.id),                                  //  output,    width = 8,                                                                    .bid
            .axi_bridge_0_m0_bresp                                                     (axi_cdc_src_resp.b.resp),                                //  output,    width = 2,                                                                    .bresp
            .axi_bridge_0_m0_bvalid                                                    (axi_cdc_src_resp.b_valid),                               //  output,    width = 1,                                                                    .bvalid
            .axi_bridge_0_m0_bready                                                    (axi_cdc_src_req.b_ready),                               //   input,    width = 1,                                                                    .bready
            .axi_bridge_0_m0_arid                                                      (axi_cdc_src_req.ar.id),                                 //   input,    width = 8,                                                                    .arid
            .axi_bridge_0_m0_araddr                                                    (axi_cdc_src_req.ar.addr),                               //   input,   width = 64,                                                                    .araddr
            .axi_bridge_0_m0_arlen                                                     (axi_cdc_src_req.ar.len),                                //   input,    width = 8,                                                                    .arlen
            .axi_bridge_0_m0_arsize                                                    (axi_cdc_src_req.ar.size),                               //   input,    width = 3,                                                                    .arsize
            .axi_bridge_0_m0_arburst                                                   (axi_cdc_src_req.ar.burst),                              //   input,    width = 2,                                                                    .arburst
            .axi_bridge_0_m0_arlock                                                    (axi_cdc_src_req.ar.lock),                               //   input,    width = 1,                                                                    .arlock
            .axi_bridge_0_m0_arcache                                                   (axi_cdc_src_req.ar.cache),                              //   input,    width = 4,                                                                    .arcache
            .axi_bridge_0_m0_arprot                                                    (axi_cdc_src_req.ar.prot),                               //   input,    width = 3,                                                                    .arprot
            .axi_bridge_0_m0_arvalid                                                   (axi_cdc_src_req.ar_valid),                              //   input,    width = 1,                                                                    .arvalid
            .axi_bridge_0_m0_arready                                                   (axi_cdc_src_resp.ar_ready),                              //  output,    width = 1,                                                                    .arready
            .axi_bridge_0_m0_rid                                                       (axi_cdc_src_resp.r.id),                                  //  output,    width = 8,                                                                    .rid
            .axi_bridge_0_m0_rdata                                                     (axi_cdc_src_resp.r.data),                                //  output,   width = 64,                                                                    .rdata
            .axi_bridge_0_m0_rresp                                                     (axi_cdc_src_resp.r.resp),                                //  output,    width = 2,                                                                    .rresp
            .axi_bridge_0_m0_rlast                                                     (axi_cdc_src_resp.r.last),                                //  output,    width = 1,                                                                    .rlast
            .axi_bridge_0_m0_rvalid                                                    (axi_cdc_src_resp.r_valid),                               //  output,    width = 1,                                                                    .rvalid
            .axi_bridge_0_m0_rready                                                    (axi_cdc_src_req.r_ready),                                                                                
            .emif_fm_0_ctrl_amm_0_address                                                          (ddr_sc_amm_address),       //  output,   width = 27,                                                            emif_fm_0_ctrl_amm_0.address
            .emif_fm_0_ctrl_amm_0_write                                                            (ddr_sc_amm_write),         //  output,    width = 1,                                                                                .write
            .emif_fm_0_ctrl_amm_0_read                                                             (ddr_sc_amm_read),          //  output,    width = 1,                                                                                .read
            .emif_fm_0_ctrl_amm_0_readdata                                                         (ddr_sc_amm_rdata),      //   input,  width = 512,                                                                                .readdata
            .emif_fm_0_ctrl_amm_0_writedata                                                        (ddr_sc_amm_wdata),     //  output,  width = 512,                                                                                .writedata
            .emif_fm_0_ctrl_amm_0_burstcount                                                       (ddr_sc_amm_burstcount),    //  output,    width = 7,                                                                                .burstcount
            .emif_fm_0_ctrl_amm_0_byteenable                                                       (ddr_sc_amm_byteenable),    //  output,   width = 64,                                                                                .byteenable
            .emif_fm_0_ctrl_amm_0_readdatavalid                                                    (ddr_sc_amm_readdatavalid), //   input,    width = 1,                                                                                .readdatavalid
            .emif_fm_0_ctrl_amm_0_waitrequest                                                      (ddr_sc_amm_wait_request),  //   input,    width = 1,                                                                                .waitrequest
            .axi_bridge_0_m0_translator_clk_reset_reset_bridge_in_reset_reset          (~ndmreset_n),                       //   input,    width = 1,          axi_bridge_0_m0_translator_clk_reset_reset_bridge_in_reset.reset
            .emif_fm_0_ctrl_amm_0_translator_reset_reset_bridge_in_reset_reset         (~ndmreset_n),                   //   input,    width = 1,         emif_fm_0_ctrl_amm_0_translator_reset_reset_bridge_in_reset.reset
            .emif_fm_0_ctrl_amm_0_agent_rsp_fifo_clk_reset_reset_bridge_in_reset_reset (~ndmreset_n),                   //   input,    width = 1, emif_fm_0_ctrl_amm_0_agent_rsp_fifo_clk_reset_reset_bridge_in_reset.reset
            .emif_fm_0_emif_usr_clk_clk                                                (clk) //   input,    width = 1,                                              emif_fm_0_emif_usr_clk.clk
        );
    
        test_mm_ccb_0 mm_ccb_0 (
            .m0_clk           (ddr_clock_out),                      //   input,    width = 1,   m0_clk.clk
            .m0_reset         (rst),                                //   input,    width = 1, m0_reset.reset
            .s0_clk           (clk),                //   input,    width = 1,   s0_clk.clk
            .s0_reset         (~ndmreset_n), //   input,    width = 1, s0_reset.reset
            .s0_waitrequest   (ddr_sc_amm_wait_request),            //  output,    width = 1,       s0.waitrequest
            .s0_readdata      (ddr_sc_amm_rdata),               //  output,  width = 512,         .readdata
            .s0_readdatavalid (ddr_sc_amm_readdatavalid),          //  output,    width = 1,         .readdatavalid
            .s0_burstcount    (ddr_sc_amm_burstcount),             //   input,    width = 8,         .burstcount
            .s0_writedata     (ddr_sc_amm_wdata),              //   input,  width = 512,         .writedata
            .s0_address       (ddr_sc_amm_address),                //   input,   width = 27,         .address
            .s0_write         (ddr_sc_amm_write),                  //   input,    width = 1,         .write
            .s0_read          (ddr_sc_amm_read),                   //   input,    width = 1,         .read
            .s0_byteenable    (ddr_sc_amm_byteenable),             //   input,   width = 64,         .byteenable
            .s0_debugaccess   (1'b0),            //   input,    width = 1,         .debugaccess
            .m0_waitrequest   (ddr_amm_wait_request),            //   input,    width = 1,       m0.waitrequest
            .m0_readdata      (ddr_amm_rdata),               //   input,  width = 512,         .readdata
            .m0_readdatavalid (ddr_amm_readdatavalid),          //   input,    width = 1,         .readdatavalid
            .m0_burstcount    (ddr_amm_burstcount),             //  output,    width = 8,         .burstcount
            .m0_writedata     (ddr_amm_wdata),              //  output,  width = 512,         .writedata
            .m0_address       (ddr_amm_address),                //  output,   width = 27,         .address
            .m0_write         (ddr_amm_write),                  //  output,    width = 1,         .write
            .m0_read          (ddr_amm_read),                   //  output,    width = 1,         .read
            .m0_byteenable    (ddr_amm_byteenable),             //  output,   width = 64,         .byteenable
            .m0_debugaccess   ()             //  output,    width = 1,         .debugaccess
        );
        
        
        ariane_axi::req_t   axi_cdc_src_req, axi_cdc_dst_req;
        ariane_axi::resp_t  axi_cdc_src_resp,axi_cdc_dst_resp;
        
        
        `AXI_ASSIGN_TO_REQ(axi_cdc_src_req, dram)
        `AXI_ASSIGN_FROM_RESP(dram, axi_cdc_src_resp)
    end
  endgenerate


ed_synth_emif_fm_0 inst_ddr4 (
    .local_reset_req           ('0),           //   input,     width = 1,           local_reset_req.local_reset_req
    // .local_reset_done          (ddr_rst_done),          //  output,     width = 1,        local_reset_status.local_reset_done
    .pll_ref_clk               (clk_ddr4_ch0_p),               //   input,     width = 1,               pll_ref_clk.clk
    .pll_locked                (ddr_pll_locked),                //  output,     width = 1,                pll_locked.pll_locked
    .oct_rzqin                 (oct_rzqin),                 //   input,     width = 1,                       oct.oct_rzqin
    .mem_ck                    (ddr4_ck_p),                    //  output,     width = 1,                       mem.mem_ck
    .mem_ck_n                  (ddr4_ck_n),                  //  output,     width = 1,                          .mem_ck_n
    .mem_a                     (ddr4_a),                     //  output,    width = 17,                          .mem_a
    .mem_act_n                 (ddr4_act_n),                 //  output,     width = 1,                          .mem_act_n
    .mem_ba                    (ddr4_ba),                    //  output,     width = 2,                          .mem_ba
    .mem_bg                    (ddr4_bg),                    //  output,     width = 2,                          .mem_bg
    .mem_cke                   (ddr4_cke),                   //  output,     width = 1,                          .mem_cke
    .mem_cs_n                  (ddr4_cs_n),                  //  output,     width = 1,                          .mem_cs_n
    .mem_odt                   (ddr4_odt),                   //  output,     width = 1,                          .mem_odt
    .mem_reset_n               (ddr4_reset_n),               //  output,     width = 1,                          .mem_reset_n
    .mem_par                   (ddr4_par),                   //  output,     width = 1,                          .mem_par
    .mem_alert_n               (ddr4_alert_n),               //   input,     width = 1,                          .mem_alert_n
    .mem_dqs                   (ddr4_dqs_p),                   //   inout,     width = 9,                          .mem_dqs
    .mem_dqs_n                 (ddr4_dqs_n),                 //   inout,     width = 9,                          .mem_dqs_n
    .mem_dq                    (ddr4_dq),                    //   inout,    width = 72,                          .mem_dq
    .mem_dbi_n                 (ddr4_dbi_n),                 //   inout,     width = 9,                          .mem_dbi_n
    .local_cal_success         (cal_success),         //  output,     width = 1,                    status.local_cal_success
    // .local_cal_fail            (led[0]),            //  output,     width = 1,                          .local_cal_fail
    .calbus_read               (calbus_read),               //   input,     width = 1,               emif_calbus.calbus_read
    .calbus_write              (calbus_write),              //   input,     width = 1,                          .calbus_write
    .calbus_address            (calbus_addr),            //   input,    width = 20,                          .calbus_address
    .calbus_wdata              (calbus_wdata),              //   input,    width = 32,                          .calbus_wdata
    .calbus_rdata              (calbus_rdata),              //  output,    width = 32,                          .calbus_rdata
    .calbus_seq_param_tbl      (calbus_seq_param_tbl),      //  output,  width = 4096,                          .calbus_seq_param_tbl
    .calbus_clk                (calbus_clk),                //   input,     width = 1,           emif_calbus_clk.clk
    .emif_usr_reset_n          (ddr_sync_reset),          //  output,     width = 1,          emif_usr_reset_n.reset_n
    .emif_usr_clk              (ddr_clock_out),              //  output,     width = 1,              emif_usr_clk.clk
    .amm_ready_0               (ddr_amm_ready),               //  output,     width = 1,                ctrl_amm_0.waitrequest_n
    .amm_read_0                (ddr_amm_read),                //   input,     width = 1,                          .read
    .amm_write_0               (ddr_amm_write),               //   input,     width = 1,                          .write
    .amm_address_0             (ddr_amm_address),             //   input,    width = 27,                          .address
    .amm_readdata_0            (ddr_amm_rdata),            //  output,   width = 512,                          .readdata
    .amm_writedata_0           (ddr_amm_wdata),           //   input,   width = 512,                          .writedata
    .amm_burstcount_0          (ddr_amm_burstcount),          //   input,     width = 7,                          .burstcount
    .amm_byteenable_0          (ddr_amm_byteenable),          //   input,    width = 64,                          .byteenable
    .amm_readdatavalid_0       (ddr_amm_readdatavalid)        //  output,     width = 1,                          .readdatavalid
);

emif_cal ddr_calibration (
    .calbus_read_0           (calbus_read),           //  output,     width = 1,     emif_calbus_0.calbus_read
    .calbus_write_0          (calbus_write),          //  output,     width = 1,                  .calbus_write
    .calbus_address_0        (calbus_addr),        //  output,    width = 20,                  .calbus_address
    .calbus_wdata_0          (calbus_wdata),          //  output,    width = 32,                  .calbus_wdata
    .calbus_rdata_0          (calbus_rdata),          //   input,    width = 32,                  .calbus_rdata
    .calbus_seq_param_tbl_0  (calbus_seq_param_tbl),  //   input,  width = 4096,                  .calbus_seq_param_tbl
    
    .calbus_read_1          (calbus_read1),          //  output,     width = 1,   emif_calbus_1.calbus_read
    .calbus_write_1         (calbus_write1),         //  output,     width = 1,                .calbus_write
    .calbus_address_1       (calbus_addr1),       //  output,    width = 20,                .calbus_address
    .calbus_wdata_1         (calbus_wdata1),         //  output,    width = 32,                .calbus_wdata
    .calbus_rdata_1         (calbus_rdata1),         //   input,    width = 32,                .calbus_rdata
    .calbus_seq_param_tbl_1 (calbus_seq_param_tbl1), //   input,  width = 4096,                .calbus_seq_param_tbl
	.calbus_clk              (calbus_clk)              //  output,     width = 1,   emif_calbus_clk.clk
	);

wire h2f_reset; 
wire ninit_done; 

assign system_reset_n            = ~h2f_reset & ~ninit_done;

AXI_BUS #(
    .AXI_ADDR_WIDTH ( CVA6Cfg.XLEN     ),
    .AXI_DATA_WIDTH ( 128              ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) master_to_hps[0:0]();

axi_dw_adapter  #(
    .ADDR_WIDTH            (CVA6Cfg.XLEN),
    .S_DATA_WIDTH          (AxiAddrWidth),
    .M_DATA_WIDTH          (128),
    .ID_WIDTH              (AxiIdWidthSlaves)
)i_axi_dwidth_converter_hps(
       .clk(clk),
       .rst(~ndmreset_n),
       .s_axi_awid(master[ariane_soc::HPS].aw_id),
       .s_axi_awaddr(master[ariane_soc::HPS].aw_addr[31:0]),
       .s_axi_awlen(master[ariane_soc::HPS].aw_len),
       .s_axi_awsize(master[ariane_soc::HPS].aw_size),
       .s_axi_awburst(master[ariane_soc::HPS].aw_burst),
       .s_axi_awlock(master[ariane_soc::HPS].aw_lock),
       .s_axi_awcache(master[ariane_soc::HPS].aw_cache),
       .s_axi_awprot(master[ariane_soc::HPS].aw_prot),
       .s_axi_awregion(master[ariane_soc::HPS].aw_region),
       .s_axi_awqos(master[ariane_soc::HPS].aw_qos),
       .s_axi_awvalid(master[ariane_soc::HPS].aw_valid),
       .s_axi_awready(master[ariane_soc::HPS].aw_ready),
       .s_axi_wdata(master[ariane_soc::HPS].w_data),
       .s_axi_wstrb(master[ariane_soc::HPS].w_strb),
       .s_axi_wlast(master[ariane_soc::HPS].w_last),
       .s_axi_wvalid(master[ariane_soc::HPS].w_valid),
       .s_axi_wready(master[ariane_soc::HPS].w_ready),
       .s_axi_bid(master[ariane_soc::HPS].b_id),
       .s_axi_bresp(master[ariane_soc::HPS].b_resp),
       .s_axi_bvalid(master[ariane_soc::HPS].b_valid),
       .s_axi_bready(master[ariane_soc::HPS].b_ready),
       .s_axi_arid(master[ariane_soc::HPS].ar_id),
       .s_axi_araddr(master[ariane_soc::HPS].ar_addr[31:0]),
       .s_axi_arlen(master[ariane_soc::HPS].ar_len),
       .s_axi_arsize(master[ariane_soc::HPS].ar_size),
       .s_axi_arburst(master[ariane_soc::HPS].ar_burst),
       .s_axi_arlock(master[ariane_soc::HPS].ar_lock),
       .s_axi_arcache(master[ariane_soc::HPS].ar_cache),
       .s_axi_arprot(master[ariane_soc::HPS].ar_prot),
       .s_axi_arregion(master[ariane_soc::HPS].ar_region),
       .s_axi_arqos(master[ariane_soc::HPS].ar_qos),
       .s_axi_arvalid(master[ariane_soc::HPS].ar_valid),
       .s_axi_arready(master[ariane_soc::HPS].ar_ready),
       .s_axi_rid(master[ariane_soc::HPS].r_id),
       .s_axi_rdata(master[ariane_soc::HPS].r_data),
       .s_axi_rresp(master[ariane_soc::HPS].r_resp),
       .s_axi_rlast(master[ariane_soc::HPS].r_last),
       .s_axi_rvalid(master[ariane_soc::HPS].r_valid),
       .s_axi_rready(master[ariane_soc::HPS].r_ready),
       .m_axi_awaddr(master_to_hps[0].aw_addr),
       .m_axi_awlen(master_to_hps[0].aw_len),
       .m_axi_awsize(master_to_hps[0].aw_size),
       .m_axi_awburst(master_to_hps[0].aw_burst),
       .m_axi_awlock(master_to_hps[0].aw_lock),
       .m_axi_awcache(master_to_hps[0].aw_cache),
       .m_axi_awprot(master_to_hps[0].aw_prot),
       .m_axi_awregion(master_to_hps[0].aw_region),
       .m_axi_awqos(master_to_hps[0].aw_qos),
       .m_axi_awvalid(master_to_hps[0].aw_valid),
       .m_axi_awready(master_to_hps[0].aw_ready),
       .m_axi_wdata(master_to_hps[0].w_data ),
       .m_axi_wstrb(master_to_hps[0].w_strb),
       .m_axi_wlast(master_to_hps[0].w_last),
       .m_axi_wvalid(master_to_hps[0].w_valid),
       .m_axi_wready(master_to_hps[0].w_ready),
       .m_axi_bresp(master_to_hps[0].b_resp),
       .m_axi_bvalid(master_to_hps[0].b_valid),
       .m_axi_bready(master_to_hps[0].b_ready),
       .m_axi_araddr(master_to_hps[0].ar_addr),
       .m_axi_arlen(master_to_hps[0].ar_len),
       .m_axi_arsize(master_to_hps[0].ar_size),
       .m_axi_arburst(master_to_hps[0].ar_burst),
       .m_axi_arlock(master_to_hps[0].ar_lock),
       .m_axi_arcache(master_to_hps[0].ar_cache),
       .m_axi_arprot(master_to_hps[0].ar_prot),
       .m_axi_arregion(master_to_hps[0].ar_region),
       .m_axi_arqos(master_to_hps[0].ar_qos),
       .m_axi_arvalid(master_to_hps[0].ar_valid),
       .m_axi_arready(master_to_hps[0].ar_ready),
       .m_axi_rdata(master_to_hps[0].r_data),
       .m_axi_rresp(master_to_hps[0].r_resp),
       .m_axi_rlast(master_to_hps[0].r_last),
       .m_axi_rvalid(master_to_hps[0].r_valid),
       .m_axi_rready(master_to_hps[0].r_ready)
   );

system hps_minimal (
        .hps_h2f_sdmmc_interrupt_irq(sd_irq), //  output,   width = 1
        .hps_hps_io_EMAC0_TX_CLK  (hps_emac0_TX_CLK),  								//  output,   width = 1,           hps_hps_io.EMAC0_TX_CLK
        .hps_hps_io_EMAC0_TXD0    (hps_emac0_TXD0),    								//  output,   width = 1,                     .EMAC0_TXD0
        .hps_hps_io_EMAC0_TXD1    (hps_emac0_TXD1),    								//  output,   width = 1,                     .EMAC0_TXD1
        .hps_hps_io_EMAC0_TXD2    (hps_emac0_TXD2),    								//  output,   width = 1,                     .EMAC0_TXD2
        .hps_hps_io_EMAC0_TXD3    (hps_emac0_TXD3),    								//  output,   width = 1,                     .EMAC0_TXD3
        .hps_hps_io_EMAC0_RX_CTL  (hps_emac0_RX_CTL),  								//   input,   width = 1,                     .EMAC0_RX_CTL
        .hps_hps_io_EMAC0_TX_CTL  (hps_emac0_TX_CTL),  								//  output,   width = 1,                     .EMAC0_TX_CTL
        .hps_hps_io_EMAC0_RX_CLK  (hps_emac0_RX_CLK),  								//   input,   width = 1,                     .EMAC0_RX_CLK
        .hps_hps_io_EMAC0_RXD0    (hps_emac0_RXD0),    								//   input,   width = 1,                     .EMAC0_RXD0
        .hps_hps_io_EMAC0_RXD1    (hps_emac0_RXD1),    								//   input,   width = 1,                     .EMAC0_RXD1
        .hps_hps_io_EMAC0_RXD2    (hps_emac0_RXD2),    								//   input,   width = 1,                     .EMAC0_RXD2
        .hps_hps_io_EMAC0_RXD3    (hps_emac0_RXD3),    								//   input,   width = 1,                     .EMAC0_RXD3
        .hps_hps_io_EMAC0_MDIO    (hps_emac0_MDIO),    								//   inout,   width = 1,                     .EMAC0_MDIO
        .hps_hps_io_EMAC0_MDC     (hps_emac0_MDC),     								//  output,   width = 1,                     .EMAC0_MDC
        .hps_hps_io_SDMMC_CMD     (hps_sdmmc_CMD),     								//   inout,   width = 1,                     .SDMMC_CMD
        .hps_hps_io_SDMMC_D0      (hps_sdmmc_D0),      								//   inout,   width = 1,                     .SDMMC_D0
        .hps_hps_io_SDMMC_D1      (hps_sdmmc_D1),      								//   inout,   width = 1,                     .SDMMC_D1
        .hps_hps_io_SDMMC_D2      (hps_sdmmc_D2),      								//   inout,   width = 1,                     .SDMMC_D2
        .hps_hps_io_SDMMC_D3      (hps_sdmmc_D3),      								//   inout,   width = 1,                     .SDMMC_D3
        .hps_hps_io_SDMMC_CCLK    (hps_sdmmc_CCLK),    								//  output,   width = 1,                     .SDMMC_CCLK
        .hps_hps_io_UART0_RX      (hps_uart0_RX),      								//   input,   width = 1,                     .UART0_RX
        .hps_hps_io_UART0_TX      (hps_uart0_TX),      								//  output,   width = 1,                     .UART0_TX
        .hps_hps_io_I2C1_SDA      (hps_i2c1_SDA),      								//   inout,   width = 1,                     .I2C1_SDA
        .hps_hps_io_I2C1_SCL      (hps_i2c1_SCL),      								//   inout,   width = 1,                     .I2C1_SCL
        .hps_hps_io_gpio1_io0     (hps_gpio1_io0),      								//   inout,   width = 1,                     .gpio1_io0
        .hps_hps_io_jtag_tck      (hps_jtag_tck),      								//   input,   width = 1,                     .jtag_tck
        .hps_hps_io_jtag_tms      (hps_jtag_tms),      								//   input,   width = 1,                     .jtag_tms
        .hps_hps_io_jtag_tdo      (hps_jtag_tdo),      								//  output,   width = 1,                     .jtag_tdo
        .hps_hps_io_jtag_tdi      (hps_jtag_tdi),      								//   input,   width = 1,                     .jtag_tdi
		.hps_hps_io_hps_osc_clk   (hps_ref_clk),                              //   input,    width = 1,                                              .hps_osc_clk
		.h2f_reset_reset          (h2f_reset),                                     //  output,    width = 1,                                     h2f_reset.reset
		
		.hps_f2h_axi_clock_clk    (clk),                               //   input,    width = 1,                             hps_f2h_axi_clock.clk
		.hps_f2h_axi_reset_reset_n(ndmreset_n),                           //   input,    width = 1,                             hps_f2h_axi_reset.reset_n
		.hps_emif_pll_ref_clk_clk (emif_hps_pll_ref_clk_p), 							//   input,   width = 1, hps_emif_pll_ref_clk.clk
        .hps_emif_oct_oct_rzqin   (emif_hps_oct_oct_rzqin),   						//   input,   width = 1,         hps_emif_oct.oct_rzqin
        .hps_emif_mem_mem_ck      (emif_hps_mem_mem_ck),      						//  output,   width = 1,         hps_emif_mem.mem_ck
        .hps_emif_mem_mem_ck_n    (emif_hps_mem_mem_ck_n),    						//  output,   width = 1,                     .mem_ck_n
        .hps_emif_mem_mem_a       (emif_hps_mem_mem_a),       						//  output,  width = 17,                     .mem_a
        .hps_emif_mem_mem_act_n   (emif_hps_mem_mem_act_n),   						//  output,   width = 1,                     .mem_act_n
        .hps_emif_mem_mem_ba      (emif_hps_mem_mem_ba),      						//  output,   width = 2,                     .mem_ba
        .hps_emif_mem_mem_bg      (emif_hps_mem_mem_bg),      						//  output,   width = 2,                     .mem_bg
        .hps_emif_mem_mem_cke     (emif_hps_mem_mem_cke),     						//  output,   width = 1,                     .mem_cke
        .hps_emif_mem_mem_cs_n    (emif_hps_mem_mem_cs_n),    						//  output,   width = 1,                     .mem_cs_n
        .hps_emif_mem_mem_odt     (emif_hps_mem_mem_odt),     						//  output,   width = 1,                     .mem_odt
        .hps_emif_mem_mem_reset_n (emif_hps_mem_mem_reset_n), 						//  output,   width = 1,                     .mem_reset_n
        .hps_emif_mem_mem_par     (emif_hps_mem_mem_par),     						//  output,   width = 1,                     .mem_par
        .hps_emif_mem_mem_alert_n (emif_hps_mem_mem_alert_n), 						//   input,   width = 1,                     .mem_alert_n
        .hps_emif_mem_mem_dqs     (emif_hps_mem_mem_dqs),     						//   inout,   width = 8,                     .mem_dqs
        .hps_emif_mem_mem_dqs_n   (emif_hps_mem_mem_dqs_n),   						//   inout,   width = 8,                     .mem_dqs_n
        .hps_emif_mem_mem_dq      (emif_hps_mem_mem_dq),      						//   inout,  width = 64,                     .mem_dq
        .hps_emif_mem_mem_dbi_n   (emif_hps_mem_mem_dbi_n),   						//   inout,   width = 8,                     .mem_dbi_n

        .hps_emif_emif_calbus_calbus_read                    (calbus_read1),                    //   input,     width = 1,                          hps_emif_emif_calbus.calbus_read
		.hps_emif_emif_calbus_calbus_write                   (calbus_write1),                   //   input,     width = 1,                                              .calbus_write
		.hps_emif_emif_calbus_calbus_address                 (calbus_address1),                 //   input,    width = 20,                                              .calbus_address
		.hps_emif_emif_calbus_calbus_wdata                   (calbus_wdata1),                   //   input,    width = 32,                                              .calbus_wdata
		.hps_emif_emif_calbus_calbus_rdata                   (calbus_rdata1),                   //  output,    width = 32,                                              .calbus_rdata
		.hps_emif_emif_calbus_calbus_seq_param_tbl           (calbus_seq_param_tbl1),           //  output,  width = 4096,                                              .calbus_seq_param_tbl
		.hps_emif_emif_calbus_clk_clk                        (calbus_clk),                        //   input,     width = 1,                      hps_emif_emif_calbus_clk.clk

		.ninit_done_ninit_done    (ninit_done),                               //  output,    width = 1,                                    ninit_done.ninit_done

		.system_intel_cache_coherency_translator_clock_clk   (clk),   //   input,    width = 1, system_intel_cache_coherency_translator_clock.clk
		.system_intel_cache_coherency_translator_reset_reset (~ndmreset_n), //   input,    width = 1, system_intel_cache_coherency_translator_reset.reset
		.system_intel_cache_coherency_translator_s0_araddr   (master_to_hps[0].ar_addr),   //   input,   width = 32,    system_intel_cache_coherency_translator_s0.araddr
		.system_intel_cache_coherency_translator_s0_arburst  (master_to_hps[0].ar_burst),  //   input,    width = 2,                                              .arburst
		.system_intel_cache_coherency_translator_s0_arcache  (master_to_hps[0].ar_cache),  //   input,    width = 4,                                              .arcache
		.system_intel_cache_coherency_translator_s0_arid     (master_to_hps[0].ar_id),     //   input,    width = 5,                                              .arid
		.system_intel_cache_coherency_translator_s0_arlen    (master_to_hps[0].ar_len),    //   input,    width = 8,                                              .arlen
		.system_intel_cache_coherency_translator_s0_arlock   (master_to_hps[0].ar_lock),   //   input,    width = 1,                                              .arlock
		.system_intel_cache_coherency_translator_s0_arprot   (master_to_hps[0].ar_prot),   //   input,    width = 3,                                              .arprot
		.system_intel_cache_coherency_translator_s0_arready  (master_to_hps[0].ar_ready),  //  output,    width = 1,                                              .arready
		.system_intel_cache_coherency_translator_s0_arsize   (master_to_hps[0].ar_size),   //   input,    width = 3,                                              .arsize
		.system_intel_cache_coherency_translator_s0_arvalid  (master_to_hps[0].ar_valid),  //   input,    width = 1,                                              .arvalid
		.system_intel_cache_coherency_translator_s0_awaddr   (master_to_hps[0].aw_addr),   //   input,   width = 32,                                              .awaddr
		.system_intel_cache_coherency_translator_s0_awburst  (master_to_hps[0].aw_burst),  //   input,    width = 2,                                              .awburst
		.system_intel_cache_coherency_translator_s0_awcache  (master_to_hps[0].aw_cache),  //   input,    width = 4,                                              .awcache
		.system_intel_cache_coherency_translator_s0_awid     (master_to_hps[0].aw_id),     //   input,    width = 5,                                              .awid
		.system_intel_cache_coherency_translator_s0_awlen    (master_to_hps[0].aw_len),    //   input,    width = 8,                                              .awlen
		.system_intel_cache_coherency_translator_s0_awlock   (master_to_hps[0].aw_lock),   //   input,    width = 1,                                              .awlock
		.system_intel_cache_coherency_translator_s0_awprot   (master_to_hps[0].aw_prot),   //   input,    width = 3,                                              .awprot
		.system_intel_cache_coherency_translator_s0_awready  (master_to_hps[0].aw_ready),  //  output,    width = 1,                                              .awready
		.system_intel_cache_coherency_translator_s0_awsize   (master_to_hps[0].aw_size),   //   input,    width = 3,                                              .awsize
		.system_intel_cache_coherency_translator_s0_awvalid  (master_to_hps[0].aw_valid),  //   input,    width = 1,                                              .awvalid
		.system_intel_cache_coherency_translator_s0_bid      (master_to_hps[0].b_id),      //  output,    width = 5,                                              .bid
		.system_intel_cache_coherency_translator_s0_bready   (master_to_hps[0].b_ready),   //   input,    width = 1,                                              .bready
		.system_intel_cache_coherency_translator_s0_bresp    (master_to_hps[0].b_resp),    //  output,    width = 2,                                              .bresp
		.system_intel_cache_coherency_translator_s0_bvalid   (master_to_hps[0].b_valid),   //  output,    width = 1,                                              .bvalid
		.system_intel_cache_coherency_translator_s0_rdata    (master_to_hps[0].r_data),    //  output,  width = 128,                                              .rdata
		.system_intel_cache_coherency_translator_s0_rid      (master_to_hps[0].r_id),      //  output,    width = 5,                                              .rid
		.system_intel_cache_coherency_translator_s0_rlast    (master_to_hps[0].r_last),    //  output,    width = 1,                                              .rlast
		.system_intel_cache_coherency_translator_s0_rready   (master_to_hps[0].r_ready),   //   input,    width = 1,                                              .rready
		.system_intel_cache_coherency_translator_s0_rresp    (master_to_hps[0].r_resp),    //  output,    width = 2,                                              .rresp
		.system_intel_cache_coherency_translator_s0_rvalid   (master_to_hps[0].r_valid),   //  output,    width = 1,                                              .rvalid
		.system_intel_cache_coherency_translator_s0_wdata    (master_to_hps[0].w_data),    //   input,  width = 128,                                              .wdata
		.system_intel_cache_coherency_translator_s0_wlast    (master_to_hps[0].w_last),    //   input,    width = 1,                                              .wlast
		.system_intel_cache_coherency_translator_s0_wready   (master_to_hps[0].w_ready),   //  output,    width = 1,                                              .wready
		.system_intel_cache_coherency_translator_s0_wstrb    (master_to_hps[0].w_strb),    //   input,   width = 16,                                              .wstrb
		.system_intel_cache_coherency_translator_s0_wvalid   (master_to_hps[0].w_valid)    //   input,    width = 1,                                              .wvalid
	);

//
//clocks
io_pll clocks (
    .refclk   (pll_ref_clk_p),   // 100 MHz on Agilex 7  input,  width = 1,  refclk.clk
    .locked   (pll_locked),   //  output,  width = 1,  locked.export
    .rst      (cpu_reset),      //   input,  width = 1,   reset.reset
    .outclk_0 (clk), //  output,  width = 1, outclk0.clk 50 MHz
    .outclk_1 (phy_tx_clk), //  output,  width = 1, outclk1.clk 125 MHz
    .outclk_2 (clk_200MHz_ref),  //  output,  width = 1, outclk2.clk 200 MHz
    .outclk_3 (eth_clk)  //  output,  width = 1, outclk3.clk 125 MHz 90 degrees
    );

assign sd_clk_sys = clk;     //  50 MHz

endmodule
