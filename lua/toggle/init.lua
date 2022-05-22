local ts_utils = require('nvim-treesitter.ts_utils')

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
    local old_word = nil
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

local function toggle_boolean(save)
    local line = vim.api.nvim_get_current_line()
    local language_lists = lists[vim.bo.filetype]
    if language_lists == nil then
        return false
    end

    local column = vim.api.nvim_win_get_cursor(0)[2]
    local last_word_start = get_last_word_start(line, column)
    local start, stop, word, new_word = get_start_stop_new(language_lists, line, last_word_start)
    if start == nil then
        start, stop, word, new_word = get_start_stop_new(language_lists, line, 0)
    end

    if not start then
        return false
    end

    local new_line = string.sub(line, 0, start - 1) .. new_word .. string.sub(line, stop + 1)
    vim.api.nvim_set_current_line(new_line)
    if save then
        vim.api.nvim_input('O# ORIG: ' .. word .. '<esc>j')
    end

    return true
end

local function find_parent_type(node, type)
    while node~= nil and node:type() ~= type do
        node = node:parent()
    end

    return node
end

local function find_next_sibling_type(node, type)
    while node~= nil and node:type() ~= type do
        node = node:next_sibling()
    end

    return node
end

local function find_right(assignment)
    local children = ts_utils.get_named_children(assignment)
    local right = children[2]

    return right
end


local function add_temp(save)
    if toggle_boolean(save) then
        return true
    end

    vim.api.nvim_input('^')
    local node = ts_utils.get_node_at_cursor()
    local assignment = find_parent_type(node, 'assignment')
    if not assignment then
        return nil
    end
    local right = find_right(assignment)
    local row_start, column_start = right:start()
    local row_end, column_end = right:end_()
    local orig = vim.api.nvim_buf_get_text(0, row_start, column_start, row_end, column_end, {})

    local orig_one_line = table.concat(orig, '\\n')
    local down
    if row_end > row_start then
        down = row_end - row_start .. 'j'
    else
        down = ''
    end

    if save then
        vim.api.nvim_input('O# ORIG: ' .. orig_one_line .. '<esc>j')
    end
    vim.api.nvim_input('0' .. column_start ..'l' .. 'v' .. down .. '0' .. column_end .. 'l' .. 'h"_c')

    return true
end

local function remove_temp()
    local node = ts_utils.get_node_at_cursor()
    local expression_node = find_parent_type(node, 'expression_statement')
    if not expression_node then
        expression_node = find_next_sibling_type(node:child(), 'expression_statement')
    end

    if not expression_node then
        return false
    end

    local comment_node = expression_node:prev_sibling()
    if not comment_node then
        comment_node = expression_node:parent():prev_sibling()
    end

    if not comment_node then
        return false
    end

    local start_row_comment, start_column_comment = comment_node:start()
    local end_row_comment, end_column_comment = comment_node:end_()
    local comment = vim.api.nvim_buf_get_text(0, start_row_comment, start_column_comment, end_row_comment, end_column_comment, {})[1]
    local _, _, orig_value_one_line = string.find(comment, '# ORIG: (.*)')

    if not orig_value_one_line then
        return false
    end

    local assignment = find_parent_type(node, 'assignment')
    local right = find_right(assignment)
    local row_start, column_start = right:start()
    local row_end, column_end = right:end_()

    local down
    if row_end > row_start then
        down = row_end - row_start .. 'j'
    else
        down = ''
    end
    vim.api.nvim_input('0' .. column_start ..'l' .. 'v' .. down .. '0' .. column_end .. 'l' .. 'hc' .. string.gsub(orig_value_one_line, '\\n', '\n') .. '<esc>:Black<cr>')

    -- vim.api.nvim_buf_set_text(0, row_start, column_start, row_end, column_end, {lines})
    vim.api.nvim_buf_set_lines(0, start_row_comment, end_row_comment + 1, true, {})

    return true
end

local function Toggle()
    if not remove_temp() then
        add_temp(false)
    end
end

local function ToggleSave()
    if not remove_temp() then
        add_temp(true)
    end
end

return {
    Toggle = Toggle,
    ToggleSave = ToggleSave,
}
