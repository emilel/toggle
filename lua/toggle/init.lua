local lists = {
    {'True', 'False'},
}

local function find_first(line, column)
    local first_start = nil
    local first_stop = nil
    local new_word = nil
    local old_word = nil
    for _, list in ipairs(lists) do
        for index, word in ipairs(list) do
            local start, stop = string.find(line, word, column)
            if start ~= nil and (first_start == nil or start < first_start) then
                local new_list_index
                if index == #list then
                    new_list_index = 1
                else
                    new_list_index = index + 1
                end

                first_start = start
                first_stop = stop
                old_word = word
                new_word = list[new_list_index]
            end
        end
    end


    return first_start, first_stop, old_word, new_word
end

local function get_last_word_start(line, stop)
    local i = stop + 1
    if string.find(string.sub(line, i, i), '%w') then
        while string.find(string.sub(line, i - 1, i - 1), '%w') do
            i = i - 1
        end
    end

    return i
end

local function get_orig_value(line)
    local _, _, orig_value = string.find(line, '# ORIG: (.*)')

    return orig_value
end

local function set_new(line, start, stop, value)
    local new_line = string.sub(line, 0, start) .. value ..  string.sub(line, stop)

    return new_line
end

local function Toggle(save)
    local start
    local stop
    local old_value
    local new_value
    local new_line

    local line = vim.api.nvim_get_current_line()
    new_value = get_orig_value(line)

    -- if there was an original value on the line
    if new_value then
        _, start = string.find(line, '.+=%s.')
        stop = 9000
    end

    -- if there was not an original value on the line, try to toggle value
    -- after cursor
    if not new_value then
        local column = vim.api.nvim_win_get_cursor(0)[2]
        column = get_last_word_start(line, column)
        start, stop, old_value, new_value = find_first(line, column)
    end

    -- if nothing to toggle after cursor, toggle value before cursor
    if not new_value then
        start, stop, old_value, new_value = find_first(line, 0)
    end

    -- if can toggle value
    if new_value then
        start = start - 1
        stop = stop + 1
        new_line = set_new(line, start - 1, stop + 1, new_value)
        vim.api.nvim_set_current_line(new_line)
    end

    if new_value then
        new_line = set_new(line, start, stop, new_value)
        vim.api.nvim_set_current_line(new_line)
        vim.api.nvim_input('0' .. start .. 'l')
    end

    if save and new_line then
        vim.api.nvim_set_current_line(new_line .. ' # ORIG: ' ..old_value)
    end

    -- if no value to toggle, select old value
    if not new_value then
        _, _, old_value = string.find(line, '.+=%s*(.*)')
        start, stop = string.find(line, '=%s*(.*)')
        if start then
            if save then
                vim.api.nvim_set_current_line(line .. ' # ORIG: ' ..old_value)
            end
            print('0' .. start + 1 ..'l' .. 'v' .. stop - start - 1 .. 'l')
            vim.api.nvim_input('0' .. start + 1 ..'l' .. 'v' .. stop - start - 2 .. 'lc')
        end
    end

    return true
end

return {
    Toggle = Toggle,
}
