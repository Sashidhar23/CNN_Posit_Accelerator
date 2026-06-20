#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <stdexcept>
#include <cstdint>
#include <array>
#include <algorithm>

#include <universal/number/posit/posit.hpp>
#include <universal/number/quire/quire.hpp>

using namespace sw::universal;

using Scalar = posit<16, 1>;   // change later to posit<8,1>, posit<8,2>, posit<16,2>
using Acc    = quire<Scalar>;

using Tensor3 = std::vector<std::vector<std::vector<Scalar>>>; // [C][H][W]
using Tensor4 = std::vector<std::vector<std::vector<std::vector<Scalar>>>>; // [OC][IC][KH][KW]
using Matrix  = std::vector<std::vector<Scalar>>; // [O][I]

constexpr int IMG_H = 28;
constexpr int IMG_W = 28;
constexpr int K_H   = 3;
constexpr int K_W   = 3;

struct MNISTHeader {
    std::uint32_t nimages;
    std::uint32_t rows;
    std::uint32_t cols;
};

struct MNISTSample {
    int label;
    Tensor3 image; // [1][28][28]
};

struct ConvLayer {
    Tensor4 W;               // [out_ch][in_ch][3][3]
    std::vector<Scalar> b;   // [out_ch]
    bool pool_after;
};

struct LinearLayer {
    Matrix W;                // [out_features][in_features]
    std::vector<Scalar> b;   // [out_features]
};

struct VGGMNISTModel {
    std::vector<ConvLayer> conv_layers;
    LinearLayer fc0;
    LinearLayer fc3;
};

std::vector<double> load_numbers_txt(const std::string& path)
{
    std::ifstream file(path);
    if (!file) {
        throw std::runtime_error("Cannot open file: " + path);
    }

    std::vector<double> vals;
    double x;
    while (file >> x) {
        vals.push_back(x);
    }
    return vals;
}

MNISTHeader read_mnist_header(std::ifstream& in)
{
    MNISTHeader h{};
    in.read(reinterpret_cast<char*>(&h.nimages), sizeof(h.nimages));
    in.read(reinterpret_cast<char*>(&h.rows), sizeof(h.rows));
    in.read(reinterpret_cast<char*>(&h.cols), sizeof(h.cols));

    if (!in) {
        throw std::runtime_error("Failed reading MNIST header");
    }
    if (h.rows != 28 || h.cols != 28) {
        throw std::runtime_error("Expected 28x28 MNIST images");
    }
    return h;
}

MNISTSample read_mnist_sample(std::ifstream& in)
{
    std::uint8_t label = 0;
    in.read(reinterpret_cast<char*>(&label), 1);
    if (!in) {
        throw std::runtime_error("Failed reading MNIST label");
    }

    Tensor3 image(1, std::vector<std::vector<Scalar>>(IMG_H, std::vector<Scalar>(IMG_W)));

    for (int r = 0; r < IMG_H; ++r) {
        for (int c = 0; c < IMG_W; ++c) {
            std::uint8_t pixel = 0;
            in.read(reinterpret_cast<char*>(&pixel), 1);
            if (!in) {
                throw std::runtime_error("Failed reading MNIST pixel");
            }
            image[0][r][c] = Scalar(static_cast<double>(pixel) / 255.0);
        }
    }

    return { static_cast<int>(label), image };
}

ConvLayer load_conv_layer(const std::string& wpath, const std::string& bpath, int out_ch, int in_ch, bool pool_after)
{
    const std::vector<double> wvals = load_numbers_txt(wpath);
    const std::vector<double> bvals = load_numbers_txt(bpath);

    const std::size_t expected_w = static_cast<std::size_t>(out_ch) * in_ch * K_H * K_W;
    const std::size_t expected_b = static_cast<std::size_t>(out_ch);

    if (wvals.size() != expected_w) {
        throw std::runtime_error(
            "Wrong number of weights in " + wpath +
            " expected " + std::to_string(expected_w) +
            ", got " + std::to_string(wvals.size())
        );
    }
    if (bvals.size() != expected_b) {
        throw std::runtime_error(
            "Wrong number of biases in " + bpath +
            " expected " + std::to_string(expected_b) +
            ", got " + std::to_string(bvals.size())
        );
    }

    Tensor4 W(
        out_ch,
        std::vector<std::vector<std::vector<Scalar>>>(
            in_ch,
            std::vector<std::vector<Scalar>>(K_H, std::vector<Scalar>(K_W))
        )
    );

    std::size_t idx = 0;
    for (int oc = 0; oc < out_ch; ++oc) {
        for (int ic = 0; ic < in_ch; ++ic) {
            for (int ky = 0; ky < K_H; ++ky) {
                for (int kx = 0; kx < K_W; ++kx) {
                    W[oc][ic][ky][kx] = Scalar(wvals[idx++]);
                }
            }
        }
    }

    std::vector<Scalar> b(out_ch);
    for (int i = 0; i < out_ch; ++i) {
        b[i] = Scalar(bvals[i]);
    }

    return { W, b, pool_after };
}

