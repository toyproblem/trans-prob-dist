# Measurements from N trials
fig1 = figure
    xlabel: "Trial"
    ylabel: "Measurements"
    height: 200
    series:
        color: "green"
        shadowSize: 0
        lines: {lineWidth: 1, show:true}
        points: {show: true}

L = 7.8 #; True length of pencil
N = 50 #; Number of trials
dither = rand([N]) - 0.5 #; $\in[-0.5,0.5]$
measurements = round(L + dither) #;
# Estimate
estimate = measurements.sum() / N
plot [1..N], measurements, fig: fig1
