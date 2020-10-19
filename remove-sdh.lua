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
		desc="^%s*[%[%(].+[%]%)]%s*$",
		music="^%s*[♪ ]+%s*$",
	}

	local i = 1
    while i <= #subs do
		aegisub.progress.set(i / #subs * 100)

		local processed = false
		local line = subs[i]
		if line.class == "dialogue" then
			for name, patt in pairs(sdh_patt) do
				local t = line.text:gsub('\\N', ' ')	-- remove newlines
				t = line.text:gsub('{\\%w%d?}', '')		-- remove formatting
				local st, en = t:find(patt)
				if not processed and st ~= nil then
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

