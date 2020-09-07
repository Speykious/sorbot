u = "\x1b[4m"
b = "\x1b[1m"
c = "\x1b[0m"
red = "\x1b[38;2;255;100;50m"
grn = "\x1b[38;2;50;255;150m"
blocks = [" ", "▏","▎","▍","▌","▋","▊","▉","█"]

class LoadingBar
  constructor: (@max, brackets, @cwidth, color) ->
    @i = 0
    @bo = brackets[0]
    @bc = brackets[1]
    
    rgb = {
      r: color >> 16
      g: (color >> 8) & 0xff
      b: color & 0xff
    }
    
    @ano = "\x1b[38;2;#{rgb.r};#{rgb.g};#{rgb.b}m"
    @anc = "\x1b[39m"

    @interval = undefined
    @msg = "loading..."
  
  inc: (n = 1) -> @i += n
  step: (msg, n = 1) ->
    @msg = msg
    @inc n
  
  progress: ->
    p = Math.min 1, @i / @max
    full = Math.floor @cwidth * p
    tiny = Math.floor (@cwidth * p - full) * 8
    return @bo + @ano + (blocks[8].repeat full)
      + (if tiny is 0 then "" else blocks[tiny])
      + (if p >= 1 then "" else blocks[0].repeat @cwidth - full - (if tiny then 1 else 0))
      + @anc + @bc + " " + (if p >= 1 then b + grn else b) + (p * 100).toFixed(2).padStart 3
      + "%" + c + " - #{msg}"
  
  clearInterval: -> if @interval then clearInterval @interval
  startInterval: ->
    @interval = setInterval (->
      process.stdout.write "\x1b[2K\r#{@progress()}"
      if @i >= @max then @clearInterval()
    ), 50

loading = new LoadingBar 18, "║║", 25, 0x34d9ff

module.exports = loading
