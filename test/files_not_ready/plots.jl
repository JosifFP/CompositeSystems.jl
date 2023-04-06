using GLMakie, ColorSchemes

y = [0,	25,	50,	75,	100, 125,	150,	175,	200,	225,	250,	275,	300]
x = [0,	25,	50,	75,	100, 125,	150,	175,	200]

z =[
    1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98;
    1404.98	1361.24	1325.38	1296.18	1277.36	1261.91	1249.02	1237.45	1227.04	1217.77	1210.08	1204.02	1199.96;
    1404.98	1361.24	1323.23	1290.50	1259.96	1232.53	1207.74	1189.57	1173.35	1158.76	1145.05	1132.56	1120.67;
    1404.98	1361.24	1323.23	1289.62	1258.77	1229.96	1203.03	1178.34	1155.21	1134.73	1117.53	1102.18	1087.64
]

f = Figure(resolution=(1200, 800), fontsize=24)
axs =Axis3(f[1,1]; title = "System EENS, BESS at bus 7", 
            xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
            zlabel = "EENS (MWh/y)",
            azimuth = -π/5,
            perspectiveness=0.0,
            elevation=π/6,
            zlabeloffset=120,
            xlabeloffset=70,
            ylabeloffset=70,
            xticks = WilkinsonTicks(6; k_min = 4),
            yticks = WilkinsonTicks(6; k_min = 4),
            zticks = WilkinsonTicks(6; k_min = 3),
            #aspect = (1,1,0.75)
            #aspect = :data
)

#cmap = (Reverse(:Spectral_11), 0.9)
cmap = (:viridis, 1)
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
    1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98;
    1404.98	1377.25	1362.36	1352.98	1347.03	1342.49	1338.97	1336.10	1333.81	1331.83	1330.30	1329.10	1328.20;
    1404.98	1377.25	1361.74	1351.46	1342.96	1335.88	1329.75	1325.43	1321.79	1318.56	1315.56	1312.81	1310.24;
    1404.98	1377.25	1361.74	1351.24	1342.60	1335.07	1328.40	1322.68	1317.58	1312.98	1309.17	1305.76	1287.30
    ]

cmap = (:viridis, 0.9)
s = surface!(axs,(x) ,y , z2 , color = z, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, z2, shading=false, color = :black, linewidth=0.7, overdraw=true, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])
#contour!(axs, x, y, z; colormap=:Spectral_11, levels=20,transformation=(:xy, zmax))
#contourf!(axs, x, y, z; colormap=cmap,transformation=(:xy, zmin))
#Colorbar(f[1, 2], s, width=15, ticksize=15, height=Relative(0.5), flipaxis = false)
save("figure10.png", f)








z3 = [
    243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72;
    243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72;
    243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72;
    243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72;
    243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72;
    243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72;
    243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72;
    243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72;
    243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72	243.72]
    
    cmap = (:viridis, 0.9)
    s = surface!(axs,(x) ,y , z3 , color = z, colormap=cmap)
    #contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
    wireframe!(axs,(x), y, z3, shading=false, color = :black, linewidth=0.7, overdraw=true, transparency=true)
    xmin, ymin, zmin = minimum(axs.finallimits[])
    xmax, ymax, zmax = maximum(axs.finallimits[])
    #contour!(axs, x, y, z; colormap=:Spectral_11, levels=20,transformation=(:xy, zmax))
    #contourf!(axs, x, y, z; colormap=cmap,transformation=(:xy, zmin))
    #Colorbar(f[1, 2], s, width=15, ticksize=15, height=Relative(0.5), flipaxis = false)
    save("figure3.png", f)






z =[
9.37	9.37	9.37	9.37	9.37	9.37	9.37	9.37	9.37	9.37	9.37	9.37	9.37;
9.37	8.55	8.36	8.25	8.10	8.04	8.00	7.91	7.89	7.89	7.88	7.86	7.86;
9.37	8.55	7.94	7.64	7.47	7.30	7.19	7.05	6.94	6.89	6.84	6.79	6.73;
9.37	8.55	7.94	7.38	7.11	6.83	6.66	6.51	6.36	6.28	6.16	6.06	5.98;
9.37	8.55	7.94	7.38	6.93	6.64	6.37	6.14	5.98	5.85	5.74	5.60	5.51;
9.37	8.55	7.94	7.38	6.93	6.52	6.23	5.99	5.76	5.56	5.43	5.30	5.17;
9.37	8.55	7.94	7.38	6.93	6.52	6.16	5.91	5.67	5.47	5.28	5.11	4.96;
9.37	8.55	7.94	7.38	6.93	6.52	6.16	5.87	5.62	5.42	5.22	5.04	4.88;
9.37	8.55	7.94	7.38	6.93	6.52	6.16	5.87	5.59	5.38	5.19	5.00	4.83]

