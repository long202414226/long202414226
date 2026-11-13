clc; clear; close all;

fs = 48000;        
fc = 15000;         
br = 100;     
N = round(fs/br);
z = 350;
text =  'trong moi truong nghien cuu khoa hoc hien dai viec ung dung cac thuat toan vao xu ly tin hieu so la dieu vo cung can thiet de toi uu hoa hieu suat truyen thong tin tren cac kenh truyen nhieu nhu am thanh duoi nuoc viec phan tich pho va su dung cac chuoi dong bo nhu m sequence se giup xac dinh chinh xac thoi diem bat dau khung.';

% 255bit
sync = [ ...
1 1 1 1 1 1 1 1 0 1 1 1 0 0 0 1 0 0 1 1 1 0 1 0 0 1 0 1 1 0 0 1 ...
1 1 1 1 0 1 0 0 0 0 1 0 0 1 0 0 0 1 1 0 1 0 1 1 1 0 1 1 1 1 0 0 ...
1 0 0 0 0 1 0 1 1 1 0 1 1 0 1 0 1 0 0 0 1 1 1 0 0 0 0 1 1 1 0 1 ...
1 1 0 0 0 1 0 1 0 0 1 1 1 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 1 0 1 1 ...
1 0 1 0 1 1 0 1 0 0 0 1 1 1 0 0 0 0 1 1 0 1 1 0 1 1 0 0 0 1 0 1 ...
0 0 1 1 1 1 1 1 0 1 1 0 0 1 0 0 0 0 1 1 1 0 1 1 0 1 0 0 0 1 1 0 ...
1 0 1 0 1 1 0 0 1 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 1 1 0 1 0 1 0 1 ...
0 1 0 0 1 1 0 1 1 1 0 0 0 1 1 0 1 1 0 0 1 1 0 ];

sync = [sync 0]; 

payload_bits = double(text2bits(text));
payload_bits = [1,1,1,1, payload_bits];
ze = zeros(1, z);

sync_I = 2 * sync(1:2:end) - 1;       
sync_Q = 2 * sync(2:2:end) - 1;       
sym_sync = sync_I + 1i * sync_Q;      

payload_I = 2 * payload_bits(1:2:end) - 1;
payload_Q = 2 * payload_bits(2:2:end) - 1;
sym_payload = payload_I + 1i * payload_Q;

bits = [sym_sync ze sym_payload ze];

baseband_I = kron(real(bits), ones(1, N));
baseband_Q = kron(imag(bits), ones(1, N));

t = (0:length(baseband_I)-1) / fs;
tx_signal = baseband_I .* cos(2*pi*fc*t) - baseband_Q .* sin(2*pi*fc*t);
tx_signal = 0.8*(tx_signal / max(abs(tx_signal))); % Chuẩn hóa biên độ


fprintf('Đang phát %d bit ra loa...\n', length(bits));
player = audioplayer(tx_signal, fs,16);
playblocking(player);   
disp('Đã phát xong');
