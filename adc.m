% =========================================================================
% MATLAB Script to Programmatically Generate an ADC Simulink Model
% =========================================================================

% 1. Define and load parameters into the base workspace
% Simulink blocks need these variables to exist in the workspace to run.
ADC_bits = 12;
Vref = 3.3;
step = Vref / (2^ADC_bits);

assignin('base', 'ADC_bits', ADC_bits);
assignin('base', 'Vref', Vref);
assignin('base', 'step', step);

% 2. Create and open a new Simulink model
modelName = 'My_ADC_Simulation';

% Check if a model with this name is already open, and close it if so
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

new_system(modelName);
open_system(modelName);

% 3. Add Blocks to the Model
% Syntax: add_block('LibraryPath', 'DestinationPath', 'Position', [left top right bottom])

% Analog Input (Sine Wave)
add_block('simulink/Sources/Sine Wave', [modelName, '/Analog_Input'], ...
    'Position', [50, 100, 80, 130]);

% Voltage Limits (Saturation)
add_block('simulink/Discontinuities/Saturation', [modelName, '/Voltage_Limits'], ...
    'Position', [150, 100, 180, 130]);

% Sample and Hold (Zero-Order Hold)
add_block('simulink/Discrete/Zero-Order Hold', [modelName, '/Sample_and_Hold'], ...
    'Position', [250, 100, 280, 130]);

% ADC Quantizer
add_block('simulink/Math Operations/Quantizer', [modelName, '/ADC_Quantizer'], ...
    'Position', [350, 100, 390, 130]);

% Mux (To combine signals for the Scope)
add_block('simulink/Signal Routing/Mux', [modelName, '/Mux'], ...
    'Position', [450, 80, 455, 170]);

% Scope (To view the output)
add_block('simulink/Sinks/Scope', [modelName, '/Scope'], ...
    'Position', [520, 110, 550, 140]);


% 4. Set Block Parameters
% Applying the math and settings based on your Vref and Step Size

set_param([modelName, '/Analog_Input'], ...
    'Amplitude', 'Vref/2', ...
    'Bias', 'Vref/2', ...
    'Frequency', '2*pi*10'); % 10 Hz test signal

set_param([modelName, '/Voltage_Limits'], ...
    'UpperLimit', 'Vref', ...
    'LowerLimit', '0');

set_param([modelName, '/Sample_and_Hold'], ...
    'SampleTime', '1/1000'); % 1 kHz sampling frequency

set_param([modelName, '/ADC_Quantizer'], ...
    'QuantizationInterval', 'step');

set_param([modelName, '/Mux'], ...
    'Inputs', '2');


% 5. Connect the Blocks together (Wiring)
% Syntax: add_line('ModelName', 'SourcePort', 'DestinationPort', 'autorouting', 'smart')

% Primary ADC Path
add_line(modelName, 'Analog_Input/1', 'Voltage_Limits/1', 'autorouting', 'smart');
add_line(modelName, 'Voltage_Limits/1', 'Sample_and_Hold/1', 'autorouting', 'smart');
add_line(modelName, 'Sample_and_Hold/1', 'ADC_Quantizer/1', 'autorouting', 'smart');
add_line(modelName, 'ADC_Quantizer/1', 'Mux/1', 'autorouting', 'smart');

% Branch the original analog signal to the second port of the Mux for comparison
add_line(modelName, 'Analog_Input/1', 'Mux/2', 'autorouting', 'smart');

% Send the combined Mux signal to the Scope
add_line(modelName, 'Mux/1', 'Scope/1', 'autorouting', 'smart');

% 6. Save and clean up layout
% Automatically zooms the model to fit everything neatly on screen
set_param(modelName, 'ZoomFactor', 'FitSystem');
save_system(modelName);

disp('Simulink model successfully generated and opened!');