clear; clc; close all;

%% 1. Khai báo thông số tín hiệu Sync 4-QAM (khớp với Khối Phát)
Fs = 48000;
fc = 16500;                     % Tần số sóng mang 4-QAM: 16.5 kHz
br = 700;                       % Tốc độ baud
N_sps = round(Fs / br);         % Số mẫu trên mỗi symbol (69 mẫu)
frameSize = 960;                % 20 ms mỗi khung

sync = [ ...
1 1 1 1 1 1 1 1 0 1 1 1 0 0 0 1 0 0 1 1 1 0 1 0 0 1 0 1 1 0 0 1 ...
1 1 1 1 0 1 0 0 0 0 1 0 0 1 0 0 0 1 1 0 1 0 1 1 1 0 1 1 1 1 0 0 ...
1 0 0 0 0 1 0 1 1 1 0 1 1 0 1 0 1 0 0 0 1 1 1 0 0 0 0 1 1 1 0 1 ...
1 1 0 0 0 1 0 1 0 0 1 1 1 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 1 0 1 1 ...
1 0 1 0 1 1 0 1 0 0 0 1 1 1 0 0 0 0 1 1 0 1 1 0 1 1 0 0 0 1 0 1 ...
0 0 1 1 1 1 1 1 0 1 1 0 0 1 0 0 0 0 1 1 1 0 1 1 0 1 0 0 0 1 1 0 ...
1 0 1 0 1 1 0 0 1 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 1 1 0 1 0 1 0 1 ...
0 1 0 0 1 1 0 1 1 1 0 0 0 1 1 0 1 1 0 0 1 1 0 0 ];

sync_I = 2 * sync(1:2:end) - 1;
sync_Q = 2 * sync(2:2:end) - 1;
sym_sync = sync_I + 1i * sync_Q;
baseband_I = kron(real(sym_sync), ones(1, N_sps));
baseband_Q = kron(imag(sym_sync), ones(1, N_sps));
t = (0 : length(baseband_I) - 1)' / Fs;

x_sync = baseband_I(:) .* cos(2*pi*fc*t) - baseband_Q(:) .* sin(2*pi*fc*t);
x_sync = 0.8 * (x_sync / max(abs(x_sync)));

n_dt = length(x_sync);          % 8832 mẫu (~0.184 s, dài hơn frameSize = 960)

% Chia xung x_sync thành nhiều khung 960 mẫu để phát liên tục qua adw
num_tx_frames = ceil(n_dt / frameSize);
tx_padded = [x_sync; zeros(num_tx_frames * frameSize - n_dt, 1)];
tx_frames = reshape(tx_padded, frameSize, num_tx_frames);
frame_im_lang = zeros(frameSize, 1);

%% 2. Khởi tạo bộ lọc thông dải (15.1 - 17.9 kHz) và thiết bị thu - phát
def = 1400;
[b, a] = butter(4, [(fc - def) (fc + def)] / (Fs / 2), 'bandpass');
zf = zeros(max(length(a), length(b)) - 1, 1);
prev_tail = zeros(n_dt - 1, 1);
noise_floor = 0.02;

adw = audioDeviceWriter('SampleRate', Fs);
adr = audioDeviceReader('SampleRate', Fs, 'SamplesPerFrame', frameSize);

% Làm ấm phần cứng
adw(frame_im_lang);
adr();

fprintf('=== ĐANG THU REAL-TIME (SYNC 4-QAM 16.5 kHz): CÓ SYNC THÌ PHÁT PHẢN HỒI (Ctrl+C để dừng) ===\n\n');

frame_count = 0;
tx_idx = 0;                     % Bộ đếm phát các khung của xung x_sync (0 = đang không phát)
bo_qua = 0;                     % Đếm khung nghỉ ngắn (0.1s) sau khi phát xong để chống tự kích hoạt

