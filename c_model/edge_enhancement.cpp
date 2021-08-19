#include <stdio.h>
#include <iostream>
#include <fstream>
#include <unistd.h>
#include <math.h>
#include <opencv2/opencv.hpp>

using namespace cv;
using namespace std;

#define  FRAME_WIDTH   128
#define  FRAME_HEIGHT  144

int main (int argc, char** argv)
{
    //Mat frame;
    Mat frame_proc;
    Mat inFrame(FRAME_HEIGHT, FRAME_WIDTH, CV_8UC2);
    vector <Mat> frame_proc_ch;
    double fps;
    double dWidth;
    double dHeight;
    //int   pixel_counter;
    // LUT
    float lut_value;
    int dim(256);
    Mat lut(1, &dim, CV_8U);


    char yuv1D_in[FRAME_WIDTH*FRAME_HEIGHT*2];
    ifstream inputFile("foreman_128x144.yuv", ios::binary);
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
        lut_value = 255.0 * pow((i/255.0), (1.4));
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

        inFrame = Mat(FRAME_HEIGHT, FRAME_WIDTH, CV_8UC2, yuv1D_in);
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
}


