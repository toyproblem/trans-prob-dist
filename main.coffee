a = 0
b = 2*pi
x = linspace a, b, 200 #;
w = x*0 #;
w += 1/2.pow(k)*sin(2.pow(k)*x) for k in [0..20] #;

plot x, w,
    xlabel: "x"
    ylabel: "w(x)"
    height: 160
    series:
        shadowSize: 0
        color: "black"
        lines: lineWidth: 1