while true
    frame_count = frame_count + 1;
    rx_frame = adr();
    
    % 1. Nếu đang phát dở xung x_sync (10 khung) -> tiếp tục đẩy khung tiếp theo ra loa
    if tx_idx > 0
        adw(tx_frames(:, tx_idx));
        tx_idx = tx_idx + 1;
        if tx_idx > num_tx_frames
            tx_idx = 0;         % Đã phát xong toàn bộ xung x_sync
            bo_qua = 5;         % Nghỉ bắt xung thêm 5 khung (0.1s) cho tắt âm vang
        end
        [~, zf] = filter(b, a, rx_frame(:), zf);
        continue;
    end
    
    % 2. Nếu vừa phát xong -> bỏ qua 5 khung (0.1s) để không tự nghe lại chính mình
    if bo_qua > 0
        bo_qua = bo_qua - 1;
        adw(frame_im_lang);
        [~, zf] = filter(b, a, rx_frame(:), zf);
        if bo_qua == 0
            prev_tail = zeros(n_dt - 1, 1); % Xóa sạch đuôi âm thanh tự phát trước khi nghe lại
        end
        continue;
    end
    
    % 3. Kiểm tra xem trong khung thu có xung Sync 4-QAM không
    len_tail = length(prev_tail);
    [co, idx, zf, prev_tail, max_val, ncc_val] = co_xung_rt( ...
        rx_frame, b, a, zf, prev_tail, x_sync, noise_floor);
    
    if co
        vi_tri_toan_cuc = (frame_count - 1) * frameSize - len_tail + idx;
        thoi_diem_s = (vi_tri_toan_cuc - 1) / Fs;
        fprintf('[CÓ SYNC 4-QAM] Đỉnh = %.3f | NCC = %.2f | Vị trí mẫu: %d (t = %.4f s) -> PHÁT PHẢN HỒI!\n', ...
            max_val, ncc_val, vi_tri_toan_cuc, thoi_diem_s);
        
        adw(tx_frames(:, 1));   % Phát ngay khung đầu tiên của x_sync
        tx_idx = 2;             % Các khung 2..10 sẽ tự động phát ở các vòng lặp kế tiếp
    else
        adw(frame_im_lang);     % Không có xung -> Phát im lặng
        noise_floor = 0.95 * noise_floor + 0.05 * max_val;
    end
end

%% 3. Các hàm xử lý tương quan (khớp logic với Khối Phát)
function [co, idx, zf, prev_tail, max_val, do_tuong_dong] = co_xung_rt(y, b, a, zf, prev_tail, header, noise_floor)
    [y_filt, zf] = filter(b, a, y(:), zf);

    buf = [prev_tail; y_filt];
    N = length(header);
    prev_tail = buf(end - N + 2 : end); % Cắt từ buf vì N (8832) > frameSize (960)

    [k, max_val] = find_header_pos(buf, header);

    if k < 1 || (k + N - 1) > length(buf)
        co = false;
        idx = -1;
        do_tuong_dong = 0;
        return;
    end

    doan_xung = buf(k : k + N - 1);
    nang_luong_thu = norm(doan_xung);

    if nang_luong_thu > 1e-6
        do_tuong_dong = max_val / nang_luong_thu;
    else
        do_tuong_dong = 0;
    end

    nguong_bien_do = max(5 * noise_floor, 0.35);
    nguong_hinh_dang = 0.35;

    if (max_val > nguong_bien_do) && (do_tuong_dong > nguong_hinh_dang)
        co = true;
        idx = k;
    else
        co = false;
        idx = -1;
    end
end

function [idx, max_val] = find_header_pos(rx, header)
    % Tìm vị trí bắt đầu header trong rx
    rx     = rx(:);
    header = header(:);

    h = conj(flipud(header)) / norm(header);
    y = filter(h, 1, rx);

    % Xóa đoạn quá độ đầu bộ lọc để tránh idx < 1
    y(1 : length(header) - 1) = 0;

    [max_val, idx_peak] = max(abs(y));

    % Quy đổi về vị trí bắt đầu header
    idx = idx_peak - length(header) + 1;
end