globals
[
  mutualistA ;;agent numbers of mutualistA
  mutualistB ;;agent numbers of mutualistB
  non-mutualistA ;;agent numbers of non-mutualistA
  non-mutualistB ;;agent numbers of non-mutualistB
  turtles-xcorB ;;record turtles numbers on every xcor of mutualists
  turtles-xcorR ;;record turtles numbers on every xcor of cheaters
  turtles-xcorA ;;record turtles numbers on every xcor
  i ;;save list
  
]

patches-own 
[
  environment ;;environmental gradients
]

turtles-own
[
  species      ;; 1 speciesA, 0 speciesB
  mutualist    ;; 1 mutualist, 0 non-mutualist, 2 empty
  reproduction ;; reproduction rate
  reproduce?   ;; if a turtle is going to try to reproduce
]  

to setup
  clear-all

  setup-turtles
  
  ask turtles 
  [
    set reproduction r
    set reproduce? FALSE
  ]
  
  environmental-gradient
  if color_setting = "species_strategy"
  [
    setcolor
  ]
  
  if color_setting = "species_distributions"
  [
    setcolor_S
  ]
  reset-ticks
  
end

to setup-turtles
  ;;set two kinds of turtles with colors
  
  create-turtles Species_Population ;;speciesA
  [
    set species 1 
    move-to one-of patches with [not any? turtles-here] 
    set size 0.5
    set color yellow
    if hide-turtles [hide-turtle]
  ] 
  
  create-turtles Species_Population ;;speciesB
  [
    set species 0
    move-to one-of patches with [not any? turtles-here with [species = 0]] 
    set size 0.5
    set color green
    if hide-turtles [hide-turtle]
  ]
  
  ;;generate number of agents  
  set mutualistA (SpeciesA-mutualist-percentage / 100) * Species_Population
  set non-mutualistA ((100 - SpeciesA-mutualist-percentage) / 100) * Species_Population
  set mutualistB (SpeciesB-mutualist-percentage / 100) * Species_Population
  set non-mutualistB ((100 - SpeciesB-mutualist-percentage) / 100) * Species_Population
  
  ;;allocate certain species distributions, based one species occupation rates
  ;;When a patch creates a turtle, you use sprout.
  ask n-of (mutualistA + non-mutualistA) turtles with [species = 1]
  [
    set mutualist 1 
  ]
  
  ask n-of non-mutualistA turtles with [species = 1] 
  [
    set mutualist 0
  ]
  
  ask n-of (mutualistB + non-mutualistB) turtles with [species = 0] 
  [
    set mutualist 1 
  ]
  
  ask n-of non-mutualistB turtles with [species = 0] 
  [
    set mutualist 0
  ]
  
end

to environmental-gradient
  ;;set environmental gradients - linear gradient from 1/200 to 1 
  ask patches 
  [
    set environment (1 - (pxcor / world-width))
  ]  
end

to setup-plot
  set-current-plot "Environmental_Quality"
  set-plot-x-range (1 / world-width) 1
  ask patches 
  [
    let strategyA count turtles with [pcolor = red and pxcor = pxcor]
    let strategyB count turtles with [pcolor = blue and pxcor = pxcor]
    
    histogram [strategyA] of turtles
  ]  
end

to go
  if count turtles with [species = 1] = 0 [stop]
  if count turtles with [species = 0] = 0 [stop]
  
  diffusions             ;;propagule
  deathrate
  
  if color_setting = "species_strategy"
  [
    setcolor
  ]
  
  if color_setting = "species_distributions"
  [
    setcolor_S
  ]
  ;setup-plot
  
  savecountturtles
  tick
  if ticks = 2500 [stop]
  
end

to deathrate
  ask turtles
  [
    if random-float 1 < d [die]
  ]
