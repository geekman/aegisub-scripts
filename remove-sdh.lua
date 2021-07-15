--
-- SDH subs usually contain descriptions of sounds like sighing or music.
-- this script removes those elements from the subtitles.
-- 

script_name = "Remove SDH elements"
script_description = "Removes SDH elements from subtitles"
script_author = "darell tan"
script_version = "1.1"


function remove_sdh(subs, sel)
	local sdh_patt = {
		desc="[%[%(].-[%]%)]",
		music="♪",
	}

	local i = 1
    while i <= #subs do
		aegisub.progress.set(i / #subs * 100)

		local processed = false
		local line = subs[i]
		if line.class == "dialogue" then
			local t = line.text:gsub('\\N', ' ')	-- remove newlines
			t = t:gsub('{\\%w+%d?}', '')			-- remove formatting

			local tt = t
			for name, patt in pairs(sdh_patt) do
				tt = tt:gsub(patt, '')
				tt = tt:gsub('^[%s-]+$', '')	-- remove whitespace & dashes
				tt = tt:gsub('^%s+$', '')		-- remove if all whitespace

				if not processed and tt == '' then
					aegisub.debug.out(5, "SDH elem %s: %s\n", name, line.text)
					subs.delete(i)
					processed = true
					i = i - 1
				end
			end
		end

		i = i + 1
	end

	aegisub.progress.set(100)
    aegisub.set_undo_point("remove SDH elements")
end

aegisub.register_macro(script_name, script_description, remove_sdh)

