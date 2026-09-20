function [xFilt, env, envZ] = ripple_filter_envelope(x, fs, bandHz)
    x = double(x(:));
    x = x - median(x, 'omitnan');
    nyq = fs / 2;
    if bandHz(2) >= nyq
        error('Ripple band exceeds Nyquist after downsampling.');
    end
    [b,a] = butter(4, bandHz ./ nyq, 'bandpass');
    xFilt = filtfilt(b, a, x);
    env = abs(hilbert(xFilt));
    envZ = (env - median(env, 'omitnan')) ./ mad(env, 1);
    if all(~isfinite(envZ)) || std(envZ,'omitnan') == 0
        envZ = zscore(env);
    end
end
