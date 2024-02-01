#!/usr/bin/python

import numpy as np
import sys

def generate_table(num_routers, router_id):
    table = np.zeros(num_routers, dtype=np.int32)
    for i in range(num_routers):
        if (i != router_id):
            table[i] = 1
        else:
            table[i] = 0
    return table

if __name__ == "__main__":
    if (len(sys.argv) != 3):
        print("Usage: " + sys.argv[0] + " <num_routers> <file_prefix>")
        sys.exit(1)

    num_routers = int(sys.argv[1])
    table_prefix = sys.argv[2]

    for i in range(num_routers):
        table = generate_table(num_routers, i)
        table_file = open("%s%d.hex" % (table_prefix, i), "w")
        for k in range(num_routers):
            table_file.write("%d\n" % table[k])
        table_file.close()