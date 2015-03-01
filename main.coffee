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
    
    @x2X = d3.scale.linear() # to pixels 
        .domain([-1, 1])
        .range([0.25*@w, 0.75*@w])

    @X2x = @x2X.invert

    @y2Y = d3.scale.linear()
        .domain([-1, 1])
        .range([0.75*@h, 0.25*@h])

    @Y2y = @y2Y.invert
    
    @fn: (x, xm, ym) ->
        n = -1+(x+1)*(ym+1)/(xm+1)
        p = ym+(x-xm)*(1-ym)/(1-xm)
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

    margin = {top: 0, right: 60, bottom: 60, left: 60}
    width = 480 - margin.left - margin.right
    height = 480 - margin.top - margin.bottom
    
    constructor: (@xm=0, @ym=0.8) ->
        super "plot"

        chartArea = @obj
        chartArea.attr("width", width + margin.left + margin.right)
        chartArea.attr("height", height + margin.top + margin.bottom)

        chartArea.append("g")
            .attr("class", "axis")
            .attr("transform", "translate(#{margin.left}, #{margin.top+height-110})")
                .call(@xAxis) 

        chartArea.append("g")
            .attr("class", "axis")
            .attr("transform","translate(#{margin.left+50}, #{margin.top})")
            .call(@yAxis) 

        @plotArea = chartArea.append("g")
            .attr("id", "plot")
            .attr("transform", "translate(#{margin.left},#{margin.top})")

        Xm = Trans.x2X(@xm)
        Ym = Trans.y2Y(@ym)

        @marker()
            .attr("cx", Xm)
            .attr("cy", Ym)

        @line1 = @roofLine(-1, -1)
            .attr("x2", Xm)
            .attr("y2", Ym)

        @line2 = @roofLine(1, 1)
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
                .on("drag", => @dragMarker(m, d3.mouse(@plotArea.node())))
                #.on("drag", => @dragMarker(m, d3.event.x, d3.event.y))
            )

    dragMarker: (marker, pos) ->

        u = pos[0]
        v = pos[1]
        U = Trans.X2x u
        V = Trans.Y2y v
        return if  ((Math.abs(U)>0.49) or (Math.abs(V)>0.49))
        @xm = Trans.X2x u
        @ym = Trans.Y2y v
        marker.attr("cx", u)
        marker.attr("cy", v)
        @line1.attr('x2', u).attr('y2', v)
        @line2.attr('x2', u).attr('y2', v)
        histo.data = ({count:0} for i in  [0...20])

    hline: (m)->
        @plotArea.insert('line')
            .attr('x1', m[0])
            .attr('y1', m[1])
            .attr('x2', width-40)
            .attr('y2', m[1])
            .style('stroke', d3.hsl(0, 0, .8))
            .style('stroke-opacity', 1)
            .transition()
            .duration(2000)
            .ease(Math.sqrt)
            .attr('x1', width)
            .style('stroke-opacity', 1e-6)
            .remove()
        
    initAxes: ->
        @xAxis = d3.svg.axis()
            .scale(Trans.x2X)
            .orient("bottom")
            .tickValues([-1, 0, 1])
            .outerTickSize([0])

        @yAxis = d3.svg.axis()
            .scale(Trans.y2Y)
            .orient("left")
            .tickValues([-1, 0, 1])
            .outerTickSize([0])

class Histo extends d3Object

    margin = {top: 0, right: 0, bottom: 0, left: 0}
    width = 90 - margin.left - margin.right
    height = 180 - margin.top - margin.bottom

    constructor: (@N=20, @lo=0, @hi=180) ->
        super "histo"

        chartArea = @obj
        chartArea.attr("width", width + margin.left + margin.right)
        chartArea.attr("height", height + margin.top + margin.bottom)
        chartArea.attr('class', 'histo')
        

        @plotArea = chartArea.append("g")
            .attr("transform", "translate(#{margin.left},#{margin.top})")
            .attr("width", width)
            .attr("height", height)

        @del = (@hi-@lo)/@N
        @data = ({count:0} for i in  [0...@N])

        @plotArea.selectAll("rect")
           .data(@data)
           .enter()
           .append("rect")
           .attr('y', (d,i) => height-@del*(i+1))
           .attr('height', @del)

    update: () ->
        cmax = d3.max(@data[i].count for i in [0...@N])
        @plotArea.selectAll("rect")
            .data(@data)
            #.transition()
            #.duration(400)
            #.ease('linear')
            .attr('width', (d) => d.count/cmax*width)

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
            
    setCollision: () ->
        x = Trans.X2x @pos.x
        y = Trans.fn x, plot.xm, plot.ym
        @limit =  Trans.y2Y y
        @bin = Math.floor((y+1)*20/2)  
 
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
        #@sun = new Sun
        
    start: () ->
        setTimeout (=> @animate 20000), 200
        
    snapshot: () ->
        Canvas.clear()
        sun.emit()

    animate: () ->
        @timer = setInterval (=> @snapshot()), 50

    stop: ->
        clearInterval @timer
        @timer = null


plot = new Plot
histo = new Histo
sun = new Sun
sim = new Simulation
$("#params4b").on "click", =>
    sim.stop()
setTimeout (-> sim.start()), 2000
