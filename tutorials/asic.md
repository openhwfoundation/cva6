## ASIC Synthesis

How to make cva6 synthesis ?
```
make -C pd/synth cva6_synth FOUNDRY_PATH=/your/techno/basepath/ TECH_NAME=yourTechnoName TARGET_LIBRARY_FILES="yourLib1.db\ yourLib2.db" PERIOD=10 NAND2_AREA=650 TARGET=cv64a6_imafdc_sv39 ADDITIONAL_SEARCH_PATH="others/libs/paths/one\ others/libs/paths/two"
```
Don't forget to escape spaces in lists.
Reports are under: pd/synth/ariane/reports


## ASIC Gate Simulation with `core-v-verif` repository

> :warning: **Warning**: this chapter needs to be updated. See Github issue https://github.com/openhwgroup/cva6/issues/1358.

```sh
export DV_SIMULATORS=veri-testharness,spike
cva6/regress/smoke-tests.sh
make -C pd/synth cva6_synth FOUNDRY_PATH=/your/techno/basepath/ TECH_NAME=yourTechnoName TARGET_LIBRARY_FILES="yourLib1.db\ yourLib2.db" PERIOD=10 NAND2_AREA=650 TARGET=cv64a6_imafdc_sv39 ADDITIONAL_SEARCH_PATH="others/libs/paths/one\ others/libs/paths/two"
sed 's/module SyncSpRamBeNx64_1/module SyncSpRamBeNx64_2/' pd/synth/ariane_synth.v > pd/synth/ariane_synth_modified.v
cd cva6/sim
make vcs_clean
python3 cva6.py --testlist=../tests/testlist_riscv-tests-cv64a6_imafdc_sv39-p.yaml --test rv64ui-p-ld --iss_yaml cva6.yaml --target cv64a6_imafdc_sv39 --iss=spike,vcs-core-gate $DV_OPTS
```
