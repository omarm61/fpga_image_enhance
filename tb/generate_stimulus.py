#!/usr/bin/env python
import sys, getopt

def help():
    print ('add_newline.py -i <InputFile> -o <OutputFile> -w <LineWidth>')


def main(argv):
    file_in  = 'foreman_128x144.yuv'
    file_out = 'video_in_sim.txt'
    width    = 2*128
    counter  = 0

    # Check for input arguments
    try:
        opts, args = getopt.getopt(argv, "hi:o:w:", ["input=", "output=", "width="])
    except getopt.GetoptError:
        help()
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            help()
            sys.exit()
        elif opt in ("-i", "--input"):
            file_in = arg
        elif opt in ("-o", "--output"):
            file_out = arg
        elif opt in ("-w", "--width"):
            width = arg



    # Open File
    video_in  = open(file_in, 'r')
    video_out = open(file_out, 'w')

    # Read input file character by character
    while True:
        char = video_in.read(1)
        counter = counter + 1
        if (not char):
            print ("generate_stimulus is done")
            print ("input file : %s" % (file_in))
            print ("output file: %s" % (file_out))
            print ("# bytes    : %d" % (width))
            break
        else:
            # Check if the original file contains a new line
            if (ord(char) == 0x0A):
                video_out.write(chr(ord(char) + 1))
            else:
                video_out.write(char)

            # Add newline
            if (counter == width):
                # Reset counter
                counter = 0
                # Add newline to file
                video_out.write("\n")

    # Close file
    video_in.close()
    video_out.close()


if __name__ == "__main__":
    main(sys.argv[1:])
