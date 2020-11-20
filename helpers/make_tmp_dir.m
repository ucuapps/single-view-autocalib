
function dirpath = make_tmp_dir()
    today = num2str(yyyymmdd(datetime(floor(now),...
                                'ConvertFrom','datenum')));
    dirpath = GetFullPath(fullfile('~','tmp',today));
    mkdir(fullfile('~','tmp',today));
end