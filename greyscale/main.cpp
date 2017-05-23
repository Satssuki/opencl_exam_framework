#include <cp_lib.h>
#include <opencl_utility.h>
#include <opencl_api.h>
#include <cp_image.h>
#include <algorithm>
#include <cp_params.h>


int
main(CP_UNUSED int argc,
     CP_UNUSED char** argv)
{
    namespace cpcl = cp::opencl;
    cp_log_init();

    auto params = cp::parse_cmd(argc, argv, "assets/color_swirl.png", "assets/grey_scale_output.png");

    cpcl::api api(params.device_type,
                  "kernels/greyscale.cl",
                  "-Ikernels/cp_lib/ -Werror -cl-std=CL1.2");


    auto h_input_image = cp::load_image(params.in_filepath.c_str(),
                                        LCT_RGBA);

    cl_image_format image_format;
    image_format.image_channel_order = CL_RGBA;
    image_format.image_channel_data_type = CL_UNSIGNED_INT8;

    cl_image_desc image_description;
    image_description.image_type = CL_MEM_OBJECT_IMAGE2D;
    image_description.image_width = h_input_image.width;
    image_description.image_height = h_input_image.height;
    image_description.image_row_pitch = h_input_image.width * 4;
    image_description.image_slice_pitch = h_input_image.height * 4;
    image_description.num_mip_levels = 0;
    image_description.num_samples = 0;
    image_description.buffer = nullptr;

    cpcl::buffer d_input_image =
        cpcl::create_resource(clCreateImage,
                              api.context(),
                              CL_MEM_READ_ONLY |
                              CL_MEM_COPY_HOST_PTR |
                              CL_MEM_HOST_NO_ACCESS,
                              &image_format,
                              &image_description,
                              h_input_image.pixels.data());

    image_description.image_row_pitch = 0;
    image_description.image_slice_pitch = 0;

    cpcl::buffer d_output_image =
        cpcl::create_resource(clCreateImage,
                              api.context(),
                              CL_MEM_WRITE_ONLY |
                              CL_MEM_HOST_READ_ONLY,
                              &image_format,
                              &image_description,
                              nullptr);

    cpcl::kernel gaussian_blur =
        cpcl::create_resource(clCreateKernel,
                              api.program(),
                              "greyscale");

    cpcl::invoke(clSetKernelArg,
                 gaussian_blur.data(),
                 0,
                 sizeof(cl_mem),
                 &d_input_image.data());

    cpcl::invoke(clSetKernelArg,
                 gaussian_blur.data(),
                 1,
                 sizeof(cl_mem),
                 &d_output_image.data());

    std::size_t work_size[] = {h_input_image.width, h_input_image.height};
    cpcl::invoke(clEnqueueNDRangeKernel,
                 api.queue(), gaussian_blur.data(),
                 2, nullptr,
                 work_size,
                 nullptr, 0, nullptr, nullptr);

    cpcl::invoke(clFinish, api.queue());

    CP_DEBUG("Finished running kernel");

    cp::image h_output_image;
    h_output_image.width = h_input_image.width;
    h_output_image.height = h_input_image.height;
    h_output_image.pixels.resize(h_input_image.pixels.size());

    std::size_t origin[3] = {0,0,0};
    std::size_t region[3] = {h_input_image.width, h_input_image.height , 1};
    cpcl::invoke(clEnqueueReadImage,
                 api.queue(),
                 d_output_image.data(),
                 CL_TRUE,
                 origin,
                 region,
                 h_input_image.width * 4,
                 h_input_image.height * 4,
                 h_output_image.pixels.data(),
                 0, nullptr, nullptr),

    cp::write_image(params.out_filepath.c_str(),
                    h_output_image,
                    LCT_RGBA);

    cp_log_shutdown();

    return 0;
}