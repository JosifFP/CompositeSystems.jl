using GLMakie, ColorSchemes

y = [0,	25,	50,	75,	100, 125,	150,	175,	200,	225,	250,	275,	300]
x = [0,	25,	50,	75,	100, 125,	150,	175,	200]

zbase_6 =[
    1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98;
    1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98;
    1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98;
    1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98;
    1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98;
    1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98;
    1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98;
    1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98;
    1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98	1404.98;   
]

f = Figure(resolution=(1200, 800), fontsize=26)
axs =Axis3(f[1,1]; title = "System EENS, ESS at bus 6", 
            xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
            zlabel = "EENS (MWh/y)",
            azimuth = 4.5π/6,
            perspectiveness=0.0,
            elevation=π/8,
            zlabeloffset=90,
            xlabeloffset=60,
            ylabeloffset=60,
            xticks = WilkinsonTicks(6; k_min = 4),
            yticks = WilkinsonTicks(6; k_min = 4),
            zticks = WilkinsonTicks(6; k_min = 4),
            #aspect = (1,1,0.75)
            #aspect = :data
)

#cmap = (Reverse(:Spectral_11), 0.9)
cmap = (:gray1, 1.0)
s = surface!(axs,(x) ,y , zbase_6 , color = zbase_6, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, zbase_6, shading=false, color = :black, linewidth=0.5, overdraw=true, transparency=false)
#xmin, ymin, zmin = minimum(axs.finallimits[])
#xmax, ymax, zmax = maximum(axs.finallimits[])
#contourf!(axs, x, y, zbase_6; colormap=cmap,transformation=(:xy, zmin))
#rowgap!(f.layout, 50)
#Colorbar(f[2, 1], s, width=Relative(0.8), flipaxis = false, vertical = false)
#Colorbar(f[2, 1], s, width=Relative(0.5), flipaxis = false, vertical = false)

zcase1_6 = [
    1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45;
    1478.45	1433.74	1396.91	1367.14	1347.12	1330.43	1316.46	1304.29	1293.28	1283.36	1275.55	1269.27	1265.12;
    1478.45	1433.74	1395.10	1361.54	1330.45	1302.56	1277.26	1257.75	1240.23	1224.41	1209.51	1195.99	1183.40;
    1478.45	1433.74	1395.10	1360.79	1329.33	1300.08	1272.57	1247.15	1223.12	1201.51	1182.98	1166.32	1150.30;
    1478.45	1433.74	1395.10	1360.79	1328.92	1299.47	1271.79	1245.66	1220.88	1198.07	1176.51	1156.18	1137.26;
    1478.45	1433.74	1395.10	1360.79	1328.92	1299.31	1271.47	1245.27	1220.41	1197.22	1175.21	1154.54	1134.94;
    1478.45	1433.74	1395.10	1360.79	1328.92	1299.31	1271.38	1245.08	1220.18	1196.95	1174.88	1153.95	1134.08;
    1478.45	1433.74	1395.10	1360.79	1328.92	1299.31	1271.38	1245.03	1220.08	1196.82	1174.72	1153.78	1133.87;
    1478.45	1433.74	1395.10	1360.79	1328.92	1299.31	1271.38	1245.03	1220.04	1196.76	1174.65	1153.70	1133.78;   
]

cmap = (:viridis, 1)
s = surface!(axs,(x) ,y , zcase1_6 , color = zcase1_6, colormap=cmap)
wireframe!(axs,(x), y, zcase1_6, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])


