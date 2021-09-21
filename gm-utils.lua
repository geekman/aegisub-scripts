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

	-- skip whitespace or style tags
	local pos2 = skip_tag(t, pos - 1, -1)
	if pos2 < pos then pos = pos2 end

	if pos == 0 then
		return 1
	elseif pos > 1 and t:sub(pos-1, pos) == "\\N" then
		return pos
	end

	return 0
end

-- Looks for an EOL following pos, if any.
-- If there is any whitespace at pos, it will be skipped. If no EOL immediately
-- follows, then nil is returned. Otherwise, the position of the newline is
-- returned.
function next_eol(t, pos)
	if pos > #t then return pos end

	repeat
		-- advance beyond whitespace, if any
		local ws, ws_end = t:find('%s+', pos) 
		if ws ~= nil and ws == pos then pos = ws_end end

		-- skip past tags, if any
		pos2 = skip_tag(t, pos, 1)
		if pos2 == pos then break end
		pos = pos2
	until pos > #t

	if pos > #t then
		return pos
	elseif t:sub(pos, pos+1) == "\\N" then
		return pos + 2
	else
		return nil
	end
end

-- Advance past style tags (and whitespace).
-- On entry, pos must point to a tag or whitespace to continue search.
-- dir specifies the direction, either +1 or -1
-- After skipping, returned pos may be 0 or beyond #t
function skip_tag(t, pos, dir)
	local tagStartChar = dir < 0 and '}' or '{'

	local tagChar = ''
	while pos >= 1 and pos <= #t do
		local c = t:sub(pos, pos)
		if c == '{' or c == '}' then
			if tagChar == '' then		-- check for valid start
				if c ~= tagStartChar then break end
				tagChar = c
			elseif c ~= tagChar then	-- as long as start was valid, this check should suffice for end
				if c ~= tagStartChar then
					tagChar = '' -- mark not-in-tag
				else
					tagChar = c
				end
			else
				-- invalid tag transition
				break
			end
		elseif c == ' ' then
			-- skip whitespace
		elseif tagChar == '' then
			-- unknown char, and not in tag
			break
		end

		pos = pos + dir
	end

	return pos
end

-- removes formatting like italics or bold
function strip_formatting(t)
	return t:gsub('{\\%w+%d?}', '')
end

-- Given a (styled) string, check that the style tags are self-contained
-- i.e. they cancel out and don't leave any side-effects.
function check_styles_neutral(t)
	local styles = {}
	for tag, val in t:gmatch('{\\(%a+)(%d?)}') do
		if val == '' then val = '0' end

		-- keep state in styles
		local l = styles[tag] or {}
		local lastval = l[#l]
		if #l > 0 and lastval ~= val then
			table.remove(l)
		else
			table.insert(l, val)
		end
		styles[tag] = l
	end

	for tag, val in pairs(styles) do
		if #val > 0 then return false end
	end

	return true
end

