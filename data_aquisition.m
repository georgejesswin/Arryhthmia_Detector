% =========================================================================
% Module: Data Acquisition (ADC Simulation)
% Engineer: [Your Name]
% Objective: Simulate sampling, quantization, and digital output generation.
% =========================================================================

% Note: 'ecg_filtered', 'fs', and 't' must exist in the workspace.
% If testing standalone, load the dataset from the Signal Conditioning Engineer:
% load('data/ecg_filtered.mat');

%% Step 1: ADC Parameters
ADC_bits = 12;      % 12-bit ADC resolution [cite: 139]
Vref = 3.3;         % 3.3V reference voltage [cite: 140]

% Calculate the quantization step size (LSB)
step = Vref / (2^ADC_bits); % [cite: 142, 144]

%% Step 2: Quantization
% Map the continuous analog voltages to discrete digital levels
ecg_adc = round(ecg_filtered / step) * step; % [cite: 146]

%% Step 3: Quantization Error
% Calculate the difference between the ideal analog signal and the digitized version
error = ecg_filtered - ecg_adc; % [cite: 148, 149]

%% Required Plots [cite: 151]
figure('Name', 'Data Acquisition - ADC Quantization', 'Position', [150, 150, 900, 700]);

% 1. Analog signal vs Digital signal [cite: 152]
% Zooming in on a small time window (e.g., 1 to 1.5 seconds) to actually see the steps
subplot(3,1,1);
zoom_idx = find(t >= 1 & t <= 1.5); 
plot(t(zoom_idx), ecg_filtered(zoom_idx), 'b', 'LineWidth', 1.5); hold on;
stairs(t(zoom_idx), ecg_adc(zoom_idx), 'r'); 
title('Analog Signal vs Digitized Signal (Zoomed View)');
xlabel('Time (s)'); ylabel('Voltage (V)');
legend('Analog (Filtered)', 'Digital (Quantized)');
grid on;

% 2. Quantization Error Signal [cite: 153]
subplot(3,1,2);
plot(t, error, 'k');
title(['Quantization Error (ADC Resolution: ', num2str(ADC_bits), '-bit)']);
xlabel('Time (s)'); ylabel('Error (V)');
grid on;

% 3. Histogram of Quantization Error [cite: 154]
subplot(3,1,3);
histogram(error, 50, 'FaceColor', '#7E2F8E');
title('Histogram of Quantization Error');
xlabel('Voltage Error (V)'); ylabel('Frequency');
grid on;

%% Deliverables [cite: 155]
% Save output for the Calibration and Validation Engineers
% save('data/ecg_adc.mat', 'ecg_adc', 'error', 't', 'fs'); % [cite: 157, 158]