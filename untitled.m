% =========================================================================
% KHỐI PHÁT (TRẠM A): ĐO VÀ IN KHOẢNG CÁCH THAY ĐỔI THEO THỜI GIAN THỰC
% =========================================================================
clc; clear; close all;
fs = 96000;        
fc = 16500;         
br = 700;     
N = round(fs/br);
v_sound = 343; 

% 1. Tạo tín hiệu tương quan chuẩn (xp)
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

def = 1400;
[b_bp, a_bp] = butter(4, [(fc-def) (fc+def)] / (fs/2), 'bandpass');
player = audioplayer(xp, fs, 16);

% 2. Bật thu âm nền chạy liên tục xuyên suốt chương trình
r = audiorecorder(fs, 16, 1);
record(r);
pause(0.2);

L = r.TotalSamples;
chunk_size = 25000; % Quét mỗi 25.000 mẫu (~0.26s) để cập nhật nhanh
dt_B = 0;           % Thời gian trễ cố định tại Khối Thu (để 0 hoặc điền số hiệu chuẩn)
lan_do = 0;

disp('=== BẮT ĐẦU ĐO KHOẢNG CÁCH REAL-TIME (Nhấn Ctrl+C để dừng) ===');

% 3. Vòng lặp Real-time: Phát -> Bắt idx_di -> Đợi idx_ve -> In khoảng cách -> Lặp lại
while L < 10000000
    lan_do = lan_do + 1;
    
    % Đánh dấu vị trí mẫu ngay trước khi phát xung mới
    y_now = getaudiodata(r, 'double');
    Start_Cycle = max(1, length(y_now));
    
    % Phát tín hiệu tương quan ra loa
    playblocking(player);
    pause(0.05); % Chờ đuôi sóng âm vừa phát lọt hết vào Mic
    
    % --- BƯỚC A: Tìm vị trí tương quan lúc phát đi (idx_di) ---
    y = getaudiodata(r, 'double')';
    if length(y) - Start_Cycle <= length(xp)
        continue;
    end
    
    yr_di = filtfilt(b_bp, a_bp, y(Start_Cycle:end));
    idx_di_rel = find_header_pos(yr_di, xp);
    
    if isempty(idx_di_rel)
        fprintf('[Lần %d] Không bắt được xung phát đi (idx_di), đang phát lại...\n', lan_do);
        continue;
    end
    
    % Quy đổi idx_di về tọa độ tuyệt đối trên toàn luồng thu
    idx_di = Start_Cycle + round(idx_di_rel) - 1;
    
    % Đặt con trỏ Start_P nhảy qua khỏi xung phát đi + 0.05s chống tiếng vọng phòng
    Start_P = idx_di + length(xp) + round(0.05 * fs);
    
    % --- BƯỚC B: Quét real-time đợi xung phản hồi từ Khối Thu (idx_ve) ---
    idx_ve = [];
    timeout_samples = round(2.0 * fs); % Chờ tối đa 2 giây cho mỗi lần phát
    
    while (r.TotalSamples - idx_di) < timeout_samples
        pause(0.03);
        y = getaudiodata(r, 'double')';
        Ly = length(y);
        
        if Ly - Start_P > chunk_size
            yr_ve = filtfilt(b_bp, a_bp, y(Start_P:Ly));
            idx_ve_rel = find_header_pos(yr_ve, xp);
            
            if ~isempty(idx_ve_rel)
                % Quy đổi idx_ve về tọa độ tuyệt đối
                idx_ve = Start_P + round(idx_ve_rel) - 1;
                break; % Đã bắt được phản hồi, thoát vòng chờ để in kết quả ngay
            end
            
            % Trượt cửa sổ tìm kiếm (giữ lại đuôi dài bằng xp để không cắt đứt tín hiệu)
            Start_P = Ly - length(xp);
        end
    end
    
    % --- BƯỚC C: Tính và in khoảng cách Real-time ---
    if ~isempty(idx_ve)
        dt_A = (idx_ve - idx_di) / fs;
        t = (dt_A - dt_B) / 2;
        distance = t * v_sound;
        
        fprintf('[Lần %02d] idx_di: %7d | idx_ve: %7d | dt_A: %.4f s --> KHOẢNG CÁCH: %6.3f m\n', ...
                lan_do, idx_di, idx_ve, dt_A, distance);
    else
        fprintf('[Lần %02d] idx_di: %7d | Quá thời gian chờ (Không thấy Khối Thu phản hồi)\n', ...
                lan_do, idx_di);
    end
    
    pause(0.15); % Nghỉ ngắn cho tắt hẳn âm vang trước khi bắn xung tiếp theo
    L = r.TotalSamples;
end

stop(r);

