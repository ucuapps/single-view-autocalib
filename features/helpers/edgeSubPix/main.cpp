#include "mex.hpp"
#include "mexAdapter.hpp"
#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include "Canny.h"

using namespace matlab::data;
using matlab::mex::ArgumentList;
using namespace std;
using namespace cv;

class MexFunction : public matlab::mex::Function {
public:
    void operator()(ArgumentList outputs, ArgumentList inputs) {
        Mat image;
        if (inputs[0].getType() == ArrayType::MATLAB_STRING) {
            TypedArray<MATLABString> filenameref = inputs[0];
            string filename = std::string(filenameref[0]);
            image = imread(filename, IMREAD_GRAYSCALE);
        } else {
            TypedArray<uchar> imageInfo = std::move(inputs[0]);
            image = Mat(imageInfo.getDimensions()[0],imageInfo.getDimensions()[1], CV_8UC1, Scalar::all(0));
            int height = imageInfo.getDimensions()[0];
            int width = imageInfo.getDimensions()[1];
            for (int i = 0; i < height; i++) {
                for (int j = 0; j < width; j++) {
                    image.at<uchar>(i, j) = (uchar) (imageInfo[i][j][2] * 0.114 + imageInfo[i][j][1] * 0.587 + imageInfo[i][j][0] * 0.299);
                }
            }
        }

        const int low = inputs[1][0];
        const int high = inputs[2][0];
        const double alpha = inputs[3][0];
        int mode = 1;

        vector<Contour> contours;
        vector<Vec4i> hierarchy;

        Canny(image, alpha, low, high, contours, hierarchy, mode);
//        cout << contours[0].points;
        ArrayFactory factory;
        outputs[0] = factory.createCellArray({ 1, contours.size() });
        for (int i = 0; i < contours.size(); i++) {
            int length = contours[i].points.size() * 2;
            double *points = new double[length];
            for (int j = 0; j < contours[i].points.size(); j++) {
                points[2 * j] = contours[i].points[j].x;
                points[2 * j + 1] = contours[i].points[j].y;
            }
            outputs[0][i] = factory.createArray<double>({ 2, contours[i].points.size()}, points, points + length);
        }
    }

    void checkArguments(ArgumentList outputs, ArgumentList inputs) {
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        ArrayFactory factory;
        if (inputs[0].getType() != ArrayType::DOUBLE ||
            inputs[0].getType() == ArrayType::COMPLEX_DOUBLE)
        {
            matlabPtr->feval(u"error", 0,
                             std::vector<Array>({ factory.createScalar("Input must be double array") }));
        }

        if (outputs.size() > 1) {
            matlabPtr->feval(u"error", 0,
                             std::vector<Array>({ factory.createScalar("Only one output is returned") }));
        }
    }
};