end


  
to diffusions ;;propagule
  ask turtles with [species = 1]
  [ 
    let parents-strategy mutualist
    let other-mutualist 0
    ask other turtles-here [set other-mutualist mutualist] ;; if there is another turtle here who is mutualist, then...
    
    ;; actual probability of reproduction is: (r * environment-gradient) + b - c
    set reproduction (r * environment) + (b * other-mutualist) - (c * mutualist) ;; ... multiply our b & c payoffs by 1 or 0 to determine if they take effect (because mutualist)
    
    spatial_effectA
    
    if reproduction < 0 [set reproduction 0]
    
    let pvalue random-float 1
    if (sum [count turtles-here with [species = 1]] of neighbors4 < count neighbors4) and (pvalue < reproduction)
    [
      ask one-of neighbors4 with [not any? turtles-here with [species = 1]] 
      [
        sprout 1 
        [
          set species 1
          set mutualist parents-strategy
          set reproduction r
          set size 0.5
          set color yellow
          if hide-turtles [hide-turtle]
        ]
      ]
    ]
  ]
     
     
  ask turtles with [species = 0]
  [
    let parents-strategy mutualist
    let other-mutualist 0
    ask other turtles-here [set other-mutualist mutualist]
    
    ;; actual probability of reproduction is: (r * environment-gradient) + b - c
    set reproduction (r * environment) + (b * other-mutualist) - (c * mutualist)
    
    spatial_effectB
    
    if reproduction < 0 [set reproduction 0]
    
    let pvalue random-float 1
    
    if (sum [count turtles-here with [species = 0]] of neighbors4 < count neighbors4) and (pvalue < reproduction)
    [
      ask one-of neighbors4 with [not any? turtles-here with [species = 0]] 
      [ 
        sprout 1 
        [
          set species 0
          set mutualist parents-strategy
          set reproduction r
          set size 0.5
          set color green
          if hide-turtles [hide-turtle]
        ]
      ]
    ]
  ]
end

to spatial_effectA
    if Spatial_Weights = "no-effects"
    [
      
    ]
    
    if Spatial_Weights = "Rook-contiguity"
    [
      if heterogeneity = "no_effects" ;;either mutualists or cheaters increase the reproduction rates 
      [
      ;;4neighbor clusters make effects on reproduction rates
      if sum [count turtles-here with [species = 1]] of neighbors4 > (count neighbors4 / 2) 
      [
        set reproduction reproduction * (1 + sum [count turtles-here with [species = 1]] of neighbors4 / count neighbors4)
      ]
      ]
      
      if heterogeneity = "species_strategy"
      [
        if mutualist = 1 ;;mutualists with neighbor effects => increase reproduction rates
        [
        if sum [count turtles-here with [species = 1]] of neighbors4 > (count neighbors4 / 2) 
        [
          set reproduction reproduction * (1 + ((sum [count turtles-here with [species = 1]] of neighbors4) ) * 0.005) 
        ]
        
        ]
        if mutualist = 0 ;;cheaters with neighbor effects => decrease reproduction rates
        [
          if sum [count turtles-here with [species = 1]] of neighbors4 > (count neighbors4 / 2) 
        [
          set reproduction reproduction * (1 - ((sum [count turtles-here with [species = 1]] of neighbors4) ) * 0.005)
        ]
        ]
      ]
      
    ]
    
    if Spatial_Weights = "Queen-contiguity"
    [
      if heterogeneity = "no_effects" ;;either mutualists or cheaters increase the reproduction rates 
      [
      ;;8neighbor clusters make effects on reproduction rates
      if sum [count turtles-here with [species = 1]] of neighbors > (count neighbors / 2) 
      [ 
        set reproduction reproduction * (1 + sum [count turtles-here with [species = 1]] of neighbors / count neighbors)
      ]
      ]
      
      if heterogeneity = "species_strategy"
      [
        if mutualist = 1 ;;mutualists with neighbor effects => increase reproduction rates
        [
         if sum [count turtles-here with [species = 1]] of neighbors > (count neighbors / 2) 
         [ 
           set reproduction reproduction * (1 + ((sum [count turtles-here with [species = 1]] of neighbors) ) * 0.005)
         ]
        ]
        
        if mutualist = 0 ;;mutualists with neighbor effects => increase reproduction rates
        [
        if sum [count turtles-here with [species = 1]] of neighbors4 > (count neighbors / 2) 
        [
          set reproduction reproduction * (1 - ((sum [count turtles-here with [species = 1]] of neighbors) ) * 0.005)
        ]
        ]
      ]
    ]
    
