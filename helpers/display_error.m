function display_error(e)
    for k=numel(e.stack):-1:1
        fprintf('\nError in %s (line %d):\n', e.stack(k).name, e.stack(k).line);
    end
    fprintf('\n    %s\n\n', e.message);
end