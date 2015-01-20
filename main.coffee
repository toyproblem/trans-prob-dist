#!vanilla

pi = Math.PI

class d3Object

    constructor: (id) ->
        @element = d3.select "##{id}"
        @element.selectAll("svg").remove()
        @obj = @element.append "svg"
        #@initAxes()
        
    append: (obj) -> @obj.append obj
    
    initAxes: ->

class Histo extends d3Object

    margin = {top: 10, right: 30, bottom: 30, left: 30}
    width = 240 - margin.left - margin.right
    height = 240 - margin.top - margin.bottom

    constructor: (@N=20, @lo=0, @hi=100) ->
        super "histo"
        chartArea = @obj

        @dx = (@hi-@lo)/@N
        @x = (@dx*n for n in [0...@N])
        console.log "???", @x


        @count = (i for i in  [0...@N])
        @data = ({count:i, x:i*@dx} for i in  [0...@N])

        console.log "data", @data
        console.log "count", @count


        @values = d3.range(100).map(d3.random.bates(10))

        @xScale = d3.scale.linear()
            .domain([0, 1])
            .range([0, width])

        #@data = d3.layout.histogram().frequency(false)
        #    .bins(@xScale.ticks(20)) @values

        ##console.log "data", @data

        @yScale = d3.scale.linear()
            .domain([0, 1])
            .range([0, height]);

        chartArea.attr("width", width + margin.left + margin.right)
        chartArea.attr("height", height + margin.top + margin.bottom)
        chartArea.attr("class","chart")
        chartArea.attr("id", "chartArea")

        @plotArea = chartArea.append("g")
            .attr("transform", "translate(#{margin.left},#{margin.top})")
            .attr("id", "plotArea")
            .attr("width", width)
            .attr("height", height)

        @plotArea.selectAll("rect")
           .data(@data)
           .enter()
           .append("rect")
           #.attr("x", (d) -> d.x*width)
           #console.log "x", @x
           #.attr("x", (d,i) => i*@dx )
           .attr("x", (d) -> d.x )
           #.attr("y", (d) -> height*(1-d.y))
           .attr("y", (d,i) => (1-@count[i]/Math.max(@count...))*height)
           #.attr("width", (d) -> d.dx*width)
           #.attr("width", (d,i) => @x[i])
           .attr("width", @dx)
           #.attr("height", (d) -> d.y*height)
           .attr("height", (d, i) => @count[i]/Math.max(@count...)*height)

        @values2 = d3.range(100).map(d3.random.bates(10))
        @data2 = d3.layout.histogram().frequency(false)
            .bins(@xScale.ticks(20)) @values2

    update2: (val) ->
        index=Math.floor(val/(@hi-@lo))
        @count[index] += 1
        
    update: (values) ->
        data = d3.layout.histogram().frequency(false)
            .bins(@xScale.ticks(20)) values
        @plotArea.selectAll("rect")
            .data(data)
            .attr("y", (d) -> height*(1-d.y))
            .attr("height", (d) -> d.y*height)

        
class Canvas

    @width = 480
    @height = 480
    
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


class Sunlight # extends Photon
    
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
        @yscale = d3.scale.linear()
            .domain([@h/2-100, @h/2+100])
            .range([-1, 1])

        @xscale = d3.scale.linear()
            .domain([-pi/2, pi/2])
            .range([@w/2-100, @w/2+100])

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

        rad = 100
        cy = @h/2  # Canvas center
        @velocity[0] = new Vector @vel0.x, @vel0.y
        theta = Math.asin((@pos.y - cy)/rad) 
        #@velocity[1] = (new Vector).polar(@vel0.mag(), pi-2*theta)
        @velocity[1] = (new Vector).polar(10, pi/2)        

        #@limit = @w/2 - Math.sqrt(rad*rad-(@pos.y-cy)*(@pos.y-cy))
        #console.log "??", Math.asin(@yscale(@pos.y))
        @limit =  @xscale(Math.asin(@yscale(@pos.y)))
        @bin = Math.floor((pi/2+Math.asin(@yscale(@pos.y)))/(pi)*20)
        #console.log "bin", @bin
 
    collision: -> @pos.x > @limit



#==== Emitters ====

class Emitter

    maxPhotons: 4000
    rate: 0
    checked: true
    
    cy: Canvas.height/2  # Canvas center
    
    constructor: ->
        @photons = []

    emit: () ->
        unless @photons.length > @maxPhotons
            # emitPhoton defined in subclass
            @photons.push(@emitPhoton()) for [0...@rate]
        @photons = @photons.filter (photon) => photon.visible()
        for photon in @photons
            photon.move()
            if @checked then photon.draw()

class Sun extends Emitter

    x: 1
    l: 200
    
    constructor: ->
        @velocity = new Vector 2, 0
        super()

    emitPhoton: ->
        pos = new Vector @x, @cy + @l*(Math.random()-0.5) 
        new Sunlight(pos, @velocity)


#==== Simulation ====
 
class Simulation

    constructor: ->
        @sun = new Sun
        @sun.rate = 10

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


count = (0 for [0..19])
sim = new Simulation
$("#params4b").on "click", =>
    sim.stop()
setTimeout (-> sim.start()), 2000


new Histo