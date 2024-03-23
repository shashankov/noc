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
                    dist_down = (i - row_id + num_rows) % num_rows
                    dist_up = (row_id - i + num_rows) % num_rows
                    if (dist_down < dist_up):
                        table[i * num_cols + j] = 3
                    elif (dist_down > dist_up):
                        table[i * num_cols + j] = 1
                    else:
                        table[i * num_cols + j] = 1 if ((row_id % 2) == 0) else 3
            else:
                dist_right = (j - col_id + num_cols) % num_cols
                dist_left = (col_id - j + num_cols) % num_cols
                if (dist_right < dist_left):
                    table[i * num_cols + j] = 4
                elif (dist_right > dist_left):
                    table[i * num_cols + j] = 2
                else:
                    table[i * num_cols + j] = 4 if ((col_id % 2) == 0) else 2

    return table

if __name__ == "__main__":
    if (len(sys.argv) != 4):
        print("Usage: " + sys.argv[0] + " <num_rows> <num_cols> <file_prefix>")
        sys.exit(1)

    num_rows = int(sys.argv[1])
    num_cols = int(sys.argv[2])
    table_prefix = sys.argv[3]
    num_routers = num_rows * num_cols

    # Create folder if it doesn't exist
    import os
    if not os.path.exists(table_prefix):
        os.makedirs(table_prefix)

    for i in range(num_rows):
        for j in range(num_cols):
            table = generate_table(num_rows, num_cols, i, j)
            table_file = open("%s/%d_%d.hex" % (table_prefix, i, j), "w")
            for k in range(num_routers):
                table_file.write("%d\n" % table[k])
            table_file.close()
