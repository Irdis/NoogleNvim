local M = {}

local VERSION_SIZE = 3

local function max_by(list, cmp)
    local best = list[1]
    for i = 2, #list do
        if cmp(list[i], best) > 0 then
            best = list[i]
        end
    end

    return best
end

function M.get_latest(root_path)
    local folders = {}

    for name, type in vim.fs.dir(root_path) do
        local b, _, v1, v2, v3 = string.find(name, "(%d+).(%d+).(%d+)")
        if type == "directory" and b ~= nil then
            table.insert(folders, {
                name = name,
                version = {
                    tonumber(v1),
                    tonumber(v2),
                    tonumber(v3)
                }
            })
        end
    end
    if #folders == 0 then
        return nil
    end
    local latest = max_by(folders, function (a, b)
        for i = 1, VERSION_SIZE do
            if a.version[i] > b.version[i] then
                return 1
            end
            if a.version[i] < b.version[i] then
                return -1
            end
        end
        return 0
    end)

    return root_path .. latest.name .. "/"
end

return M