zcase2_8 = [
    1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69;
    1789.69	1733.65	1688.62	1651.82	1627.22	1606.80	1589.03	1573.57	1559.52	1546.90	1536.66	1528.68	1523.34;
    1789.69	1733.65	1685.90	1644.17	1606.02	1571.62	1540.04	1516.04	1494.46	1474.97	1456.47	1439.37	1423.38;
    1789.69	1733.65	1685.90	1643.02	1604.39	1568.26	1534.11	1502.40	1472.57	1445.51	1422.51	1401.71	1381.85;
    1789.69	1733.65	1685.90	1643.02	1603.75	1567.38	1532.95	1500.39	1469.66	1440.98	1414.16	1388.88	1364.94;
    1789.69	1733.65	1685.90	1643.02	1603.75	1567.12	1532.54	1499.85	1469.02	1439.89	1412.50	1386.85	1362.27;
    1789.69	1733.65	1685.90	1643.02	1603.75	1567.12	1532.44	1499.71	1468.79	1439.61	1412.16	1386.19	1361.29;
    1789.69	1733.65	1685.90	1643.02	1603.75	1567.12	1532.44	1499.68	1468.76	1439.54	1412.04	1386.04	1361.05;
    1789.69	1733.65	1685.90	1643.02	1603.75	1567.12	1532.44	1499.68	1468.74	1439.52	1412.00	1385.97	1360.95;         
]

cmap = (:viridis, 1)
s = surface!(axs,(x) ,y , zcase2_8 , color = zcase2_8, colormap=cmap)
wireframe!(axs,(x), y, zcase2_8, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])

save("figure1a.png", f)


##########################################################################################################################

f = Figure(resolution=(1200, 800), fontsize=26)
axs =Axis3(f[1,1]; title = "System EENS, ESS at bus 8", 
xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
zlabel = "EENS (MWh/y)",
azimuth = 4.5π/6,
perspectiveness=0.0,
elevation=π/8,
zlabeloffset=90,
xlabeloffset=60,
ylabeloffset=60,
xticks = WilkinsonTicks(6; k_min = 4),
yticks = WilkinsonTicks(6; k_min = 4),
zticks = WilkinsonTicks(6; k_min = 4),
#aspect = (1,1,0.75)
#aspect = :data
)

#cmap = (Reverse(:Spectral_11), 0.9)
cmap = (:gray1, 1.0)
s = surface!(axs,(x) ,y , zbase_6 , color = zbase_6, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, zbase_6, shading=false, color = :black, linewidth=0.5, overdraw=true, transparency=false)
#xmin, ymin, zmin = minimum(axs.finallimits[])
#xmax, ymax, zmax = maximum(axs.finallimits[])
#contourf!(axs, x, y, zbase_6; colormap=cmap,transformation=(:xy, zmin))
#rowgap!(f.layout, 50)
#Colorbar(f[2, 1], s, width=Relative(0.8), flipaxis = false, vertical = false)
#Colorbar(f[2, 1], s, width=Relative(0.5), flipaxis = false, vertical = false)

zcase1_8 = [
    1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45;
    1478.45	1432.21	1394.24	1363.51	1342.67	1325.31	1310.77	1298.07	1286.63	1276.38	1268.27	1261.72	1257.36;
    1478.45	1432.21	1392.38	1357.79	1325.81	1297.15	1271.18	1251.03	1232.91	1216.56	1201.17	1187.23	1174.23;
    1478.45	1432.21	1392.38	1357.03	1324.67	1294.64	1266.46	1240.39	1215.76	1193.58	1174.52	1157.41	1140.98;
    1478.45	1432.21	1392.38	1357.03	1324.26	1294.02	1265.66	1238.89	1213.51	1190.13	1168.05	1147.28	1127.96;
    1478.45	1432.21	1392.38	1357.03	1324.26	1293.86	1265.35	1238.50	1213.05	1189.29	1166.75	1145.64	1125.64;
    1478.45	1432.21	1392.38	1357.03	1324.26	1293.86	1265.28	1238.33	1212.83	1189.03	1166.45	1145.10	1124.86;
    1478.45	1432.21	1392.38	1357.03	1324.26	1293.86	1265.28	1238.30	1212.76	1188.94	1166.34	1144.98	1124.72;
    1478.45	1432.21	1392.38	1357.03	1324.26	1293.86	1265.28	1238.30	1212.75	1188.92	1166.31	1144.95	1124.68;       
]

