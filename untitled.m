clc; clear; close all;
fs = 96000;        
fc = 16500;         
br = 700;     
N = round(fs/br);
v_sound = 343; 

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

r = audiorecorder(fs, 16, 1);
record(r);
pause(0.2);

L = r.TotalSamples;
chunk_size = 25000; 
dt_B = 0;           
lan_do = 0;

disp('=== BẮT ĐẦU ĐO KHOẢNG CÁCH REAL-TIME (Nhấn Ctrl+C để dừng) ===');

while L < 15 * fs
    lan_do = lan_do + 1;
    
    y_now = getaudiodata(r, 'double');
    Start_Cycle = max(1, length(y_now));
    
    playblocking(player);
    pause(0.05);
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
    
    idx_di = Start_Cycle + round(idx_di_rel) - 1;
    Start_P = idx_di + length(xp) + round(0.05 * fs);
    

    yr_ve = filtfilt(b_bp, a_bp, y(Start_P:end));
    idx_ve = find_header_pos(yr_ve, xp);

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
    
    pause(0.15);
    L = r.TotalSamples;
end

stop(r);

