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
    
    constructor: (@xm=0, @ym=0.275) ->
        super "plot"

        chartArea = @obj
        chartArea.attr("width", width + margin.left + margin.right)
        chartArea.attr("height", height + margin.top + margin.bottom)

        chartArea.append("g")
            .attr("class", "axis")
            .attr("transform", "translate(#{margin.left}, #{margin.top})")
            .call(@xAxis) 

        chartArea.append("g")
            .attr("class", "axis")
            .attr("transform","translate(#{margin.left+width}, #{margin.top})")
            .call(@yAxis) 

        @plotArea = chartArea.append("g")
            .attr("id", "plot")
            .attr("transform", "translate(#{margin.left},#{margin.top})")

        Xm = Trans.x2X(@xm)
        Ym = Trans.y2Y(@ym)

        @marker()
            .attr("cx", Xm)
            .attr("cy", Ym)

        @line1 = @roofLine(-0.5, -0.5)
            .attr("x2", Xm)
            .attr("y2", Ym)

        @line2 = @roofLine(0.5, 0.5)
            .attr("x2", Xm)
            .attr("y2", Ym)

    roofLine: (xFixed, yFixed) ->
        @plotArea.append("line")
            .attr("x1", Trans.x2X xFixed)
            .attr("y1", Trans.y2Y yFixed)
            .style("stroke", 'black')
            .style("stroke-width","1")

    marker: () ->
        m = @plotArea.append('circle')
            .attr('r',10)
            .style('fill', 'black')
            .style('stroke', 'black')
            .style('stroke-width','1')
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
        @line1.attr('x2', u).attr('y2', v)
        @line2.attr('x2', u).attr('y2', v)

    hline: (m)->
        @plotArea.insert('line')
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
        @plotArea.insert('line')
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
        @xAxis = d3.svg.axis()
            .scale(Trans.x2X)
            .orient("top")

        @yAxis = d3.svg.axis()
            .scale(Trans.y2Y)
            .orient("right")

class Histo extends d3Object

    margin = {top: 10, right: 30, bottom: 30, left: 30}
    width = 240 - margin.left - margin.right
    height = 240 - margin.top - margin.bottom

    constructor: (@N=20, @lo=0, @hi=360) ->
        super "histo"

        chartArea = @obj
        chartArea.attr("width", width + margin.left + margin.right)
        chartArea.attr("height", height + margin.top + margin.bottom)

        @plotArea = chartArea.append("g")
            .attr("transform", "translate(#{margin.left},#{margin.top})")
            .attr("width", width)
            .attr("height", height)

        @del = (@hi-@lo)/@N
        @data = ({count:1, val:i*@del} for i in  [0...@N])

        @bar = {domainDir:"y", domainAttr:"height", rangeDir:"x", rangeAttr:"width"}

        @plotArea.selectAll("rect")
           .data(@data)
           .enter()
           .append("rect")
           .attr(@bar.domainDir, (d) -> height-d.val )
           .attr(@bar.domainAttr, @del)

    update: () ->
        cmax = d3.max(@data[i].count for i in [0...@N])
        @plotArea.selectAll("rect")
            .data(@data)
            .attr(@bar.rangeDir, (d,i) => (1-d.count/cmax)*width)
            .attr(@bar.rangeAttr, (d, i) => d.count/cmax*width)

class Sunlight
    
    w: Canvas.width
    h: Canvas.height

    constructor: (@pos) ->
        @setCollision()
        
    draw: ->
        Canvas.square @pos, 2, '#000'

    move: ->
        @pos.add {x:0, y:2}
        if @collision() 
            histo.data[@bin].count += 1
            histo.update()
            plot.hline([@pos.x,@pos.y])
            plot.vline([@pos.x,@pos.y])
            
    setCollision: () ->
        x = Trans.X2x @pos.x
        y = Trans.fn x, plot.xm, plot.ym
        @limit =  Trans.y2Y y
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

        for photon in @photons
            photon.setCollision()
            photon.move()
            photon.draw()

        @photons = @photons.filter (photon) => not photon.collision() 

    emitPhoton: ->
        pos = new Vector @cx + @l*(Math.random()-0.5), 1
        new Sunlight(pos)

class Simulation

    constructor: ->
        @sun = new Sun
        #@h = new Histo
        
    start: () ->
        setTimeout (=> @animate 20000), 200
        
    snapshot: () ->
        Canvas.clear()
        @sun.emit()

    animate: () ->
        @timer = setInterval (=> @snapshot()), 50

    stop: ->
        clearInterval @timer
        @timer = null

plot = new Plot
histo = new Histo

sim = new Simulation
$("#params4b").on "click", =>
    sim.stop()
setTimeout (-> sim.start()), 2000
