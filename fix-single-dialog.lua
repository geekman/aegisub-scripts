--
-- usually a dash is used to indicate multiple parties talking in one sub
-- but oddly, sometimes a single dash is present, even if only a single person
-- is talking. this script fixes that.
-- 

script_name = "Fix single dialog"
script_description = "Remove dash for single party dialog"
script_author = "darell tan"
script_version = "1"

-- Checks if pos comes after a newline.
-- It also skips over styling tags "{..}" o contine searching for newlines.
-- If a newline (or start of string) comes "immediately" before pos, return 
-- the index at which the newline was found, or 1 if it was the string start.
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

function fix_single_dialog(subs, sel)
	local pattern = "%s*[-]%s*"

	local i = 1
	while i <= #subs do
		aegisub.progress.set(i / #subs * 100)

		local line = subs[i]
		if line.class == "dialogue" then
			local t = line.text:gsub("‐", "-")	-- normalize unicode dashes
			local st, en = t:find(pattern)
			if st ~= nil and preceding_newline(t, st) == 1 then
				aegisub.debug.out(5, "dialog[%d]: %s\n", i, t)

				-- try finding another
				local multiparty = false
				local nx_end = en
				while nx_end ~= nil do
					local nx
					nx, nx_end = t:find(pattern, nx_end + 1)
					--if nx ~= nil then aegisub.debug.out(5, "	finding next: %d, %d\n", nx, nx_end) end
					if nx ~= nil and preceding_newline(t, nx) > 0 then
						local eol = next_eol(t, nx_end + 1)
						aegisub.debug.out(5, "	eol at %s\n", eol)
						if eol then
							aegisub.debug.out(5, "	removing empty dialog: %d - %d\n", nx_end, eol)
							t = t:sub(1, nx_end - 1) .. t:sub(eol, #t + 1)
							local rlen = eol - nx_end
							nx_end = eol - 1 - rlen
							aegisub.debug.out(5, "	newstr \"%s\"\n", t)
							aegisub.debug.out(5, "	next cycle from %d\n", nx_end)
						else
							multiparty = true
							break
						end
					end
				end

				t = t:gsub("\\N$", "")	-- remove trailing newline

				if not multiparty then
					-- if there's no other, we remove this one
					t = t:sub(1, st-1) .. t:sub(en+1)
					if t == '' then
						subs.delete(i)
						i = i - 1
					else
						line.text = t
						subs[i] = line
					end
				end
			end
		end

		i = i + 1
	end

	aegisub.progress.set(100)
	aegisub.set_undo_point("fix single dialog")
end

aegisub.register_macro(script_name, script_description, fix_single_dialog)
