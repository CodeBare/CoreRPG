-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function showFullHeaders(show_flag)
	if descframe then
		descframe.setVisible(show_flag);
	end
	description.setVisible(show_flag);
	if subdescription then
		subdescription.setVisible(show_flag and subdescription.getValue ~= "");
	end
end
