%% MAY 2: THU XUNG TU MAY 1 VA PHAT TRA LAI (KHONG DAY)
clear; clc;

%% 1. Khoi tao xung giong het code goc cua ban
Fs = 192000;                % Doi thanh 48000 neu card am thanh khong ho tro 192kHz
dt = 0.0005;                % Do rong xung: 0.5 ms
Fc = 80000;                 % Doi thanh 16500 neu dung Fs = 48000

n_dt = round(dt * Fs);
t = (1:n_dt) / Fs;
x = 0.8 * sin(2 * pi * Fc * t); % Xung phat (vector hang 1 x n_dt)

% Bo loc thong dai tu dong bam theo Fc va Fs
[b, a] = butter(5, [Fc - 5000, Fc + 5000] / (Fs / 2));

%% 2. Mo Micro ghi am lien tuc
r = audiorecorder(Fs, 16, 1);
don_dep = onCleanup(@() stop(r));
record(r);
pause(0.5);

vi_tri_quet = round(0.4 * Fs);
cua_so_quet = round(0.05 * Fs); % Quet moi 50 ms

fprintf('=== MAY 2 DANG CHO XUNG TU MAY 1 (Nhan Ctrl + C de dung) ===\n\n');

while true
    pause(0.015);
    tong_mau = get(r, 'TotalSamples');
    if tong_mau <= vi_tri_quet + cua_so_quet
        continue;
    end
    
    y = getaudiodata(r, 'double');
    bat_dau = vi_tri_quet - n_dt;
    doan_thu = y(bat_dau : tong_mau);
    
    % Loc thong dai va lay duong bao
    yf = filtfilt(b, a, doan_thu);
    env = abs(hilbert(yf));
    
    nguong = max(6 * median(env) / 0.6745, 0.30 * max(env));
    
    % Tim dinh dau tien vuot nguong (xung tu May 1 toi)
    dinh = find(env(2:end-1) > env(1:end-2) & ...
                env(2:end-1) >= env(3:end) & ...
                env(2:end-1) > nguong, 1, 'first');
            
    if ~isempty(dinh)
        n_nhan = bat_dau + dinh;
        
        % 1. Phat ngay xung tra loi so 1
        sound(x, Fs);
        pause(0.18); % Doi xung phat ra khoi loa va duoc mic ghi lai
        
        % 2. Do xem xung tra loi 1 thuc su roi khoi loa May 2 tai mau nao
        y_kt = getaudiodata(r, 'double');
        moc_tim = n_nhan + round(0.008 * Fs);
        env_tx = abs(hilbert(filtfilt(b, a, y_kt(moc_tim : end))));
        [~, dinh_tx] = max(env_tx);
        n_phat_lai = moc_tim + dinh_tx - 1;
        
        % Tinh do tre phan cung N_tre_B (mau) cua May 2
        N_tre_B = max(round(n_phat_lai - n_nhan), round(0.01 * Fs));
        
        % 3. Phat cap xung kep cach nhau dung N_tre_B mau de bao cho May 1
        x_kep = [x, zeros(1, N_tre_B), x];
        sound(x_kep, Fs);
        
        fprintf('[Da phan hoi] Nhan tai mau %d -> Tre phat lai = %d mau\n', n_nhan, N_tre_B);
        
        pause(0.35); % Doi tat han doi am trong nuoc
        vi_tri_quet = get(r, 'TotalSamples');
    else
        vi_tri_quet = tong_mau - n_dt;
    end
end