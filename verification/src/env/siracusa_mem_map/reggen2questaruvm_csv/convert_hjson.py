#!/usr/bin/env python3

import csv
from typing import Tuple
import click
from pathlib import Path

from reggen.access import HwAccess, SwRdAccess
from reggen.ip_block import IpBlock

REG_NAME = "Register Name"
REG_DESC = "Register Description"
REG_ADDR = "Register Address"
REG_WIDTH = "Register Width"
REG_ACCESS = "Register Access"
REG_RESVAL = "Register Reset Value"
FIELD_NAME = "Field Name"
FIELD_DESC = "Field Description"
FIELD_OFFSET = "Field Offset"
FIELD_WIDTH = "Field Width"
FIELD_ACCESS = "Field Access"
FIELD_RESVAL = "Field Reset Value"
FIELD_IS_RES = "Field is Reserved"
FIELD_IS_VOL = "Field is Volatile"
FIELD_BACKDOOR = "Field Backdoor"
regs_fields = [REG_NAME, REG_DESC, REG_ADDR, REG_WIDTH, REG_ACCESS, REG_RESVAL, FIELD_NAME, FIELD_DESC, FIELD_OFFSET,
              FIELD_WIDTH, FIELD_ACCESS, FIELD_RESVAL, FIELD_IS_VOL, FIELD_IS_RES, FIELD_BACKDOOR]
BLOCK_NAME = "Block Name"
BLOCK_DESCRIPTION = "Block Description"
BLOCK_COVERAGE = "Block Coverage"
BLOCK_BACKDOOR = "Block Backdoor"
BLOCK_COMPONENT_NAME = "Block Component Name"
BLOCK_INSTANCE_NAME = "Block Instance Name"
BLOCK_INSTANCE_TYPE = "Block Instance Type"
BLOCK_INSTANCE_DESCRIPTION = "Block Instance Description"
BLOCK_INSTANCE_DIMENSION = "Block Instance Dimension"
BLOCK_INSTANCE_BACKDOOR = "Block Instance Backdoor"
BLOCK_INSTANCE_NO_REG_TESTS = "Block Instance No Reg Tests"
BLOCK_INSTANCE_NO_REG_ACCESS_TEST = "Block Instance No Reg Access Test"
BLOCK_INSTANCE_NO_REG_SHARED_ACCESS_TEST = "Block Instance No Reg Shared Access Test"
BLOCK_INSTANCE_NO_REG_BIT_BASH_TEST = "Block Instance No Reg Bit Bash Test"
BLOCK_INSTANCE_NO_REG_HW_RESET_TEST = "Block Instance No Reg HW Reset Test"
BLOCK_INSTANCE_NO_MEM_TESTS = "Block Instance No Mem Tests"
BLOCK_INSTANCE_NO_MEM_ACCESS_TEST = "Block Instance No Mem Access Test"
BLOCK_INSTANCE_NO_MEM_SHARED_ACCESS_TEST = "Block Instance No Mem Shared Access Test"
BLOCK_INSTANCE_NO_MEM_WALK_TEST = "Block Instance No Mem Walk Test"
PROJECT_EXTRA_IMPORTS = "Project Extra Imports"
block_fields = [BLOCK_NAME, BLOCK_DESCRIPTION, BLOCK_COVERAGE, BLOCK_BACKDOOR, BLOCK_COMPONENT_NAME, BLOCK_INSTANCE_NAME, BLOCK_INSTANCE_TYPE, BLOCK_INSTANCE_DESCRIPTION, BLOCK_INSTANCE_DIMENSION, BLOCK_INSTANCE_BACKDOOR, BLOCK_INSTANCE_NO_REG_TESTS, BLOCK_INSTANCE_NO_REG_ACCESS_TEST, BLOCK_INSTANCE_NO_REG_SHARED_ACCESS_TEST, BLOCK_INSTANCE_NO_REG_BIT_BASH_TEST, BLOCK_INSTANCE_NO_REG_HW_RESET_TEST, BLOCK_INSTANCE_NO_MEM_TESTS, BLOCK_INSTANCE_NO_MEM_ACCESS_TEST, BLOCK_INSTANCE_NO_MEM_SHARED_ACCESS_TEST, BLOCK_INSTANCE_NO_MEM_WALK_TEST, PROJECT_EXTRA_IMPORTS]

MAP_BLOCK_NAME = "Block Name"
MAP_BLOCK_MAP_NAME = "BlockMap Name"
MAP_BLOCK_MAP_DESCRIPTION = "BlockMap Description"
MAP_BLOCK_MAP_IS_DEFAULT = "BlockMap is default"
MAP_BLOCK_MAP_INSTANCE_NAME = "BlockMap Instance Name"
MAP_BLOCK_MAP_INSTANCE_ADDRESS = "BlockMap Instance Address"
MAP_BLOCK_MAP_INSTANCE_ACCESS = "BlockMap Instance Access"
MAP_BLOCK_MAP_ADDRESS_OFFSET = "BlockMap Address Offset"

map_fields = [MAP_BLOCK_NAME, MAP_BLOCK_MAP_NAME, MAP_BLOCK_MAP_DESCRIPTION, MAP_BLOCK_MAP_IS_DEFAULT, MAP_BLOCK_MAP_INSTANCE_NAME, MAP_BLOCK_MAP_INSTANCE_ADDRESS, MAP_BLOCK_MAP_INSTANCE_ACCESS, MAP_BLOCK_MAP_ADDRESS_OFFSET]