cmap = (:viridis, 1)
s = surface!(axs,(x) ,y , zcase1_8 , color = zcase1_8, colormap=cmap)
wireframe!(axs,(x), y, zcase1_8, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])


zcase2_8 = [
    1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69;
    1789.69	1733.62	1688.57	1651.74	1627.15	1606.73	1588.98	1573.53	1559.49	1546.87	1536.63	1528.65	1523.31;
    1789.69	1733.62	1685.85	1644.11	1605.94	1571.53	1539.95	1515.96	1494.38	1474.89	1456.40	1439.32	1423.34;
    1789.69	1733.62	1685.85	1642.96	1604.32	1568.17	1534.02	1502.31	1472.48	1445.43	1422.44	1401.64	1381.78;
    1789.69	1733.62	1685.85	1642.96	1603.67	1567.29	1532.85	1500.30	1469.57	1440.89	1414.07	1388.79	1364.86;
    1789.69	1733.62	1685.85	1642.96	1603.67	1567.03	1532.44	1499.75	1468.92	1439.80	1412.40	1386.76	1362.18;
    1789.69	1733.62	1685.85	1642.96	1603.67	1567.03	1532.34	1499.61	1468.70	1439.52	1412.06	1386.10	1361.20;
    1789.69	1733.62	1685.85	1642.96	1603.67	1567.03	1532.34	1499.58	1468.66	1439.44	1411.94	1385.94	1360.95;
    1789.69	1733.62	1685.85	1642.96	1603.67	1567.03	1532.34	1499.58	1468.65	1439.43	1411.91	1385.88	1360.86;         
]

cmap = (:viridis, 1)
s = surface!(axs,(x) ,y , zcase2_8 , color = zcase2_8, colormap=cmap)
wireframe!(axs,(x), y, zcase2_8, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])


save("figure1b.png", f)


##########################################################################################################################

zcase1_9 = [
    1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45;
    1478.45	1433.75	1396.93	1367.17	1347.17	1330.49	1316.53	1304.37	1293.38	1283.47	1275.68	1269.41	1265.27;
    1478.45	1433.75	1395.12	1361.58	1330.50	1302.63	1277.34	1257.84	1240.33	1224.53	1209.63	1196.13	1183.55;
    1478.45	1433.75	1395.12	1360.83	1329.38	1300.14	1272.65	1247.24	1223.22	1201.62	1183.11	1166.46	1150.45;
    1478.45	1433.75	1395.12	1360.83	1328.97	1299.53	1271.86	1245.75	1220.98	1198.18	1176.64	1156.32	1137.41;
    1478.45	1433.75	1395.12	1360.83	1328.97	1299.37	1271.55	1245.36	1220.51	1197.33	1175.33	1154.68	1135.09;
    1478.45	1433.75	1395.12	1360.83	1328.97	1299.37	1271.46	1245.17	1220.28	1197.06	1175.00	1154.09	1134.23;
    1478.45	1433.75	1395.12	1360.83	1328.97	1299.37	1271.46	1245.11	1220.18	1196.93	1174.78	1153.91	1134.02;
    1478.45	1433.75	1395.12	1360.83	1328.97	1299.37	1271.46	1245.11	1220.14	1196.87	1174.78	1153.84	1133.93;     
]

zcase2_9 = [
    1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69;
    1789.69	1733.64	1688.60	1651.78	1627.19	1606.79	1589.03	1573.58	1559.54	1546.92	1536.68	1528.70	1523.36;
    1789.69	1733.64	1685.88	1644.14	1605.98	1571.57	1539.98	1516.00	1494.42	1474.95	1456.46	1439.37	1423.40;
    1789.69	1733.64	1685.88	1642.99	1604.35	1568.21	1534.06	1502.34	1472.52	1445.47	1422.48	1401.69	1381.85;
    1789.69	1733.64	1685.88	1642.99	1603.70	1567.32	1532.88	1500.33	1469.61	1440.93	1414.12	1388.86	1364.93;
    1789.69	1733.64	1685.88	1642.99	1603.70	1567.06	1532.48	1499.79	1468.96	1439.84	1412.45	1386.82	1362.25;
    1789.69	1733.64	1685.88	1642.99	1603.70	1567.06	1532.38	1499.65	1468.73	1439.56	1412.11	1386.16	1361.28;
    1789.69	1733.64	1685.88	1642.99	1603.70	1567.06	1532.38	1499.62	1468.70	1439.48	1412.00	1386.01	1361.03;
    1789.69	1733.64	1685.88	1642.99	1603.70	1567.06	1532.38	1499.62	1468.68	1439.47	1411.96	1385.94	1360.94;      
]


