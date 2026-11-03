# TRISTAN/rb_cva6_cropro_wrapper
This repository is holding the source RTL for the CVX-if coprocessor wrapper  CRC designed by Bosch, in the context of the TRISTAN project.
Additionnaly, some testbenches are available.

## Table of Contents <!-- omit in toc -->
- [How to use this repo](#howto)
- [Directory Structure](#directory-structure)
- [Links and resources](#links-resources)
- [About](#about)
  - [Maintainers](#maintainers)

An example implementation of a CRC and EXP coprocessor wrapper on the CVX-ID interface is given below :

```
 
  // ---------------
  // CRC Coprocessor wrapper : CRC +EXP 
  // ---------------

  cvxif_pkg::cvxif_req_t  [cvxif_wrapper_pkg::COPRO_NBR-1:0] cvxif_req_copro;
  cvxif_pkg::cvxif_resp_t [cvxif_wrapper_pkg::COPRO_NBR-1:0] cvxif_resp_copro;  
 
  cvxif_coprocessor_wrapper #(
        .COPRO_NBR        ( cvxif_wrapper_pkg::COPRO_NBR ),
        .SAME_COPRO_NBR   ( cvxif_wrapper_pkg::SAME_COPRO_NBR ),
        .SAME_COPRO_TABLE ( cvxif_wrapper_pkg::SAME_COPRO_TABLE ),
        .DECODING_TYPE    ( cvxif_wrapper_pkg::DECODING_TYPE ),
        .decoding_LUT     ( cvxif_wrapper_pkg::decoding_LUT ),
        .i_resp_LUT       ( cvxif_wrapper_pkg::i_resp_LUT )
    ) i_cvxif_coprocessor_wrapper (
      .clk_i                ( clk                            ),
      .rst_ni               ( sys_rst_n                      ),
      .cvxif_req_i          ( cvxif_req                      ),
      .cvxif_req_copro      ( cvxif_req_copro                ),
      .cvxif_resp_copro     ( cvxif_resp_copro               ),
      .cvxif_resp_o         ( cvxif_resp                     )
    );
 
    cvxif_crc_coprocessor i_cvxif_crc_coprocessor0 (
      .clk_i                ( clk                            ),
      .rst_ni               ( sys_rst_n                      ),
      .cvxif_req_i          ( cvxif_req_copro[0]             ),
      .cvxif_resp_o         ( cvxif_resp_copro[0]            )
    );
 
    cvxif_exp_coprocessor i_cvxif_exp_coprocessor1 (
      .clk_i                ( clk                            ),
      .rst_ni               ( sys_rst_n                      ),     
      .cvxif_req_i          ( cvxif_req_copro[1]             ),
      .cvxif_resp_o         ( cvxif_resp_copro[1]            )
    );
 
 
```


## Directory Structure <a name="directory-structure"></a>

This repository is structured according to the standard EIY folder structure :
* rtl_v : contains RTL files


## Links and resources <a name="links-resources"></a>
* [EU TRISTAN project description](https://cordis.europa.eu/project/id/101095947)

## About <a name="about"></a>
Together for RISc-V Technology and ApplicatioNs (TRISTAN) is a project financed partly by the Europan Union and involving multiple companies.
Some of the activities done by BOSCH will by open-sourced while other aspects will stay closed source.

### Maintainers <a name="maintainers"></a>

* [Nicolas TRIBIE](nicolas.tribie___at__@fr.bosch.com)
