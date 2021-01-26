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
    @displaying = no
    @msg = "loading..."
  
  inc: (n = 1) -> @i += n
  step: (msg, n = 1) ->
    @msg = msg
    @inc n
    @display()

  progress: ->
    p = Math.min 1, @i / @max
    full = Math.floor @cwidth * p
    tiny = Math.floor (@cwidth * p - full) * 8

    tr = @bo + @ano + (blocks[8].repeat full)
    tr += (if tiny is 0 then "" else blocks[tiny])
    tr += (if p >= 1 then "" else blocks[0].repeat @cwidth - full - (if tiny then 1 else 0))
    tr += @anc + @bc + " " + (if p >= 1 then b + grn else b) + (p * 100).toFixed(2).padStart 3
    tr += "%" + c + " - #{@msg}"
    return tr
  
  display: ->
    if @displaying then process.stdout.write "\x1b[1A\x1b[2K\r#{@progress()}\n"
  
  startDisplaying: ->
    process.stdout.write "\n"
    @displaying = yes
  stopDisplaying: ->
    @displaying = no



loading = new LoadingBar 17, "║║", 25, 0x34d9ff

module.exports = loading
