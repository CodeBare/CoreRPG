-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nStep = 1;

function onButtonPrev()
	nStep = math.max(1, math.min(3, nStep - 1));
	updateDisplay();
end
function onButtonNext()
	nStep = math.max(1, math.min(3, nStep + 1));
	updateDisplay();
end
function updateDisplay()
	local bStep2 = (nStep == 2);
	local bStep3 = (nStep == 3);
	local bStep1 = (not bStep2 and not bStep3);
	
	step1.setVisible(bStep1);
	step2.setVisible(bStep2);
	step3.setVisible(bStep3);
	
	button_prev.setVisible(not bStep1);
	button_next.setVisible(not bStep3);
	button_finish.setVisible(bStep3);
end
