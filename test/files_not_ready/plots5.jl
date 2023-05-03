using GLMakie, ColorSchemes

y = [0,	25,	50,	75,	100, 125,	150,	175,	200,	225,	250,	275,	300]
x = [0,	25,	50,	75,	100, 125,	150,	175,	200]

zbase =[
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00;
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00;
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00;
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00;
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00;
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00;
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00;
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00;
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00;
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
            zticks = WilkinsonTicks(8; k_min = 6),
            #aspect = (1,1,0.75)
            #aspect = :data
)

cmap = (:gray1, 1.0)
s = surface!(axs,(x) ,y , zbase , color = zbase, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, zbase, shading=false, color = :black, linewidth=0.5, overdraw=true, transparency=false)


z =[
    -384.71	-384.71	-384.71	-384.71	-384.71	-384.71	-384.71	-384.71	-384.71	-384.71	-384.71	-384.71	-384.71;
    -384.71	-328.66	-283.62	-246.80	-222.21	-201.81	-184.05	-168.60	-154.56	-141.94	-131.70	-123.72	-118.38;
    -384.71	-328.66	-280.90	-239.16	-201.00	-166.59	-135.00	-111.02	-89.44	-69.97	-51.48	-34.39	-18.42;
    -384.71	-328.66	-280.90	-238.01	-199.37	-163.23	-129.08	-97.36	-67.54	-40.49	-17.50	3.29	23.13;
    -384.71	-328.66	-280.90	-238.01	-198.72	-162.34	-127.90	-95.35	-64.63	-35.95	-9.14	16.12	40.05;
    -384.71	-328.66	-280.90	-238.01	-198.72	-162.08	-127.50	-94.81	-63.98	-34.86	-7.47	18.16	42.73;
    -384.71	-328.66	-280.90	-238.01	-198.72	-162.08	-127.40	-94.67	-63.75	-34.58	-7.13	18.82	43.70;
    -384.71	-328.66	-280.90	-238.01	-198.72	-162.08	-127.40	-94.64	-63.72	-34.50	-7.02	18.97	43.95;
    -384.71	-328.66	-280.90	-238.01	-198.72	-162.08	-127.40	-94.64	-63.70	-34.49	-6.98	19.04	44.04;  
]

cmap = (:Spectral_11, 0.95)
#cmap = (:viridis, 1)
s = surface!(axs,(x) ,y , z , color = z, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, z, shading=false, color = :black, linewidth=0.7, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])
#contour!(axs, x, y, z; colormap=:Spectral_11, levels=20,transformation=(:xy, zmax))
#contourf!(axs, x, y, z; colormap=cmap,transformation=(:xy, zmin))
#Colorbar(f[1, 2], s, width=15, ticksize=15, height=Relative(0.5), flipaxis = false)

#save("figure1.png", f)


#  BUS 2  ##########################################################################################################

z2 = [
    -73.47	-73.47	-73.47	-73.47	-73.47	-73.47	-73.47	-73.47	-73.47	-73.47	-73.47	-73.47	-73.47;
    -73.47	-28.77	8.05	37.81	57.81	74.49	88.45	100.61	111.60	121.51	129.30	135.57	139.71;
    -73.47	-28.77	9.86	43.40	74.48	102.35	127.64	147.14	164.65	180.46	195.35	208.85	221.43;
    -73.47	-28.77	9.86	44.15	75.60	104.84	132.33	157.74	181.76	203.36	221.87	238.52	254.53;
    -73.47	-28.77	9.86	44.15	76.01	105.45	133.12	159.23	184.00	206.80	228.34	248.66	267.57;
    -73.47	-28.77	9.86	44.15	76.01	105.61	133.43	159.62	184.47	207.65	229.65	250.30	269.89;
    -73.47	-28.77	9.86	44.15	76.01	105.61	133.52	159.81	184.70	207.92	229.98	250.89	270.75;
    -73.47	-28.77	9.86	44.15	76.01	105.61	133.52	159.87	184.80	208.05	230.20	251.07	270.96;
    -73.47	-28.77	9.86	44.15	76.01	105.61	133.52	159.87	184.84	208.11	230.20	251.14	271.05;
             
]


cmap = (:Spectral_11, 0.95)

s = surface!(axs,(x) ,y , z2 , color = z, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, z2, shading=false, color = :black, linewidth=0.7,  overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])

save("figure5.png", f)














z3 = [
    56.04	101.08	137.91	162.50	182.90	200.66	216.11	230.15	242.77	253.01	260.99	266.33;
    56.04	103.80	145.54	183.71	218.12	249.71	273.69	295.26	314.74	333.23	350.31	366.29;
    56.04	103.80	146.69	185.33	221.48	255.63	287.34	317.17	344.21	367.20	387.99	407.84;
    56.04	103.80	146.69	185.98	222.36	256.80	289.35	320.08	348.76	375.56	400.83	424.76;
    56.04	103.80	146.69	185.98	222.62	257.21	289.90	320.73	349.85	377.23	402.86	427.43;
    56.04	103.80	146.69	185.98	222.62	257.31	290.04	320.95	350.13	377.57	403.52	428.41;
    56.04	103.80	146.69	185.98	222.62	257.31	290.07	320.99	350.20	377.69	403.68	428.66;
    56.04	103.80	146.69	185.98	222.62	257.31	290.07	321.00	350.22	377.73	403.74	428.75;            
]


cmap = (:Spectral_11, 0.95)

s = surface!(axs,(x) ,y , z3 , color = z, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, z3, shading=false, color = :black, linewidth=0.7, overdraw=false, transparency=true)
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