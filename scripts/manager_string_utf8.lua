-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function isContinuationByte(c)
	return ((c >= 128) and (c < 192));
end

function len(s)
	if not s then
		return 0;
	end
	local nByteLen = #s;
	if (nByteLen == 0) or isContinuationByte(s:byte(1)) then
		return 0;
	end

	local nBytePos = 1;
	local nLen = 0;
	while nBytePos <= nByteLen do
		nBytePos = nBytePos + 1;
		while (nBytePos < nByteLen) and isContinuationByte(s:byte(nBytePos)) do
			nBytePos = nBytePos + 1;
		end
		nLen = nLen + 1;
	end

	return nLen;
end

function offset(s, n)
	if not s or (n == 0) then
		return nil;
	end

	if n > 0 then
		local nBytePos = 1;
		local nByteLen = #s;
		while (n > 1) and (nBytePos <= nByteLen) do
			nBytePos = nBytePos + 1;
			while (nBytePos < nByteLen) and isContinuationByte(s:byte(nBytePos)) do
				nBytePos = nBytePos + 1;
			end
			n = n - 1;
		end

		if n == 1 then
			return nBytePos;
		end
	else
		local nBytePos = #s + 1;
		while (n < 0) and (nBytePos > 0) do
			nBytePos = nBytePos - 1;
			while (nBytePos > 0) and isContinuationByte(s:byte(nBytePos)) do
				nBytePos = nBytePos - 1;
			end
			n = n + 1;
		end

		if n == 0 then
			return nBytePos;
		end
	end
	return nil;
end

function getSubstringPositive(s, i, j)
    i = offset(s, i);
    j = offset(s, j + 1);
    if j then
    	j = j - 1;
    end
    return s:sub(i, j);
end
