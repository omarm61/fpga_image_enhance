#include <opencv2/opencv.hpp>
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <unistd.h>
#include <math.h>

using namespace cv;
using namespace std;

#define  FRAME_WIDTH_DEFAULT        128
#define  FRAME_HEIGHT_DEFAULT       144
#define  GAMMA_RATIO_DEFAULT        1.4

int c;
struct arg_t {
    char *InFile;
    int frame_width    = FRAME_WIDTH_DEFAULT;
    int frame_height   = FRAME_HEIGHT_DEFAULT;
    bool verbose       = 0;
    float gamma        = GAMMA_RATIO_DEFAULT;
};

void printhelp() {
    cout << "praw -i <Input Image> -s <WidthxHeight>" << endl;
    cout << "-i:     Input video" << endl;
    cout << "-s:     frame dimensions. (default= 128x144)" << endl;
    cout << "-v:     verbose" << endl;
    cout << "-h:     Help" << endl;
}

int main (int argc, char** argv)
{
    struct arg_t arg;
    const string s_delim = "x";
    string s_dim;
    string s_width;
    string s_height;
    int frame_width;
    int frame_height;
    //Mat frame;
    Mat frame_proc;
    vector <Mat> frame_proc_ch;
    double fps;
    double dWidth;
    double dHeight;
    //int   pixel_counter;
    // LUT
    float lut_value;
    int dim(256);
    Mat lut(1, &dim, CV_8U);

    // Parse Input Arguments
    while ((c = getopt (argc, argv, "hvi:s:g:")) != EOF)
    switch(c)
    {
        case 'i':
            arg.InFile = optarg;
            break;
        case 's':
            s_dim = optarg;
            // Parse frame dimensions string
            s_width  = s_dim.substr(0, s_dim.find(s_delim)); // Extract width
            s_dim    = s_dim.erase(0, s_dim.find(s_delim) + s_delim.length());
            s_height = s_dim;
            // Convert string to integer
            arg.frame_width  = stoi(s_width);
            arg.frame_height = stoi(s_height);
            break;
        case 'g':
            arg.gamma = stof(optarg);
            break;
        case 'v':
            arg.verbose = 1;
            break;
        case 'h':
            printhelp();
            //goto ExitProgram;
            break;
    }


    if (arg.verbose) {
        cout << "Input File: "  << arg.InFile << endl;
        cout << "Image Width: " << arg.frame_width << endl;
        cout << "Image Height: " << arg.frame_height << endl;
        cout << "Gamma Ratio: " << arg.gamma << endl;
    }

    char yuv1D_in[arg.frame_width*arg.frame_height*2];
    Mat inFrame(arg.frame_height, arg.frame_width, CV_8UC2);
    ifstream inputFile(arg.InFile, ios::binary);
    ofstream outputFile("c_edge_enhancement.yuv", ios::binary);

    float kdata[] = {-1, -1, -1,
                     -1, 9, -1,
                     -1, -1, -1};
    Mat kernel(3,3,CV_32F,kdata);

    //String window_name = "My first Video";
    String window_name_proc = "Filter window";
    String window_yuv_feed = "YUV Feed";

    // Generate LUT
    for (int i=0; i<256; i++) {
        lut_value = 255.0 * pow((i/255.0), (arg.gamma));
        lut.at<char>(i)= (int)lut_value;
    }

    //namedWindow(window_name, WINDOW_NORMAL);
    namedWindow(window_name_proc, WINDOW_NORMAL);
    resizeWindow(window_name_proc, 200, 200);
    moveWindow(window_name_proc, 0, 0);
    namedWindow(window_yuv_feed, WINDOW_NORMAL);
    resizeWindow(window_yuv_feed, 200, 200);
    moveWindow(window_yuv_feed, 300, 0);

    while (true)
    {
        if (inputFile.is_open())
        {
            inputFile.read(yuv1D_in, sizeof(yuv1D_in));
        }

        inFrame = Mat(arg.frame_height, arg.frame_width, CV_8UC2, yuv1D_in);
        split(inFrame, frame_proc_ch);
        //cvtColor(inFrame, inFrame, cv::COLOR_YUV2BGR_YUYV);


        // Apply LUT
        LUT(frame_proc_ch[0], lut, frame_proc_ch[0]);
        // Change the brightness
        //frame.convertTo(frame, -1, 1, -40);
        //cvtColor(inFrame, frame_proc, COLOR_RGB2GRAY);
        filter2D(frame_proc_ch[0], frame_proc_ch[0], -1, kernel, Point(-1,-1), 0, BORDER_DEFAULT);
        //merge(inFrame_ch, inFrame);
        merge(frame_proc_ch,frame_proc);

        // Write data to file
        if (outputFile.is_open())
        {
            outputFile << frame_proc.data;
        }

        // Change color space
        cvtColor(inFrame, inFrame, cv::COLOR_YUV2BGR_YUYV);
        cvtColor(frame_proc, frame_proc, cv::COLOR_YUV2BGR_YUYV);

        // Show frame
        imshow(window_yuv_feed, inFrame);
        imshow(window_name_proc, frame_proc);


        usleep(30000);
        if ( waitKey(10) == 114)
        {
            printf("Repeat");
            inputFile.seekg(0);
        }
        if ( waitKey(10) == 27 || inputFile.eof() == 1)
        {
            printf("Stopping video\n");
            break;
        }
    }

    inputFile.close();
    outputFile.close();
    return 0;

//ExitProgram:
//    if (arg.verbose)
//        cout << "\nDone\n";

}


