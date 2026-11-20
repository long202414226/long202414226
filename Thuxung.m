%% MAY 2 (KHOI THU / DAP): TU DO TRE PHAN CUNG VA PHAT TRA LAI
clear; clc;

%% 1. Cau hinh xung Chirp (Phai giong het May 1)
Fs = 96000;                 % Neu may nao khong ho tro 96000, doi ca 2 may thanh 48000
dt = 0.003;                 % Do rong xung Chirp: 3 ms
f0 = 10000;                 % Tan so dau: 10 kHz
f1 = 16000;                 % Tan so cuoi: 16 kHz

n_dt = round(dt * Fs);
t = (0:n_dt-1) / Fs;
cua_so = 0.5 * (1 - cos(2 * pi * (0:n_dt-1) / (n_dt - 1)));
x = 0.8 * sin(2 * pi * (f0 * t + (f1 - f0) / (2 * dt) * t.^2)) .* cua_so;
x_ref = flipud(x(:));

[b, a] = butter(5, [f0 - 1000, f1 + 1000] / (Fs / 2));

%% 2. Mo Micro ghi am lien tuc
r = audiorecorder(Fs, 16, 1);
don_dep = onCleanup(@() stop(r));
record(r);
pause(0.5);

vi_tri_quet = round(0.4 * Fs);
cua_so_quet = round(0.04 * Fs);

fprintf('=== MAY 2 DANG LANG NGHE (Nhan Ctrl + C de dung) ===\n\n');

while true
    pause(0.015);
    tong_mau = get(r, 'TotalSamples');
    if tong_mau <= vi_tri_quet + cua_so_quet
        continue;
    end
    
    y = getaudiodata(r, 'double');
    bat_dau = vi_tri_quet - n_dt;
    doan_thu = y(bat_dau : tong_mau);
    
    yf = filtfilt(b, a, doan_thu);
    env = abs(hilbert(conv(yf, x_ref)));
    
    noiseStd = median(env) / 0.6745;
    nguong = max(12 * noiseStd, 1e-4);
    
    pk = find(env(2:end-1) > env(1:end-2) & ...
              env(2:end-1) >= env(3:end) & ...
              env(2:end-1) > nguong, 1, 'first');
          
    if ~isempty(pk)
        n_nhan = bat_dau + dinh_le(env, pk + 1) - 1;
        
        % 1. Phat xung tra loi so 1
        sound(x, Fs);
        
        % 2. Doi cho den khi Mic May 2 thuc su bat duoc xung phat ra cua chinh no (toi da 0.45s)
        moc_tim = round(n_nhan) + round(0.02 * Fs);
        n_phat_lai = 0;
        for k_wait = 1:30
            pause(0.015);
            y_kt = getaudiodata(r, 'double');
            if length(y_kt) > moc_tim + n_dt
                env_tx = abs(hilbert(conv(filtfilt(b, a, y_kt(moc_tim : end)), x_ref)));
                if max(env_tx) > nguong
                    [~, dinh_tx] = max(env_tx);
                    n_phat_lai = moc_tim + dinh_le(env_tx, dinh_tx) - 1;
                    break;
                end
            end
        end
        
        if n_phat_lai > 0
            % Tinh do tre phan cung thuc te N_tre_B cua May 2
            N_tre_B = round(n_phat_lai - n_nhan);
            
            % Rut ngan khoang cach cap xung hieu chuan xuong 1/2 de tiet kiem thoi gian
            N_gap = max(round(N_tre_B / 2), n_dt + round(0.02 * Fs));
            N_tre_gui = N_gap * 2; % Gia tri chan chinh xac de May 1 nhan doi lai
            
            x_kep = [x, zeros(1, N_gap - n_dt), x];
            sound(x_kep, Fs);
            
            fprintf('[Phan hoi] Nhan tai %.1f | Tre May 2 = %d mau (%.1f ms)\n', ...
                n_nhan, N_tre_gui, N_tre_gui / Fs * 1000);
        else
            fprintf('[Canh bao May 2] Khong tu ghi lai duoc xung phat (kiem tra loopback May 2).\n');
        end
        
        pause(0.45); % Doi tat han doi am
        vi_tri_quet = get(r, 'TotalSamples');
    else
        vi_tri_quet = tong_mau - n_dt;
    end
end

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