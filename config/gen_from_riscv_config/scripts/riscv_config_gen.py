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
# Original Author: Oukalrazqou Abdessamii
"""Module is used to factorize multiples registers with the same name to
a specific format of registers"""

import argparse

from libs.utils import CsrParser
from libs.utils import IsaParser
from libs.utils import SpikeParser
from libs.utils import IsaGenerator
from libs.utils import CsrGenerator
from libs.utils import SpikeGenerator
from libs.utils import RstAddressBlock
from libs.utils import AdocAddressBlock
from libs.utils import MdAddressBlock
from libs.utils import InstrstBlock
from libs.utils import InstadocBlock
from libs.utils import InstmdBlock


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="GEN From RISC-V Config")
    parser.add_argument("-s", "--srcFile", help="isa_gen yaml input file")
    parser.add_argument("-c", "--customFile", help=" custom_gen yaml input file")
    parser.add_argument("-d", "--debugFile", help=" debug_gen yaml input file")
    parser.add_argument("-m", "--modif", help="ISA /CSR Formatter if exist")
    parser.add_argument("-i", "--temp", help="Full ISA /SPIKETemplate")
    parser.add_argument("-t", "--target", help="Specify Config Name")
    parser.add_argument("-f", "--format", help="Specify format output")
    args, unknown_args = parser.parse_known_args()

    if args.format in ['rst']:
        C_instrBlock = InstrstBlock
        C_AddressBlock = RstAddressBlock
    elif args.format in ['adoc']:
        C_instrBlock = InstadocBlock
        C_AddressBlock = AdocAddressBlock
    elif args.format in ['md']:
        C_instrBlock = InstmdBlock
        C_AddressBlock = MdAddressBlock
    else:
        C_instrBlock = InstrstBlock
        C_AddressBlock = RstAddressBlock

    if args.temp:
        if "isa" in args.temp:
            e = IsaParser(args.srcFile, args.temp, args.target, args.modif)
            document = e.returnDocument()
            generator = IsaGenerator(args.target)
            generator.generateISA(C_instrBlock, document)
        elif "spike" in args.temp:
            e = SpikeParser(args.srcFile, args.target)
            document = e.returnDocument()
            spike_generator = SpikeGenerator(args.target, args.temp, args.modif)
            spike_generator.generateSpike(document)
    else:
        e = CsrParser(
            args.srcFile, args.customFile, args.debugFile, args.target, args.modif
        )
        document = e.returnDocument()
        generator = CsrGenerator(args.target)
        generator.generateCSR(C_AddressBlock, document)
