%% MAY 2 (SLAVE TRANSPONDER) - DUNG XUNG DON TAN 80 kHz
clear; clc;

%% 1. Thong so xung (Giu nguyen theo code cua ban)
Fs = 192000;                % Tan so lay mau (Hz)
dt = 0.0005;                % Do rong xung: 0.5 ms
Fc = 80000;                 % Tan so song mang: 80 kHz

n_dt = round(dt * Fs);      % 96 mau
t = (1:n_dt)' / Fs;
x = sin(2 * pi * Fc * t);   % Xung phat goc cua ban (vector cot 96x1)
pulseRef = flipud(x);       % Bo loc phoi hop (Matched Filter)

%% 2. Thong so dinh thoi & Bo loc thu
M = 2048;                   % Kich thuoc 1 khung DMA (~10.67 ms o 192 kHz)
N_wait  = 19200;            % Tre phan hoi co dinh: 0.1 s (19200 mau)
N_guard = 12000;            % Khoa bo do dinh ~62.5 ms sau khi phat de tranh doi am
txGain  = 0.8;              % Bien do phat (0.0 -> 1.0)

% Bo loc thong dai 75 - 85 kHz (Nyquist = Fs/2 = 96 kHz)
[b, a] = butter(5, [75 85] / 96, 'bandpass');
zf = zeros(max(length(a), length(b)) - 1, 1);

%% 3. Khoi tao luong thu-phat dong bo (Yeu cau Audio Toolbox)
apr = audioPlayerRecorder('SampleRate', Fs);
cleanupObj = onCleanup(@() release(apr));

rxFiltHist = zeros(2 * M, 1);
txFrame    = zeros(M, 1);

globalSample     = 1;
replyActive      = false;
replyStartSample = 0;
guardUntilSample = 0;

fprintf('=== MAY 2 DANG CHAY (Fc = %d Hz, Fs = %d Hz) ===\n', Fc, Fs);
fprintf('Dang cho xung tu May 1... Nhan Ctrl + C de dung.\n\n');

%% 4. Vong lap thoi gian thuc
while true
    [rxFrame, underRun, overRun] = apr(txFrame);
    if underRun > 0 || overRun > 0
        fprintf('[Canh bao] Rot mau audio (Under:%d, Over:%d)\n', underRun, overRun);
    end
    
    % Loc thong dai 75-85 kHz va ghep cua so truot 2 khung
    [rxFiltFrame, zf] = filter(b, a, rxFrame, zf);
    rxFiltHist = [rxFiltHist(M+1:end); rxFiltFrame];
    
    % Tim xung toi khi dang o trang thai lang nghe
    if ~replyActive && (globalSample > guardUntilSample) && (globalSample > M)
        % Tuong quan voi xung mau x va lay duong bao Hilbert
        corrOut = conv(rxFiltHist, pulseRef);
        env = abs(hilbert(corrOut));
        
        noiseStd = median(env) / 0.6745;
        thresh = max(6 * noiseStd, 0.30 * max(env));
        
        % Quet trong vung [M+1, 2*M] de moi xung chi kich hoat dung 1 lan
        seg = env(M : 2*M + 1);
        localMaxIdx = find(seg(2:end-1) > seg(1:end-2) & ...
                           seg(2:end-1) >= seg(3:end) & ...
                           seg(2:end-1) > thresh, 1, 'first');
        
        if ~isempty(localMaxIdx)
            cIdx = M + localMaxIdx;
            % Noi suy parabol 3 diem
            y1 = env(cIdx - 1); y2 = env(cIdx); y3 = env(cIdx + 1);
            denom = y1 - 2*y2 + y3;
            delta = 0;
            if abs(denom) > 1e-12
                delta = 0.5 * (y1 - y3) / denom;
            end
            cIdxExact = cIdx + delta;
            
            histStart = globalSample - M;
            nPeakB = histStart + (cIdxExact - 1);
            
            % Len lich phat tra lai dung xung x sau N_wait mau
            replyStartSample = round(nPeakB) + N_wait;
            guardUntilSample = replyStartSample + n_dt + N_guard;
            replyActive = true;
            
            fprintf('[Rx] Nhan xung tai mau %.2f -> Phat tra tai mau %d\n', nPeakB, replyStartSample);
        end
    end
    
    % Nap du lieu xung x vao khung phat ke tiep neu den lich
    nextFrameStart = globalSample + M;
    txFrame = zeros(M, 1);
    if replyActive
        sStart = max(nextFrameStart, replyStartSample);
        sEnd   = min(nextFrameStart + M - 1, replyStartSample + n_dt - 1);
        if sStart <= sEnd
            txIdx = (sStart - nextFrameStart + 1) : (sEnd - nextFrameStart + 1);
            chIdx = (sStart - replyStartSample + 1) : (sEnd - replyStartSample + 1);
            txFrame(txIdx) = txGain * x(chIdx);
        end
        if nextFrameStart > guardUntilSample
            replyActive = false;
        end
    end
    
    globalSample = nextFrameStart;
end