% Create radio object
pluto = sdrrx('Pluto');

% Configure radio parameters for TechToo sensor frequency range
pluto.CenterFrequency = 915e6;      % 915 MHz (typical for IoT sensors)
pluto.BasebandSampleRate = 1e6;      % 1 MHz (narrower bandwidth for better sensitivity)
pluto.GainSource = 'Manual';
pluto.Gain = 60;                     % Slightly reduced gain to avoid saturation
pluto.SamplesPerFrame = 8192;        % Larger frame size for better resolution

% Create a new figure for comparison
figure('Name', 'Antenna Comparison', 'Position', [100 100 1200 800]);

% Test procedure
fprintf('Antenna Testing Procedure:\n');
fprintf('1. Place the first antenna and press Enter\n');
pause;
results.antenna1 = measureAntenna(pluto, 'Antenna 1', 1);

fprintf('\n2. Place the second antenna and press Enter\n');
pause;
results.antenna2 = measureAntenna(pluto, 'Antenna 2', 2);

% Print comparison results
fprintf('\nComparison Results:\n');
fprintf('Antenna 1: Avg Power = %.2f dBm, Peak Power = %.2f dBm\n', ...
    results.antenna1.avgPower, results.antenna1.peakPower);
fprintf('Antenna 2: Avg Power = %.2f dBm, Peak Power = %.2f dBm\n', ...
    results.antenna2.avgPower, results.antenna2.peakPower);

% Export results in multiple formats
timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
export_folder = 'antenna_test_results';
mkdir(export_folder);

% Save MATLAB data
save(fullfile(export_folder, sprintf('antenna_test_%s.mat', timestamp)), 'results');

% Export to CSV
csv_file = fullfile(export_folder, sprintf('antenna_test_%s.csv', timestamp));
fid = fopen(csv_file, 'w');
fprintf(fid, 'Antenna,Average Power (dBm),Peak Power (dBm),SNR (dB)\n');
fprintf(fid, 'Antenna 1,%.2f,%.2f,%.2f\n', results.antenna1.avgPower, results.antenna1.peakPower, results.antenna1.snr);
fprintf(fid, 'Antenna 2,%.2f,%.2f,%.2f\n', results.antenna2.avgPower, results.antenna2.peakPower, results.antenna2.snr);
fclose(fid);

% Save plots as PNG
saveas(gcf, fullfile(export_folder, sprintf('antenna_comparison_%s.png', timestamp)));

fprintf('\nResults exported to folder: %s\n', export_folder);
fprintf('Files saved:\n');
fprintf('- MATLAB data: antenna_test_%s.mat\n', timestamp);
fprintf('- CSV report: antenna_test_%s.csv\n', timestamp);
fprintf('- Plot image: antenna_comparison_%s.png\n', timestamp);

function results = measureAntenna(pluto, label, plotIndex)
    fprintf('\nTesting %s:\n', label);
    
    % Capture multiple frames for reliable measurement
    numFrames = 20;
    powerSum = 0;
    peakPower = -inf;
    all_frames = [];
    snr_values = [];
    
    for i = 1:numFrames
        [frame, valid] = pluto();
        if valid
            % Convert frame to double for complex operations
            frame_double = double(frame);
            
            % Calculate power in dBm
            power_db = 10*log10(mean(abs(frame_double).^2)) + 30;
            powerSum = powerSum + power_db;
            peakPower = max(peakPower, power_db);
            all_frames = [all_frames; frame_double];
            
            % Calculate SNR
            signal_power = mean(abs(frame_double).^2);
            noise_power = var(abs(frame_double));
            snr = 10*log10(signal_power/noise_power);
            snr_values = [snr_values; snr];
        end
        pause(0.1);
    end
    
    avgPower = powerSum / numFrames;
    avgSNR = mean(snr_values);
    
    % Store comprehensive results
    results.avgPower = avgPower;
    results.peakPower = peakPower;
    results.frames = all_frames;
    results.snr = avgSNR;
    results.timestamp = datetime('now');
    
    % Plot in the comparison figure
    subplot(2, 2, plotIndex);
    plot(real(all_frames(1:1000)));
    hold on;
    plot(imag(all_frames(1:1000)));
    title(sprintf('%s: %.1f dBm, SNR: %.1f dB', label, avgPower, avgSNR));
    xlabel('Sample');
    ylabel('Amplitude');
    legend('I', 'Q');
    grid on;
    
    subplot(2, 2, plotIndex + 2);
    pwelch(all_frames, hanning(1024), 512, 1024, pluto.BasebandSampleRate, 'centered');
    title(sprintf('Spectrum - %s', label));
    grid on;
    
    % Print detailed results
    fprintf('Results for %s:\n', label);
    fprintf('  Average Signal Strength: %.2f dBm\n', avgPower);
    fprintf('  Peak Signal Strength: %.2f dBm\n', peakPower);
    fprintf('  Average SNR: %.2f dB\n', avgSNR);
end