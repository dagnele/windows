-- Simple zoxide integration
clink.onfilterinput(function(text)
    -- Handle 'z' command with no arguments
    if text:match("^z%s*$") then
        os.execute('zoxide query -l')
        return ""
    end
    
    -- Handle 'z <query>' command
    local query = text:match("^z%s+(.+)")
    if query then
        local handle = io.popen('zoxide query "' .. query .. '" 2>nul')
        local path = handle:read("*a")
        handle:close()
        
        if path and path:match("%S") then
            path = path:gsub("%s+$", "") -- trim whitespace
            return 'cd /d "' .. path .. '"'
        else
            print("zoxide: no match found")
            return ""
        end
    end
    
    -- Handle 'zi' command
    if text:match("^zi%s*$") then
        local handle = io.popen('zoxide query -i 2>nul')
        local path = handle:read("*a")
        handle:close()
        
        if path and path:match("%S") then
            path = path:gsub("%s+$", "") -- trim whitespace
            return 'cd /d "' .. path .. '"'
        else
            return ""
        end
    end
    
    return nil
end)

-- Auto-add directories
clink.prompt.register_filter(function()
    local cwd = clink.get_cwd()
    os.execute('zoxide add "' .. cwd .. '" 2>nul')
end, 1)

print("Zoxide commands loaded: z <query>, zi (interactive), z (list all)")