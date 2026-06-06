local M = {}

M.noogle_path = nil
M.additional_locations = {}

M.ensure_build = function()
    if M.noogle_exist_and_version_match() then
        return
    end

    M.log('Updating binaries...')

    local plugin_root = M.plugin_root()
    local release_folder = M.release_folder()

    local build_folder = plugin_root .. 'build/'
    local release_tool =  release_folder .. 'tool/'
    M.clean_dir(build_folder)
    M.copy_folder_content(release_tool, build_folder);

    local parser_folder = plugin_root .. 'parser/'
    local release_parser = release_folder .. 'parser/'
    M.clean_dir(parser_folder)
    M.copy_folder_content(release_parser, parser_folder);

    local old_version = release_folder .. 'version'
    local new_version = plugin_root .. 'build/version'
    M.copy_file(old_version, new_version)

    if M.is_linux() then
        vim.fn.system({ "chmod", "+x", plugin_root .. "build/noogle" })
    end

    M.log('Binaries updated')
end

M.clean_dir = function (path)
    local files = vim.fn.readdir('.')
    for _, file in ipairs(files) do
        if file ~= "." and file ~= ".." then
            local file_path = path .. '/' .. file
            os.remove(file_path)
        end
    end
end

M.copy_folder_content = function (source_path, dest_path)
    M.log('copying ' .. source_path .. ' -> ' .. dest_path)
    local files = vim.fn.readdir(source_path)
    for _, file in ipairs(files) do
        if file ~= "." and file ~= ".." then
            local source_file_path = source_path .. file
            local dest_file_path = dest_path .. file
            M.copy_file(source_file_path, dest_file_path)
        end
    end
end

M.copy_file = function(source_path, dest_path)
    local input_file = io.open(source_path, "rb")
    if not input_file then return nil, "Source file not found" end

    local output_file = io.open(dest_path, "wb")
    if not output_file then
        input_file:close()
        return nil, "Cannot open destination file"
    end

    output_file:write(input_file:read("a"))

    output_file:close()
    input_file:close()
end


M.is_linux = function ()
    local os_name = vim.loop.os_uname().sysname
    return os_name == "Linux"
end

M.noogle_exist_and_version_match = function ()
    local tool_path = M.get_tool_path()
    if not M.file_exists(tool_path) then
        return false
    end

    local plugin_root = M.plugin_root()

    local original_version_file = plugin_root .. 'build/version'
    if not M.file_exists(original_version_file) then
        return false
    end

    local original_version = vim.fn.readfile(original_version_file)

    local release_folder = M.release_folder()
    local new_version_file = release_folder .. 'version'
    local new_version = vim.fn.readfile(new_version_file)

    return original_version[1] == new_version[1]
end

M.get_tool_path = function ()
    local net_dir = M.plugin_root()
    net_dir = net_dir .. 'build/'
    if M.is_linux() then
        net_dir = net_dir .. 'noogle'
    else
        net_dir = net_dir .. 'noogle.exe'
    end
    return net_dir
end

M.release_folder = function ()
    local release = M.plugin_root() .. 'release/';
    if M.is_linux() then
        release = release .. 'linux/'
    else
        release = release .. 'win/'
    end
    return release
end

M.plugin_root = function ()
    return M.plugin_dir() .. '../../';
end

M.plugin_dir = function ()
    local source = debug.getinfo(1, "S").source:sub(2)
    local plugin_dir = vim.fn.fnamemodify(source, ":p:h")
    return plugin_dir .. '/'
end

M.setup = function(config)
    M.ensure_build()
    M.setup_treesitter()

    M.noogle_path = M.get_tool_path()

    vim.api.nvim_create_user_command("Noogle", M.run_cmd, { nargs = "*", })

    vim.api.nvim_create_user_command("NoogleType", M.noogle_type, { nargs = "*", })
    vim.api.nvim_create_user_command("NoogleTypeExt", M.noogle_type_ext, { nargs = "*", })
    vim.api.nvim_create_user_command("NoogleMethod", M.noogle_method, { nargs = "*", })
    vim.api.nvim_create_user_command("NoogleMethodExt", M.noogle_method_ext, { nargs = "*", })

    if not config then
        return
    end
    if config.noogle_path then
        M.noogle_path = config.noogle_path
    end
    if config.additional_locations then
        M.additional_locations = config.additional_locations
    end
end

M.setup_treesitter = function ()
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'noogle',
        callback = function() vim.treesitter.start() end
    })
end

M.noogle_type = function (args)
    M.run_cmd({ args = '-t ' .. args.args })
end

M.noogle_type_ext = function (args)
    M.run_cmd({ args = '-i -a -t ' .. args.args})
end

M.noogle_method = function (args)
    M.run_cmd({ args = '-m ' .. args.args })
end

