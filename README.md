# 💻 FFT Architecture
> MATLAB 기반 Fixed Point 모델 설계와 SystemVerilog RTL 구현을 통해 512-point FFT를 설계 및 검증한 신호 처리 시스템입니다.  
> 8-radix FFT와 CBFP(Coefficient Block Floating Point) 알고리즘을 적용하여 연산 효율과 정밀도를 동시에 확보하였습니다.

---

# 🎯 설계 목표 (Front-end Process)

| 단계 | 내용 | 세부 사항 |
|------|------|-----------|
| **1) Spec. Analysis** | 사양 분석 | FFT 512pt, 입력 9bit |
| **2) Algorithm Search** | 알고리즘 탐색 | 8-radix FFT, CBFP 적용 |
| **3) Floating-point Modeling** | 부동소수점 모델링 | MATLAB 기반 FFT 구현 |
| **4) Fixed-point Modeling** | 고정소수점 모델링 | MATLAB `<3.6>` 포맷 변환 |
| **5) RTL Design (ASIC)** | RTL 설계 | SystemVerilog FFT 모듈 구현 및 검증 |
| **6) RTL Verification (FPGA)** | RTL 검증 | Vivado VIO 기반 데이터 merge |
| **7) Logic Synthesis** | 논리 합성 | Synthesis & Implementation (+Bitstream 생성) |

---

# 📦 FFT Top Module Block Diagram

<img width="500" alt="제목 없는 다이어그램 drawio (5)" src="https://github.com/user-attachments/assets/5dd10ab2-4817-460c-8faa-5e821aaafc86" />

---

# 📈 RTL Simulation
<img width="1109" height="340" alt="image" src="https://github.com/user-attachments/assets/f1f9f4a0-94c4-4ed1-9bda-d05cb5776e7b" />

# ➕ module0~2 연산 결과 검증 (MATLAB vs RTL Sim)

### 1️⃣ 비교 개요
- **대상 모듈**: `module0~2` 내 각 버터플라이 연산 블록 (`bfly02`, `bfly12`, `bfly22`)
- **검증 항목**:
  - **cosine 입력 데이터(왼쪽 파형)**
  - **random 입력 데이터(오른쪽 파형)**
- **검증 방법**: MATLAB 참조 모델 결과 vs RTL 시뮬레이션 결과 비교 (Real/Imag)

### 2️⃣ bfly02 연산 결과
- **그래프 해석**: Real/Imag 파형 완전 일치, Diff 전 구간 0 → 스케일링, 덧셈/뺄셈, Twiddle 곱 모두 정확.

<img width="1500" alt="image" src="https://github.com/user-attachments/assets/f1f9f4a0-94c4-4ed1-9bda-d05cb5776e7b" />

### 3️⃣ bfly12 연산 결과
- **그래프 해석**: Real/Imag 파형 완전 일치, Diff 전 구간 0 → 스케일링, 덧셈/뺄셈, Twiddle 곱 모두 정확.

<img width="1500" alt="image" src="https://github.com/user-attachments/assets/8d7683ea-b89f-476d-9800-7df552efc727" />


### 4️⃣ bfly22 연산 결과
- **그래프 해석**: Real/Imag 파형 완전 일치, Diff 전 구간 0 → 스케일링, 덧셈/뺄셈, Twiddle 곱 모두 정확.

<img width="1500" alt="image" src="https://github.com/user-attachments/assets/d122e9e7-dbeb-4522-9a42-d78255f429cb" />

---

# 🧪 Performance Analysis

### 1️⃣ 구조 비교(512-point / 16-point)
- **변경 전 (Non-Pipelined Structure, 68clk)**  
  - **입력 방식**: 512포인트 전체 수집 후 연산 시작, 연산 중 입력 불가  
  - **동작 흐름**: `IDLE → COLLECT → COMPUTE → SCALE`  
  - **효과**:  
    - Latency 길어짐 (**68clk**)  
    - Throughput 낮음
<img width="1500" alt="image" src="https://github.com/user-attachments/assets/f995c425-9296-47bb-afb7-16db59f10e08" />

- **변경 후 (Pipelined Structure, 38clk)**  
  - **입력 방식**: 1클럭당 16포인트 입력, 입력과 연산 병행 처리  
  - **동작 흐름**: `COLLECT`와 `COMPUTE` 병행, Headroom 최소값 단계적 계산 후 즉시 스케일링  
  - **효과**:  
    - Latency 약 44% 감소 (**38clk**)  
    - Throughput 대폭 향상  
<img width="1500" alt="image" src="https://github.com/user-attachments/assets/8f74f0a4-7c82-415e-bc56-1767e341a2da" />

### 2️⃣ bfly02 연산 RTL 검증 결과 (Random Data, 16-point)

- **상단 파형 (RTL 내부 신호)**  
  - `G1~G6`: 클럭, 리셋, 입력 유효 신호, 카운터 상태 등 제어 신호
  - **입력 버퍼 (`buffer_reg_re`, `buffer_reg_im`)**:  
    각 입력 샘플이 순차적으로 저장되고 연산 타이밍에 맞춰 읽힘
  - **출력 (`bfly02_e`, `bfly02_m`)**:  
    실수부·허수부 연산 결과가 순차적으로 발생  
    파이프라인 구조로 인해 입력 대비 지연(latency) 존재

| 항목 | MATLAB 결과 | RTL 결과 | 일치 여부 |
|------|-------------|----------|-----------|
| **실수부 (`bfly02_e`)** | 아래 그래프 좌측 상단 | 아래 그래프 우측 상단 | ✅ |
| **허수부 (`bfly02_m`)** | 아래 그래프 좌측 하단 | 아래 그래프 우측 하단 | ✅ |
<img width="1500" alt="image" src="https://github.com/user-attachments/assets/8669c8c5-1e78-4898-b730-21ded712891d" />

### 3️⃣ Synthesis Area 비교 (512-point vs 16-point)
- **규모 차이**: 512-point 설계의 총 셀 면적은 16-point 대비 약 **6.32배** 큼.
- **주요 원인**:
  - **Combinational Logic**: 512-point의 조합 논리 면적이 64K로, 16-point 대비 약 17.4배 큼 → FFT 크기에 따라 버터플라이 및 멀티플라이어 개수가 급격히 증가.
  - **Sequential Logic**: 512-point에서 레지스터 수가 약 2.4배 많음 → 파이프라인 단계 증가 영향.
  - **Buf/Inv 개수**: 신호 팬아웃 증가에 따라 버퍼/인버터가 약 21배 더 많음.
<img width="1500" alt="image" src="https://github.com/user-attachments/assets/0c4c7db1-46eb-4c52-aa04-374cecadf1aa" />

### 4️⃣ Setup Timing 결과 (512-point vs 16-point)

| 항목 | 512-point FFT | 16-point FFT |
|---|---:|---:|
| data required time | 1300.18 | 1300.18 |
| data arrival time  | -1300.06 | -1299.94 |
| **slack (MET)**    | **0.12** | **0.24** |

> Slack = required time − arrival time  
> 두 설계 모두 **양수 슬랙 → Setup 타이밍 충족(MET)**

- **512-point**: slack **0.12** → 여유가 작아 **가장 크리티컬**. 주기 단축(클록 상승) 시 위반 가능.
- **16-point**: slack **0.24** → 여유가 더 큼.
<img width="1500" alt="image" src="https://github.com/user-attachments/assets/a870db1e-482d-4c36-8232-8e7f3e7cd48d" />

