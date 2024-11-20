# Import our modules that we are using
import struct
import numpy as np
import math
import sys, getopt
from scipy.interpolate import CubicSpline

# Parameters
max_value = 255
midpoint = max_value // 2  # Halfway point




def help():
    print ('generate_gamma.py -o <OutputFile> -g <ratio>')


def main(argv):
    file_out  = 'gamma_lut.mif'
    gamma = 0.7

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
    #x = np.array(range(256))
    #gamma_lut = (255 * (x/255) ** (gamma))

    dip_factor = gamma  # Factor to lower the midpoint (0 to 1)
    # Define key points for the curve
    x_points = [0, midpoint // 4, midpoint // 2,  midpoint // 2 + 50, midpoint + 80, 50 + midpoint + midpoint // 2, max_value]
    y_points = [0, midpoint // 4, midpoint // 2, midpoint // 2 + 50, 80 + midpoint * dip_factor,50 + midpoint + midpoint // 2 - 20, max_value]

    # Create a cubic spline through the points
    spline = CubicSpline(x_points, y_points)
    
    # Generate x values and corresponding y values
    x = np.linspace(0, max_value, 255)
    gamma_lut = spline(x)



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
