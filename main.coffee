#!vanilla

pi = Math.PI

class Canvas

    @width = 360
    @height = 360
    
    @canvas = document.querySelector('canvas')
    @canvas.width = @width
    @canvas.height = @height
    @ctx = @canvas.getContext('2d')
    
    @clear: -> @ctx.clearRect(0, 0, @width, @height)
    
    @square: (pos, size, color) ->
        @ctx.fillStyle = color
        @ctx.fillRect(pos.x, pos.y, size, size)


class Trans

    @w = Canvas.width
    @h = Canvas.height
    @ax = [-1, 1, -1, 1]
    
    @x2X = d3.scale.linear() # to pixels 
        .domain(@ax[0..1])
        .range([0, @w])

    @X2x = @x2X.invert

    @y2Y = d3.scale.linear()
        .domain(@ax[2..3])
        .range([@h, 0])

    @Y2y = @y2Y.invert
    
    @fn: (x, xm, ym) ->
        n = -0.5+(x+0.5)*(2*ym+1)/(2*xm+1)
        p = ym+(x-xm)*(1-2*ym)/(1-2*xm)
        n*(x<xm) + p*(x>=xm)
    
class Vector

    z = -> new Vector

    constructor: (@x=0, @y=0) ->
        
    add: (v=z()) ->
        @x += v.x
        @y += v.y
        this
    
    mag: () -> Math.sqrt(@x*@x + @y*@y)
        
    ang: () -> Math.atan2(@y, @x)
        
    polar: (m, a) ->
        @x = m*Math.cos(a)
        @y = m*Math.sin(a)
        this


class d3Object

    constructor: (id) ->
        @element = d3.select "##{id}"
        @element.selectAll("svg").remove()
        @obj = @element.append "svg"
        @initAxes()
        
    append: (obj) -> @obj.append obj
    
    initAxes: ->

class Plot extends d3Object

    margin = {top: 60, right: 60, bottom: 60, left: 60}
    width = 480 - margin.left - margin.right
    height = 480 - margin.top - margin.bottom
    
    constructor: (@xm=0, @ym=0) ->

        super "plot"
        chartArea = @obj
        chartArea.attr("width", width + margin.left + margin.right)
        chartArea.attr("height", height + margin.top + margin.bottom)
        chartArea.attr("class","chart")
        chartArea.attr("id", "chartArea")

        @obj.append("g") # x axis
            .attr("class", "axis")
                .attr("transform", "translate(#{margin.left}, #{margin.top-10})")
            .call(@xAxis) 

        @obj.append("g") # y axis
            .attr("class", "axis")
            .attr("transform","translate(#{margin.left+width+10}, #{margin.top})")
            .call(@yAxis) 

        @plot = @obj.append("g") # Plot area
            .attr("id", "plot")
            .attr("transform", "translate(#{margin.left},#{margin.top})")

        Xm = Trans.x2X(@xm)
        Ym = Trans.y2Y(@ym)

        @marker0 = @marker('black')
        @marker0.attr("cx", Xm)
        @marker0.attr("cy", Ym)

        @l1 = @roofLine(-0.5, -0.5)
        @l1.attr("x2", Xm)
        @l1.attr("y2", Ym)

        @l2 = @roofLine(0.5, 0.5)
        @l2.attr("x2", Xm)
        @l2.attr("y2", Ym)

    roofFn: (x) ->
        xm = Trans.X2x(@marker0.attr('cx'))
        ym = Trans.Y2y(@marker0.attr('cy'))
        #(x<0)*(-0.5+(x+0.5)*(2*ym+1)/(2*xm+1)) + (x>=0)*(ym+(x-xm)*(1-2*ym)/(1-2*xm))
        Trans.fn(x, xm, ym)

    roofLine: (xFixed, yFixed) ->
        @plot.append("line")
            .attr("x1", @xScale xFixed)
            .attr("y1", @yScale yFixed)
            .style("stroke", 'black')
            .style("stroke-width","1")

    marker: (color) ->
        m = @plot.append("circle")
            .attr("r",10)
            .style("fill", color)
            .style("stroke", color)
            .style("stroke-width","1")
            .call(
                d3.behavior
                .drag()
                .origin(=>
                    x:m.attr("cx")
                    y:m.attr("cy")
                )
                .on("drag", => @dragMarker(m, d3.event.x, d3.event.y)) #, guide))
            )

    dragMarker: (marker, u, v) ->
        @xm = Trans.X2x u
        @ym = Trans.Y2y v
        marker.attr("cx", u)
        marker.attr("cy", v)
        @l1.attr('x2', u).attr('y2', v)
        @l2.attr('x2', u).attr('y2', v)

    pwl: (X, Y)-> # piece-wise linear
        lineData = ({ x: x, y:Y[i] } for x,i in X)
        @plot.append("path")
            .attr("d", @lineFunction(lineData))
            .attr("stroke", "blue")
            .attr("stroke-width", 2)
            .attr("fill", "none");

    circ: (m)->
        @plot.insert('circle')
            .attr('cx', m[0])
            .attr('cy', m[1])
            .attr('r', 1e-6)
            .style('stroke', d3.hsl(i = (i + 1) % 360, 1, .5))
            .style('stroke-opacity', 1)
            .transition()
            .duration(2000)
            .ease(Math.sqrt)
            .attr('r', 100)
            .style('stroke-opacity', 1e-6)
            .remove()

    hline: (m)->
        @plot.insert('line')
            .attr('x1', m[0])
            .attr('y1', m[1])
            .attr('x2', width)
            .attr('y2', m[1])
            .style('stroke', d3.hsl(i = (i + 1) % 360, 1, .5))
            .style('stroke-opacity', 1)
            .transition()
            .duration(2000)
            .ease(Math.sqrt)
            .attr('x1', width)
            .style('stroke-opacity', 1e-6)
            .remove()

    vline: (m)->
        @plot.insert('line')
            .attr('x1', m[0])
            .attr('y1', m[1])
            .attr('x2', m[0])
            .attr('y2', height)
            .style('stroke', d3.hsl(i = (i + 1) % 360, 1, .5))
            .style('stroke-opacity', 1)
            .transition()
            .duration(2000)
            .ease(Math.sqrt)
            .attr('y1', height)
            .style('stroke-opacity', 1e-6)
            .remove()
        
    initAxes: ->
        @xScale = d3.scale.linear() # sim units -> screen units
            .domain([-1, 1])
            .range([0, width])

        @yScale = d3.scale.linear() # sim units -> screen units
            .domain([-1, 1])
            .range([height, 0])

        @xAxis = d3.svg.axis()
            .scale(@xScale)
            .orient("top")

        @yAxis = d3.svg.axis()
            .scale(@yScale)
            .orient("right")

        @lineFunction = d3.svg.line()
            .x( (d) => @xScale d.x )
            .y( (d) => @yScale d.y )
            .interpolate("linear");

    radialLine: (color) ->
        @plot.append('line')
            .attr("x1", @xScale 0)
            .attr("y1", @yScale 0)
            .style("stroke", color)
            .style("stroke-width","1")
        
    moveMarker: (marker, u, v) ->
        marker.attr("cx", u)
        marker.attr("cy", v)

        