f = Figure(resolution=(1200, 800), fontsize=24)
    axs =Axis3(f[1,1]; title = "System EDLC, BESS at bus 8", 
    xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
    zlabel = "EENS (MWh/y)",
    azimuth = -π/5,
    perspectiveness=0.0,
    elevation=π/6,
    zlabeloffset=120,
    xlabeloffset=70,
    ylabeloffset=70,
    xticks = WilkinsonTicks(6; k_min = 4),
    yticks = WilkinsonTicks(6; k_min = 4),
    zticks = WilkinsonTicks(6; k_min = 3),
    #aspect = (1,1,0.75)
    #aspect = :data
)
#cmap = (Reverse(:Spectral_11), 0.9)
cmap = (:sunset, 0.9)
s = surface!(axs,(x) ,y , z , color = z, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, z, shading=false, color = :black, linewidth=0.7, overdraw=true, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])
#contour!(axs, x, y, z; colormap=:Spectral_11, levels=20,transformation=(:xy, zmax))
contourf!(axs, x, y, z; colormap=cmap,transformation=(:xy, zmin))
Colorbar(f[1, 2], s, width=15, ticksize=15, height=Relative(0.5), label = "EDLC (hrs/y)", flipaxis = false)

save("figure4.png", f)


zx =[
    90.01	90.01	90.01	90.01	90.01	90.01	90.01	90.01	90.01	90.01	90.01	90.01	90.01;
    90.01	93.96	92.48	90.96	90.96	90.32	89.77	89.77	89.10	88.81	88.70	88.64	88.42;
    90.01	93.96	96.70	97.02	95.75	95.07	93.83	93.86	93.60	92.90	92.20	91.72	91.40;
    90.01	93.96	96.70	99.75	100.03	100.69	99.92	99.28	98.74	97.50	97.39	97.12	96.61;
    90.01	93.96	96.70	99.75	102.04	102.97	103.95	104.33	103.73	103.37	102.69	102.48	101.78;
    90.01	93.96	96.70	99.75	102.04	104.33	105.63	106.38	107.33	107.86	107.19	107.24	107.31;
    90.01	93.96	96.70	99.75	102.04	104.33	106.27	107.26	108.39	109.06	109.69	110.28	110.46;
    90.01	93.96	96.70	99.75	102.04	104.33	106.27	107.70	108.84	109.66	110.46	111.20	111.92;
    90.01	93.96	96.70	99.75	102.04	104.33	106.27	107.70	109.11	109.94	110.75	111.61	112.53;
    ]

f = Figure(resolution=(1200, 800), fontsize=24)
    axs =Axis3(f[1,1]; title = "EENS/EDLC, BESS at bus 8", 
    xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
    zlabel = "MWh/hr",
    azimuth = -π/5,
    perspectiveness=0.0,
    elevation=π/6,
    zlabeloffset=120,
    xlabeloffset=70,
    ylabeloffset=70,
    xticks = WilkinsonTicks(6; k_min = 4),
    yticks = WilkinsonTicks(6; k_min = 4),
    zticks = WilkinsonTicks(6; k_min = 3),
    #aspect = (1,1,0.75)
    #aspect = :data
)
#cmap = (Reverse(:Spectral_11), 0.9)
cmap = (Reverse(:seaborn_rocket_gradient), 0.9)
s = surface!(axs,(x) ,y , zx , color = z, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, zx, shading=false, color = :black, linewidth=0.7, overdraw=true, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])
#contour!(axs, x, y, z; colormap=:Spectral_11, levels=20,transformation=(:xy, zmax))
contourf!(axs, x, y, zx; colormap=(:seaborn_rocket_gradient, 0.9),transformation=(:xy, zmin))

save("figure6.png", f)


















#surface(x, y, z, axis=(type=Axis3,), shading=true, colormap = :watermelon)
#surface(x, y, z, axis=(type=Axis3,), shading=true, colormap = :sunset)
#surface(x, y, z, axis=(type=Axis3,), shading=true, colormap = :seaborn_rocket_gradient)