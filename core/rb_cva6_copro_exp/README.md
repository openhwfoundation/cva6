# TRISTAN/rb_cva6_cropro_exp
This repository is holding the source RTL for  EXP coprocessor designed by Bosch, in the context of the TRISTAN project.

This EXPonential coprocessor, computes exp(-x) in fixed point , where : 
  - x is in Q5.26 (i.e in [0,32[  ,
  - exp(-x) in  Q0.31 in ]0,1[ 


Additionnaly, some testbenches are available.

## Table of Contents <!-- omit in toc -->
- [How to use this repo](#howto)
- [Directory Structure](#directory-structure)
- [Links and resources](#links-resources)
- [About](#about)
  - [Maintainers](#maintainers)

An example implementation of a CRC and EXP coprocessor wrapper on the CVX-F interface is given below .:

```
 
  // ---------------
  // EXP Coprocessor
  // ---------------

 
    cvxif_exp_coprocessor i_cvxif_exp_coprocessor0 (
      .clk_i                ( clk                  ),
      .rst_ni               ( sys_rst_n             ),     
      .cvxif_req_i          ( cvxif_req             ),
      .cvxif_resp_o         ( cvxif_resp            )
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
