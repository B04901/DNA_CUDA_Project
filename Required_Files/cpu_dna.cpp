#include <chrono>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>

using namespace std;

struct SearchResult {
    unsigned long long count = 0;
};

// อ่าน DNA sequence จากไฟล์ FASTA
string readFasta(const string& filename) {
    ifstream file(filename);

    if (!file.is_open()) {
        throw runtime_error("Cannot open FASTA file: " + filename);
    }

    string dna;
    string line;

    while (getline(file, line)) {
        // ข้ามบรรทัด Header ของ FASTA
        if (!line.empty() && line[0] == '>') {
            continue;
        }

        for (char c : line) {
            // เปลี่ยนตัวอักษรเล็กเป็นตัวใหญ่
            if (c >= 'a' && c <= 'z') {
                c = char(c - 'a' + 'A');
            }

            // เก็บเฉพาะเบสที่ใช้ใน DNA
            if (c == 'A' || c == 'C' || c == 'G' ||
                c == 'T' || c == 'N') {
                dna.push_back(c);
            }
        }
    }

    return dna;
}

// อ่าน Pattern จากไฟล์ และตรวจสอบว่าเป็น A/C/G/T เท่านั้น
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

// Brute Force: ตรวจสอบ Pattern ที่ทุกตำแหน่งที่เป็นไปได้
SearchResult bruteForceSearch(const string& dna, const string& pattern) {
    SearchResult result;

    const size_t N = dna.size();
    const size_t M = pattern.size();

    if (M > N) {
        return result;
    }

    for (size_t i = 0; i <= N - M; ++i) {
        size_t j = 0;

        while (j < M && dna[i + j] == pattern[j]) {
            ++j;
        }

        if (j == M) {
            ++result.count;
        }
    }

    return result;
}

template <typename Function>
double measureTimeMs(Function function, SearchResult& result) {
    const auto start = chrono::steady_clock::now();

    result = function();

    const auto stop = chrono::steady_clock::now();

    return chrono::duration<double, milli>(stop - start).count();
}

int main(int argc, char* argv[]) {
    try {
        if (argc < 3 || argc > 4) {
            cerr << "Usage: cpu_dna <fasta_file> <pattern_file> [max_bases]\n";
            return 1;
        }

        string dna = readFasta(argv[1]);
        const string pattern = readPattern(argv[2]);

        // จำกัดขนาด DNA สำหรับการทดลอง หากระบุ max_bases
        if (argc == 4) {
            const unsigned long long maxBases = stoull(argv[3]);

            if (maxBases < dna.size()) {
                dna.resize(static_cast<size_t>(maxBases));
            }
        }

        cout << "DNA length: " << dna.size() << " bases\n";
        cout << "Pattern: " << pattern << "\n";

        SearchResult bruteResult;

        const double bruteTime = measureTimeMs(
            [&]() {
                return bruteForceSearch(dna, pattern);
            },
            bruteResult
        );

        cout << "\n--- CPU Brute Force ---\n";
        cout << "Matches: " << bruteResult.count << "\n";
        cout << "Time: " << fixed << setprecision(3)
             << bruteTime << " ms\n";

        return 0;
    } catch (const exception& e) {
        cerr << "Error: " << e.what() << "\n";
        return 1;
    }
}
