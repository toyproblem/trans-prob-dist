# Measurements from N trials

fig3 = figure
    xlabel: "probabilty"
    ylabel: "inverse erf"
    yaxis: {min:-4, max:4}
    height: 200
    colors: ["green", "red"]
    series:
        shadowSize: 0
        lines: {lineWidth: 1, show:true}
        points: {show: false}

p = linspace -0.9999, 0.9999, 1000 #;

c0 = 1.758 #;
c1 = -2.257 #;
c2 = 0.1661 #;

sign = (u) -> (u<=0)-(u>0)

erfinv = (u) ->
    s = sign(u)
    t = sqrt(-log(0.5*(1+s*u)))
    (c0 + c1*t + c2*t*t)*s

erfinv2 = (x) ->
    a = 8*(pi-3)/3/pi/(4-pi)
    b = log(1-x*x)
    -sign(x)*sqrt(sqrt((2/pi/a+b/2).pow(2)-b/a)-(2/pi/a+b/2))

plot p, [erfinv(p), erfinv2(p)], fig: fig3
