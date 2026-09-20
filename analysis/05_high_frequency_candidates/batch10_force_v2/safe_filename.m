function fname = safe_filename(fname)
    fname = regexprep(char(fname), '[^\w\.\-]', '_');
end
