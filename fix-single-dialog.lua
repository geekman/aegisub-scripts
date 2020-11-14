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

	local i = 1
	while i <= #subs do
		aegisub.progress.set(i / #subs * 100)

		local line = subs[i]
		if line.class == "dialogue" then
			local t = line.text:gsub("‐", "-")	-- normalize unicode dashes
			local st, en = t:find(pattern)
			if st ~= nil and st == 1 then
				--aegisub.debug.out(5, "dialog: %s\n", t)

				-- try finding another
				local multiparty = false
				local nx_end = en
				while nx_end ~= nil do
					local nx
					nx, nx_end = t:find(pattern, nx_end + 1)
					--if nx ~= nil then aegisub.debug.out(5, "	finding next: %d, %d\n", nx, nx_end) end
					if nx ~= nil and preceding_newline(t, nx) then
						multiparty = true
						break
					end
				end

				if not multiparty then
					-- if there's no other, we remove this one
					t = t:sub(en+1)
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
