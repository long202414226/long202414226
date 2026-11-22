clear; clc; close all;

%% 1. Khai báo thông số tín hiệu Chirp
Fs = 48000;
dt = 0.005;                     % Độ rộng xung Chirp: 5 ms (240 mẫu)
f0 = 13000;                     % Tần số bắt đầu quét: 13 kHz
f1 = 19000;                     % Tần số kết thúc quét: 19 kHz
frameSize = 960;                % 20 ms mỗi khung

n_dt = round(dt * Fs);          % 240 mẫu (nhỏ hơn frameSize = 960)
t = (0 : n_dt - 1)' / Fs;

% Tạo xung Chirp tuyến tính + Cửa sổ Hann chống ringing đầu dò
k_chirp = (f1 - f0) / dt;
x_raw = sin(2 * pi * (f0 * t + 0.5 * k_chirp * t.^2));
win = hann(n_dt);
x = x_raw .* win;               % Xung Chirp chuẩn

h_mf = flipud(x);               % Bộ lọc phối hợp cho xung Chirp

frame_co_xung = [x; zeros(frameSize - n_dt, 1)];
frame_im_lang = zeros(frameSize, 1);

%% 2. Khởi tạo bộ lọc và thiết bị thu - phát
% Mở rộng dải thông từ 12 kHz đến 20 kHz bao trọn xung Chirp (13 - 19 kHz)
[b, a] = butter(4, [12000 20000] / (Fs / 2), 'bandpass');
zf = zeros(max(length(a), length(b)) - 1, 1);
prev_tail = zeros(n_dt - 1, 1);
noise_floor = 0.02;

adw = audioDeviceWriter('SampleRate', Fs);
adr = audioDeviceReader('SampleRate', Fs, 'SamplesPerFrame', frameSize);

% Làm ấm phần cứng
adw(frame_im_lang);
adr();

fprintf('=== ĐANG THU REAL-TIME (CHIRP 13-19 kHz): CÓ XUNG THÌ PHÁT XUNG (Ctrl+C để dừng) ===\n\n');

frame_count = 0;
bo_qua = 0;                     % Đếm khung nghỉ ngắn (0.1s) để không tự bắt lại xung vừa phát

while true
    frame_count = frame_count + 1;
    rx_frame = adr();
    
    % Nếu vừa mới phát xung xong thì bỏ qua 5 khung (0.1s) để không tự nghe lại chính mình
    if bo_qua > 0
        bo_qua = bo_qua - 1;
        adw(frame_im_lang);
        [y_filt, zf] = filter(b, a, rx_frame(:), zf);
        prev_tail = y_filt(end - n_dt + 2 : end);
        continue;
    end
    
    % Kiểm tra xem trong khung thu có xung Chirp không
    [co, idx, zf, prev_tail, max_env, ncc_val] = co_xung_rt( ...
        rx_frame, b, a, zf, prev_tail, h_mf, noise_floor);
    
    if co
        vi_tri_toan_cuc = (frame_count - 1) * frameSize + idx;
        thoi_diem_s = (vi_tri_toan_cuc - 1) / Fs;
        fprintf('[CÓ CHIRP] Đỉnh = %.3f | NCC = %.2f | Vị trí mẫu: %d (t = %.4f s) -> PHÁT PHẢN HỒI!\n', ...
            max_env, ncc_val, vi_tri_toan_cuc, thoi_diem_s);
        
        adw(frame_co_xung);     % Thu được Chirp -> Phát ngay lập tức 1 xung Chirp
        bo_qua = 5;             % Nghỉ bắt xung 0.1s (5 khung) tránh tự kích hoạt lặp vô hạn
    else
        adw(frame_im_lang);     % Không có xung -> Phát im lặng
        noise_floor = 0.95 * noise_floor + 0.05 * max_env;
    end
end

function [co, idx, zf, prev_tail, max_env, do_tuong_dong] = co_xung_rt(y, b, a, zf, prev_tail, h_mf, noise_floor)
    [y_filt, zf] = filter(b, a, y(:), zf);

    buf = [prev_tail; y_filt];
    N = length(h_mf);
    prev_tail = y_filt(end - N + 2 : end);

    c = conv(buf, h_mf, 'valid');
    env = abs(hilbert(c));
    [max_env, k] = max(env);

    doan_xung = buf(k : k + N - 1);
    nang_luong_thu = norm(doan_xung);
    nang_luong_mau = norm(h_mf);
    
    if nang_luong_thu > 1e-6
        do_tuong_dong = max_env / (nang_luong_thu * nang_luong_mau);
    else
        do_tuong_dong = 0;
    end

    nguong_bien_do = max(5 * noise_floor, 0.35);
    nguong_hinh_dang = 0.55;

    if (max_env > nguong_bien_do) && (do_tuong_dong > nguong_hinh_dang)
        co = true;
        idx = k;
    else
        co = false;
        idx = -1;
    end
end