end

  
to spatial_effectB
  if Spatial_Weights = "no-effects"
  [
    
  ]
  
      if Spatial_Weights = "Rook-contiguity"
    [
      if heterogeneity = "no_effects" ;;either mutualists or cheaters increase the reproduction rates 
      [
      ;;4neighbor clusters make effects on reproduction rates
      if sum [count turtles-here with [species = 0]] of neighbors4 > (count neighbors4 / 2) 
      [
        set reproduction reproduction * (1 + sum [count turtles-here with [species = 0]] of neighbors4 / count neighbors4) ;;1 + (?/4)
      ]
      ]
      
      if heterogeneity = "species_strategy"
      [
        if mutualist = 1 ;;mutualists with neighbor effects => increase reproduction rates
        [
        if sum [count turtles-here with [species = 0]] of neighbors4 > (count neighbors4 / 2) ;;neighbor > 2
        [
          set reproduction reproduction * (1 + ((sum [count turtles-here with [species = 0]] of neighbors4) ) * 0.005) 
        ]
        
        ]
        if mutualist = 0 ;;cheaters with neighbor effects => decrease reproduction rates
        [
          if sum [count turtles-here with [species = 0]] of neighbors4 > (count neighbors4 / 2) 
        [
          set reproduction reproduction * (1 - ((sum [count turtles-here with [species = 0]] of neighbors4) ) * 0.005)
        ]
        ]
      ]
    ]
    
    if Spatial_Weights = "Queen-contiguity"
    [
      if heterogeneity = "no_effects" ;;either mutualists or cheaters increase the reproduction rates
      [
      ;;8neighbor clusters make effects on reproduction rates
      if sum [count turtles-here with [species = 0]] of neighbors > (count neighbors / 2) 
      [ 
        set reproduction reproduction * (1 + sum [count turtles-here with [species = 0]] of neighbors / count neighbors)
      ]
      ]
      
      if heterogeneity = "species_strategy"
      [
        if mutualist = 1 ;;mutualists with neighbor effects => increase reproduction rates
        [
         if sum [count turtles-here with [species = 0]] of neighbors > (count neighbors / 2) 
         [ 
           set reproduction reproduction * (1 + ((sum [count turtles-here with [species = 0]] of neighbors) ) * 0.005)
           
         ]
        ]
        
        if mutualist = 0 ;;cheaters with neighbor effects => decrease reproduction rates
        [
        if sum [count turtles-here with [species = 0]] of neighbors4 > (count neighbors / 2) 
        [
          set reproduction reproduction * (1 - ((sum [count turtles-here with [species = 0]] of neighbors) ) * 0.005)
        ]
        ]
      ]
    ]
   
            
end    

to savecountturtles
  set i 0
  set turtles-xcorB []
  set turtles-xcorR []
  set turtles-xcorA []
  repeat world-width 
  [
    if i < world-width
    [
    let resultB count patches with [pxcor = i and (pcolor = blue or pcolor = 102)]
    let resultR count patches with [pxcor = i and (pcolor = red or pcolor = 12)]
    let resultA count turtles with [pxcor = i]
    set turtles-xcorB lput (resultB) turtles-xcorB
    set turtles-xcorR lput (resultR) turtles-xcorR
    set turtles-xcorA lput (resultA) turtles-xcorA
    set i i + 1
    ]
    
  ]
end
  
to setcolor
  ask patches [set pcolor white]
  
  ask patches
  [
    if count turtles-here = 2
    [
      ask turtles-here
      [
        ifelse mutualist = 0 ;;cheater
        [
          ifelse [mutualist] of one-of other turtles-here = 0
            [set pcolor 15] ;;both cheater, bright red
            [set pcolor 65] ;;one cheater & one mutualist, green
        ]
        [;;mutualist
          ifelse [mutualist] of one-of other turtles-here = 0
            [set pcolor 65] ;;one mutualist & one cheater, green
            [set pcolor 105] ;;both mutualist, bright blue
        ]
      ]
    ]
    
    if count turtles-here = 1
    [
      ask turtles-here [
        ifelse mutualist = 1
        [set pcolor 102];;one mutualist, dark blue
        [set pcolor 12] ;;one cheater, dark red
      ]
    ]   
  ]
end

to setcolor_S
  ask patches [set pcolor white]
  
  ask patches
  [
    if count turtles-here = 2
    [
      ask turtles-here
      [
        if species = 1 ;;speciesA
        [
          if [species] of one-of other turtles-here = 0
            [
              set pcolor 65
             ] ;;one speciesA & one speciesB, green
        ]

      ]
    ]
    
    if count turtles-here = 1
    [
      ask turtles-here [
        ifelse species = 1
        [set pcolor 102];;one speciesA, dark blue
        [set pcolor 12] ;;one speciesB, dark red
      ]
    ]   
  ]
