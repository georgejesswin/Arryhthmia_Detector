% =========================================================================
% Module: Calibration and Standards
% Engineer: [Your Name]
% Objective: Verify IEC 60601 / AHA standards, calculate HR, detect Arrhythmia.
% =========================================================================

% Note: 'ecg_filtered', 'ecg_adc', 'fs', and 't' must exist in the workspace.
% load('data/ecg_adc.mat');
% load('data/ecg_filtered.mat');

%% Step 1: Frequency Response Verification (AHA Standard)
% Target Bandwidth: 0.5Hz <= f <= 40Hz
N = length(ecg_filtered);
f_vec = (0:N-1)*(fs/N); % Frequency vector
fft_ecg = abs(fft(ecg_filtered));

% Keep only the positive frequencies up to the Nyquist limit (fs/2)
half_N = floor(N/2);
f_half = f_vec(1:half_N);
fft_ecg_half = fft_ecg(1:half_N);

%% Step 2: Amplitude Calibration
% --- BUG FIX: Scale the measured signal back down ---
Gain = 1000;
Measured_Amplitude = max(ecg_adc) / Gain; 
Actual_Amplitude = max(ecg_clean); % Dynamically find actual peak from clean source

Amplitude_Error = (Measured_Amplitude - Actual_Amplitude) / Actual_Amplitude;

fprintf('--- Calibration Metrics ---\n');
fprintf('Amplitude Error: %.2f%%\n', Amplitude_Error * 100);

%% Step 3: Heart Rate Detection
% --- BUG FIX: Use a dynamic threshold that ignores the initial startup transient ---
valid_idx = find(t > 2.0);
dynamic_adc_threshold = max(ecg_adc(valid_idx)) * 0.4;

[pks, locs] = findpeaks(ecg_adc, 'MinPeakHeight', dynamic_adc_threshold, 'MinPeakDistance', fs*0.4);

% Calculate time differences between peaks (R-R intervals)
rr_intervals = diff(t(locs));
HR = 60 / mean(rr_intervals);

fprintf('Average Heart Rate: %.1f BPM\n', HR);

%% Step 4: Arrhythmia Detection Algorithm
% Detects irregular heartbeats by checking R-R interval variability
rr_mean = mean(rr_intervals);
rr_variations = abs(rr_intervals - rr_mean);

% Standard clinical threshold: If variability exceeds 0.15 seconds (150ms)
arrhythmia_threshold = 0.15; 
is_arrhythmia = any(rr_variations > arrhythmia_threshold);

if is_arrhythmia
    fprintf('>>> ALERT: Arrhythmia Detected (Irregular R-R Intervals) <<<\n');
else
    fprintf('>>> Normal Sinus Rhythm <<<\n');
end

%% Required Plots
figure('Name', 'Standards, Calibration, and Detection', 'Position', [200, 100, 900, 800]);

% 1. FFT Spectrum (Verify 0.5Hz to 40Hz Bandwidth)
subplot(3,1,1);
plot(f_half, fft_ecg_half, 'b', 'LineWidth', 1.2);
xlim([0 60]); % Focus on 0 to 60Hz to verify 40Hz cutoff and 50Hz notch
xline(0.5, 'r--', '0.5 Hz');
xline(40, 'r--', '40 Hz');
title('Frequency Response Verification (AHA Standard)');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
grid on;

% 2. R-Peak Detection
subplot(3,1,2);
plot(t, ecg_adc, 'k'); hold on;
plot(t(locs), pks, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
title(sprintf('R-Peak Detection (HR: %.1f BPM)', HR));
xlabel('Time (s)'); ylabel('Amplitude (V)');
legend('Digitized ECG', 'Detected R-Peaks');
grid on;

% 3. Heart Rate Estimation (R-R Interval Analysis)
subplot(3,1,3);
% Plot the R-R intervals over beat number
plot(1:length(rr_intervals), rr_intervals, '-bs', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
yline(rr_mean, 'g--', 'Mean R-R');
yline(rr_mean + arrhythmia_threshold, 'r:', 'Upper Limit (+150ms)');
yline(rr_mean - arrhythmia_threshold, 'r:', 'Lower Limit (-150ms)');

if is_arrhythmia
    title('R-R Interval Variability (ARRHYTHMIA DETECTED)', 'Color', 'r');
else
    title('R-R Interval Variability (Normal Rhythm)', 'Color', 'g');
end
xlabel('Beat Number'); ylabel('R-R Interval (seconds)');
ylim([min(rr_intervals)-0.2, max(rr_intervals)+0.2]);
grid on;