# Import our modules that we are using
import struct
import numpy as np
import math
import sys, getopt

def help():
    print ('generate_gamma.py -o <OutputFile> -g <ratio>')


def main(argv):
    file_out  = 'gamma_lut_.mif'
    gamma = 1.4

    # Check for input arguments
    try:
        opts, args = getopt.getopt(argv, "ho:g:", ["output=", "gamma="])
    except getopt.GetoptError:
        help()
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            help()
            sys.exit()
        elif opt in ("-o", "--output"):
            file_out = arg
        elif opt in ("-g", "--gamma"):
            gamma = float(arg)

    # Open File
    f=open(file_out, "w")

    # Generate LUT
    # Create the vectors X and Y
    x = np.array(range(256))
    gamma_lut = (255 * (x/255) ** (gamma))


    # Write data to file

    # Convert data to binary and write to file
    for i in range(len(gamma_lut)):
        lut_val = format(int(gamma_lut[i]), '03x')
        f.write(lut_val)
        f.write("\n")

    # Close file
    f.close()

if __name__ == "__main__":
    main(sys.argv[1:])