f = Figure(resolution=(1200, 800), fontsize=26)
axs =Axis3(f[1,1]; title = "System EENS, ESS at bus 9", 
xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
zlabel = "EENS (MWh/y)",
azimuth = 4.5π/6,
perspectiveness=0.0,
elevation=π/8,
zlabeloffset=90,
xlabeloffset=60,
ylabeloffset=60,
xticks = WilkinsonTicks(6; k_min = 4),
yticks = WilkinsonTicks(6; k_min = 4),
zticks = WilkinsonTicks(6; k_min = 4),
#aspect = (1,1,0.75)
#aspect = :data
)

#cmap = (Reverse(:Spectral_11), 0.9)
cmap = (:gray1, 1.0)
s = surface!(axs,(x) ,y , zbase_6 , color = zbase_6, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, zbase_6, shading=false, color = :black, linewidth=0.5, overdraw=true, transparency=false)
#xmin, ymin, zmin = minimum(axs.finallimits[])
#xmax, ymax, zmax = maximum(axs.finallimits[])
#contourf!(axs, x, y, zbase_6; colormap=cmap,transformation=(:xy, zmin))
#rowgap!(f.layout, 50)
#Colorbar(f[2, 1], s, width=Relative(0.8), flipaxis = false, vertical = false)
#Colorbar(f[2, 1], s, width=Relative(0.5), flipaxis = false, vertical = false)

cmap = (:viridis, 1)
s = surface!(axs,(x) ,y , zcase1_9 , color = zcase1_9, colormap=cmap)
wireframe!(axs,(x), y, zcase1_9, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])


cmap = (:viridis, 1)
s = surface!(axs,(x) ,y , zcase2_9 , color = zcase2_9, colormap=cmap)
wireframe!(axs,(x), y, zcase2_9, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])


save("figure1c.png", f)




##########################################################################################################################

zcase1_10 = [
    1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45	1478.45;
    1478.45	1433.75	1396.93	1367.17	1347.17	1330.49	1316.53	1304.37	1293.38	1283.47	1275.68	1269.41	1265.27;
    1478.45	1433.75	1395.12	1361.58	1330.50	1302.63	1277.34	1257.84	1240.33	1224.53	1209.63	1196.13	1183.55;
    1478.45	1433.75	1395.12	1360.83	1329.38	1300.14	1272.65	1247.24	1223.22	1201.62	1183.11	1166.46	1150.45;
    1478.45	1433.75	1395.12	1360.83	1328.97	1299.53	1271.86	1245.75	1220.98	1198.18	1176.64	1156.32	1137.41;
    1478.45	1433.75	1395.12	1360.83	1328.97	1299.37	1271.55	1245.36	1220.51	1197.33	1175.33	1154.68	1135.09;
    1478.45	1433.75	1395.12	1360.83	1328.97	1299.37	1271.46	1245.17	1220.28	1197.06	1175.00	1154.09	1134.23;
    1478.45	1433.75	1395.12	1360.83	1328.97	1299.37	1271.46	1245.11	1220.18	1196.93	1174.78	1153.91	1134.02;
    1478.45	1433.75	1395.12	1360.83	1328.97	1299.37	1271.46	1245.11	1220.14	1196.87	1174.78	1153.84	1133.93;     
]

