local handle = io.popen('starship init cmd 2>nul')

if handle then
    local init_script = handle:read('*a') or ''
    handle:close()

    if init_script:match('%S') then
        local chunk, load_error = load(init_script)
        if chunk then
            local ok, runtime_error = pcall(chunk)
            if not ok then
                print('starship init failed: ' .. tostring(runtime_error))
            end
        else
            print('starship init failed: ' .. tostring(load_error))
        end
    end
end