end  
@#$#@#$#@
GRAPHICS-WINDOW
278
17
788
548
-1
-1
5.0
1
10
1
1
1
0
0
0
1
0
99
0
99
0
0
1
ticks
30.0

SLIDER
811
255
983
288
d
d
0
0.3
0.08
0.01
1
NIL
HORIZONTAL

SLIDER
809
94
981
127
b
b
0
1
0.15
0.01
1
NIL
HORIZONTAL

SLIDER
809
138
981
171
c
c
0
0.1
0.02
0.01
1
NIL
HORIZONTAL

BUTTON
30
60
100
93
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
106
60
169
93
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
174
60
237
93
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
810
18
960
36
Reproduction Rate
11
0.0
1

TEXTBOX
815
235
965
253
Death Rate
11
0.0
1

TEXTBOX
810
430
1008
542
Reference: \nTravis, J.M.J., Brooker, R.W., & Dytham, C. (2005). The interplay of positive and negative species interactions across an environmental gradient: insights from an individual-based simulation model. Biology Letters, 1, 5-8
11
0.0
1

SLIDER
18
119
243
152
SpeciesA-mutualist-percentage
SpeciesA-mutualist-percentage
0
80
50
1
1
%
HORIZONTAL

SLIDER
18
156
243
189
SpeciesB-mutualist-percentage
SpeciesB-mutualist-percentage
0
80
50
1
1
%
HORIZONTAL

SLIDER
21
11
250
44
Species_Population
Species_Population
10
2000
350
10
1
NIL
HORIZONTAL

SLIDER
808
45
980
78
r
r
0
1
0.3
0.01
1
NIL
HORIZONTAL

SWITCH
18
211
149
244
hide-turtles
hide-turtles
0
1
-1000

PLOT
1018
19
1531
314
Environmental_Quality
NIL
NIL
0.0
200.0
0.0
10.0
true
true
"set-plot-x-range min-pxcor max-pxcor\nset-histogram-num-bars world-width" ""
PENS
"mutualist" 1.0 1 -13791810 true "" "histogram [xcor] of turtles with [pcolor = blue or pcolor = 102]"
"cheater" 1.0 1 -2674135 true "" "histogram [xcor] of turtles with [pcolor = red or pcolor = 12]"

CHOOSER
16
340
191
385
Spatial_Weights
Spatial_Weights
"no_effects" "Rook-contiguity" "Queen-contiguity"
2

PLOT
1041
328
1241
478
the_best_environment
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"cheater" 1.0 0 -2674135 true "" "plot count turtles with [pxcor < 25 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor < 25]"
"mutualist" 1.0 0 -13345367 true "" "plot count turtles with [pxcor < 25 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor < 25]"

PLOT
1042
489
1242
639
better_environment
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"cheater" 1.0 0 -2674135 true "" "plot count turtles with [pxcor < 50 and pxcor >= 25 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor < 50 and pxcor >= 25]"
"mutualist" 1.0 0 -13345367 true "" "plot count turtles with [pxcor < 50 and pxcor >= 25 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor < 50 and pxcor >= 25]"

PLOT
1252
326
1452
476
worse_environment
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"cheater" 1.0 0 -2674135 true "" "plot count turtles with [pxcor < 75 and pxcor >= 50 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor < 75 and pxcor >= 50]"
"mutualist" 1.0 0 -13345367 true "" "plot count turtles with [pxcor < 75 and pxcor >= 50 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor < 75 and pxcor >= 50]"

TEXTBOX
19
318
169
336
Neighbor Effects
11
0.0
1

CHOOSER
812
328
985
373
Color_setting
Color_setting
"species_strategy" "species_distributions"
0

