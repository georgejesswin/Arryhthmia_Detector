% =========================================================================
% Module: Signal Conditioning (Analog Front-End Simulation)
% Engineer: [Your Name]
% Objective: Amplify signal, remove baseline drift, powerline, and muscle noise.
% =========================================================================

% Note: 'ecg_raw', 'fs', and 't' must exist in the workspace before running this.
% If testing standalone, load the dataset from the Sensor Engineer first:
% load('data/ecg_raw.mat'); 

%% Step 1: Instrumentation Amplifier
Gain = 1000; % [cite: 98]
ecg_amp = Gain * ecg_raw; % [cite: 99]

%% Step 2: High-Pass Filter
% Cutoff frequency: 0.5 Hz to remove baseline drift [cite: 101]
hp = designfilt('highpassiir', 'FilterOrder', 4, ...
    'HalfPowerFrequency', 0.5, 'SampleRate', fs); % [cite: 103, 104]
ecg_hp = filtfilt(hp, ecg_amp); % [cite: 105]

%% Step 3: Notch Filter
% Removes 50 Hz powerline interference [cite: 107]
notch = designfilt('bandstopiir', 'FilterOrder', 2, ...
    'HalfPowerFrequency1', 49, 'HalfPowerFrequency2', 51, ...
    'SampleRate', fs); % [cite: 109, 110, 111, 112]
ecg_notch = filtfilt(notch, ecg_hp); % [cite: 113]

%% Step 4: Low-Pass Filter
% Cutoff frequency: 40 Hz to remove high-frequency muscle noise [cite: 116]
lp = designfilt('lowpassiir', 'FilterOrder', 4, ...
    'HalfPowerFrequency', 40, 'SampleRate', fs); % [cite: 117, 118]
ecg_filtered = filtfilt(lp, ecg_notch); % Output variable required for next stage [cite: 119, 129]

%% Required Plots [cite: 120]
figure('Name', 'Signal Conditioning Stages', 'Position', [100, 100, 800, 800]);

% 1. Raw ECG vs Amplified ECG [cite: 121]
subplot(4,1,1);
plot(t, ecg_raw, 'b'); hold on;
plot(t, ecg_amp/Gain, 'r--'); % Scaled back down visually to prove shape matches
title('Step 1: Raw ECG vs Amplified ECG (Scaled for comparison)');
xlabel('Time (s)'); ylabel('Amplitude');
legend('Raw', 'Amplified (Scaled)');
grid on;

% 2. After high-pass filtering [cite: 122]
subplot(4,1,2);
plot(t, ecg_hp, 'k');
title('Step 2: After 0.5 Hz High-Pass Filter (Baseline Drift Removed)');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;

% 3. After notch filtering [cite: 123]
subplot(4,1,3);
plot(t, ecg_notch, 'm');
title('Step 3: After 50 Hz Notch Filter (Powerline Noise Removed)');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;

% 4. Final filtered ECG [cite: 124]
subplot(4,1,4);
plot(t, ecg_filtered, 'g');
title('Step 4: Final Filtered ECG (After 40 Hz Low-Pass)');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;

