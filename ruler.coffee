 # Approx. inverse error function (<a href="http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=4630740">pdf</a>):

erfinv = (u) -> #;
    c0 = 1.758
    c1 = -2.257
    c2 = 0.1661
    s = (u<=0)-(u>0) # sign
    t = sqrt( -log(0.5*(1+s*u)) )
    (c0 + c1*t + c2*t*t)*s

# Inverse error function plot 

fig1 = figure
    xlabel: "u"
    ylabel: "y=erfinv(u)"
    yaxis: {min:-4, max:4}
    height: 320
    colors: ["green"]
    series:
        shadowSize: 0
        lines: {lineWidth: 1, show:true}
        points: {show: false}

u = linspace -1, 1, 1000 #;
y = erfinv u #;
plot u, y, fig: fig1

 # uniformly distributed input (-1,1)

U = 2*rand([10000])-1 #;

 # transform by erfinv

Y = erfinv(U) #;

 # estimate dist with histogram

histo = (U, N, l, r) -> #;
    # (input, Nbins, min, max) ->
    d = (r-l)/N # bin width
    bin = [0...N]*d+l
    count = bin*0
    I = (floor((u-l)/d) for u in U)
    count[i]+=1 for i in I
    {bin:bin , prob:count/U.length/d}

h = histo(erfinv(U), 200, -4, 4) #;

 # ideal distribution

gauss = (u) -> 1/sqrt(2*pi)*exp(-u*u/2) #;

# approximate Gaussian distrution plot

fig2 = figure
    xlabel: "y"
    ylabel: "prob(y)"
    height: 250
    colors: ["green", "black"]
    series:
        shadowSize: 0
        lines: {lineWidth: 1, show:true}
        points: {show: false}

plot h.bin, [h.prob, gauss(h.bin)], fig:fig2
    
                                                                    