class KeyValueParamType(click.ParamType):
    name="key-value_pair"
    def convert(self, value, param, ctx) -> Tuple[str, str]:
        if isinstance(value, tuple):
            return value
        elif isinstance(value, str):
            pair = value.split('=')
            if len(pair) != 2:
                self.fail(f"{value!r} is not a valid key-value pair", param, ctx)
            else:
                return (pair[0].strip(), pair[1].strip())
        else:
            self.fail(f"{value!r} is not a valid key-value pair", param, ctx)




@click.command()
@click.argument("src", type=click.Path(exists=True, file_okay=True, dir_okay=False))
@click.argument("outdir", type=click.Path(exists=True, file_okay=False, dir_okay=True))
@click.option("--param", "-p", multiple=True, type=KeyValueParamType(), help="Change parameter values of the reggen hjson description. Supply the parameters in the form param_name=value. You can use this option multiple times to supply multiple parameters.")
@click.option("--block-bkdr", type=str, help="The backdoor hdl path if the block is used as the toplevel block")
def convert_hjson(src: str, outdir: str, param, block_bkdr):
    """Parse a reggen hjson file and create a set of CSV file compatible with the Questa UVM RAL generator."""
    obj = IpBlock.from_path(src, param)
    outdir_path = Path(outdir)
    block_csv = outdir_path/f"{obj.name}_block.csv"
    regs_csv = outdir_path/f"{obj.name}_regs.csv"
    map_csv = outdir_path/f"{obj.name}_map.csv"
    with block_csv.open("w+") as block_file, regs_csv.open("w+") as regs_file, map_csv.open("w+") as map_file:
        regs_csv_writer = csv.DictWriter(regs_file, fieldnames=regs_fields)
        regs_csv_writer.writeheader()
        block_csv_writer = csv.DictWriter(block_file, fieldnames=block_fields)
        block_csv_writer.writeheader()
        map_csv_writer = csv.DictWriter(map_file, fieldnames=map_fields)
        map_csv_writer.writeheader()

        # Create block entry
        block_entry = {
            BLOCK_NAME: obj.name.lower()+"_block",
            BLOCK_BACKDOOR: block_bkdr
        }
        block_csv_writer.writerow(block_entry)

        # Create map entry
        map_entry = {
            MAP_BLOCK_NAME: obj.name.lower()+"_block",
            MAP_BLOCK_MAP_NAME: obj.name.lower()+"_map",
            MAP_BLOCK_MAP_DESCRIPTION: "Default Map",
            MAP_BLOCK_MAP_IS_DEFAULT: True
        }
        map_csv_writer.writerow(map_entry)

        for reg_block in obj.reg_blocks.values():
            for reg in reg_block.flat_regs:
                # Create reg entry in the regs csv
                reg_entry = {
                    REG_NAME: obj.name.lower() + "_" +reg.name.lower(),
                    REG_WIDTH: obj.regwidth,
                    REG_DESC: reg.desc,
                    REG_ADDR: reg.offset,
                    REG_RESVAL: reg.resval
                }
                regs_csv_writer.writerow(reg_entry)
                # Create entry in the block csv with the HDL path
                block_entry = {
                    BLOCK_NAME: obj.name.lower()+"_block",
                    BLOCK_COMPONENT_NAME: obj.name.lower() + "_" + reg.name.lower(),
                    BLOCK_INSTANCE_NAME: reg.name.lower(),
                    BLOCK_INSTANCE_TYPE: "reg",
                    BLOCK_INSTANCE_BACKDOOR: "%(FIELDS)",
                    BLOCK_INSTANCE_DESCRIPTION: reg.desc,
                }
                block_csv_writer.writerow(block_entry)
                # Create entry in map csv
                map_entry = {
                    MAP_BLOCK_NAME: obj.name.lower() + "_block",
                    MAP_BLOCK_MAP_NAME: obj.name.lower() + "_map",
                    MAP_BLOCK_MAP_INSTANCE_NAME: reg.name.lower(),
                    MAP_BLOCK_MAP_INSTANCE_ADDRESS: reg.offset
                }
                map_csv_writer.writerow(map_entry)
                for field in reg.fields:
                    if field.swaccess.key == "r0w1c":
                        field_access = "W1C"
                    else:
                        if field.swaccess.value[1].name:
                            field_access = field.swaccess.value[1].name
                        else:
                            if reg.swaccess.key == "r0w1c":
                                field_access = "W1C"
                            else:
                                field_access = reg.swaccess.value[1].name

                    if not field.hwaccess.allows_write():
                        field_volatile = 0
                    else:
                        field_volatile = 1
                    if len(reg.fields) == 1:
                        reg_field_name = reg.name.lower()
                    else:
                        reg_field_name = reg.name.lower() + "_" + field.name.lower()
                    if ((field.hwaccess.value[1] == HwAccess.NONE and field.swaccess.swrd() == SwRdAccess.RD and not field.swaccess.allows_write())):
                        backdoor_path = f"{reg_field_name}_qs"
                    else:
                        backdoor_path = f"u_{reg_field_name}.q{'s' if reg.hwext else ''}"
                    field_entry = {
                        REG_NAME: obj.name.lower() + "_" +reg.name.lower(),
                        FIELD_NAME: field.name.lower(),
                        FIELD_DESC: field.desc,
                        FIELD_OFFSET: field.bits.lsb,
                        FIELD_WIDTH: field.bits.width(),
                        FIELD_RESVAL: field.resval,
                        FIELD_ACCESS: field_access,
                        FIELD_IS_VOL: field_volatile,
                        FIELD_BACKDOOR: backdoor_path
                    }
                    regs_csv_writer.writerow(field_entry)






if __name__ == '__main__':
    convert_hjson()
    #convert_hjson(["/usr/scratch/blitzstein/meggiman/projects/siracusa/siracusa-fe/.bender/git/checkouts/i3c_wrapper-2389730b2a013638/i3c_registers.hjson", "."])

