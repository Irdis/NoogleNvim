local M = {}

M.noogle_path = "noogle";

M.setup = function()
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

    M.buf = vim.api.nvim_get_current_buf()

    local file_path = vim.api.nvim_buf_get_name(M.buf)
    local root_folder = vim.loop.cwd()
    local csproj = M.get_csproj(file_path, root_folder)
    if not csproj then 
        M.log("Unable to locate .csproj")
        return
    end

    local dll = M.get_dll(csproj, configuration)
    if not dll then 
        M.log("Unable to locate .dll")
        return
    end
    local directory = vim.fn.fnamemodify(dll, ":h")

    local cmd = M.build_cmd(directory, options.args)
    M.run_in_buf(cmd)
end

M.run_in_buf = function(cmd)
    print(cmd)
    local output = vim.api.nvim_exec2("!" .. cmd, { output = true }).output
    local lines = vim.split(output, "\n");

    table.remove(lines, 1)
    table.remove(lines, 1)
    table.remove(lines)

    for i, line in ipairs(lines) do
        lines[i] = string.sub(line, 1, -2) 
    end
    local buf = vim.api.nvim_create_buf(false, true) 
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(buf)
end

M.build_cmd = function(location, args)
    local cmd = M.noogle_path

    if args ~= "" then
        cmd = cmd .. " " .. args
    end
    if string.find(location, " ") then
        location = "\"" .. location .. "\"";
    end
    cmd = cmd .. " " .. "-p " .. location
    return cmd
end

M.get_dll = function(csproj, configuration)
    local csproj_folder = vim.fn.fnamemodify(csproj, ":h")
    local csproj_name_noext = vim.fn.fnamemodify(csproj, ":t:r")
    local dll_name = csproj_name_noext .. ".dll"
    local initial_folder = csproj_folder .. "\\bin\\" .. configuration
    local dll_path = M.look_for_dll(dll_name, initial_folder)

    return dll_path
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