class Histo extends d3Object

    margin = {top: 10, right: 30, bottom: 30, left: 30}
    width = 240 - margin.left - margin.right
    height = 240 - margin.top - margin.bottom

    constructor: (@N=20, @lo=0, @hi=360) ->
        super "histo"
        chartArea = @obj
        chartArea.attr("width", width + margin.left + margin.right)
        chartArea.attr("height", height + margin.top + margin.bottom)
        chartArea.attr("class","chart")
        chartArea.attr("id", "chartArea")

        @del = (@hi-@lo)/@N
        @data = ({count:1, val:i*@del} for i in  [0...@N])

        @plotArea = chartArea.append("g")
            .attr("transform", "translate(#{margin.left},#{margin.top})")
            .attr("id", "plotArea")
            .attr("width", width)
            .attr("height", height)

        @bar = {domainDir:"y", domainAttr:"height", rangeDir:"x", rangeAttr:"width"}

        @plotArea.selectAll("rect")
           .data(@data)
           .enter()
           .append("rect")
           .attr(@bar.domainDir, (d) -> height-d.val )
           .attr(@bar.domainAttr, @del)

    update: (c) ->
        @data[i].count = c[i] for i in [0...@N]
        cmax = d3.max(c)
        @plotArea.selectAll("rect")
            .data(@data)
            .attr(@bar.rangeDir, (d,i) => (1-d.count/cmax)*width)
            .attr(@bar.rangeAttr, (d, i) => d.count/cmax*width)


class Sunlight
    
    colors: ["#ff0", "#000"]
    sizes: [2, 6]
    w: Canvas.width
    h: Canvas.height
    O: -> new Vector 0, 0

    constructor: (@pos=@O()) ->

        # sim units -> screen units
        @xScale = d3.scale.linear()
            .domain([-1, 1])
            .range([0, @w])
        @yScale = d3.scale.linear()
            .domain([-1, 1])
            .range([@h, 0])

        # dynamics
        @d = 0
        @velocity = []
        @velocity[0] = new Vector 0, 2
        @velocity[1] = @O()
        @setCollision()
        @setState 0

        #@colPos = []
        
    setState: (@state) ->
        return if @state<0
        @vel = @velocity[@state]
        @color = @colors[@state]
        @size = @sizes[@state]

    visible: ->
        (0 < @pos.x < @w) and (0 < @pos.y < @h) and @vel.mag() > 0
        
    draw: ->
        Canvas.square @pos, @size, @color

    move: ->
        if @collision() and @state is 0
            @setState(1)
            count[@bin] += 1
            colPos.push(@pos)

        @d += @vel.mag()
        @pos.add @vel

    setCollision: () ->
        y = Trans.fn(@xScale.invert(@pos.x), plot.xm, plot.ym)
        @limit =  @yScale(y)
        @bin = Math.floor((y+0.5)*20)  
 
    collision: -> @pos.y > @limit


class Sun

    l: 180
    maxPhotons: 4000
    rate: 2
    cx: Canvas.width/2
    
    constructor: () ->
        @photons = []

    emit: () ->
        unless @photons.length > @maxPhotons
            @photons.push(@emitPhoton()) for [0...@rate]
        @photons = @photons.filter (photon) => photon.visible()
        for photon in @photons
            photon.setCollision()
            photon.move()
            photon.draw()

    emitPhoton: ->
        pos = new Vector @cx + @l*(Math.random()-0.5), 1
        new Sunlight(pos)

class Simulation

    constructor: ->

        xm = 0
        ym = 0.275

        #@p = new Plot(xm, ym)
        @sun = new Sun
        #@h = new Histo
        
    start: () ->
        setTimeout (=> @animate 20000), 200
        
    snapshot: () ->
        Canvas.clear()
        @sun.emit()
        #@h.update(count)

        #@p.hline([colPos[0].x,colPos[0].y])
        #@p.vline([colPos[0].x,colPos[0].y])

        colPos.pop() for c in colPos

    animate: () ->
        @timer = setInterval (=> @snapshot()), 50

    stop: ->
        clearInterval @timer
        @timer = null


count = (0 for [0..19])
colPos = []

plot = new Plot

sim = new Simulation
$("#params4b").on "click", =>
    sim.stop()
setTimeout (-> sim.start()), 2000

