#include <cp_lib_types.h>
// 5x5 kernel, sigma 1.0
// Generated from: http://dev.theomader.com/gaussian-kernel-calculator/

__constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE |
                               CLK_ADDRESS_CLAMP_TO_EDGE |
                               CLK_FILTER_NEAREST;

__constant const int32_t matrix_size = 15;

//__constant float weight_matrix[5][5] =
//{
//    {0.003765f,    0.015019f,    0.023792f,    0.015019f,    0.003765f},
//    {0.015019f,    0.059912f,    0.094907f,    0.059912f,    0.015019f},
//    {0.023792f,    0.094907f,    0.150342f,    0.094907f,    0.023792f},
//    {0.015019f,    0.059912f,    0.094907f,    0.059912f,    0.015019f},
//    {0.003765f,    0.015019f,    0.023792f,    0.015019f,    0.003765f},
//};

__constant float weight_matrix[15][15] =
{
    { 0.00326f,     0.003479f,    0.003676f,    0.003845f,    0.003982f,    0.004082f,    0.004144f,    0.004165f,    0.004144f,    0.004082f,    0.003982f,    0.003845f,    0.003676f,    0.003479f,    0.00326f },
    { 0.003479f,    0.003713f,    0.003922f,    0.004103f,    0.004249f,    0.004356f,    0.004422f,    0.004444f,    0.004422f,    0.004356f,    0.004249f,    0.004103f,    0.003922f,    0.003713f,    0.003479f },
    { 0.003676f,    0.003922f,    0.004144f,    0.004334f,    0.004489f,    0.004602f,    0.004672f,    0.004695f,    0.004672f,    0.004602f,    0.004489f,    0.004334f,    0.004144f,    0.003922f,    0.003676f },
    { 0.003845f,    0.004103f,    0.004334f,    0.004534f,    0.004695f,    0.004814f,    0.004887f,    0.004911f,    0.004887f,    0.004814f,    0.004695f,    0.004534f,    0.004334f,    0.004103f,    0.003845f },
    { 0.003982f,    0.004249f,    0.004489f,    0.004695f,    0.004862f,    0.004985f,    0.005061f,    0.005086f,    0.005061f,    0.004985f,    0.004862f,    0.004695f,    0.004489f,    0.004249f,    0.003982f },
    { 0.004082f,    0.004356f,    0.004602f,    0.004814f,    0.004985f,    0.005111f,    0.005188f,    0.005214f,    0.005188f,    0.005111f,    0.004985f,    0.004814f,    0.004602f,    0.004356f,    0.004082f },
    { 0.004144f,    0.004422f,    0.004672f,    0.004887f,    0.005061f,    0.005188f,    0.005267f,    0.005293f,    0.005267f,    0.005188f,    0.005061f,    0.004887f,    0.004672f,    0.004422f,    0.004144f },
    { 0.004165f,    0.004444f,    0.004695f,    0.004911f,    0.005086f,    0.005214f,    0.005293f,    0.00532f,     0.005293f,    0.005214f,    0.005086f,    0.004911f,    0.004695f,    0.004444f,    0.004165f },
    { 0.004144f,    0.004422f,    0.004672f,    0.004887f,    0.005061f,    0.005188f,    0.005267f,    0.005293f,    0.005267f,    0.005188f,    0.005061f,    0.004887f,    0.004672f,    0.004422f,    0.004144f },
    { 0.004082f,    0.004356f,    0.004602f,    0.004814f,    0.004985f,    0.005111f,    0.005188f,    0.005214f,    0.005188f,    0.005111f,    0.004985f,    0.004814f,    0.004602f,    0.004356f,    0.004082f },
    { 0.003982f,    0.004249f,    0.004489f,    0.004695f,    0.004862f,    0.004985f,    0.005061f,    0.005086f,    0.005061f,    0.004985f,    0.004862f,    0.004695f,    0.004489f,    0.004249f,    0.003982f },
    { 0.003845f,    0.004103f,    0.004334f,    0.004534f,    0.004695f,    0.004814f,    0.004887f,    0.004911f,    0.004887f,    0.004814f,    0.004695f,    0.004534f,    0.004334f,    0.004103f,    0.003845f },
    { 0.003676f,    0.003922f,    0.004144f,    0.004334f,    0.004489f,    0.004602f,    0.004672f,    0.004695f,    0.004672f,    0.004602f,    0.004489f,    0.004334f,    0.004144f,    0.003922f,    0.003676f },
    { 0.003479f,    0.003713f,    0.003922f,    0.004103f,    0.004249f,    0.004356f,    0.004422f,    0.004444f,    0.004422f,    0.004356f,    0.004249f,    0.004103f,    0.003922f,    0.003713f,    0.003479f },
    { 0.00326f,     0.003479f,    0.003676f,    0.003845f,    0.003982f,    0.004082f,    0.004144f,    0.004165f,    0.004144f,    0.004082f,    0.003982f,    0.003845f,    0.003676f,    0.003479f,    0.00326f },
};

__kernel void gaussian_blur(__read_only image2d_t input_image,
                                       __write_only image2d_t output_image)
{
    int2 pos = (int2)(get_global_id(0), get_global_id(1));

    float4 blur_sum = {0.0f, 0.0f, 0.0f, 0.0f};

    for (int32_t i = -matrix_size / 2; i <= matrix_size / 2; ++i)
    {
        for (int32_t j = -matrix_size / 2; j <= matrix_size / 2; ++j)
        {
            float4 value = convert_float4(read_imageui(input_image,
                                                       sampler,
                                                       (int2)(pos.x + i, pos.y + j)));

            blur_sum += value * weight_matrix[i + matrix_size / 2][j + matrix_size / 2];
        }
    }

    write_imageui(output_image, pos, convert_uint4(blur_sum));
}