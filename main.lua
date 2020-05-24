pickStyle=false

Grid = require'grid'
cw,ch = 64,64
bw,bh = 8,8
figsize = 0.75
picked = nil

function switch(e,a,b)
  if e then return a else return b end
end

function copy(a)
  local t={}
  for i,v in pairs(a) do
    t[i]=v
  end
  return t
end

function fillBoard(gr,inv)
  
  local function set(x,y,v)
    local a,b=copy(v),copy(v)
    a.team=not inv
    b.team=not a.team
    gr:set(x,y,a)
    gr:set(x,gr.h+1-y,b)
  end
  local function syms(x,y,v)
    set(x,y,v) set(gr.w+1-x,y,v)
  end
  

  for i=1,gr.w do
    set(i,2,{fig=1})
  end
  syms(1,1,{fig=4})
  syms(2,1,{fig=2})
  syms(3,1,{fig=3})
  set(4,1,{fig=5})
  set(5,1,{fig=6})
  
end

function flipBoard(gr) return gr end --placeholder

local function setFigSize(h)
  fig_size = ch*h
  chess_font=love.graphics.newFont('chess.ttf',fig_size)
end

function love.resize(w,h)
  print(("Window resized:%d,%d"):format(w, h))
  --[[if w*h<(bw*bh)*((cw+ch)/2) then
    return
  end]]
  cw=w/bw
  ch=h/bh
  setFigSize(figsize)
end

function love.load()
  grid = Grid.new(bw,bh)
  fillBoard(grid)
  love.window.setMode(grid.w*cw, grid.h*ch, {vsync=false,resizable=true} )
  love.window.setIcon(love.image.newImageData('icon.png'))
  font=love.graphics.newFont(24)
  setFigSize(figsize)
  fig={'g','h','i','j','k','l'}  -- пешка конь слон ладья ферзь король
  
  movFallback=function(gr,me,sx,sy,x,y) 
    if figPreventKill(gr,me,x,y) then return end
    local a,b=math.abs(sx-x),math.abs(sy-y)
    return not(a==b) and a<=1 and b<=1 and not(x==sx and y==sy)
  end
  
  function figPrevent(me,x,y,ox,oy)
    if me.team then
      return y<=oy
    else
      return y>=oy
    end
  end
  
  function figPreventKill(gr,me,x,y)
    local hit=gr:get(x,y)
    if hit and hit.team==me.team then
      return true
    end
  end
  
  figmov={
    [1]=function(gr,me,ox,oy,x,y) 
      if figPrevent(me,x,y,ox,oy) or figPreventKill(gr,me,x,y) then return false end
      local hit=gr:get(x,y)
      if not(hit) then 
        local dist=2
        if me.moved then dist=1 end
        return(math.abs(oy-y)<=dist and ox==x),'safe'
      else
        return (math.abs(ox-x)==1 and math.abs(oy-y)==1)
      end
    end,
    [2]=function(gr,me,ox,oy,x,y)
      local a=math.abs
      local dx,dy=ox-x,oy-y
      local sum=a(dx)+a(dy)
      if figPreventKill(gr,me,x,y) then return false end
      if sum~=3 or a(dx)==3 or a(dy)==3 then --a(dx)~=1 or a(dy)~=1 
        return false
      end
      if not((dx+dy)%2==0) then
        return true
      end
    end,
    [6]=function(gr,me,ox,oy,x,y,REC) 
      if figPreventKill(gr,me,x,y) or (ox==x and oy==y) then return end
      if not REC then
        for i=1,gr.w do
          for j=1,gr.h do
            local v=gr:get(i,j)
            if v~=Grid.nul then
              local fn=figmov[v.fig]
              local r1,r2
              if v.team~=me.team and fn then
                local orig=gr:get(x,y)
                gr:set(x,y,copy(me))
                r1,r2=fn(gr,v,i,j,x,y,true)
                gr:set(x,y,orig)
                --print(r2~='safe')
                if r1 and r2~='safe' then
                  return false
                end
              end
            end
          end
        end 
      end
      local dx,dy=math.abs(ox-x),math.abs(oy-y)
      --print('checkin',REC,(dx==1 and dy==1))
      return (dx<=1 and dy<=1)
    end
  }
  
  love.window.setTitle('Chess')
