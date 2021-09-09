--
-- usually a dash is used to indicate multiple parties talking in one sub
-- but oddly, sometimes a single dash is present, even if only a single person
-- is talking. this script fixes that.
-- 

script_name = "Fix single dialog"
script_description = "Remove dash for single party dialog"
script_author = "darell tan"
script_version = "1"

require 'gm-utils'

function fix_single_dialog(subs, sel)
	local pattern = "%s*[-]%s*"

	local i = 1
	while i <= #subs do
		aegisub.progress.set(i / #subs * 100)

		local line = subs[i]
		if line.class == "dialogue" then
			local t = line.text:gsub("‐", "-")	-- normalize unicode dashes

			-- move start styles after newline, which makes it more "logical"
			t = t:gsub('({\\%a1})%s*\\N', '\\N%1')

			local st, en = t:find(pattern)
			if st ~= nil and preceding_newline(t, st) > 0 then
				aegisub.debug.out(5, "dialog[%d]: %s\n", i, t)

				local dialog_count = 0
				local nx_end = st - 1
				while nx_end ~= nil and dialog_count <= 1 do
					local nx
					nx, nx_end = t:find(pattern, nx_end + 1)
					--if nx ~= nil then aegisub.debug.out(5, "	finding next: %d, %d\n", nx, nx_end) end
					if nx ~= nil and preceding_newline(t, nx) > 0 then
						local eol = next_eol(t, nx_end + 1)
						aegisub.debug.out(5, "	eol at %s\n", eol)
						if eol then
							aegisub.debug.out(5, "	removing empty dialog: %d - %d\n", nx, eol)
							t = t:sub(1, nx - 1) .. t:sub(eol, #t + 1)
							local rlen = eol - nx_end
							nx_end = eol - 1 - rlen
							aegisub.debug.out(5, "	newstr \"%s\"\n", t)
							aegisub.debug.out(5, "	next cycle from %d\n", nx_end)
						else
							dialog_count = dialog_count + 1
						end
					end
				end

				t = t:gsub("\\N$", "")	-- remove trailing newline

				if dialog_count <= 1 then
					-- if there's no other, we remove this one
					-- but search again, as it may have been removed or shifted
					st, en = t:find(pattern)
					if st ~= nil and preceding_newline(t, st) == 1 then
						t = t:sub(1, st-1) .. t:sub(en+1)
					end
					if strip_formatting(t) == '' then
						subs.delete(i)
						i = i - 1
					elseif line.text ~= t then
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
