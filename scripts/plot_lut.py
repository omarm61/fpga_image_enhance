# Import our modules that we are using
import matplotlib.pyplot as plt
import numpy as np
import math
import sys
import getopt

def print_help():
    print ("./plot_lut.py -g <gamma ratio>")

def main(argv):
    gamma = 1.4
    try:
        opts, args = getopt.getopt(argv, "g:", ["gamma="])
    except getopt.GetoptError:
        print_help()
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print_help()
            sys.exit()
        elif opt in ("-g", "--gamma"):
            gamma = float(arg)

    # Create the vectors X and Y
    x = np.array(range(256))
    y = x+2*(255 * (x/255) ** (gamma))

    # Create the plot
    plt.plot(x[0:255],y[0:255])

    # Show the plot
    plt.show()

if __name__ == "__main__":
    main(sys.argv[1:])
