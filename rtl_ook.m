% This code analyzes a 433MHz receiver using the
% http://code.google.com/p/rc-switch/ library and an RTL-SDR dongle.
% It simply filters the signal for noise, calculates the envelope, and
% converts it to a binary 0-1 signal. It converts and prints the encoded
% messages based on the pulse length after a simple debouncing.
%
% See https://ilias.giechaskiel.com/posts/rtl_433/index.html
% for details.
%
% Note that the script is very sensitive so the parameters might need to be
% tweaked for other applications, or even for other receivers/transmitters.

fc = 433.989e6; % Center frequency (Hz)
sr = 1e6;       % Samples per second
fl = 262144;    % Frame length (keep it as large as possible)

sdr_rx = comm.SDRRTLReceiver(...
    'CenterFrequency', fc, ...
    'EnableTunerAGC',  true, ...
    'SampleRate',      sr, ...
    'SamplesPerFrame', fl, ...
    'OutputDataType',  'double');

pl = 350e-6;                % pulse length
high_thres = 0.5;           % threshold for classifying as a 0 or 1
low_dur = sr*pl;            % pulse duration for a 0
high_mult = 3;              % multiplier for a 1
high_dur = high_mult*sr*pl; % pulse duration for a 1
db_dur = sr*pl/5;           % debouncing duration

high_len = 0; % number of high pulses
low_len = 0;  % number of low pulses for debouncing

num_secs = 1.5; % number of seconds to listen

binary = zeros(fl, 1); % array which will keep binary values

if ~isempty(sdrinfo(sdr_rx.RadioAddress)) % if dongle is connected
    num_repeats = ceil(num_secs*sr/fl); % number of loop repetitions
    for repeat = 1 : num_repeats
        [data,~] = step(sdr_rx); % data is complex-valued and in [-1 1]
        
        rdata = real(data); % just worry about in-phase data
        % plot(rdata)
        % ylim([-1 1])
        % pause(1)
        
        % Savitzky-Golay filtering (cubic with frames of length 41)
        smoothed = sgolayfilt(rdata, 3, 41);
        % plot(smoothed)
        % ylim([-1 1])
        % pause(1)
        
        % Calculate the envelope of the signal
        envelope = abs(hilbert(smoothed));
        % plot(envelope)
        % ylim([0 1.2])
        % pause(1)
        
        % convert to a binary value based on threshold
        binary(1:fl) = 0;
        binary(envelope >= high_thres) = 1;
        % plot(binary)
        % ylim([0 1])
        % pause(1)
        
        for i = 1 : fl
            if binary(i)
                % if high, increment high pulses and reset debouncing
                high_len = high_len + 1;
                low_len = 0;
            else
                if high_len
                    % if transmission was not silent, increase debouncing
                    low_len = low_len + 1;
                end
                
                % if have exceeded debouncing, and have transmission
                if low_len > db_dur && high_len
                    % if it's close enough to a low or high pulse, print it
                    if abs(high_len - low_dur) < db_dur + 10
                        fprintf('%d', 0)
                    elseif abs(high_len - high_dur) < db_dur*high_mult
                        fprintf('%d', 1)
                    end
                    
                    % reset high and debouncing
                    low_len = 0;
                    high_len = 0;
                end
            end
        end
    end
end
fprintf('\n')

release(sdr_rx); % release system object
