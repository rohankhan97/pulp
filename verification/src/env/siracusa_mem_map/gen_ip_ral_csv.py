#!/usr/bin/env python3

from plumbum import local
from pathlib import Path

project_root = Path("../../../..")
package_hjson_path_tuples = [
    (None, "rtl/pulp/siracusa_chip_ctrl/chip_ctrl_registers.hjson"),
    (None, "rtl/pulp/padframe/siracusa_pads/src/siracusa_pads_debug_regs.hjson"),
    (None, "rtl/pulp/padframe/siracusa_pads/src/siracusa_pads_functional_regs.hjson"),
    ("cluster_write_fifo", "cluster_write_fifo_regs.hjson"),
    ("pulp_cluster", "rtl/weight_memory_subsystem/weight_memory_registers.hjson"),
    ("gpio", "gpio_regs.hjson"),
    ("i3c_wrapper", "i3c_registers.hjson"),
    ("pll_wrapper", "pll_registers.hjson"),
]


bender = local["bender"]
convert_hjson = local["reggen2questaruvm_csv/convert_hjson.py"]


for (package, path) in package_hjson_path_tuples:
    if not package:
        package_path = project_root
    else:
        package_path = bender('path', package).strip()
    hjson_path = Path(package_path)/path
    print(f"Generating CSV description for {hjson_path}")
    convert_hjson(hjson_path, ".")