LinearLayer load_linear_layer(const std::string& wpath, const std::string& bpath)
{
    const std::vector<double> wvals = load_numbers_txt(wpath);
    const std::vector<double> bvals = load_numbers_txt(bpath);

    const std::size_t out_features = bvals.size();
    if (out_features == 0) {
        throw std::runtime_error("Linear bias file is empty: " + bpath);
    }
    if (wvals.size() % out_features != 0) {
        throw std::runtime_error("Linear weight count does not divide bias count in " + wpath);
    }

    const std::size_t in_features = wvals.size() / out_features;

    Matrix W(out_features, std::vector<Scalar>(in_features));
    std::size_t idx = 0;
    for (std::size_t o = 0; o < out_features; ++o) {
        for (std::size_t i = 0; i < in_features; ++i) {
            W[o][i] = Scalar(wvals[idx++]);
        }
    }

    std::vector<Scalar> b(out_features);
    for (std::size_t i = 0; i < out_features; ++i) {
        b[i] = Scalar(bvals[i]);
    }

    return { W, b };
}

Scalar relu(const Scalar& x)
{
    return (x < Scalar(0)) ? Scalar(0) : x;
}

Tensor3 maxpool2x2(const Tensor3& input)
{
    const int C = static_cast<int>(input.size());
    const int H = static_cast<int>(input[0].size());
    const int W = static_cast<int>(input[0][0].size());

    const int OH = H / 2;
    const int OW = W / 2;

    Tensor3 out(C, std::vector<std::vector<Scalar>>(OH, std::vector<Scalar>(OW)));

    for (int c = 0; c < C; ++c) {
        for (int y = 0; y < OH; ++y) {
            for (int x = 0; x < OW; ++x) {
                Scalar m = input[c][2 * y][2 * x];
                Scalar v1 = input[c][2 * y][2 * x + 1];
                Scalar v2 = input[c][2 * y + 1][2 * x];
                Scalar v3 = input[c][2 * y + 1][2 * x + 1];

                if (v1 > m) m = v1;
                if (v2 > m) m = v2;
                if (v3 > m) m = v3;

                out[c][y][x] = m;
            }
        }
    }
    return out;
}

std::vector<Scalar> flatten(const Tensor3& x)
{
    std::vector<Scalar> out;
    for (const auto& ch : x) {
        for (const auto& row : ch) {
            for (const auto& v : row) {
                out.push_back(v);
            }
        }
    }
    return out;
}

Scalar dot_quire(const std::vector<Scalar>& a, const std::vector<Scalar>& b)
{
    if (a.size() != b.size()) {
        throw std::runtime_error("dot_quire size mismatch");
    }

    Acc q;
    for (std::size_t i = 0; i < a.size(); ++i) {
        q += a[i] * b[i];
    }
    return q.convert_to<Scalar>();
}

Tensor3 conv2d_same(const Tensor3& input, const ConvLayer& layer, bool apply_relu = true)
{
    const int IC = static_cast<int>(input.size());
    const int H  = static_cast<int>(input[0].size());
    const int W  = static_cast<int>(input[0][0].size());
    const int OC = static_cast<int>(layer.W.size());

    Tensor3 out(OC, std::vector<std::vector<Scalar>>(H, std::vector<Scalar>(W)));

    for (int oc = 0; oc < OC; ++oc) {
        for (int y = 0; y < H; ++y) {
            for (int x = 0; x < W; ++x) {

                Acc q;

                for (int ic = 0; ic < IC; ++ic) {
                    for (int ky = 0; ky < 3; ++ky) {
                        for (int kx = 0; kx < 3; ++kx) {
                            int iy = y + ky - 1;
                            int ix = x + kx - 1;

                            if (iy >= 0 && iy < H && ix >= 0 && ix < W) {
                                q += input[ic][iy][ix] * layer.W[oc][ic][ky][kx];
                            }
                        }
                    }
                }

                Scalar v = q.convert_to<Scalar>();
                v += layer.b[oc];

                if (apply_relu) {
                    v = relu(v);
                }

                out[oc][y][x] = v;
            }
        }
    }

    return out;
}

