% =========================================================================
% KHỐI THU (TRẠM B) - LẮNG NGHE & PHẢN HỒI REAL-TIME
% =========================================================================
clc; clear; close all;

fs = 96000;        
fc = 16500;         
br = 700;     
N = round(fs/br);

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

% Khởi tạo player 1 lần ở ngoài để tái sử dụng
player = audioplayer(xp, fs, 16);

def = 1400;
[b_bp, a_bp] = butter(4, [(fc-def) (fc+def)] / (fs/2), 'bandpass');

disp('=== ĐANG LẮNG NGHE TÍN HIỆU (Nhấn Ctrl+C để dừng) ===');
r = audiorecorder(fs, 16, 1);
record(r);
pause(0.1);

Start_P = 1;
chunk_size = 40000;     
L = r.TotalSamples;

% Đổi thành vòng lặp dài hơn để lắng nghe liên tục nhiều chu kỳ
while L < 10000000 
    pause(0.05); 
    y = getaudiodata(r, 'double')';
    Ly = length(y);
    
    % SỬA LỖI 2: Chỉ xử lý khi thu đủ 1 khối (chunk)
    if Ly - Start_P > chunk_size
        yr = y(Start_P:Ly);
        yr = filtfilt(b_bp, a_bp, yr);
        
        idx_rel = find_header_pos1(yr, xp);    
        
        if ~isempty(idx_rel)
            % Tính tọa độ tuyệt đối
            idx_thu = Start_P + round(idx_rel) - 1;
            fprintf('\n--> ĐÃ TÌM THẤY HEADER TẠI MẪU %d!\n', idx_thu);
            
            disp('Đang phát phản hồi...');
            playblocking(player);   
            disp('Đã phát xong, tiếp tục lắng nghe...');
            
            % SỬA LỖI 3: Nhảy Start_P qua phần âm thanh vừa phát
            % Cập nhật lại mảng y sau khi loa phát xong
            y_after = getaudiodata(r, 'double');
            Start_P = max(1, length(y_after));
            
        else
            % SỬA LỖI 1: Trượt cửa sổ đi tiếp, giữ lại phần đuôi xp
            Start_P = Ly - length(xp);
        end
    end
    
    L = r.TotalSamples;
end

stop(r); 
disp('=== ĐÃ DỪNG THU ÂM ===');

% =========================================================================
% SỬA LỖI 4: HÀM TÌM VỊ TRÍ TƯƠNG QUAN CHỐNG NHIỄU
% =========================================================================
function idx = find_header_pos1(rx, header)
    rx     = rx(:);
    header = header(:);

    h = conj(flipud(header));
    y = filter(h, 1, rx);

    [max_val, idx_peak] = max(abs(y));
    idx = idx_peak - length(header) + 1;

    % Kiểm tra lỗi tọa độ (âm hoặc sát lề)
    if idx < 1 || (idx + length(header) - 1) > length(rx) || idx_peak > length(rx) - 100
        idx = [];
        return;
    end
    
    % Lọc nhiễu phòng: Chỉ bắt khi hệ số tương quan đủ lớn
    seg = rx(idx : idx + length(header) - 1);
    corr_score = max_val / (norm(seg) * norm(header) + 1e-6);
    
    if corr_score < 0.25
        idx = []; % Trả về rỗng nếu chỉ là nhiễu rác
    end
end