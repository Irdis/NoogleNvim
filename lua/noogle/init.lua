local M = {}

M.noogle_path = "noogle";
M.additional_locations = {}

M.setup = function(config)
    vim.api.nvim_create_user_command("Noogle",
        M.run_cmd,
        {
            nargs = "*",
        })
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
    return path:gsub("/", "\\")
end

M.run_in_buf = function(cmd)
    print(cmd)
    local lines = vim.fn.systemlist(cmd)

    for i, line in ipairs(lines) do
        lines[i] = string.sub(line, 1, -2)
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
    for _, addional_loc in ipairs(M.additional_locations) do
        res = res .. "," .. addional_loc
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
    local initial_folder = csproj_folder .. "\\bin\\" .. configuration
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
            return directory .. "\\" .. name
        elseif type == "directory" then
            table.insert(inner_dirs, directory .. "\\" .. name)
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
            return directory .. "\\" .. name
        end
    end
    if directory == root then
        return nil
    end
    return M.get_csproj(directory, root)
end


M.log = function(msg)
    print("[noogle] " .. msg)
end

return M
