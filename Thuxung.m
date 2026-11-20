%% MAY 2 (KHOI THU / DAP): NHAN XUNG CHIRP TU MAY 1 VA PHAT TRA LAI
clear; clc;

%% 1. Cau hinh thong so xung Chirp (Phai giong het May 1)
Fs = 96000;                 % Tan so lay mau (doi thanh 48000 neu card khong ho tro 96k)
dt = 0.003;                 % Do rong xung Chirp: 3 ms
f0 = 10000;                 % Tan so bat dau quet: 10 kHz
f1 = 16000;                 % Tan so ket thuc quet: 16 kHz

n_dt = round(dt * Fs);
t = (0:n_dt-1) / Fs;
cua_so = 0.5 * (1 - cos(2 * pi * (0:n_dt-1) / (n_dt - 1))); % Cua so Hann lam muot 2 dau
x = 0.8 * sin(2 * pi * (f0 * t + (f1 - f0) / (2 * dt) * t.^2)) .* cua_so;
x_ref = flipud(x(:));       % Bo loc phoi hop (Matched Filter) dang vector cot

% Bo loc thong dai 9 - 17 kHz loai bo nhieu nen
[b, a] = butter(5, [f0 - 1000, f1 + 1000] / (Fs / 2));

%% 2. Khoi dong Micro thu am lien tuc
r = audiorecorder(Fs, 16, 1);
don_dep = onCleanup(@() stop(r));
record(r);
pause(0.5);

vi_tri_quet = round(0.4 * Fs);
cua_so_quet = round(0.04 * Fs); % Quet du lieu moi 40 ms

fprintf('=== MAY 2 DANG LANG NGHE XUNG CHIRP (Nhan Ctrl + C de dung) ===\n\n');

while true
    pause(0.015);
    tong_mau = get(r, 'TotalSamples');
    if tong_mau <= vi_tri_quet + cua_so_quet
        continue;
    end
    
    y = getaudiodata(r, 'double');
    bat_dau = vi_tri_quet - n_dt;
    doan_thu = y(bat_dau : tong_mau);
    
    % Loc thong dai -> Nen xung bang tuong quan cheo -> Tach duong bao
    yf = filtfilt(b, a, doan_thu);
    env = abs(hilbert(conv(yf, x_ref)));
    
    noiseStd = median(env) / 0.6745;
    nguong = max(12 * noiseStd, 1e-4);
    
    % Tim dinh cuc bo dau tien vuot nguong (tia di thang tu May 1)
    pk = find(env(2:end-1) > env(1:end-2) & ...
              env(2:end-1) >= env(3:end) & ...
              env(2:end-1) > nguong, 1, 'first');
          
    if ~isempty(pk)
        n_nhan = bat_dau + dinh_le(env, pk + 1) - 1;
        
        % 1. Phat ngay xung tra loi so 1
        sound(x, Fs);
        pause(0.18); % Doi xung phat ra khoi loa va duoc mic ghi lai
        
        % 2. Do lai chinh xac thoi diem xung tra loi 1 roi khoi loa May 2
        y_kt = getaudiodata(r, 'double');
        moc_tim = round(n_nhan) + round(0.015 * Fs);
        env_tx = abs(hilbert(conv(filtfilt(b, a, y_kt(moc_tim : end)), x_ref)));
        [~, dinh_tx] = max(env_tx);
        n_phat_lai = moc_tim + dinh_le(env_tx, dinh_tx) - 1;
        
        % Do tre phan cung thuc te N_tre_B (tinh bang mau) cua May 2
        N_tre_B = max(round(n_phat_lai - n_nhan), n_dt + round(0.01 * Fs));
        
        % 3. Phat cap xung kep co khoang cach giua 2 dinh dung bang N_tre_B mau
        x_kep = [x, zeros(1, N_tre_B - n_dt), x];
        sound(x_kep, Fs);
        
        fprintf('[Phan hoi] Nhan tai %.1f -> Tre phan cung May 2 = %d mau\n', n_nhan, N_tre_B);
        
        pause(0.35); % Doi tat han doi am trong be nuoc
        vi_tri_quet = get(r, 'TotalSamples');
    else
        vi_tri_quet = tong_mau - n_dt;
    end
end

%% Ham noi suy parabol tim dinh chinh xac le mau
function idx_le = dinh_le(y, k)
    if k <= 1 || k >= length(y)
        idx_le = k; return;
    end
    denom = y(k-1) - 2*y(k) + y(k+1);
    if abs(denom) > 1e-12
        idx_le = k + 0.5 * (y(k-1) - y(k+1)) / denom;
    else
        idx_le = k;
    end
end