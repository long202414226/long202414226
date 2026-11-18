% =========================================================================
% KHỐI THU THỜI GIAN THỰC (REAL-TIME RECEIVER) XÁC ĐỊNH VỊ TRÍ GÓI TIN
% =========================================================================
clc; clear; close all;

fs = 96000;        
fc = 16500;         
br = 700;     
N = round(fs/br);

% 1. Khởi tạo lại chuỗi Header (Sync) để làm mẫu dò tìm (Template)
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
baseband_I = kron(real(sym_sync), ones(1, N));
baseband_Q = kron(imag(sym_sync), ones(1, N));
t_mod = (0:length(baseband_I)-1) / fs;
xp = baseband_I .* cos(2*pi*fc*t_mod) - baseband_Q .* sin(2*pi*fc*t_mod);
xp = 0.8 * (xp / max(abs(xp))); 

% Bộ lọc thông dải để dọn nhiễu môi trường trước khi dò tìm
def = 1400;
[b_bp, a_bp] = butter(4, [(fc-def) (fc+def)] / (fs/2), 'bandpass');

% 2. Bắt đầu vòng lặp thời gian thực
disp('>> ĐANG LẮNG NGHE TÍN HIỆU... (Bấm Ctrl+C để thoát nếu đợi quá lâu)');
r = audiorecorder(fs, 16, 1);
record(r);
pause(0.1);

Start_P = 1;
chunk_size = 40000;     % Đọc mỗi khối khoảng 40.000 mẫu (~0.4 giây)
L = r.TotalSamples;
idx_giai_dieu_che = []; % Lưu vị trí bắt đầu
is_detected = false;

while L < 15 * fs % Lắng nghe tối đa 15 giây (Tránh treo máy mãi mãi)
    y_full = getaudiodata(r, 'double')';
    Ly = length(y_full);
    
    if Ly - Start_P > chunk_size 
        % Cắt lấy 1 chunk tín hiệu hiện tại
        yr = y_full(Start_P:Ly);
        yr = filtfilt(b_bp, a_bp, yr); % Lọc nhiễu
        
        % Dò tìm Header trong chunk này
        idx_chunk = find_header_pos(yr, xp);
        
        % Xác minh xem có đúng là Header thật không (hay chỉ là nhiễu rác)
        % Tính hệ số tương quan chuẩn hóa tại vị trí tìm được
        if idx_chunk > 0 && (idx_chunk + length(xp) - 1) <= length(yr)
            segment = yr(idx_chunk : idx_chunk + length(xp) - 1);
            corr_score = abs(segment * xp') / (norm(segment) * norm(xp) + 1e-6);
            
            if corr_score > 0.3 % Ngưỡng nhận diện (tùy chỉnh theo nhiễu thực tế)
                % Đã bắt được! Quy đổi vị trí trong chunk ra vị trí tuyệt đối
                idx_giai_dieu_che = Start_P + idx_chunk - 1;
                fprintf('Vị trí mẫu bắt đầu giải điều chế là: %d\n', idx_giai_dieu_che);
                is_detected = true;
                player = audioplayer(xp, fs,16);
                playblocking(player);   
                disp('Đã phát xong');
            end
        end
        
        % Chuyển sang chunk tiếp theo. 
        % QUAN TRỌNG: Lùi lại một khoảng bằng chiều dài xp để tạo chồng lấp (Overlap)
        Start_P = Ly - length(xp) + 1;
        if Start_P < 1; Start_P = 1; end
    end
    pause(0.05); % Nghỉ ngắn để CPU đỡ quá tải
    L = r.TotalSamples;
end

stop(r); % Dừng thu âm