M.noogle_method_ext = function (args)
    M.run_cmd({ args = '-i -a -m ' .. args.args})
end

M.run_cmd = function(args)
    M.run_debug({ args = args.args })
end

M.run_release = function(options)
    M.run("Release", options)
end

M.run_debug = function(options)
    M.run("Debug", options)
end

M.run = function(configuration, options)
    if not options then
        options = {}
    end

    local buf = vim.api.nvim_get_current_buf()

    local directory = M.get_directory(buf, configuration)
    if not directory then
        return
    end

    local cmd = M.build_cmd(directory, options.args)
    local scratch_buf = M.run_in_buf(cmd)
    vim.b[scratch_buf].noogle_dir = directory;
end

M.get_directory = function(buf, configuration)
    if vim.b[buf].noogle_dir then
        return vim.b[buf].noogle_dir
    end
    local file_path = vim.api.nvim_buf_get_name(buf)
    local root_folder = vim.loop.cwd()
    local csproj = M.get_csproj(file_path, root_folder)
    if not csproj then
        M.log("Unable to locate .csproj")
        return nil
    end

    local dll = M.get_dll(csproj, configuration)
    if not dll then
        M.log("Unable to locate .dll")
        return nil
    end
    local directory = vim.fn.fnamemodify(dll, ":h")
    return directory
end

M.normalize_path = function(path)
    if path == nil then return end
    if M.is_linux() then
        return path
    end
    return path:gsub("/", "\\")
end

M.run_in_buf = function(cmd)
    -- print(cmd)
    local lines = vim.fn.systemlist(cmd)

    if not M.is_linux() then
        for i, line in ipairs(lines) do
            lines[i] = string.sub(line, 1, -2)
        end
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'noogle')
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(buf)
    return buf
end

M.build_cmd = function(location, args)
    local cmd = M.noogle_path

    if args ~= "" then
        cmd = cmd .. " " .. args
    end
    location = M.escape_arg(M.add_paths(location))
    cmd = cmd .. " " .. "-p " .. location
    return cmd
end

M.add_paths = function (location)
    local res = location
    local need_quotes = M.is_linux() and #M.additional_locations > 0

    if need_quotes then
        res = "\"" .. res
    end

    for _, addional_loc in ipairs(M.additional_locations) do
        res = res .. ";" .. addional_loc
    end

    if need_quotes then
        res = res .. "\""
    end
    return res
end

M.escape_arg = function(str)
    if str:find(' ') then
        return '"' .. str .. '"'
    end
    return str
end

M.get_dll = function(csproj, configuration)
    local csproj_folder = vim.fn.fnamemodify(csproj, ":h")
    local csproj_name_noext = vim.fn.fnamemodify(csproj, ":t:r")
    local dll_name = csproj_name_noext .. ".dll"
    local initial_folder = csproj_folder .. "/bin/" .. configuration

    if not M.folder_exists(initial_folder) then
        initial_folder = csproj_folder .. "/bin"
    end
    if not M.folder_exists(initial_folder) then
        return nil
    end
    local dll_path = M.look_for_dll(dll_name, initial_folder)

    return M.normalize_path(dll_path)
end

M.look_for_dll = function(dll_name, directory)
    return M.look_for_dll_int(string.lower(dll_name), directory)
end

M.look_for_dll_int = function(dll_name, directory)
    local dir = vim.loop.fs_scandir(directory)
    if not dir then
        M.log("Unable to access: " .. directory)
        return nil
    end

    local inner_dirs = {}
    while true do
        local name, type = vim.loop.fs_scandir_next(dir)

        if not name then break end

        if type == "file" and string.lower(name) == dll_name then
            return directory .. "/" .. name
        elseif type == "directory" then
            table.insert(inner_dirs, directory .. "/" .. name)
        end
    end

    for _, inner_dir in ipairs(inner_dirs) do
        local found = M.look_for_dll_int(dll_name, inner_dir)
        if found then
            return found
        end
    end
    return nil
end

M.get_csproj = function(location, root)
    local directory = vim.fn.fnamemodify(location, ":h")

    if directory == location then
        return nil
    end

    local dir = vim.loop.fs_scandir(directory)
    if not dir then
        M.log("Unable to access: " .. directory)
        return nil
    end
    while true do
        local name, type = vim.loop.fs_scandir_next(dir)

        if not name then break end

        if type == "file" and string.match(name, "%.csproj$") then
            return directory .. "/" .. name
        end
    end
    if directory == root then
        return nil
    end
    return M.get_csproj(directory, root)
end

M.file_exists = function (path)
    return vim.loop.fs_stat(path) ~= nil
end

M.folder_exists = function (path)
    return vim.loop.fs_stat(path) ~= nil
end

M.log = function(msg)
    print("[noogle] " .. msg)
end

return M
