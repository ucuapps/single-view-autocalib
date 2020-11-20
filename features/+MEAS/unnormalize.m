function [meas, varinput] = unnormalize(meas, K, varinput)
    unnorm_fns = containers.Map();
    unnorm_fns('rgn') = @RP2.unnormalize;
    unnorm_fns('arc') = @ARC.unnormalize;
    unnorm_fns('ct') = @RP2.unnormalize;
    unnorm_fns('pt') = @RP2.unnormalize;
    
    for key = meas.keys
        key = key{1};
        unnorm_fn = unnorm_fns(key);
        if ~isempty(meas(key))
            if nargout(unnorm_fn) == 2 && nargout == 2 
                [meas(key), varinput(key)] = ...
                            unnorm_fn(meas(key), K, varinput(key));
            else
                meas(key) = unnorm_fn(meas(key), K);
            end
        end
    end
end