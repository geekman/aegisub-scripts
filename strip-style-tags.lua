-- modified from strip-tags.lua by Thomas Goyne <plorkyeran@aegisub.org>
--
-- Permission to use, copy, modify, and distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

local tr = aegisub.gettext

script_name = tr"Strip font,color tags"
script_description = tr"Remove font,color tags from selected lines"
script_author = "darell tan"
script_version = "1"

function remove_styles(tag)
	local styles = ""
	for s in string.gmatch(tag, "\\([^\\}]+)") do
		local c = s:sub(1, 1)
		if c ~= "f" and c ~= "c" then
			styles = styles .. "\\" .. s
		end
	end

	if styles:len() > 0 then styles = "{" .. styles .. "}" end
	return styles
end

function replace_with_single(text, pattern) 
	local plen = string.len(pattern)
	local i = 1
	while i <= string.len(text) do
		local st, en = string.find(text, pattern, i, true)
		if st == nil then break end
		en = en + 1 -- shift end to be AFTER pattern

		for j = st + plen, string.len(text) - plen + 1, plen do
			if string.sub(text, j, j + plen - 1) == pattern then
				en = j + plen
			else
				break
			end
		end

		text = string.sub(text, 1, st + plen - 1) .. string.sub(text, en)
		i = en
	end

	return text
end

function strip_style_tags(subs, sel)
    for _, i in ipairs(sel) do
        local line = subs[i]
        line.text = line.text:gsub("{[^}]+}", remove_styles)

		-- move start tags before NL
        line.text = line.text:gsub("({[^}]*\\[a-z]+1[^}]*})\\N", "\\N%1")

        line.text = line.text:gsub("^%s*(.-)%s*$", "%1") -- trim whitespaces
        line.text = replace_with_single(line.text, "\\N")
        line.text = line.text:gsub("\\N+$", "") -- trim trailing newlines
        line.text = line.text:gsub("^\\N+", "") -- trim leading newlines
        subs[i] = line
    end
    aegisub.set_undo_point(tr"strip font,color tags")
end

aegisub.register_macro(script_name, script_description, strip_style_tags)

