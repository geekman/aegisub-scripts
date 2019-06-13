--
-- usually a dash is used to indicate multiple parties talking in one sub
-- but oddly, sometimes a single dash is present, even if only a single person
-- is talking. this script fixes that.
-- 

script_name = "Fix single dialog"
script_description = "Remove dash for single party dialog"
script_author = "darell tan"
script_version = "1"

function preceding_newline(t, pos)
	return pos == 1 or t:sub(pos-2, pos-1) == "\\N"
end

function fix_single_dialog(subs, sel)
	local pattern = "%s*[-]%s*"

	for i, line in ipairs(subs) do
		aegisub.progress.set(i / #subs * 100)

		if line.class == "dialogue" then
			local st, en = line.text:find(pattern)
			if st ~= nil and st == 1 then
				--aegisub.debug.out(5, "dialog: %s\n", line.text)

				-- try finding another
				local multiparty = false
				local nx_end = en
				while nx_end ~= nil do
					local nx
					nx, nx_end = line.text:find(pattern, nx_end + 1)
					--if nx ~= nil then aegisub.debug.out(5, "	finding next: %d, %d\n", nx, nx_end) end
					if nx ~= nil and preceding_newline(line.text, nx) then
						multiparty = true
						break
					end
				end

				if not multiparty then
					-- if there's no other, we remove this one
					line.text = line.text:sub(en+1)
					subs[i] = line
				end
			end
		end
	end

	aegisub.progress.set(100)
	aegisub.set_undo_point("fix single dialog")
end

aegisub.register_macro(script_name, script_description, fix_single_dialog)
