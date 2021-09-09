--
-- subtitle processing utilities
-- abstracted out here to be included by other aegisub scripts
--

-- Checks if pos comes after a newline.
-- It also skips over styling tags "{..}" to contine searching for newlines.
-- If a newline (or start of string) comes "immediately" before pos, return 
-- the index at which the newline was found (1 if it was the string start).
-- Otherwise, a 0 is returned, indicating it was not a newline preceding pos.
function preceding_newline(t, pos)
	if pos == 1 then return pos end

	local intag = false
	while pos > 1 do
		pos = pos - 1
		local c = t:sub(pos, pos)
		--print(pos, c)

		if c == '{' or c == '}' then
			intag2 = c == '}'	-- next intag state
			if intag == intag2 then		-- invalid state transition
				break
			else
				intag = intag2
			end

			if not intag and pos == 1 then return pos end
		elseif not intag then
			if pos > 1 and t:sub(pos-1, pos) == "\\N" then
				return pos
			else
				break
			end
		end
	end
	return 0
end

-- Looks for an EOL following pos, if any.
-- If there is any whitespace at pos, it will be skipped. If no EOL immediately
-- follows, then nil is returned. Otherwise, the position of the newline is
-- returned.
function next_eol(t, pos)
	if pos > #t then return pos end

	-- advance beyond whitespace, if any
	local ws, ws_end = t:find('%s+', pos) 
	if ws ~= nil and ws == pos then pos = ws_end end

	if t:sub(pos, pos+1) == "\\N" then
		return pos + 2
	else
		return nil
	end
end

-- removes formatting like italics or bold
function strip_formatting(t)
	return t:gsub('{\\%w+%d?}', '')
end

