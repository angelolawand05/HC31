function txt = p_to_label(p)
    if isnan(p)
        txt = 'p = NaN';
    elseif p < 0.001
        txt = '*** p < 0.001';
    elseif p < 0.01
        txt = '** p < 0.01';
    elseif p < 0.05
        txt = '* p < 0.05';
    else
        txt = sprintf('n.s. p = %.3f', p);
    end
end
