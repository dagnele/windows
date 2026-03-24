local function trim(value)
    if not value then
        return ''
    end

    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function home_dir()
    return os.getenv('USERPROFILE') or os.getenv('HOME') or ''
end

local function quote_arg(value)
    return '"' .. tostring(value):gsub('"', '\\"') .. '"'
end

local function join_args(args)
    local quoted = {}

    for _, arg in ipairs(args) do
        quoted[#quoted + 1] = quote_arg(arg)
    end

    return table.concat(quoted, ' ')
end

local function split_args(text)
    local args = {}
    local current = {}
    local in_quotes = false
    local i = 1

    while i <= #text do
        local ch = text:sub(i, i)

        if ch == '"' then
            in_quotes = not in_quotes
        elseif ch:match('%s') and not in_quotes then
            if #current > 0 then
                args[#args + 1] = table.concat(current)
                current = {}
            end
        else
            current[#current + 1] = ch
        end

        i = i + 1
    end

    if #current > 0 then
        args[#args + 1] = table.concat(current)
    end

    return args
end

local function run_capture(command, suppress_stderr)
    if suppress_stderr == nil or suppress_stderr then
        command = command .. ' 2>nul'
    end

    local handle = io.popen(command)
    if not handle then
        return nil
    end

    local output = handle:read('*a')
    handle:close()
    return trim(output)
end

local function normalize_path(path)
    local expanded = tostring(path)

    if expanded == '~' then
        expanded = home_dir()
    elseif expanded:match('^~[\\/]') then
        expanded = home_dir() .. expanded:sub(2)
    end

    return expanded:gsub('/', '\\')
end

local function is_path_like(arg)
    return arg == '.'
        or arg == '..'
        or arg == '-'
        or arg == '~'
        or arg:match('^~[\\/]') ~= nil
        or arg:match('^[A-Za-z]:[\\/]') ~= nil
        or arg:match('^[%.][\\/]') ~= nil
        or arg:match('^[\\/]') ~= nil
        or arg:find('\\', 1, true) ~= nil
        or arg:find('/', 1, true) ~= nil
end

local function zoxide_query(args, interactive)
    local command = interactive and 'zoxide query -i -- ' or 'zoxide query -- '
    local path = run_capture(command .. join_args(args), not interactive)

    if path == '' then
        return nil
    end

    return path
end

local function list_matches(args)
    local command = 'zoxide query -l'
    if #args > 0 then
        command = command .. ' -- ' .. join_args(args)
    end

    os.execute(command)
end

local function print_help(command_name)
    print('zoxide commands for Clink/cmd.exe')
    print('')
    print('  z [terms...]        Jump to the best match')
    print('  z -l [terms...]     List ranked matches')
    print('  zi [terms...]       Interactive selection via fzf')
    print('  z ..                Go to parent directory')
    print('  z -                 Go to previous directory')
    print('  z .\\path           Go to a relative path')
    print('  z C:\\path          Go to an absolute path')
    print('  z -- -              Search for a literal dash term')
    print('  ' .. command_name .. ' --help         Show this help')
end

local function resolve_path_command(arg)
    if arg == '-' then
        return 'cd -'
    end

    return 'cd /d ' .. quote_arg(normalize_path(arg))
end

local function parse_command_args(args, force_interactive)
    local interactive = force_interactive
    local list = false
    local query_args = {}
    local passthrough = false

    for index, arg in ipairs(args) do
        if passthrough then
            query_args[#query_args + 1] = arg
        elseif arg == '--' then
            passthrough = true
        elseif arg == '-i' then
            interactive = true
        elseif arg == '-l' then
            list = true
        else
            query_args[#query_args + 1] = arg

            for rest_index = index + 1, #args do
                query_args[#query_args + 1] = args[rest_index]
            end

            break
        end
    end

    return interactive, list, query_args, passthrough
end

local function is_single_command(text)
    return not text:find('[&|]')
end

clink.onfilterinput(function(text)
    local line = trim(text)
    if line == '' or not is_single_command(line) then
        return nil
    end

    local cmd, rest = line:match('^(%S+)%s*(.-)%s*$')
    if cmd ~= 'z' and cmd ~= 'zi' then
        return nil
    end

    local args = split_args(rest or '')
    local interactive, list, query_args, passthrough = parse_command_args(args, cmd == 'zi')

    if #args == 1 and (args[1] == '--help' or args[1] == '-h') then
        print_help(cmd)
        return ''
    end

    if not interactive and list then
        list_matches(query_args)
        return ''
    end

    if not passthrough and #query_args == 1 and is_path_like(query_args[1]) then
        return resolve_path_command(query_args[1])
    end

    if not interactive and #query_args == 0 then
        list_matches({})
        return ''
    end

    local path = zoxide_query(query_args, interactive)
    if path then
        return 'cd /d ' .. quote_arg(path)
    end

    if not interactive then
        print('zoxide: no match found')
    end

    return ''
end)

clink.prompt.register_filter(function()
    local cwd = clink.get_cwd()
    if cwd and cwd ~= '' then
        os.execute('zoxide add ' .. quote_arg(cwd) .. ' 2>nul')
    end
end, 1)
