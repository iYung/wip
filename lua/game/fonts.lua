local PATH = "assets/fonts/font.ttf"
return { new = function(size) return love.graphics.newFont(PATH, size, "light") end }
