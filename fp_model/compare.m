% ✅ 파일 경로 설정
file1 = 'bfly21_tb.txt';       % 시뮬레이션 출력
file2 = 'bfly21_result.txt';   % MATLAB 기준 정답

% ✅ 복소수 읽기 함수 (양식: "int int")
function data = read_complex_file(filename)
    fid = fopen(filename, 'r');
    lines = textscan(fid, '%d %d');  % 실수 허수 순서
    fclose(fid);
    re = lines{1};
    im = lines{2};
    data = complex(double(re), double(im));  % 복소수 배열로 변환
end

% ✅ 데이터 로딩
data1 = read_complex_file(file1);
data2 = read_complex_file(file2);

% ✅ 길이 확인
if length(data1) ~= length(data2)
    error('❌ 두 파일의 데이터 길이가 다릅니다.');
end

% ✅ 항목별 분해 및 차이 계산
real1 = real(data1); real2 = real(data2);
imag1 = imag(data1); imag2 = imag(data2);
diff_real = real1 - real2;
diff_imag = imag1 - imag2;
x = 1:length(data1);

% ✅ 시각화 (4개 subplot)
figure('Name', 'bfly21 실수/허수 비교', 'Position', [100 100 1400 800]);

% ── 실수부 비교 ──
subplot(2,2,1);
plot(x, real1, '-b', 'LineWidth', 1.5); hold on;
plot(x, real2, '--r', 'LineWidth', 1.5);
title('① 실수부 비교'); legend('VCS Sim', 'MATLAB');
ylabel('Real'); grid on;

subplot(2,2,2);
plot(x, diff_real, '-k', 'LineWidth', 1.5);
title('② 실수부 오차'); ylabel('Diff (Real)');
grid on;

% ── 허수부 비교 ──
subplot(2,2,3);
plot(x, imag1, '-b', 'LineWidth', 1.5); hold on;
plot(x, imag2, '--r', 'LineWidth', 1.5);
title('③ 허수부 비교'); legend('VCS Sim', 'MATLAB');
ylabel('Imag'); grid on;

subplot(2,2,4);
plot(x, diff_imag, '-k', 'LineWidth', 1.5);
title('④ 허수부 오차'); ylabel('Diff (Imag)');
xlabel('Index'); grid on;
