using GLMakie, ColorSchemes

y = [25,	50,	75,	100, 125,	150,	175,	200,	225,	250,	275,	300]
x = [25,	50,	75,	100, 125,	150,	175,	200]

z =[
    43.74	79.60	108.80	127.62	143.07	155.96	167.53	177.94	187.21	194.90	200.96	205.02;
    43.74	81.75	114.48	145.02	172.45	197.24	215.41	231.63	246.22	259.93	272.42	284.31;
    43.74	81.75	115.36	146.21	175.02	201.95	226.64	249.77	270.25	287.45	302.80	317.34;
    43.74	81.75	115.36	146.64	175.63	202.78	228.25	252.10	273.83	294.17	313.32	330.83;
    43.74	81.75	115.36	146.64	175.81	203.07	228.66	252.61	274.74	295.45	314.88	333.13;
    43.74	81.75	115.36	146.64	175.81	203.12	228.79	252.84	275.03	295.80	315.46	333.99;
    43.74	81.75	115.36	146.64	175.81	203.12	228.81	252.89	275.12	295.94	315.65	334.23;
    43.74	81.75	115.36	146.64	175.81	203.12	228.81	252.89	275.13	295.95	315.70	334.32;
        
]

f = Figure(resolution=(1200, 800), fontsize=24)
axs =Axis3(f[1,1]; title = "System EENS, ESS at bus 8", 
            xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
            zlabel = "EENS GAP (MWh/y)",
            azimuth = -π/5,
            perspectiveness=0.0,
            elevation=π/6,
            zlabeloffset=100,
            xlabeloffset=60,
            ylabeloffset=60,
            xticks = WilkinsonTicks(6; k_min = 4),
            yticks = WilkinsonTicks(6; k_min = 4),
            zticks = WilkinsonTicks(6; k_min = 3),
            #aspect = (1,1,0.75)
            #aspect = :data
)

cmap = (:Spectral_11, 0.95)
#cmap = (:viridis, 1)
s = surface!(axs,(x) ,y , z , color = z, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, z, shading=false, color = :black, linewidth=0.7, overdraw=true, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])
#contour!(axs, x, y, z; colormap=:Spectral_11, levels=20,transformation=(:xy, zmax))
#contourf!(axs, x, y, z; colormap=cmap,transformation=(:xy, zmin))
#Colorbar(f[1, 2], s, width=15, ticksize=15, height=Relative(0.5), flipaxis = false)

#save("figure1.png", f)


#  BUS 2  ##########################################################################################################

z2 = [
    56.07	101.12	137.94	162.54	182.95	200.71	216.16	230.20	242.82	253.06	261.04	266.38;
    56.07	103.84	145.58	183.74	218.15	249.74	273.73	295.31	314.79	333.29	350.37	366.35;
    56.07	103.84	146.73	185.37	221.51	255.67	287.38	317.20	344.26	367.25	388.05	407.91;
    56.07	103.84	146.73	186.02	222.40	256.84	289.39	320.12	348.80	375.61	400.89	424.83;
    56.07	103.84	146.73	186.02	222.66	257.25	289.93	320.77	349.89	377.29	402.93	427.51;
    56.07	103.84	146.73	186.02	222.66	257.34	290.07	320.99	350.17	377.63	403.59	428.49;
    56.07	103.84	146.73	186.02	222.66	257.34	290.11	321.03	350.24	377.74	403.74	428.73;
    56.07	103.84	146.73	186.02	222.66	257.34	290.11	321.04	350.26	377.78	403.81	428.83 ;         
    ]


cmap = (:Spectral_11, 0.95)

s = surface!(axs,(x) ,y , z2 , color = z, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, z2, shading=false, color = :black, linewidth=0.7, overdraw=true, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])
Colorbar(f[2, 1], s, width=Relative(0.5), flipaxis = false, vertical = false)
rowgap!(f.layout, 80)
save("figure7.png", f)




#contour!(axs, x, y, z; colormap=:Spectral_11, levels=20,transformation=(:xy, zmax))
#contourf!(axs, x, y, z; colormap=cmap,transformation=(:xy, zmin))
#Colorbar(f[1, 2], s, width=15, ticksize=15, height=Relative(0.5), flipaxis = false)
#contour!(axs, x, y, z; colormap=:Spectral_11, levels=20,transformation=(:xy, zmax))
#contourf!(axs, x, y, zx; colormap=(:seaborn_rocket_gradient, 0.9),transformation=(:xy, zmin))
#surface(x, y, z, axis=(type=Axis3,), shading=true, colormap = :watermelon)
#surface(x, y, z, axis=(type=Axis3,), shading=true, colormap = :sunset)
#surface(x, y, z, axis=(type=Axis3,), shading=true, colormap = :seaborn_rocket_gradient)