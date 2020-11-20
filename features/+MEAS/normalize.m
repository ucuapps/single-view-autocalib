function [meas2, varinput2] = normalize(meas, K, varinput)
    norm_fns = containers.Map();
    norm_fns('rgn') = @RP2.normalize;
    norm_fns('arc') = @ARC.normalize;
    norm_fns('ct') = @norm_ct;
    norm_fns('pt') = @RP2.normalize;
    norm_fns('corners') = @norm_corners;
    
    meas2 = containers.Map(meas.keys, meas.values);
    if nargout == 2
        varinput2 = containers.Map(varinput.keys,...
                                   varinput.values);
    end
    for key = meas.keys
        key = key{1};
        if isKey(norm_fns, key)
            norm_fn = norm_fns(key);
            if ~isempty(meas(key))
                if nargout(norm_fn) == 2
                    [meas2(key), varinput2(key)] = ...
                                norm_fn(meas(key), K, varinput(key));
                else
                    meas2(key) = norm_fn(meas(key), K);
                    if isKey(varinput, key)
                        varinput2(key) = varinput(key);
                    end
                end
            end
        else
            meas2(key) = meas(key);
            if isKey(varinput, key)
                varinput2(key) = varinput(key);
            end
        end
    end
end

function corners = norm_corners(corners, K)
    x_norm = arrayfun(@(c) RP2.normalize(c.x,K), corners,'UniformOutput',false);
    [corners(:).x] = deal(x_norm{:});
end

function ct = norm_ct(ct, K)
    for n=1:numel(ct)
        ct{n} = cellfun(@(x) RP2.normalize(x,K), ct{n},'UniformOutput',0);
    end
end