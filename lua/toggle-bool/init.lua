local lists = {
    python = {
        {'True', 'False'},
    },
    javascript = {
        {'true', 'false'}
    }
}

local function get_start_stop_new(language_lists, line, column)
    local first_start = nil
    local first_stop = nil
    local new_word = nil
    for _, list in ipairs(language_lists) do
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
                new_word = list[new_list_index]
            end
        end
    end

    return first_start, first_stop, new_word
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

local function replace(line, new_word, start, stop)
    return string.sub(line, 0, start - 1) .. new_word .. string.sub(line, stop + 1)
end

local function get_new_line(line)
    local language_lists = lists[vim.bo.filetype]
    if language_lists == nil then
        return nil
    end

    local column = vim.api.nvim_win_get_cursor(0)[2]
    local last_word_start = get_last_word_start(line, column)
    local start, stop, new_word = get_start_stop_new(language_lists, line, last_word_start)
    if start == nil then
        start, stop, new_word = get_start_stop_new(language_lists, line, 0)
    end

    if not start then
        return nil
    end

    new_line = replace(line, new_word, start, stop)

    return new_line
end

local function Toggle()
    local line = vim.api.nvim_get_current_line()
    local new_line = get_new_line(line)

    if new_line ~= nil then
        vim.api.nvim_set_current_line(new_line)
    end
end

return {
    Toggle = Toggle
}