end

local function rgb(a,b,c,d) 
  return{
    a/255,
    b/255,
    c/255,
    (d or 255)/255
  } 
end

local function center(pw,iw)
  return (pw/2)-(iw/2)
end

local dark,light,selection,kill = {.2,.4,.2},{.3,.6,.3},{0,1,0,0.5},{1,0,0,0.5}

function love.update(d)
  dt=d
  mx,my=love.mouse.getPosition()
  m1,m2=love.mouse.isDown(1),love.mouse.isDown(2)
  mcx,mcy=math.floor(mx/cw)+1,math.floor(my/ch)+1
  --print(mx,my,m1,m2,mcx,mcy)
end

local function drawFig(v,cx,cy,alpha)
  local g=love.graphics
  if v then
    g.setFont(chess_font)
    local col=switch(v.team,{0,0,0},{1,1,1})
    if alpha then
      col[4]=alpha
    end
    g.setColor(col)
    local sym=fig[v.fig]
    g.print(
      sym,
      cx+center(cw,chess_font:getWidth(sym)),
      cy+center(ch,chess_font:getHeight())
    )
  end
end

function love.draw()
  local g = love.graphics
  w,h=g.getWidth(),g.getHeight()
  g.setColor(light)
  for i=1,grid.w do
    for j=1,grid.h do
      local v=grid:get(i,j)
      local hover = (mcx==i and mcy==j)
      g.setFont(font)
      
      local isDark = not((i+j)%2==0)
      local cx,cy = (i-1)*cw, (j-1)*ch
      
      g.setColor(switch(isDark,dark,light))
      g.rectangle('fill',cx,cy,cw,ch)
      
      g.setColor(switch(not(isDark),dark,light))
      if i==1 then
        g.print(grid.h+1-j,cx,cy)
      end
      if j==grid.h then
        local sym=string.char(i+96)
        g.print(sym,cx+cw-font:getWidth(sym),cy+ch-font:getHeight())
      end
      
      if hover then
        g.setColor(selection)
        g.rectangle('fill',cx,cy,cw,ch)
        if m1 then 
          if not picked then
            picked=v 
            pickx,picky=i,j
            grid:set(i,j,Grid.nul)
          end
        else
          if picked then
            local chk=figmov[picked.fig] or movFallback
            if chk(grid,picked,pickx,picky,i,j) then
              picked.moved=true
              grid:set(i,j,picked)
              grid=flipBoard(grid)
            else
              grid:set(pickx,picky,picked)
            end
          end
          picked=nil
        end
        if m2 then
          grid:set(i,j,Grid.nul)
        end
      end
      drawFig(v,cx,cy)
      
      if picked then
        local fn=figmov[picked.fig]
        if not fn then fn=movFallback end
        local responce=fn(grid,picked,pickx,picky,i,j)
        if responce then
          local hit=grid:get(i,j)
          if hit then
            g.setColor(kill)
          else
            g.setColor(selection)
          end
          g.rectangle('fill',(i-1)*cw,(j-1)*ch,cw,ch)
        end
      end
      
    end
  end

  if picked then
    g.setColor(1,0,0)
    if pickStyle then
      drawFig(
        picked,
        mx-cw/2,
        my-ch/2,
        0.7
      )
    else
      drawFig(
        picked,
        (mcx-1)*cw,
        (mcy-1)*ch-ch/4,
        0.7
      )
    end
  end
  
  g.setFont(font)
  g.setColor(1,1,1)
  local fps=love.timer.getFPS()
  g.print(fps,w-font:getWidth(fps))
end


--[[
function(gr,me,ox,oy,x,y) -- return (allow move?)
      return true
      --  if gr:get(x,y)==Grid.nul then
      --    if (ox==x and y<oy and oy-y<=2) then 
      --      return true
       --   end
       -- else
       --   if (ox-x==1 and math.abs(oy-y)==1) then
      --      return true
      --    end
      --  end
    end
    
    
    ]]
    