CHOOSER
17
402
191
447
heterogeneity
heterogeneity
"no_effects" "species_strategy"
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Queen_Dstrategy" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2500"/>
    <metric>turtles-xcorB</metric>
    <metric>turtles-xcorR</metric>
    <metric>turtles-xcorA</metric>
    <metric>count turtles with [pxcor &lt; 25 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor &lt; 25]</metric>
    <metric>count turtles with [pxcor &lt; 25 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor &lt; 25]</metric>
    <metric>count turtles with [pxcor &lt; 50 and pxcor &gt;= 25 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor &lt; 50 and pxcor &gt;= 25]</metric>
    <metric>count turtles with [pxcor &lt; 50 and pxcor &gt;= 25 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor &lt; 50 and pxcor &gt;= 25]</metric>
    <metric>count turtles with [pxcor &lt; 75 and pxcor &gt;= 50 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor &lt; 75 and pxcor &gt;= 50]</metric>
    <metric>count turtles with [pxcor &lt; 75 and pxcor &gt;= 50 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor &lt; 75 and pxcor &gt;= 50]</metric>
    <metric>count turtles with [pxcor &gt;= 75 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor &gt;= 75]</metric>
    <metric>count turtles with [pxcor &gt;= 75 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor &gt;= 75]</metric>
    <enumeratedValueSet variable="Color_setting">
      <value value="&quot;species_strategy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Species_Population">
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-turtles">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Spatial_Weights">
      <value value="&quot;Queen-contiguity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SpeciesA-mutualist-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterogeneity">
      <value value="&quot;species_strategy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SpeciesB-mutualist-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d">
      <value value="0.08"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Rook_Dstrategy" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2500"/>
    <metric>turtles-xcorB</metric>
    <metric>turtles-xcorR</metric>
    <metric>turtles-xcorA</metric>
    <metric>count turtles with [pxcor &lt; 25 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor &lt; 25]</metric>
    <metric>count turtles with [pxcor &lt; 25 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor &lt; 25]</metric>
    <metric>count turtles with [pxcor &lt; 50 and pxcor &gt;= 25 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor &lt; 50 and pxcor &gt;= 25]</metric>
    <metric>count turtles with [pxcor &lt; 50 and pxcor &gt;= 25 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor &lt; 50 and pxcor &gt;= 25]</metric>
    <metric>count turtles with [pxcor &lt; 75 and pxcor &gt;= 50 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor &lt; 75 and pxcor &gt;= 50]</metric>
    <metric>count turtles with [pxcor &lt; 75 and pxcor &gt;= 50 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor &lt; 75 and pxcor &gt;= 50]</metric>
    <metric>count turtles with [pxcor &gt;= 75 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor &gt;= 75]</metric>
    <metric>count turtles with [pxcor &gt;= 75 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor &gt;= 75]</metric>
    <enumeratedValueSet variable="Color_setting">
      <value value="&quot;species_strategy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Species_Population">
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-turtles">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Spatial_Weights">
      <value value="&quot;Rook-contiguity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SpeciesA-mutualist-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterogeneity">
      <value value="&quot;species_strategy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SpeciesB-mutualist-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d">
      <value value="0.08"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="noeffects" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2500"/>
    <metric>turtles-xcorB</metric>
    <metric>turtles-xcorR</metric>
    <metric>turtles-xcorA</metric>
    <metric>count turtles with [pxcor &lt; 25 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor &lt; 25]</metric>
    <metric>count turtles with [pxcor &lt; 25 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor &lt; 25]</metric>
    <metric>count turtles with [pxcor &lt; 50 and pxcor &gt;= 25 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor &lt; 50 and pxcor &gt;= 25]</metric>
    <metric>count turtles with [pxcor &lt; 50 and pxcor &gt;= 25 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor &lt; 50 and pxcor &gt;= 25]</metric>
    <metric>count turtles with [pxcor &lt; 75 and pxcor &gt;= 50 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor &lt; 75 and pxcor &gt;= 50]</metric>
    <metric>count turtles with [pxcor &lt; 75 and pxcor &gt;= 50 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor &lt; 75 and pxcor &gt;= 50]</metric>
    <metric>count turtles with [pxcor &gt;= 75 and (pcolor = red or pcolor = 12)] / count turtles with [pxcor &gt;= 75]</metric>
    <metric>count turtles with [pxcor &gt;= 75 and (pcolor = blue or pcolor = 102)] / count turtles with [pxcor &gt;= 75]</metric>
    <enumeratedValueSet variable="c">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Spatial_Weights">
      <value value="&quot;no_effects&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d">
      <value value="0.08"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-turtles">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Color_setting">
      <value value="&quot;species_strategy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SpeciesB-mutualist-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Species_Population">
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SpeciesA-mutualist-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterogeneity">
      <value value="&quot;no_effects&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.15"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
