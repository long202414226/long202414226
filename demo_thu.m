clear; clc; close all;

fs = 48000;
br = 700;                       % Tốc độ bit (700 bit/s)
fc = 12400;                     % Tần số trung tâm: 12.4 kHz (f0 = 12000 Hz, f1 = 12800 Hz)
df = 400;                       % Độ lệch tần FSK (±400 Hz)

chunk_size = 960;               % Khung đọc thời gian thực (20 ms)
max_record_sec = 30;            % Làm mới bộ đệm định kỳ tránh tràn RAM
max_record_samples = max_record_sec * fs;
t_echo_guard = 0.05;            % Nghỉ 50 ms sau khi phát lại tránh tự kích hoạt

sync = [ ...
1 1 1 1 1 1 1 0 1 0 1 0 1 0 0 1 1 0 0 1 1 1 0 1 1 1 0 1 0 0 1 0 ...
1 1 0 0 0 1 1 0 1 1 1 1 0 1 1 0 1 0 1 1 0 1 1 0 0 1 0 0 1 0 0 0 ...
1 1 1 0 0 0 0 1 0 1 1 1 1 1 0 0 1 0 1 0 1 1 1 0 0 1 1 0 1 0 0 0 ...
1 0 0 1 1 1 1 0 0 0 1 0 1 0 0 0 0 1 1 0 0 0 0 0 1 0 0 0 0 0 0 ];

N_bits = length(sync);
L_frame = round((N_bits / br) * fs);            % Đúng 8709 mẫu (tránh lệch 54 mẫu do round(fs/br))
t = (0 : L_frame - 1)' / fs;

bit_idx = min(floor(t * br) + 1, N_bits);
bits_mau = sync(bit_idx)';
f_inst = (fc - df) + (2 * df) * bits_mau;       % 12000 Hz (bit 0) và 12800 Hz (bit 1)
frame_sig = sin(2 * pi * cumsum(f_inst) / fs);  % Liên tục pha khớp với file phát

h_mf = flipud(frame_sig);                       % Bộ lọc phối hợp
norm_h = norm(h_mf);

% Bộ lọc thông dải bao trọn búp chính FSK: [11300 Hz - 13500 Hz]
f_low  = fc - df - br;
f_high = fc + df + br;
[b, a] = butter(4, [f_low f_high] / (fs / 2), 'bandpass');
zf_init = zeros(max(length(a), length(b)) - 1, 1);

r = audiorecorder(fs, 16, 1);
player = audioplayer(0.9 * frame_sig, fs, 16);

noise_floor = 0.02;
nguong_hinh_dang = 0.25;        % Ngưỡng NCC thực tế cho kênh truyền qua loa - micro (0.25 - 0.35)
nguong_bien_do_min = 0.30;      % Ngưỡng biên độ tối thiểu

so_lan_phan_hoi = 0;
fprintf('Khối thu FSK (12.0 - 12.8 kHz) đang lắng nghe thời gian thực...\n');

record(r);
cursor_doc = 0;
zf = zf_init;
prev_tail = zeros(L_frame - 1, 1);

while true
    pause(0.01);

    if (r.TotalSamples - cursor_doc) >= chunk_size
        y_all = getaudiodata(r, 'double');
        y_moi = y_all(cursor_doc + 1 : cursor_doc + chunk_size);
        cursor_doc = cursor_doc + chunk_size;

        [co, zf, prev_tail, max_env, ncc] = ...
            phat_hien_xung_rt(y_moi, b, a, zf, prev_tail, h_mf, norm_h, ...
                              noise_floor, nguong_bien_do_min, nguong_hinh_dang);

        if co
            so_lan_phan_hoi = so_lan_phan_hoi + 1;
            fprintf('[Phản hồi #%d] BẮT ĐƯỢC XUNG (Đỉnh: %.2f | NCC: %.2f) -> Phát lại...\n', ...
                so_lan_phan_hoi, max_env, ncc);

            stop(r);
            playblocking(player);
            pause(t_echo_guard);

            % Làm mới trạng thái trước khi thu tiếp
            zf = zf_init;
            prev_tail = zeros(L_frame - 1, 1);
            cursor_doc = 0;
            record(r);
        else
      
             noise_floor = 0.95 * noise_floor + 0.05 * max_env;
        

            if cursor_doc >= max_record_samples
                stop(r);
                zf = zf_init;
                prev_tail = zeros(L_frame - 1, 1);
                cursor_doc = 0;
                record(r);
            end
        end
    end
end

function [co, zf, prev_tail, max_env, do_tuong_dong] = ...
    phat_hien_xung_rt(y, b, a, zf, prev_tail, h_mf, norm_h, ...
                      noise_floor, nguong_bien_do_min, nguong_hinh_dang)

    [y_filt, zf] = filter(b, a, y(:), zf);

    buf = [prev_tail; y_filt];
    L = length(h_mf);
    prev_tail = buf(end - L + 2 : end);

    c = conv(buf, h_mf, 'valid');
    env = abs(hilbert(c));
    [max_env, k] = max(env);

    doan_xung = buf(k : k + L - 1);
    nang_luong_thu = norm(doan_xung);

    if nang_luong_thu > 1e-6
        do_tuong_dong = max_env / (nang_luong_thu * norm_h);
    else
        do_tuong_dong = 0;
    end

    nguong_bien_do = max(5 * noise_floor, nguong_bien_do_min);

    if (max_env > nguong_bien_do) && (do_tuong_dong > nguong_hinh_dang)
        co = true;
    else
        co = false;
    end
end