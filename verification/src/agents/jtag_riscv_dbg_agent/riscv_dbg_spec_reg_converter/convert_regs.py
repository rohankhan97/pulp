#!/usr/bin/env python3

import csv
import xml.etree.ElementTree as ET
import click
from pathlib import Path

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

ACCESS_TYPE_MAP = {
    "R": "RO",
    "R/W": "RW",
    "R/W1C": "W1C",
    "W" : "WO",
    "W1" : "WO",
    "WARL" : "RW",
    "WARZ" : "WO"
}

RESET_MAP = {
    "-": "",
    "Preset": "",
    "preset": ""
}

@click.command()
@click.argument("src", type=click.Path(exists=True, file_okay=True, dir_okay=False))
@click.argument("dst", type=click.Path(exists=False, file_okay=True, dir_okay=False))
def convert_riscv_regs(src, dst):
    """Parse the XML register description format from the RISC-V debug specification repo and write a CSV file suitable for parsing with questa verguvm"""

    tree = ET.parse(src)
    root = tree.getroot()
    fields = [REG_NAME, REG_DESC, REG_ADDR, REG_WIDTH, REG_ACCESS, REG_RESVAL, FIELD_NAME, FIELD_DESC, FIELD_OFFSET, FIELD_WIDTH, FIELD_ACCESS, FIELD_RESVAL, FIELD_IS_VOL, FIELD_IS_RES]
    with Path(dst).open("w+") as dst_file:
        csv_writer = csv.DictWriter(dst_file, fieldnames=fields)
        csv_writer.writeheader()
        for reg in root:
            reg_name = reg.attrib.get('short', reg.attrib['name'])
            reg_entry = {
                REG_NAME: reg_name,
                REG_WIDTH: 32,
                REG_DESC: reg.attrib['name'],
                REG_ADDR: reg.attrib['address']
            }
            csv_writer.writerow(reg_entry)
            for field in reg:
                if field.attrib['name'] != "0":
                    bits: str = field.attrib['bits']
                    bit_range = sorted([int(idx) for idx in bits.split(":",1)])
                    start_bit = bit_range[0]
                    field_size = 1 if len(bit_range) == 1 else bit_range[1] - bit_range[0] + 1
                    field_entry = {
                        REG_NAME: reg_name,
                        FIELD_NAME: field.attrib['name'],
                        FIELD_OFFSET: start_bit,
                        FIELD_WIDTH: field_size,
                        FIELD_ACCESS: ACCESS_TYPE_MAP[field.attrib['access']],
                        FIELD_RESVAL: RESET_MAP.get(field.attrib['reset'],field.attrib['reset']),
                        FIELD_IS_RES: "FALSE",
                        FIELD_IS_VOL: "TRUE"
                    }
                    csv_writer.writerow(field_entry)


if __name__ == '__main__':
    # convert_riscv_regs(["dm_registers.xml", "dm_regs.csv"])
    convert_riscv_regs()
