#Cook
export CONFIG_DIR=/config_cook_path/cook #shared config directory (techno.yml compile.yml setenv.sh)
#Spike
export SPIKE_PATH=/spike_path/spike #shared root directory of spike installation
export NUM_JOBS=24
#Synopsys
export SYN_VCS_BASHRC=/synopsys_path/vcs/version/setup/bashrc.example
export SYN_VERDI_BASHRC=/synopsys_path/verdi/version/setup/bashrc.example
export VCS_UVM_HOME=/synopsys_path/vcs/version/etc/uvm-1.2/
export SYN_SG_BASHRC=/synopsys_path/spyglass/version/setup/bashrc.example
export SYN_DCSHELL_BASHRC=/synopsys_path/syn/version/setup/bashrc.example
#Cadence
export CADENCE_XCELIUM_BASHRC=/cadence_path/xcelium/version/setup/bashrc.example
export XCELIUM_HOME=/cadence_path/xcelium/version  # Required for UVM paths
#Siemens (Mentor)
export SIEMENS_QUESTA_BASHRC=/siemens_path/questa/version/setup/bashrc.example
#export QUESTASIM_HOME=/siemens_path/questa/version  # Optional: auto-detected from vsim
#AMD/Xilinx (FPGA recipes)
# Vivado 2018.2 is the version the CVA6 FPGA flow is tested with. Synthesis
# and implementation need a licence covering the device of the board
# (xc7k325t for genesys2/kc705): WebPACK does not cover it.
export XILINX_VIVADO_BASHRC=/xilinx_path/Vivado/2018.2/settings64.sh
#export XILINXD_LICENSE_FILE=port@your_xilinx_license_server
# Board reached over the network, the USB cables staying on the machine it is
# wired to (see the FPGA section of flows/README.md):
#   hw_server <host>:3121 for the JTAG, a serial to TCP bridge for the console
#export HW_SERVER_URL=bench-pc:3121
#export UART_SERIAL=rfc2217://bench-pc:4001
#Intel/Altera (FPGA recipes)
# Quartus Prime Pro, with qsys-script and qsys-generate of its
# sopc_builder/bin in PATH, and a licence covering the device of the board.
export QUARTUS_SETUP=/altera_path/quartus/version/setup/bashrc.example
# Hardware setup name of the board, as the Quartus Programmer sees it.
# Optional: the recipe asks jtagconfig when it is unset.
#export JTAG_CABLE="AGF FPGA Development Kit [1-3]"
#Generic tool
export VERIBLE_PATH=/verible_path/verible-v0.0-3922-g26d4b0e0/bin
# Verilator of the TestHarness recipes, also put in PATH below
export VERILATOR_INSTALL_DIR=/verilator_path/verilator-v5.008
#Python
# The interpreter the recipes run with, and the one pip installs their
# entry points next to: black, pylint and sphinx-build are found through
# it. A virtual environment keeps them out of the system packages:
#   python3 -m venv .venv && . .venv/bin/activate
#   pip3 install -r flows/requirements.txt
# This file is shared by every checkout, so the environment is looked for
# in the current directory rather than named here: source it from the root
# of the CVA6 repository. Leave VENV_PATH unset to use no virtual
# environment and put the entry points in PATH yourself (PYTHON_PATH).
export VENV_PATH=$PWD/.venv
export PYTHON_PATH=~/.local/bin
#Documentation (docs-build)
# The RISC-V manuals are rendered by AsciiDoctor with four Ruby
# extensions, and the two npm diagram generators it shells out to. Both
# package managers put their binaries where the shell already looks, so
# nothing has to be added to PATH:
#   gem install --user-install -g docs/riscv-isa/riscv-isa-manual/dependencies/Gemfile
#   npm install -g wavedrom-cli bytefield-svg
# Uncomment GEM_HOME only when a GEM_PATH set by the site hides the gems
# installed with `--user-install`, which asciidoctor then reports as
# `cannot load such file`. The CVA6 design manual needs none of them.
#export GEM_HOME=$(ruby -e 'puts Gem.user_dir')
#Report to dashboard CI
export DASHBOARD_USER_EMAIL=gituser@example.com
export DASHBOARD_USER_NAME="gituser"
export DASHBOARD_URL="git@exemple.com:group/dashboard.git"
#Update Path
export PATH=$PATH:$VERIBLE_PATH
export PATH=$PATH:$VERILATOR_INSTALL_DIR/bin
export PATH=$PATH:$PYTHON_PATH
# Activating the virtual environment last puts its interpreter first, so
# `./cook.py` runs with it whatever the shell had before.
if [ -n "$VENV_PATH" ] && [ -f "$VENV_PATH/bin/activate" ]; then
  . "$VENV_PATH/bin/activate"
fi

#source $SYN_VERDI_BASHRC
#source $SYN_VCS_BASHRC
#source $SYN_SG_BASHRC
#source $SYN_DCSHELL_BASHRC
#source $SYN_PTSHELL_BASHRC
#source $CADENCE_XCELIUM_BASHRC
#source $SIEMENS_QUESTA_BASHRC
#source $XILINX_VIVADO_BASHRC
#source $QUARTUS_SETUP