zcase2_10 = [
    1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69	1789.69;
    1789.69	1733.64	1688.60	1651.78	1627.19	1606.79	1589.02	1573.56	1559.51	1546.90	1536.65	1528.67	1523.34;
    1789.69	1733.65	1685.90	1644.17	1606.01	1571.61	1540.02	1516.03	1494.44	1474.96	1456.45	1439.36	1423.37;
    1789.69	1733.65	1685.90	1643.02	1604.39	1568.25	1534.09	1502.38	1472.55	1445.50	1422.50	1401.70	1381.84;
    1789.69	1733.65	1685.90	1643.02	1603.74	1567.36	1532.92	1500.37	1469.64	1440.96	1414.14	1388.86	1364.91;
    1789.69	1733.65	1685.90	1643.02	1603.74	1567.10	1532.51	1499.82	1468.99	1439.87	1412.47	1386.82	1362.24;
    1789.69	1733.65	1685.90	1643.02	1603.74	1567.10	1532.42	1499.69	1468.77	1439.59	1412.13	1386.16	1361.26;
    1789.69	1733.65	1685.90	1643.02	1603.74	1567.10	1532.42	1499.65	1468.73	1439.51	1412.01	1386.01	1361.02;
    1789.69	1733.65	1685.90	1643.02	1603.74	1567.10	1532.42	1499.65	1468.72	1439.50	1411.97	1385.94	1360.92;      
]


f = Figure(resolution=(1200, 800), fontsize=26)
axs =Axis3(f[1,1]; title = "System EENS, ESS at bus 10", 
xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
zlabel = "EENS (MWh/y)",
azimuth = 4.5π/6,
perspectiveness=0.0,
elevation=π/8,
zlabeloffset=90,
xlabeloffset=60,
ylabeloffset=60,
xticks = WilkinsonTicks(6; k_min = 4),
yticks = WilkinsonTicks(6; k_min = 4),
zticks = WilkinsonTicks(6; k_min = 4),
#aspect = (1,1,0.75)
#aspect = :data
)

#cmap = (Reverse(:Spectral_11), 0.9)
cmap = (:gray1, 1.0)
s = surface!(axs,(x) ,y , zbase_6 , color = zbase_6, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, zbase_6, shading=false, color = :black, linewidth=0.5, overdraw=true, transparency=false)
#xmin, ymin, zmin = minimum(axs.finallimits[])
#xmax, ymax, zmax = maximum(axs.finallimits[])
#contourf!(axs, x, y, zbase_6; colormap=cmap,transformation=(:xy, zmin))
#rowgap!(f.layout, 50)
#Colorbar(f[2, 1], s, width=Relative(0.8), flipaxis = false, vertical = false)
#Colorbar(f[2, 1], s, width=Relative(0.5), flipaxis = false, vertical = false)

cmap = (:viridis, 1)
s = surface!(axs,(x) ,y , zcase1_10 , color = zcase1_10, colormap=cmap)
wireframe!(axs,(x), y, zcase1_10, shading=false, color = :black, linewidth=0.7, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])


cmap = (:viridis, 1)
s = surface!(axs,(x) ,y , zcase2_10 , color = zcase2_10, colormap=cmap)
wireframe!(axs,(x), y, zcase2_10, shading=false, color = :black, linewidth=0.7, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])


save("figure1d.png", f)



#################################################

zbase_6 =[
    12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50;
    12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50;
    12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50;
    12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50;
    12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50;
    12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50;
    12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50;
    12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50;
    12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50	12.50;     
]

f = Figure(resolution=(1200, 800), fontsize=26)
axs =Axis3(f[1,1]; title = "System EDLC, ESS at bus 8", 
            xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
            zlabel = "EDLC (hours/y)",
            azimuth = 4.5π/6,
            perspectiveness=0.0,
            elevation=π/8,
            zlabeloffset=90,
            xlabeloffset=60,
            ylabeloffset=60,
            xticks = WilkinsonTicks(6; k_min = 4),
            yticks = WilkinsonTicks(6; k_min = 4),
            zticks = WilkinsonTicks(6; k_min = 4),
            #aspect = (1,1,0.75)
            #aspect = :data
)

