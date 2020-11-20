cmake_minimum_required(VERSION 3.10)
project(edgeSubPix)

set(CMAKE_CXX_STANDARD 14)

set(HEADER_FILES include/Canny.h)
set(SRC_FILES src/Canny.cpp)

find_package(OpenCV REQUIRED)
find_package(Matlab REQUIRED)

include_directories(include ${OpenCV_INCLUDE_DIRS})

matlab_add_mex(NAME ${PROJECT_NAME} SRC main.cpp ${SRC_FILES} ${HEADER_FILES} LINK_TO ${OpenCV_LIBS})