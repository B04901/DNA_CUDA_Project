
#include <cuda_runtime.h>

#include <chrono>
#include <climits>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>

using namespace std;

#define CUDA_CHECK(call)                                      \
    do {                                                      \
        cudaError_t error = (call);                           \
        if (error != cudaSuccess) {                           \
            cerr << "CUDA error: "                            \
                 << cudaGetErrorString(error) << endl;        \
            return 1;                                         \
        }                                                     \
    } while (0)

// อ่าน DNA sequence จาก FASTA
string readFasta(const string& filename) {
    ifstream file(filename);

    if (!file.is_open()) {
        throw runtime_error("Cannot open FASTA file: " + filename);
    }

    string dna;
    string line;

    while (getline(file, line)) {
        // ข้าม Header ของ FASTA
        if (!line.empty() && line[0] == '>') {
            continue;
        }

        for (char c : line) {
            // แปลงตัวอักษรเล็กเป็นตัวใหญ่
            if (c >= 'a' && c <= 'z') {
                c = char(c - 'a' + 'A');
            }

            if (c == 'A' || c == 'C' || c == 'G' ||
                c == 'T' || c == 'N') {
                dna.push_back(c);
            }
        }
    }

    return dna;
}

// อ่าน Pattern จาก pattern.txt
string readPattern(const string& filename) {
    ifstream file(filename);

    if (!file.is_open()) {
        throw runtime_error("Cannot open pattern file: " + filename);
    }

    string pattern;
    file >> pattern;

    for (char& c : pattern) {
        if (c >= 'a' && c <= 'z') {
            c = char(c - 'a' + 'A');
        }

        if (c != 'A' && c != 'C' && c != 'G' && c != 'T') {
            throw runtime_error("Pattern must contain only A, C, G, T.");
        }
    }

    if (pattern.empty()) {
        throw runtime_error("Pattern cannot be empty.");
    }

    return pattern;
}

// CUDA Kernel: หนึ่ง thread ตรวจสอบหนึ่งตำแหน่งเริ่มต้น
__global__ void candidateMatching(
    const char* dna,
    const char* pattern,
    unsigned long long* matchCount,
    int dnaLength,
    int patternLength
) {
    int position = blockIdx.x * blockDim.x + threadIdx.x;
    int candidateCount = dnaLength - patternLength + 1;

    if (position >= candidateCount) {
        return;
    }

    bool matched = true;

    for (int j = 0; j < patternLength; ++j) {
        if (dna[position + j] != pattern[j]) {
            matched = false;
            break;
        }
    }

    if (matched) {
        atomicAdd(matchCount, 1ULL);
    }
}

int main(int argc, char* argv[]) {
    try {
        if (argc < 3 || argc > 4) {
            cerr << "Usage: cuda_dna <fasta_file> <pattern_file> [max_bases]\n";
            return 1;
        }

        string dna = readFasta(argv[1]);
        string pattern = readPattern(argv[2]);

        // Optional: จำกัดจำนวน DNA bases สำหรับทดลอง
        if (argc == 4) {
            unsigned long long maxBases = stoull(argv[3]);

            if (maxBases < dna.size()) {
                dna.resize(static_cast<size_t>(maxBases));
            }
        }

        if (dna.size() < pattern.size()) {
            cout << "DNA length is shorter than the pattern.\n";
            cout << "Matches: 0\n";
            return 0;
        }

        // เวอร์ชันนี้ใช้ int สำหรับ index และรองรับ DNA ไม่เกิน INT_MAX
        if (dna.size() > static_cast<size_t>(INT_MAX)) {
            throw runtime_error("DNA is too large for this version.");
        }

        int dnaLength = static_cast<int>(dna.size());
        int patternLength = static_cast<int>(pattern.size());
        int candidateCount = dnaLength - patternLength + 1;

        char* dDNA = nullptr;
        char* dPattern = nullptr;
        unsigned long long* dMatchCount = nullptr;

        // วัดเวลารวมของการจัดสรร memory, copy, kernel และ copy ผลกลับ
        auto totalStart = chrono::steady_clock::now();

        CUDA_CHECK(cudaMalloc(
            reinterpret_cast<void**>(&dDNA),
            dna.size() * sizeof(char)
        ));

        CUDA_CHECK(cudaMalloc(
            reinterpret_cast<void**>(&dPattern),
            pattern.size() * sizeof(char)
        ));

        CUDA_CHECK(cudaMalloc(
            reinterpret_cast<void**>(&dMatchCount),
            sizeof(unsigned long long)
        ));

        CUDA_CHECK(cudaMemcpy(
            dDNA, dna.data(), dna.size(),
            cudaMemcpyHostToDevice
        ));

        CUDA_CHECK(cudaMemcpy(
            dPattern, pattern.data(), pattern.size(),
            cudaMemcpyHostToDevice
        ));

        CUDA_CHECK(cudaMemset(
            dMatchCount, 0, sizeof(unsigned long long)
        ));

        int blockSize = 256;
        int gridSize = (candidateCount + blockSize - 1) / blockSize;

        // จับเวลาเฉพาะ Kernel
        cudaEvent_t start, stop;
        CUDA_CHECK(cudaEventCreate(&start));
        CUDA_CHECK(cudaEventCreate(&stop));

        CUDA_CHECK(cudaEventRecord(start));

        candidateMatching<<<gridSize, blockSize>>>(
            dDNA,
            dPattern,
            dMatchCount,
            dnaLength,
            patternLength
        );

        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaEventSynchronize(stop));

        float kernelTimeMs = 0.0f;
        CUDA_CHECK(cudaEventElapsedTime(
            &kernelTimeMs, start, stop
        ));

        unsigned long long gpuMatches = 0;

        CUDA_CHECK(cudaMemcpy(
            &gpuMatches,
            dMatchCount,
            sizeof(unsigned long long),
            cudaMemcpyDeviceToHost
        ));

        auto totalStop = chrono::steady_clock::now();

        double totalTimeMs =
            chrono::duration<double, milli>(
                totalStop - totalStart
            ).count();

        cout << "DNA length: " << dnaLength << " bases\n";
        cout << "Pattern: " << pattern << "\n";
        cout << "CUDA matches: " << gpuMatches << "\n";

        cout << fixed << setprecision(3);
        cout << "Kernel time: " << kernelTimeMs << " ms\n";
        cout << "End-to-end GPU time: " << totalTimeMs << " ms\n";

        CUDA_CHECK(cudaEventDestroy(start));
        CUDA_CHECK(cudaEventDestroy(stop));
        CUDA_CHECK(cudaFree(dDNA));
        CUDA_CHECK(cudaFree(dPattern));
        CUDA_CHECK(cudaFree(dMatchCount));

        return 0;
    } catch (const exception& error) {
        cerr << "Error: " << error.what() << endl;
        return 1;
    }
}

