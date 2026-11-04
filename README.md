
# คู่มือการติดตั้งและรันโปรเจกต์
## CUDA DNA Exact Pattern Matching

### 1. รายละเอียดโปรเจกต์

โปรเจกต์นี้เปรียบเทียบการค้นหา DNA pattern แบบตรงตัว (Exact Pattern Matching) บน CPU และ GPU โดยใช้ข้อมูลลำดับ DNA ของโครโมโซม 1 จากฐานข้อมูล NCBI

ภายในโปรเจกต์ประกอบด้วยอัลกอริทึม CPU ได้แก่ Brute Force และอัลกอริทึม CUDA ที่แบ่งงานค้นหาไปยังหลาย GPU threads

### 2. ไฟล์ที่ต้องมี

จัดเก็บไฟล์ทั้งหมดไว้ในโฟลเดอร์เดียวกัน เช่น

```text
DNA_CUDA_Project/
-download_data.py
-cpu_dna.cpp
-cuda_dna.cu
-pattern.txt
-chr1.fa
```

- `download_data.py` ใช้ดาวน์โหลดข้อมูล DNA
- `cpu_dna.cpp` เป็นโปรแกรมค้นหาบน CPU
- `cuda_dna.cu` เป็นโปรแกรมค้นหาบน GPU ด้วย CUDA
- `pattern.txt` เก็บ DNA pattern ที่ต้องการค้นหา

สำหรับ `chr1.fa` ให้เปิด Terminal ในโฟลเดอร์โปรเจกต์แล้วรัน:

```bash
python download_data.py
```

ตรวจสอบว่ามีไฟล์ `chr1.fa` ปรากฏในโฟลเดอร์แล้ว

### 3. ข้อกำหนดของระบบ

การคอมไพล์และรันโปรแกรม CUDA บน Windows ต้องมี:

1. NVIDIA GPU ที่รองรับ CUDA
2. NVIDIA GPU Driver
3. CUDA Toolkit ซึ่งมีคำสั่ง `nvcc`
4. Visual Studio หรือ Visual Studio Build Tools ที่ติดตั้ง workload **Desktop development with C++**
5. Python สำหรับดาวน์โหลดข้อมูล หากยังไม่มีไฟล์ `chr1.fa`

สามารถตรวจสอบการติดตั้งได้ด้วยคำสั่ง:

```bat
nvidia-smi
nvcc --version
```

ควรตรวจสอบว่าเวอร์ชัน CUDA Toolkit รองรับเวอร์ชัน MSVC ที่ติดตั้งอยู่ด้วย

### 4. เตรียม pattern

สร้างไฟล์ `pattern.txt` ในโฟลเดอร์โปรเจกต์ แล้วใส่ลำดับ DNA ที่ต้องการค้นหา เช่น:

```text
ATCGATCG
```

Pattern ควรประกอบด้วยตัวอักษร `A`, `C`, `G` และ `T` เท่านั้น และไม่ควรมีข้อความอื่นในไฟล์

### 5. เปิด Terminal ที่พร้อมใช้งาน CUDA

บน Windows ให้เปิด **x64 Native Tools Command Prompt for Visual Studio** จากนั้นเข้าไปยังโฟลเดอร์โปรเจกต์ เช่น:

```bat
cd C:\path\to\DNA_CUDA_Project
```

หากใช้ VS Code สามารถเปิด VS Code จากหน้าต่างนี้ได้ด้วยคำสั่ง:

```bat
code .
```

วิธีนี้ช่วยให้ Terminal ของ VS Code สืบทอด environment ที่จำเป็นสำหรับ `cl.exe` ได้

### 6. คอมไพล์และรันโปรแกรม CPU

คอมไพล์ด้วย C++ compiler เช่น `g++`:

```bash
g++ -O3 -std=c++17 cpu_dna.cpp -o cpu_dna.exe
```

รันโปรแกรมโดยระบุไฟล์ข้อมูลและ pattern:

```bat
.\cpu_dna.exe chr1.fa pattern.txt
```

หากโปรแกรมรองรับอาร์กิวเมนต์ตัวที่สามสำหรับกำหนดจำนวนเบสที่ใช้ทดสอบ สามารถเริ่มจากข้อมูลบางส่วนได้ เช่น:

```bat
.\cpu_dna.exe chr1.fa pattern.txt 1000000
```

### 7. คอมไพล์และรันโปรแกรม CUDA

คอมไพล์ไฟล์ CUDA ด้วย `nvcc`:

```bat
nvcc -O3 -std=c++17 cuda_dna.cu -o cuda_dna.exe
```

รันโปรแกรม:

```bat
.\cuda_dna.exe chr1.fa pattern.txt
```

หรือเริ่มทดสอบด้วยข้อมูลบางส่วน หากโปรแกรมรองรับอาร์กิวเมนต์จำนวนเบส:

```bat
.\cuda_dna.exe chr1.fa pattern.txt 1000000
```

เริ่มจากข้อมูลบางส่วนเพื่อตรวจสอบความถูกต้องก่อน แล้วจึงรันกับข้อมูลทั้งหมด

### 8. ตรวจสอบผลลัพธ์

บันทึกผลจากโปรแกรม CPU และ GPU โดยตรวจสอบว่า:

- ทั้งสองโปรแกรมใช้ไฟล์ DNA และ pattern เดียวกัน
- จำนวน matches จาก CPU และ GPU ต้องตรงกัน
- บันทึกเวลารันที่โปรแกรมรายงานจริง
- คำนวณ speedup จากเวลาที่วัดได้ โดยใช้สูตร:

 Speedup = (CPU runtime) / (GPU runtime)


ควรระบุให้ชัดเจนว่าเวลา GPU ที่นำมาเปรียบเทียบเป็นเวลา kernel หรือเวลารวมการคัดลอกข้อมูลและการทำงานอื่น ๆ

### 9. การแก้ปัญหาเบื้องต้น

**กรณี `nvcc` ไม่พบคำสั่ง**  
ตรวจสอบว่าได้ติดตั้ง CUDA Toolkit และเพิ่มตำแหน่ง `bin` ของ CUDA Toolkit ใน PATH แล้ว

**กรณี `Cannot find compiler 'cl.exe' in PATH`**  
เปิด x64 Native Tools Command Prompt for Visual Studio แล้วคอมไพล์จากหน้าต่างนั้น หรือเปิด VS Code จากหน้าต่างดังกล่าวด้วย `code .`

**กรณี `cudafe++` ล้มเหลวหรือเกิด Access Violation**  
ตรวจสอบความเข้ากันได้ระหว่าง CUDA Toolkit กับ MSVC และทดลองคอมไพล์ไฟล์ CUDA ขนาดเล็กก่อน หากยังเกิดปัญหา ให้ซ่อมหรือติดตั้ง CUDA Toolkit เวอร์ชันที่รองรับ compiler ที่ใช้อยู่

**กรณีไม่มี NVIDIA GPU**  
สามารถคอมไพล์โค้ดได้ในบางสภาพแวดล้อม แต่ไม่สามารถรัน CUDA kernel บนเครื่องที่ไม่มี GPU ที่รองรับ CUDA ได้

### 10. แหล่งข้อมูล

ชุดข้อมูล DNA มาจาก NCBI RefSeq:

https://www.ncbi.nlm.nih.gov/nuccore/NC_000001.11?report=fasta