std::vector<Scalar> linear_forward(const std::vector<Scalar>& x, const LinearLayer& layer, bool apply_relu)
{
    const int out_features = static_cast<int>(layer.W.size());
    const int in_features  = static_cast<int>(x.size());

    std::vector<Scalar> y(out_features);

    for (int o = 0; o < out_features; ++o) {
        if (static_cast<int>(layer.W[o].size()) != in_features) {
            throw std::runtime_error("Linear layer dimension mismatch");
        }

        Scalar v = dot_quire(x, layer.W[o]);
        v += layer.b[o];

        if (apply_relu) {
            v = relu(v);
        }

        y[o] = v;
    }

    return y;
}

VGGMNISTModel load_model(const std::string& base)
{
    VGGMNISTModel model;

    // This architecture matches the exported files you showed earlier.
    // Keep this list here so main() stays clean.
    const std::array<std::tuple<std::string, std::string, int, int, bool>, 10> conv_specs = {{
        {base + "features_0_weight.txt",  base + "features_0_bias.txt",  1,   64,  false},
        {base + "features_2_weight.txt",  base + "features_2_bias.txt",  64,   64,  true },
        {base + "features_5_weight.txt",  base + "features_5_bias.txt",  64,  128,  false},
        {base + "features_7_weight.txt",  base + "features_7_bias.txt", 128,  128,  true },
        {base + "features_10_weight.txt", base + "features_10_bias.txt", 128, 256, false},
        {base + "features_12_weight.txt", base + "features_12_bias.txt", 256, 256, false},
        {base + "features_14_weight.txt", base + "features_14_bias.txt", 256, 256, true },
        {base + "features_17_weight.txt", base + "features_17_bias.txt", 256, 512, false},
        {base + "features_19_weight.txt", base + "features_19_bias.txt", 512, 512, false},
        {base + "features_21_weight.txt", base + "features_21_bias.txt", 512, 512, true }
    }};

    for (const auto& spec : conv_specs) {
        model.conv_layers.push_back(
            load_conv_layer(
                std::get<0>(spec),
                std::get<1>(spec),
                std::get<3>(spec),
                std::get<2>(spec),
                std::get<4>(spec)
            )
        );
    }

    model.fc0 = load_linear_layer(
        base + "classifier_0_weight.txt",
        base + "classifier_0_bias.txt"
    );

    model.fc3 = load_linear_layer(
        base + "classifier_3_weight.txt",
        base + "classifier_3_bias.txt"
    );

    return model;
}

int predict(const VGGMNISTModel& model, const Tensor3& image)
{
    Tensor3 x = image;

    for (const auto& layer : model.conv_layers) {
        x = conv2d_same(x, layer, true);
        if (layer.pool_after) {
            x = maxpool2x2(x);
        }
    }

    std::vector<Scalar> feat = flatten(x);

    auto h = linear_forward(feat, model.fc0, true);
    auto logits = linear_forward(h, model.fc3, false);

    int pred = 0;
    Scalar best = logits[0];
    for (int i = 1; i < 10; ++i) {
        if (logits[i] > best) {
            best = logits[i];
            pred = i;
        }
    }

    return pred;
}

double evaluate_accuracy(const std::string& mnist_bin, const VGGMNISTModel& model)
{
    std::ifstream in(mnist_bin, std::ios::binary);
    if (!in) {
        throw std::runtime_error("Cannot open MNIST binary file: " + mnist_bin);
    }

    MNISTHeader header = read_mnist_header(in);

    std::uint32_t limit = std::min<std::uint32_t>(header.nimages, 10);

    std::size_t correct = 0;

    for (std::uint32_t idx = 0; idx < limit; ++idx) {
        MNISTSample sample = read_mnist_sample(in);
        int pred = predict(model, sample.image);

        if (pred == sample.label) {
            ++correct;
        }

        std::cout << "Processed " << idx << "/" << limit << "\r" << std::flush;
    }

    std::cout << std::endl;

    return 100.0 * static_cast<double>(correct) / static_cast<double>(limit);
}

int main()
{
    const std::string BASE = "/mnt/c/Users/Oishik Ganguli/PS-1 Tasks/VGG16_MNIST_Epoch20/";
    const std::string MNIST_BIN = "/mnt/c/Users/Oishik Ganguli/PS-1 Tasks/mnist_test.bin";

    VGGMNISTModel model = load_model(BASE);

    double acc = evaluate_accuracy(MNIST_BIN, model);

    std::cout << "Final test accuracy = " << acc << "%" << std::endl;

    return 0;
}