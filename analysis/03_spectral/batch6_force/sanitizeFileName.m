function out = sanitizeFileName(strIn)
out = regexprep(char(strIn), '[^A-Za-z0-9_\-]', '_');
end
