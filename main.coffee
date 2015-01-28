#!vanilla

pi = Math.PI

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
    
    constructor: () ->

        x = [-0.5, -0.3, -0.1, 0.1, 0.3, 0.5]
        y = [0.5, -0.25, 0.5, 0.25, -0.5, 0.5]
        
        super "plot"
        chartArea = @obj
        chartArea.attr("width", width + margin.left + margin.right)
        chartArea.attr("height", height + margin.top + margin.bottom)
        chartArea.attr("class","chart")
        chartArea.attr("id", "chartArea")

        @obj.append("g") # x axis
            .attr("class", "axis")
            .attr("transform", "translate(#{margin.left}, #{margin.top+height+10})")
            .call(@xAxis) 

        @obj.append("g") # y axis
            .attr("class", "axis")
            .attr("transform","translate(#{margin.left-10}, #{margin.top})")
            .call(@yAxis) 

        @plot = @obj.append("g") # Plot area
            .attr("id", "plot")
            .attr("transform", "translate(#{margin.left},#{margin.top})")

        @draw(x,y)

    draw: (X, Y)->
        lineData = ({ x: x, y:Y[i] } for x,i in X)
        @plot.append("path")
            .attr("d", @lineFunction(lineData))
            .attr("stroke", "blue")
            .attr("stroke-width", 2)
            .attr("fill", "none");
         
    initAxes: ->
        @xScale = d3.scale.linear() # sim units -> screen units
            .domain([-1, 1])
            .range([0, width])

        @yScale = d3.scale.linear() # sim units -> screen units
            .domain([-1, 1])
            .range([height, 0])

        @xAxis = d3.svg.axis()
            .scale(@xScale)
            .orient("bottom")

        @yAxis = d3.svg.axis()
            .scale(@yScale)
            .orient("left")

        @lineFunction = d3.svg.line()
            .x( (d) => @xScale d.x )
            .y( (d) => @yScale d.y )
            .interpolate("linear");
        
class Histo extends d3Object

    margin = {top: 10, right: 30, bottom: 30, left: 30}
    width = 240 - margin.left - margin.right
    height = 240 - margin.top - margin.bottom

    constructor: (@N=20, @lo=0, @hi=100) ->
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
        #@bar = {domainDir:"x", domainAttr:"width", rangeDir:"y", rangeAttr:"height"}        

        @plotArea.selectAll("rect")
           .data(@data)
           .enter()
           .append("rect")
           .attr(@bar.domainDir, (d) -> d.val )
           .attr(@bar.domainAttr, @del)

    update: (c) ->
        @data[i].count = c[i] for i in [0...@N]
        cmax = d3.max(c)
        @plotArea.selectAll("rect")
            .data(@data)
            .attr(@bar.rangeDir, (d,i) => (1-d.count/cmax)*width)
            .attr(@bar.rangeAttr, (d, i) => d.count/cmax*width)

        
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

#==== Particles ====


class Sunlight
    
    colors: ["#ff0", "#00f"]
    sizes: [2, 3]
    w: Canvas.width
    h: Canvas.height
    O: -> new Vector 0, 0

    constructor: (@pos=@O(), @vel0=@O()) ->
        @init()
        @limit = 0
        @velocity = []  # Set of velocities indexed by state
        @setVelocities()  # Configured in subclass
        @d = 0
        @setState 0

    init: ->
        @xScale = d3.scale.linear() # sim units -> screen units
            .domain([-1, 1])
            .range([0, @w])

        @yScale = d3.scale.linear() # sim units -> screen units
            .domain([-1, 1])
            .range([@h, 0])

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
            console.log "count", count
        
        @d += @vel.mag()
        @pos.add @vel


    setVelocities: ->

        @velocity[0] = new Vector @vel0.x, @vel0.y
        @velocity[1] = (new Vector).polar(10, pi/2)        

        g = (u) -> ((u<0)*1.5 + (u>0)/2)*u + 0.375 
        h = (u) -> Math.floor(20*(u+0.5))

        @limit =  @yScale(g(@xScale.invert(@pos.x)))
        #console.log "???", h(@xScale.invert(@pos.x))
        @bin = Math.floor((@yScale.invert(@limit)+0.875)/2*20)
 
    collision: -> @pos.y > @limit



#==== Emitters ====

class Emitter

    maxPhotons: 4000
    rate: 0
    
    cy: Canvas.height/2  # Canvas center
    cx: Canvas.width/2  # Canvas center
    
    constructor: ->
        @photons = []

    emit: () ->
        unless @photons.length > @maxPhotons
            # emitPhoton defined in subclass
            # console.log "photons", @photons
            @photons.push(@emitPhoton()) for [0...@rate]
        @photons = @photons.filter (photon) => photon.visible()
        for photon in @photons
            photon.move()
            photon.draw()

class Sun extends Emitter

    x: 1
    l: 180
    
    constructor: ->
        #@velocity = new Vector 2, 0
        @velocity = new Vector  0, 2
        super()

    emitPhoton: ->
        #pos = new Vector @x, @cy + @l*(Math.random()-0.5)
        pos = new Vector @cx + @l*(Math.random()-0.5), 1
        new Sunlight(pos, @velocity)


#==== Simulation ====
 
class Simulation

    constructor: ->
        @sun = new Sun
        @sun.rate = 10
        @h = new Histo
        
    start: () ->
        setTimeout (=> @animate 20000), 200
        
    snapshot: () ->
        Canvas.clear()
        @sun.emit()
        @h.update(count)

    animate: () ->
        @timer = setInterval (=> @snapshot()), 50
        
    stop: ->
        clearInterval @timer
        @timer = null


count = (0 for [0..19])
sim = new Simulation
$("#params4b").on "click", =>
    sim.stop()
setTimeout (-> sim.start()), 2000

new Plot
