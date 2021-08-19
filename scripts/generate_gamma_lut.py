# Import our modules that we are using
import struct
import numpy as np
import math

# Open File
f=open("gamma_lut.mif", "w")

# Generate LUT
# Create the vectors X and Y
x = np.array(range(256))
gamma_lut = (255 * (x/255) ** (1.8))


# Write data to file

# Convert data to binary and write to file
for i in range(len(gamma_lut)):
    lut_val = format(int(gamma_lut[i]), '03x')
    f.write(lut_val)
    f.write("\n")

# Close file
f.close()
