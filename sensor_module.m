%% Secure Wearable ECG Arrhythmia Detection System
% Role: Sensor / Transducer Engineer [cite: 1, 46]
% Objective: Simulate ECG acquisition, electrode interface, and noise [cite: 53, 54]

clear; clc; close all;

%% 1. Global System Parameters [cite: 39]
% To maintain consistency across all modules [cite: 40]
fs = 500;                       % Sampling Frequency (Hz) [cite: 41, 61]
duration = 30;                  % Simulation Duration (seconds) 
t = 0:1/fs:duration;            % Time vector [cite: 62]

%% 2. Step 1: Generate Ideal ECG [cite: 60]
sfecg = fs;          % Your project's required 500 Hz 
N = 35;              % Number of beats (approx 70 bpm for 30s)
noise_level = 0;     % We add our own noise later per project docs [cite: 57]
hrmean = 70;         % Mean heart rate
hrstd = 1;           % Heart rate standard deviation
lfhfr = 0.5;         % LF/HF ratio
sfint = 500;         % FIXED: Must be an integer multiple of sfecg (500/500=1)

% We only need the first output (the signal 's')
% This prevents the 'ipeaks' array from overwriting our time data
ecg_clean_raw = ecgsyn(sfecg, N, noise_level, hrmean, hrstd, lfhfr, sfint);

% Force it to be a row vector (1 x M) to prevent matrix expansion
ecg_clean_raw = ecg_clean_raw(:)';

% Truncate the signal to exactly match the length of our time vector 't'
if length(ecg_clean_raw) >= length(t)
    ecg_clean = ecg_clean_raw(1:length(t));
else
    % Failsafe in case N=40 wasn't long enough
    ecg_clean = [ecg_clean_raw, zeros(1, length(t) - length(ecg_clean_raw))];
end

% Scale to fit the project amplitude range (approx 1.5mV)
ecg_clean = (ecg_clean - min(ecg_clean)); 
ecg_clean = (ecg_clean / max(ecg_clean)) * 1.5;

%% 3. Step 2: Electrode Interface Modeling [cite: 64]
% Modeling artifacts introduced by the skin-electrode interface [cite: 65, 66]
baseline = 0.3 * sin(2 * pi * 0.3 * t);    % Baseline wander (low-freq drift) [cite: 67, 68]
motion = 0.1 * randn(size(t));             % Motion artifact (random transients) [cite: 69, 70]

%% 4. Step 3: Physiological Noise [cite: 71]
% Adding environmental and biological interference [cite: 57]
powerline = 0.05 * sin(2 * pi * 50 * t);   % 50 Hz interference [cite: 72, 73]
muscle = 0.02 * randn(size(t));            % Muscle noise (EMG) [cite: 74, 75, 76]

%% 5. Step 4: Raw ECG Signal [cite: 77]
% Combining all components to produce the raw input for the front-end [cite: 58]
ecg_raw = ecg_clean + baseline + powerline + muscle + motion; % [cite: 79]

%% 6. Required Plots [cite: 80]
figure('Name', 'Sensor Module: ECG Signal Generation');

subplot(3,1,1);
plot(t, ecg_clean);
title('Step 1: Clean ECG Signal [cite: 81]');
ylabel('Amplitude'); grid on;

subplot(3,1,2);
plot(t, baseline, 'r', t, powerline, 'g');
title('Step 2 & 3: Individual Noise Components [cite: 82]');
legend('Baseline', 'Powerline');
ylabel('Amplitude'); grid on;

subplot(3,1,3);
plot(t, ecg_raw);
title('Step 4: Final Raw ECG Signal [cite: 83]');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

%% 7. Deliverables [cite: 85]
% Saving the dataset for the Signal Conditioning Engineer [cite: 86, 205]
% Ensure the 'data' folder exists in your project directory [cite: 227]

save('ecg_raw.mat', 'ecg_raw', 'fs', 't'); % [cite: 86, 235]

fprintf('Sensor Module complete. Output variable "ecg_raw" saved to data/ecg_raw.mat\n');