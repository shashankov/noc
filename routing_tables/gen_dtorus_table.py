#!/usr/bin/python

import numpy as np
import sys


def generate_table(num_rows, num_cols, row_id, col_id):
    num_routers = num_rows * num_cols
    table = np.zeros(num_routers, dtype=np.int32)
    for i in range(num_rows):
        for j in range(num_cols):
            if (j == col_id):
                if (i == row_id):
                    table[i * num_cols + j] = 0
                else:
                    table[i * num_cols + j] = 1
            else:
                table[i * num_cols + j] = 2

    return table

if __name__ == "__main__":
    if (len(sys.argv) != 4):
        print("Usage: " + sys.argv[0] + " <num_rows> <num_cols> <file_prefix>")
        sys.exit(1)

    num_rows = int(sys.argv[1])
    num_cols = int(sys.argv[2])
    table_prefix = sys.argv[3]
    num_routers = num_rows * num_cols

    for i in range(num_rows):
        for j in range(num_cols):
            table = generate_table(num_rows, num_cols, i, j)
            table_file = open("%s%d_%d.hex" % (table_prefix, i, j), "w")
            for k in range(num_routers):
                table_file.write("%d\n" % table[k])
            table_file.close()