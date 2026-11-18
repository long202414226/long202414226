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
player = audioplayer(xp, fs, 16);

def = 1400;
[b_bp, a_bp] = butter(4, [(fc-def) (fc+def)] / (fs/2), 'bandpass');

disp('ĐANG LẮNG NGHE TÍN HIỆU');
r = audiorecorder(fs, 16, 1);
record(r);
pause(0.1);
Start_P = 1;
chunk_size = 40000;     
L = r.TotalSamples;

while L < 15 * fs % Lắng nghe tối đa 15 giây (Tránh treo máy mãi mãi)
    pause(0.05); 
    y = getaudiodata(r, 'double')';
    Ly = length(y);
    idx = 0;

     if Ly - Start_P > chunk_size 
        yr = y(Start_P:Ly);
        yr = filtfilt(b_bp, a_bp, yr);
        idx = find_header_pos(yr, xp);    
        Start_P = Ly - length(xp) + 1;
     if Start_P < 1; Start_P = 1; end
     end
    if isempty(idx)
        fprintf('\n--> ĐÃ TÌM THẤY HEADER!\n');
        player = audioplayer(xp, fs,16);
        playblocking(player);   
        disp('Đã phát xong');
        
    else
        disp('Không bắt được tín hiệu.');

    end
        pause(0.05); % Nghỉ ngắn để CPU đỡ quá tải
        L = r.TotalSamples;
end
stop(r); % Dừng thu âm

