clear; clc; close all;

%% 1. Khai báo thông số tín hiệu Chirp
Fs = 48000;
dt = 0.005;                     % Độ rộng xung Chirp: 5 ms (240 mẫu)
f0 = 13000;                     % Tần số bắt đầu quét: 13 kHz
f1 = 19000;                     % Tần số kết thúc quét: 19 kHz
t_thu = 0.1;                    % Thời lượng thu mỗi lần recordblocking (0.1 giây = 4800 mẫu)

n_dt = round(dt * Fs);          % 240 mẫu
t = (0 : n_dt - 1)' / Fs;

% Tạo xung Chirp tuyến tính + Cửa sổ Hann chống ringing đầu dò
k_chirp = (f1 - f0) / dt;
x_raw = sin(2 * pi * (f0 * t + 0.5 * k_chirp * t.^2));
win = hann(n_dt);
x = x_raw .* win;               % Xung Chirp chuẩn

h_mf = flipud(x);               % Bộ lọc phối hợp cho xung Chirp

%% 2. Khởi tạo bộ lọc và đối tượng audiorecorder
[b, a] = butter(4, [12000 20000] / (Fs / 2), 'bandpass');
zf = zeros(max(length(a), length(b)) - 1, 1);
prev_tail = zeros(n_dt - 1, 1);
noise_floor = 0.02;

recObj = audiorecorder(Fs, 16, 1);

fprintf('=== ĐANG THU (RECORDBLOCKING - CHIRP 13-19 kHz): CÓ XUNG THÌ PHÁT XUNG (Ctrl+C để dừng) ===\n\n');

luot = 0;
tong_mau_da_thu = 0;

while true
    luot = luot + 1;
    
    % 1. Thu âm đồng bộ trong khoảng thời gian t_thu (0.1 giây)
    recordblocking(recObj, t_thu);
    rx_frame = getaudiodata(recObj, 'double');
    
    % Bảo vệ trường hợp độ dài mảng thu ngắn hơn n_dt
    if length(rx_frame) < n_dt
        continue;
    end
    
    % 2. Kiểm tra xem trong đoạn vừa thu có xung Chirp không
    [co, idx, zf, prev_tail, max_env, ncc_val] = co_xung_rt( ...
        rx_frame, b, a, zf, prev_tail, h_mf, noise_floor);
    
    if co
        vi_tri_toan_cuc = tong_mau_da_thu + idx;
        thoi_diem_s = (vi_tri_toan_cuc - 1) / Fs;
        fprintf('[CÓ CHIRP - Lượt %d] Đỉnh = %.3f | NCC = %.2f | Vị trí mẫu: %d (t = %.4f s) -> PHÁT PHẢN HỒI!\n', ...
            luot, max_env, ncc_val, vi_tri_toan_cuc, thoi_diem_s);
        
        % 3. Thu được Chirp -> Phát ngay lập tức 1 xung Chirp bằng sound()
        sound(x, Fs);
        
        % Nghỉ 0.12s để loa phát xong hoàn toàn và tắt dư âm, tránh tự bắt lại ở lượt sau
        pause(dt + 0.115);
        
        % Reset lại trạng thái bộ lọc sau khoảng ngắt nghỉ
        zf = zeros(max(length(a), length(b)) - 1, 1);
        prev_tail = zeros(n_dt - 1, 1);
    else
        % Không có xung -> Cập nhật mức nhiễu nền thích nghi
        noise_floor = 0.95 * noise_floor + 0.05 * max_env;
    end
    
    tong_mau_da_thu = tong_mau_da_thu + length(rx_frame);
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