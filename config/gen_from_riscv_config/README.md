<!--
# Copyright 2024 Thales DIS France SAS
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Original Author: Abdessamii Oukalrazqou
-->

# Gen From Risc-V Config

This software takes a `Risc-V Config Yaml` description of CSR Registers, and generates  ReStructuredText documents and Markdown Documents for CSR Registers and ISA Extensions. In the example/tb directory there is an example of how to generate
the packages.
 
For more details about RISC-V Config Yaml, see [Annexes](##Annexes) section

## Requirements 
The software depend on python libraries that you need to install using `pip3` command , these libraries exist in `requirements.txt`:

```bash
pip3 install -r requirements.txt
```

##  Usage 

```bash
#Generate Restructured-text documentation for Control and Status Registers (CSR)
python3 <scripts/riscv_config_gen>.py -s <../riscv-config/Config_Name/generated/isa_gen>.yaml -c <../riscv-config/Config_Name/generated/custom_gen>.yaml -d <../riscv-config/Config_Name/generated/debug_gen>.yaml -m <updaters/Config_Name/csr_updater>.yaml -t < Config_Name>

#Generate Restructured-text documentation for ISA extensions
python3 <scripts/riscv_config_gen>.py -s <../riscv-config/Config_Name/generated/isa_gen>.yaml -i <templates/isa_template>.yaml -m <updaters/Config_Name/isa_updater>.yaml -t < Config_Name>

#Generate the Yaml spike configuration file 
python3 <scripts/riscv_config_gen>.py -s <../riscv-config/Config_Name/generated/isa_gen>.yaml -c <../riscv-config/Config_Name/generated/custom_gen>.yaml  -i <templates/spike>.mako -m <updaters/Config_Name/spike_updater>.yaml -t < Config_Name>

```

##  Usage with cv32a65x 

```bash
#Generate  the Restructured-text documentation for Control and Status Registers (CSR)
python3 scripts/riscv_config_gen.py -s ../riscv-config/cv32a65x/generated/isa_gen.yaml -c ../riscv-config/cv32a65x/generated/custom_gen.yaml  -d ../riscv-config/cv32a65x/generated/debug_gen.yaml -m updaters/cv32a65x/csr_updater.yaml -t cv32a65x

#Generate  the Restructured-text documentation for ISA extensions
python3 scripts/riscv_config_gen.py -s ../riscv-config/cv32a65x/generated/isa_gen.yaml -i templates/isa_template.yaml -m updaters/cv32a65x/isa_updater.yaml -t cv32a65x

#Generate the Yaml spike configuration file  
python3 scripts/riscv_config_gen.py -s ../riscv-config/cv32a65x/generated/isa_gen.yaml -c ../riscv-config/cv32a65x/generated/custom_gen.yaml -i templates/spike.mako -m updaters/cv32a65x/spike_updater.yaml -t cv32a65x

```
 
You could find your output files in this directory : 

if the output is ISA Documentation: 
                `<Config_Name>/isa/`
                
if the output is CSR Documentation :
                `<Config_Name>/csr/`
                
if the output is Spike yaml :
                `<Config_Name>/spike/`

               
                
                
for more details about How to write CSR or ISA Updater,see [Updaters](#updaters) section

for more details about How to write ISA template ,see [Annexes2](#annexes2) section

for more details about How to write spike template , see [mako](https://www.makotemplates.org/) section



             
## Updaters


Since the Software is to generate Documentation, to add dynamic aspect to the software we add the updater that make us able to update the output of the software either in term of ISA_Extensions we can add or remove an extension from documentation or in term of CSR we can change reset-value or exclude register who have certain conditions.


- the format of updaters  is Yaml type 
      
- the software may work without updater and will generated the documentation without modification 
      
Since the software generate CSR and ISA Documentation we have two types of updaters :



### ISA Updater

     
If you want to add an extension to documentation not existed by default u can put it in yaml :
     
- Format : 
        
        <Extension_Name>: True
          
- Example : 

        Zicond : True
          
If you want to remove an extension from documentation not existed by default u can put it in yaml :
     
- Format : 

        <Extension_Name>: False
          
- Example : 

        Zicmp : False
        
      
If you want to remove an extension from documentation  already existed : 
           
- Format : 

        <Extension_Name>: False
          
- Example : 

        M : False
        
Example : ISA_Updater.yaml

        Zicond : True 

        Zicsr :  False

        I : False 
        
### CSR Updater

     
-If  you want to modify any parameter for registers in RISC CONFIG YAML  :
      
- Format :  
 
                Register name :
                       sub_feature : 
                              key : value
 Example :
                misa :
                   rv64 :
                     accessible : false
    
    
                mcause :
                    reset-val : 12346
                    
-If you want to exclude any registers base on condition :
       
- Format :  
                
                exclude :
                        
                        key : value
                        
                        sub_key : sub_value (if exist if not dont include it )
                        
                        cond: value
- Example : 
               
                exclude : 
                
                   key : priv_mode
                   
                   cond : S  
 
              
-If you want to control the number of register in RISC CONFIG YAML :
       
    Example : (PMPADDR , MHPMCOUNTER, ...)
             
- Format :
           
                  Register Name :
            
                        range : number
- Example : 
           
                    pmpaddr :
                    
                        range : 6  #it reduces number of pmpaddr registers from (start_index to  6)
   
                 
CSR/ISA Updater read RISC-CONFIG.yaml and update the registers so if you want to add register in Risc-V Config  you need to respect it architecture.



### SPIKE Updater

     
-If  you want to modify any parameter Spike yaml:
       
- Format : 
 
                <parameter name> : <parameter value> 

- Example :
 
 
                bootrom: false
         
-If you want to to modify any parameter in core config in Spike yaml :
       
- Format : 
                
                cores:
                        
                       <parameter name> : <parameter value> 
- Example : 

                Bootroom : true
- Example : 
               
                cores: 
                   isa: rv32imc_zba_zbb_zbs_zbc_zicsr_zifencei
                   boot_addr: 0x80000000
                   marchid: 0x3
                   misa_we: false
                   misa_we_enable: true
                   pmpaddr0: 0x0
                   pmpcfg0: 0x0
                   pmpregions: 0x40
                   usable_pmpregions : 0x8
                   priv: M
                   status_fs_field_we: false
                   status_fs_field_we_enable: false
                   status_vs_field_we: false
                   status_vs_field_we_enable: false
                   misa_we: false
                   mstatus_write_mask: 0x00000088
                   mstatus_override_mask: 0x00001800
                   mtval_write_mask: 0x00000000
                   unified_traps: true

                 
Spike Updater read spike.yaml and update the parameters  so if you want to add parameter in spike.yaml  you need to respect it architecture.


## Annexes


Risc-V Config Yaml file is generated based on Risc-Config tool which include all Control and Status Registers(CSR) and ISA extensions supported in each Config of CVA6.
     
- The tool is placed  in  _vendor/riscv/riscv-config_ : 
     
   <https://github.com/openhwgroup/cva6/tree/master/vendor/riscv/riscv-config>.
                    
 
You can execute the tool from `../config/riscv-config` repo  :


- It needs python dependencies with : 

    'pip3 install -r ../../vendor/riscv-config/Requirements.txt' .

- It needs to setup path (From 'CVA6 stage') with  :

    'export PYTHONPATH =`pwd ../../vendor/riscv/riscv-config:$PYTHONPATH`.

- You can do the execution with :
     
```bash
       make -C <CVA6_top_directory>/config/riscv-config all
```

You can change the target in the makefile located in `config/riscv-config/Makefile`

The generated files will be located in `config/riscv-config/[target]/generated\`.

Risc -V Config Yaml is our input file for Gen From Risc-V Config.






## Annexes2 


isa_full_template.yaml which is in the repo is a file which include all ISA Extensions Description supported by CVA6 if you want to add any extensions to the this Yaml ,
you can write it on this format :
       
__Format__ : 
        
           Extension Full Name:
              Description : 
              Subset_Name : 
              Instructions :
                 Operation type 1:
                    Instruction Name:
                        Format:
                        Description: 
                        Pseudocode: 
                        Invalid_Values: 
                        Exception_Raised: 
                 Operation type 2:
                      Name:
                        Format:
                        Description: 
                        Pseudocode: 
                        Invalid_Values: 
                        Exception_Raised:
__Example__:
        
          RV32I Base Integer Instructions:
            Description : |
               the base integer instruction set, also known as the 'RV32I' or 'RV64I' instruction set , depending on the address space size, provides the core functionality required for general-purpose computing .
               it includes instructions for arithmetic, logical, and control operations, as well as memory access
               and manipulation
            Subset_Name : I
            Instructions :
               Integer_Register_Immediate_Operations:
                  ADDI:
                   Format: addi rd, rs1, imm[11:0]
                   Description: add sign-extended 12-bit immediate to register rs1, and store the result in register rd.
                   Pseudocode: x[rd] = x[rs1] + sext(imm[11:0])
                   Invalid_Values: NONE
                   Exception_Raised: NONE
                Integer_Register_Register_Operations:
                   ADD:
                    Format: add rd, rs1, rs2
                    Description: add rs2 to register rs1, and store the result in register rd.
                    Pseudocode: x[rd] = x[rs1] + x[rs2]
                    Invalid_Values: NONE
                     Exception_Raised: NONE
