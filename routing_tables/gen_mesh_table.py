#!/usr/bin/python

import numpy as np
import sys

def calculate_port(num_rows, num_cols, row_id, col_id, dir):
    port = 1
    if (dir == "NORTH"):
        return port
    if (row_id != 0):
        port += 1

    if (dir == "SOUTH"):
        return port
    if (row_id != num_rows - 1):
        port += 1

    if (dir == "EAST"):
        return port
    if (col_id != num_cols - 1):
        port += 1

    return port

def generate_table(num_rows, num_cols, row_id, col_id):
    num_routers = num_rows * num_cols
    table = np.zeros(num_routers, dtype=np.int32)
    for i in range(num_rows):
        for j in range(num_cols):
            if (j == col_id):
                if (i == row_id):
                    table[i * num_cols + j] = 0
                elif (i < row_id):
                    table[i * num_cols + j] = calculate_port(num_rows, num_cols, row_id, col_id, "NORTH")
                else:
                    table[i * num_cols + j] = calculate_port(num_rows, num_cols, row_id, col_id, "SOUTH")
            elif (j < col_id):
                table[i * num_cols + j] = calculate_port(num_rows, num_cols, row_id, col_id, "WEST")
            else:
                table[i * num_cols + j] = calculate_port(num_rows, num_cols, row_id, col_id, "EAST")

    return table

if __name__ == "__main__":
    if (len(sys.argv) != 4):
        print("Usage: ./gen_mesh_table.py <num_rows> <num_cols> <file_prefix>")
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