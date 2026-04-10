% =========================================================================
% Module: Error and Validation
% Engineer: [Your Name]
% Objective: Evaluate system performance, calculate SNR/RMSE, validate detection.
% =========================================================================
% Note: 'ecg_clean', 'ecg_raw', 'ecg_filtered', 'ecg_adc', 'fs', 't' must exist.
% load('data/ecg_raw.mat'); 
% load('data/ecg_filtered.mat');
% load('data/ecg_adc.mat');
%% Step 1: Signal-to-Noise Ratio (SNR) Analysis
% --- BUG FIX: Scale the filtered signal back down to physiological levels ---
% The Instrumentation Amplifier applied a gain of 1000. We must divide it out 
% before comparing it to the 1.5V ecg_clean reference signal.
Gain = 1000;
ecg_filtered_scaled = ecg_filtered / Gain;
% Calculate SNR of the raw (noisy) signal vs the clean signal
SNR_raw = 10 * log10(var(ecg_clean) / var(ecg_clean - ecg_raw));
% Calculate SNR of the filtered signal (using the SCALED filtered signal)
SNR_filtered = 10 * log10(var(ecg_clean) / var(ecg_clean - ecg_filtered_scaled)); 
% Calculate SNR Improvement
SNR_improvement = SNR_filtered - SNR_raw;
%% Step 2: RMSE Error (Equation from Project Doc 9.3)
% Calculate RMSE using the SCALED filtered signal
RMSE = sqrt(mean((ecg_clean - ecg_filtered_scaled).^2)); 
fprintf('--- Validation Metrics ---\n');
fprintf('Initial Noisy SNR: %.2f dB\n', SNR_raw);
fprintf('Final Filtered SNR: %.2f dB\n', SNR_filtered);
fprintf('SNR Improvement: %.2f dB\n', SNR_improvement);
fprintf('RMSE (Clean vs Filtered): %.4f V\n', RMSE);
%% Step 3: Detection Accuracy (Sensitivity & False Detections)
% 1. Find Ground Truth Peaks (from clean ECG) - Lower thresholds here too
[~, true_locs] = findpeaks(ecg_clean, 'MinPeakHeight', max(ecg_clean)*0.4, 'MinPeakDistance', fs*0.4);
% Avoid filter transients and scale signal
ecg_adc_scaled = ecg_adc / Gain;
valid_idx = find(t > 2.0); 
% LOWER THRESHOLD TO 40%
dynamic_threshold = max(ecg_adc_scaled(valid_idx)) * 0.4;
% 2. Find Detected Peaks
[~, detected_locs] = findpeaks(ecg_adc_scaled, 'MinPeakHeight', dynamic_threshold, 'MinPeakDistance', fs*0.4);
% 3. Compare to find True Positives (TP) and False Positives (FP)
% A detection is considered correct if it falls within +/- 50ms of a true peak
tolerance = round(0.05 * fs); 
TP = 0; FP = 0; FN = 0;
for i = 1:length(detected_locs)
    % Check if detected peak is near any true peak
    if min(abs(true_locs - detected_locs(i))) <= tolerance
        TP = TP + 1;
    else
        FP = FP + 1; % False detection
    end
end
FN = length(true_locs) - TP; % Missed detections
Sensitivity = TP / (TP + FN) * 100;
Specificity_Metric = FP; % For peak detection, we usually track pure False Detections
fprintf('--- Detection Accuracy ---\n');
fprintf('True R-Peaks: %d\n', length(true_locs));
fprintf('Correct Detections (TP): %d\n', TP);
fprintf('False Detections (FP): %d\n', FP);
fprintf('Sensitivity: %.2f%%\n', Sensitivity);
%% Step 4: Arrhythmia Simulation Results
% To satisfy 9.5, we simulate an arrhythmic dataset and plot it
t_arr = 0:1/fs:8; % 8 seconds
rr_intervals_arrhythmic = [0.8, 0.8, 0.8, 1.4, 0.6, 0.8, 0.8]; % Irregular pattern
ecg_arrhythmia = zeros(size(t_arr));
current_time = 0;
for i = 1:length(rr_intervals_arrhythmic)
    current_time = current_time + rr_intervals_arrhythmic(i);
    idx = round(current_time * fs);
    if idx < length(t_arr)-5 && idx > 5
        ecg_arrhythmia(idx-2:idx+2) = [0.2, 0.5, 1.2, 0.5, 0.2]; % Fake spike
    end
end
% R-peak detection on arrhythmic signal
[~, locs_arr] = findpeaks(ecg_arrhythmia, 'MinPeakHeight', 0.6, 'MinPeakDistance', fs*0.3);
detected_rr = diff(t_arr(locs_arr));
%% Required Plots
figure('Name', 'System Validation and Error Analysis', 'Position', [250, 50, 900, 900]);
% 1. SNR Improvement Plot
subplot(3,1,1);
bar(categorical({'Raw Signal SNR', 'Filtered Signal SNR'}), [SNR_raw, SNR_filtered], 'FaceColor', '#0072BD');
title(sprintf('SNR Improvement (Gain: +%.2f dB)', SNR_improvement));
ylabel('SNR (dB)');
grid on;
% 2. Error Analysis Plot (Residual Error)
subplot(3,1,2);
% --- BUG FIX: Use the scaled signal here so the plot shows true residual error ---
error_signal = ecg_clean - ecg_filtered_scaled; 
plot(t, error_signal, 'r');
title(sprintf('Residual Error over Time (RMSE = %.4f)', RMSE));
xlabel('Time (s)'); ylabel('Amplitude Error (V)');
grid on;
% 3. Arrhythmia Simulation Results
subplot(3,1,3);
plot(t_arr, ecg_arrhythmia, 'k'); hold on;
plot(t_arr(locs_arr), ecg_arrhythmia(locs_arr), 'ro');
title('Arrhythmia Simulation Results (Irregular R-R Intervals)');
xlabel('Time (s)'); ylabel('Amplitude (V)');
% Annotate the R-R intervals on the plot
for i = 1:length(detected_rr)
    text_x = t_arr(locs_arr(i)) + detected_rr(i)/2;
    text(text_x, 1.0, sprintf('%.2fs', detected_rr(i)), 'HorizontalAlignment', 'center', 'Color', 'b', 'FontWeight', 'bold');
end
grid on;