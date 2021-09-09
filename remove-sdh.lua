﻿--
-- SDH subs usually contain descriptions of sounds like sighing or music.
-- this script removes those elements from the subtitles.
-- 

script_name = "Remove SDH elements"
script_description = "Removes SDH elements from subtitles"
script_author = "darell tan"
script_version = "1.2"

require 'gm-utils'

function remove_sdh(subs, sel)
	btn, remove_sel = aegisub.dialog.display({
		{x=0,y=0,class="label", label="Select types of SDH elements to remove:"},

		{x=0,y=2,class="checkbox", value=true, name="desc", label="[sound description]"},
		{x=0,y=3,class="checkbox", value=true, name="desc_dialog", label="- [sound description in dialog]"},
		{x=0,y=4,class="checkbox", value=true, name="music", label="♪ (Music)"},
		{x=0,y=5,class="checkbox", value=false, name="lyrics", label="♪ Lyrics ♪"},

		{x=0,y=6,class="label"},
	}, {"Remove"})
	if btn == false then return end

	local sdh_patt = {
		desc="[%[%(].-[%]%)]",
		music="♪",
		lyrics="♪.+♪",
	}

	-- note that music should be last because it's most general/generic
	local sdh_patt_order = { 'desc', 'lyrics', 'music' }

	-- remove unselected elements from ordered list
	for i = #sdh_patt_order, 1, -1 do
		if not remove_sel[sdh_patt_order[i]] then
			sdh_patt_order[i] = nil
		end
	end

	local i = 1
    while i <= #subs do
		aegisub.progress.set(i / #subs * 100)

		local processed = false
		local line = subs[i]
		if line.class == "dialogue" then
			local t = line.text:gsub('\\N', ' ')	-- remove newlines
			t = strip_formatting(t)					-- remove formatting

			local tt = t
			for _, name in pairs(sdh_patt_order) do
				local patt = sdh_patt[name]

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

			-- if line wasn't removed, we see if dialog SDH elements 
			-- exist and need to be removed
			if not processed and remove_sel["desc_dialog"] then
				local m_st  = 0
				local m_end = 0
				local t = line.text
				repeat
					m_st, m_end = t:find('-%s-' .. sdh_patt['desc'], m_end + 1)
					if m_st ~= nil then
						local eol = next_eol(t, m_end + 1)
						if preceding_newline(t, m_st) > 0 and eol then
							t = t:sub(1, m_st - 1) .. t:sub(eol, #t + 1)
						end
					end
				until m_st == nil 

				if t ~= line.text then
					aegisub.debug.out(5, "SDH elem %s: %s\n", 'desc_dialog', line.text)
					line.text = t
					subs[i] = line
				end
			end
		end

		i = i + 1
	end

	aegisub.progress.set(100)
    aegisub.set_undo_point("remove SDH elements")
end

aegisub.register_macro(script_name, script_description, remove_sdh)

