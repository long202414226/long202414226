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
t = (0:length(baseband_I)-1) / fs;

xp = baseband_I .* cos(2*pi*fc*t) - baseband_Q .* sin(2*pi*fc*t);
xp = 0.8 * (xp / max(abs(xp)));

def = 1400;
[b_bp, a_bp] = butter(4, [(fc-def) (fc+def)] / (fs/2), 'bandpass');

r = audiorecorder(fs, 16, 1);
record(r);
pause(0.1);
L=r.TotalSamples;
Start_P = 1;
chunk_size = 40000;
player = audioplayer(xp, fs, 16);

while L<1000000
playblocking(player);
stop(r);

rx = getaudiodata(r, 'double')';
y = filtfilt(b_bp, a_bp, rx);

idx_di = find_header_pos(y(1:(length(y)/2)), xp);

if isempty(idx_di)
    disp('Không tìm thấy tín hiệu sync phát đi (idx_di)!');
    return;
end
fprintf('idx di: %d \n',idx_di);

idx_di = round(idx_di);
idx_ve = find_header_pos(y((idx_di + length(xp)):end), xp);
if isempty(idx_ve)
    disp('Không tìm thấy tín hiệu sync phản hồi từ Trạm B (idx_ve)!');
    return;
end
fprintf('idx ve: %d \n',idx_ve);

dt_A = (idx_ve - idx_di) / fs; 
dt_B = 0;
t = (dt_A - dt_B) / 2;
distance = t * v_sound;
fprintf('%f m\n',distance);

end

stop(r);