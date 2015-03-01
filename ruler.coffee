 # The two plots show a "roof" function, and
 # the corresponding transformed
 # distribution. The code, and explanation,
 # folows below ...

# "roof" function
fig1 = figure
    xlabel: "x"
    ylabel: "y=erfinv(x)"
    yaxis: {min:-4, max:4}
    height: 220
    colors: ["green"]
    series:
        shadowSize: 0
        lines: {lineWidth: 1, show:true}
        points: {show: false}


# histogram
fig2 = figure
    xlabel: "y"
    ylabel: "prob(y)"
    height: 220
    colors: ["green", "black"]
    series:
        shadowSize: 0
        lines: {lineWidth: 1, show:true}
        points: {show: false}

 # The roof function is the inverse error
 # function (erfinv). That is, the integral
 # of the Gaussian distribution when we
 # rotate the screen 90 degrees.

 # Actually, we cannot express errinv simply, so
 # we use a polynomial approximation (<a href="http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=4630740">pdf</a>):

erfinv = (u) -> #;
    c = [1.758, -2.257, 0.1661]
    s = (u<=0)-(u>0) # sign
    t = sqrt( -log(0.5*(1+s*u)) )
    (c[0] + c[1]*t + c[2]*t*t)*s

x = linspace -1, 1, 1000 #;
y = erfinv x #;
plot x, y, fig: fig1

 # Now consider applying a uniform
 # distribution to the erfinv roof
 # function.

X = 2*rand([10000])-1 #;
Y = erfinv(X) #;

 # Applying the output to a histogram,
 # we can compare the transformed
 # uniform distribution with and ideal
 # Gaussian distribution.

h = $blab.histo(Y, 200, -4, 4) #;
gauss = (u) -> 1/sqrt(2*pi)*exp(-u*u/2) #;
plot h.bin, [h.prob, gauss(h.bin)], fig:fig2
    
 # NB: the histo function is imported
 # from lib.coffee.                                                                    

