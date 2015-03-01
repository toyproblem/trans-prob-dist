$blab.histo = (U, N, l, r) -> #;
    # (input, Nbins, min, max) ->
    d = (r-l)/N # bin width
    bin = [0...N]*d+l
    count = bin*0
    I = (floor((u-l)/d) for u in U)
    count[i]+=1 for i in I
    {bin:bin , prob:count/U.length/d}
