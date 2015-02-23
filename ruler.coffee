# Measurements from N trials
fig1 = figure
    xlabel: "probabilty"
    ylabel: "inverse erf"
    height: 200
    series:
        color: "green"
        shadowSize: 0
        lines: {lineWidth: 1, show:true}
        points: {show: false}

p = linspace 0.0001, 0.9999, 1000

c0 = 1.758
c1 = -2.257
c2 = 0.1661

erfinv = (p) ->
    l = p<=0.5
    g = p>0.5
    t = sqrt(-log(p*l+(1-p)*g))
    (c0 + c1*t + c2*t*t)*(l-g)
    
plot p, erfinv(p), fig: fig1
