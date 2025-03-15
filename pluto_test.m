% Create radio object
pluto = sdrrx('Pluto');

% Configure radio parameters
pluto.CenterFrequency = 915e6;      % 915 MHz
pluto.BasebandSampleRate = 2e6;      % 2 MHz
pluto.GainSource = 'Manual';        % Set gain mode to manual
pluto.Gain = 70;                    % Increased gain to 70 dB for better sensitivity

% Increase samples for better resolution
pluto.SamplesPerFrame = 4096;       % Increased from 1024 for better resolution

% Capture multiple frames for averaging
numFrames = 10;
data = [];
for i = 1:numFrames
    [frame, valid] = pluto();
    if valid
        data = [data; frame];
    end
    pause(0.1);  % Small delay between captures
end

% Create modern spectrum analyzer
specAn = spectrumAnalyzer('SampleRate', pluto.BasebandSampleRate, ...
    'SpectrumType', 'power', ...
    'SpectralAverages', 10, ...
    'YLimits', [-120 -20]);    % Adjusted range for better visibility

% Show spectrum
specAn(data);  % Changed from show(specAn, data) to specAn(data)

% Also plot time domain for signal presence check
figure;
plot(real(data(1:1000)));
hold on;
plot(imag(data(1:1000)));
title('Time Domain Signal (I/Q)');
xlabel('Sample');
ylabel('Amplitude');
legend('I', 'Q');
grid on;

% Print some diagnostic info
fprintf('PlutoSDR Status:\n');
fprintf('Center Frequency: %.2f MHz\n', pluto.CenterFrequency/1e6);
fprintf('Sample Rate: %.2f MHz\n', pluto.BasebandSampleRate/1e6);
fprintf('Gain: %d dB\n', pluto.Gain);
fprintf('Max Signal Level: %.2f dB\n', 20*log10(max(abs(double(data(:)))))); % Convert to double before abs