#cmap = (Reverse(:Spectral_11), 0.9)
cmap = (:gray1, 1.0)
s = surface!(axs,(x) ,y , zbase_6 , color = zbase_6, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, zbase_6, shading=false, color = :black, linewidth=0.5, overdraw=true, transparency=false)
#xmin, ymin, zmin = minimum(axs.finallimits[])
#xmax, ymax, zmax = maximum(axs.finallimits[])
#contourf!(axs, x, y, zbase_6; colormap=cmap,transformation=(:xy, zmin))
#rowgap!(f.layout, 50)
#Colorbar(f[2, 1], s, width=Relative(0.8), flipaxis = false, vertical = false)
#Colorbar(f[2, 1], s, width=Relative(0.5), flipaxis = false, vertical = false)

zcase1_6 = [
    13.36	13.36	13.36	13.36	13.36	13.36	13.36	13.36	13.36	13.36	13.36	13.36	13.36;
    13.36	12.44	12.22	12.08	11.90	11.83	11.77	11.66	11.63	11.62	11.61	11.60	11.60;
    13.36	12.44	11.77	11.45	11.24	11.05	10.93	10.78	10.65	10.59	10.52	10.46	10.37;
    13.36	12.44	11.77	11.20	10.89	10.58	10.40	10.26	10.09	9.99	9.84	9.75	9.66;
    13.36	12.44	11.77	11.20	10.69	10.37	10.10	9.87	9.69	9.55	9.41	9.28	9.17;
    13.36	12.44	11.77	11.20	10.70	10.24	9.96	9.70	9.45	9.24	9.08	8.95	8.82;
    13.36	12.44	11.77	11.20	10.70	10.24	9.90	9.63	9.37	9.16	8.95	8.77	8.61;
    13.36	12.44	11.77	11.20	10.70	10.24	9.90	9.61	9.35	9.13	8.93	8.74	8.57;
    13.36	12.44	11.77	11.20	10.70	10.24	9.90	9.62	9.34	9.12	8.91	8.72	8.56  ;  
]

cmap = (Reverse(:Spectral_11), 1)
s = surface!(axs,(x) ,y , zcase1_6 , color = zcase1_6, colormap=cmap)
wireframe!(axs,(x), y, zcase1_6, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])


zcase2_8 = [
    15.48	15.48	15.48	15.48	15.48	15.48	15.48	15.48	15.48	15.48	15.48	15.48	15.48;
    15.48	14.35	14.12	13.95	13.74	13.68	13.62	13.50	13.48	13.47	13.45	13.44	13.43;
    15.48	14.35	13.57	13.23	12.99	12.81	12.70	12.50	12.38	12.30	12.23	12.15	12.07;
    15.48	14.35	13.57	12.91	12.56	12.23	12.07	11.89	11.73	11.60	11.42	11.30	11.20;
    15.48	14.35	13.57	12.91	12.28	11.95	11.66	11.37	11.20	11.04	10.87	10.71	10.55;
    15.48	14.35	13.57	12.91	12.28	11.81	11.50	11.20	10.90	10.63	10.45	10.29	10.11;
    15.48	14.35	13.57	12.91	12.28	11.81	11.41	11.09	10.79	10.52	10.29	10.07	9.87;
    15.48	14.35	13.57	12.91	12.28	11.81	11.41	11.02	10.72	10.44	10.20	9.97	9.76;
    15.48	14.35	13.57	12.91	12.28	11.81	11.41	11.02	10.67	10.39	10.15	9.92	9.70 ;          
]

cmap = (Reverse(:Spectral_11), 1)
s = surface!(axs,(x) ,y , zcase2_8 , color = zcase2_8, colormap=cmap)
wireframe!(axs,(x), y, zcase2_8, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])

save("figure4.png", f)