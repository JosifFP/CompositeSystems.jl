import CompositeSystems
import CompositeSystems.BaseModule
import CompositeSystems.OPF
import CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, BenchmarkTools, JuMP, Dates
import JuMP: termination_status
import BenchmarkTools: @btime
import Gurobi
import Distributed
using Test


#UNINSTALL THIS PACKAGES AFTER DONE WITH PLOTS
using GLMakie, ColorSchemes

x = [25,	50, 75, 100, 125, 150]
y = [150, 175,	200, 225, 250,	275, 300, 325, 350, 375, 400]


################################################################################################################################################################################
z_075 =[
1625.92	1608.90	1593.71	1580.13	1569.21	1560.50	1554.95	1551.15	1548.93	1547.27	1546.03;
1579.11	1554.12	1531.15	1509.98	1489.81	1471.40	1453.99	1437.74	1422.21	1407.82	1394.01;
1573.37	1540.92	1510.35	1482.48	1458.56	1436.39	1415.11	1395.00	1375.75	1357.21	1339.74;
1572.04	1538.78	1507.35	1477.91	1450.10	1423.87	1399.26	1376.80	1355.43	1334.78	1314.82;
1571.50	1538.04	1506.48	1476.57	1448.32	1421.75	1396.39	1372.24	1351.58	1327.26	1306.05;
1571.34	1537.82	1506.09	1476.08	1447.74	1420.94	1395.33	1370.95	1347.73	1325.40	1303.75;
]

z_050 =[
   2171.54	2148.09	2126.86	2107.55	2092.06	2079.44	2071.46	2065.92	2062.46	2059.97	2058.16;
   2113.17	2079.46	2048.39	2019.77	1992.58	1967.35	1943.27	1920.78	1899.03	1878.68	1859.24;
   2105.83	2063.10	2022.30	1985.18	1952.71	1922.76	1894.04	1866.95	1840.74	1815.46	1790.19;
   2104.34	2060.33	2018.45	1979.39	1942.56	1907.38	1874.18	1843.67	1814.72	1786.92	1760.06;
   2103.80	2059.52	2017.36	1977.64	1940.29	1904.72	1870.68	1838.20	1806.96	1776.99	1748.28;
   2103.61	2059.21	2016.86	1976.96	1939.41	1903.52	1869.15	1836.40	1804.89	1774.53	1745.07;   
]

z_unsolved =[
   1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95;
   1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95;
   1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95;
   1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95;
   1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95;
   1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95	1831.95;   
]

z_solved =[
   1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01;
   1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01;
   1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01;
   1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01;
   1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01;
   1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01	1442.01;      
]


f = Figure(resolution=(1200, 800), fontsize=26)
axs =Axis3(f[1,1]; title = "System EENS, SATA at bus 8", 
            xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
            zlabel = "EENS (MWh/y)",
            azimuth = 4.5π/6,
            perspectiveness=0.0,
            elevation=π/8,
            zlabeloffset=90,
            xlabeloffset=60,
            ylabeloffset=60,
            xticks = WilkinsonTicks(6;  k_max = 6, k_min = 6),
            yticks = WilkinsonTicks(6; k_min = 5),
            zticks = WilkinsonTicks(6; k_min = 4),
            #aspect = (1,1,0.75)
            #aspect = :data
)

#cmap = (Reverse(:Spectral_11), 0.9)
cmap = (:gray1, 1.0)
s = surface!(axs,(x) ,y , z_solved , color = z_solved, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, z_solved, shading=false, color = :black, linewidth=0.5, overdraw=true, transparency=false)
#xmin, ymin, zmin = minimum(axs.finallimits[])
#xmax, ymax, zmax = maximum(axs.finallimits[])
#contourf!(axs, x, y, z_solved; colormap=cmap,transformation=(:xy, zmin))
#rowgap!(f.layout, 50)
#Colorbar(f[2, 1], s, width=Relative(0.8), flipaxis = false, vertical = false)
#Colorbar(f[2, 1], s, width=Relative(0.5), flipaxis = false, vertical = false)

#cmap = (:viridis, 1)
cmap = (Reverse(:Spectral_11), 1)
s = surface!(axs,(x) ,y , z_075 , color = z_075, colormap=cmap)
wireframe!(axs,(x), y, z_075, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])


cmap = (Reverse(:Spectral_11), 1)
s = surface!(axs,(x) ,y , z_050 , color = z_050, colormap=cmap)
wireframe!(axs,(x), y, z_050, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])

save("figure_2.png", f)

################################################################################################################################################################################


z_075 =[
   14.08	13.96	13.93	13.91	13.90	13.88	13.87	13.85	13.85	13.84	13.84;
   13.13	12.94	12.82	12.74	12.66	12.59	12.49	12.39	12.28	12.24	12.22;
   12.48	12.29	12.13	12.01	11.83	11.72	11.62	11.54	11.47	11.39	11.31;
   12.08	11.78	11.61	11.44	11.26	11.09	10.93	10.82	10.72	10.62	10.51;
   11.93	11.61	11.33	11.06	10.86	10.69	10.51	10.31	10.18	10.05	9.95;
   11.83	11.49	11.21	10.92	10.67	10.46	10.26	10.04	9.88	9.73	9.60;
]

z_050 =[
   18.02	17.86	17.83	17.82	17.79	17.75	17.74	17.71	17.70	17.69	17.69;
   16.80	16.55	16.37	16.27	16.16	16.08	15.96	15.84	15.68	15.60	15.58;
   15.96	15.73	15.51	15.35	15.14	14.97	14.84	14.73	14.62	14.52	14.42;
   15.42	15.05	14.82	14.57	14.36	14.14	13.95	13.80	13.66	13.49	13.36;
   15.23	14.83	14.45	14.08	13.85	13.63	13.41	13.17	12.97	12.80	12.64;
   15.09	14.67	14.26	13.89	13.60	13.32	13.06	12.80	12.57	12.36	12.15;   
]

z_solved =[
   12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83;
   12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83;
   12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83;
   12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83;
   12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83;
   12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83	12.83;     
]

f = Figure(resolution=(1200, 800), fontsize=26)
axs =Axis3(f[1,1]; title = "System EDLC, SATA at bus 8", 
            xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
            zlabel = "EDLC (Hrs/y)",
            azimuth = 4.5π/6,
            perspectiveness=0.0,
            elevation=π/8,
            zlabeloffset=90,
            xlabeloffset=60,
            ylabeloffset=60,
            xticks = WilkinsonTicks(6;  k_max = 6, k_min = 6),
            yticks = WilkinsonTicks(6; k_min = 5),
            zticks = WilkinsonTicks(6; k_min = 4),
            #aspect = (1,1,0.75)
            #aspect = :data
)

#cmap = (Reverse(:Spectral_11), 0.9)
cmap = (:gray1, 1.0)
s = surface!(axs,(x) ,y , z_solved , color = z_solved, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, z_solved, shading=false, color = :black, linewidth=0.5, overdraw=true, transparency=false)
#xmin, ymin, zmin = minimum(axs.finallimits[])
#xmax, ymax, zmax = maximum(axs.finallimits[])
#contourf!(axs, x, y, z_solved; colormap=cmap,transformation=(:xy, zmin))
#rowgap!(f.layout, 50)
#Colorbar(f[2, 1], s, width=Relative(0.8), flipaxis = false, vertical = false)
#Colorbar(f[2, 1], s, width=Relative(0.5), flipaxis = false, vertical = false)

#cmap = (:viridis, 1)
cmap = (Reverse(:Spectral_11), 1)
s = surface!(axs,(x) ,y , z_075 , color = z_075, colormap=cmap)
wireframe!(axs,(x), y, z_075, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])


cmap = (Reverse(:Spectral_11), 1)
s = surface!(axs,(x) ,y , z_050 , color = z_050, colormap=cmap)
wireframe!(axs,(x), y, z_050, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])

save("figure_3.png", f)



################################################################################################################################################################################


z_1 =[
   18	20	21	22	24	25	25	25	26	26	26;
   22	25	27	29	31	33	35	37	38	40	42;
   22	25	28	31	34	37	39	41	43	45	47;
   23	26	29	32	35	38	40	43	45	48	50;
   23	26	29	32	35	38	40	43	45	48	50;
   23	26	29	32	35	38	40	43	45	48	50;
]


f = Figure(resolution=(1200, 800), fontsize=26)
axs =Axis3(f[1,1]; title = "Expected Load-Carrying Capability", 
            xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
            zlabel = "ELCC (MW)",
            azimuth = 4.5π/6,
            perspectiveness=0.0,
            elevation=π/8,
            zlabeloffset=90,
            xlabeloffset=60,
            ylabeloffset=60,
            xticks = WilkinsonTicks(6;  k_max = 6, k_min = 6),
            yticks = WilkinsonTicks(6; k_min = 5),
            zticks = WilkinsonTicks(6; k_min = 4),
            #aspect = (1,1,0.75)
            #aspect = :data
)

cmap = (:viridis, 1)
s = surface!(axs,(x) ,y , z_1 , color = z_1, colormap=cmap)
wireframe!(axs,(x), y, z_1, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])


#contourf!(axs, x, y, z_1; colormap=cmap,transformation=(:xy, zmin))
#rowgap!(f.layout, 25)
#Colorbar(f[2, 1], s, width=Relative(0.8), flipaxis = false, vertical = false)
Colorbar(f[2, 1], s, width=Relative(0.6), flipaxis = false, vertical = false)

save("figure_4.png", f)


################################################################################################################################################################################
z_1 =[
   18	20	21	22	24	25	25	25	26	26	26;
   22	25	27	29	31	33	35	37	38	40	42;
   22	25	28	31	34	37	39	41	43	45	47;
   23	26	29	32	35	38	40	43	45	48	50;
   23	26	29	32	35	38	40	43	45	48	50;
   23	26	29	32	35	38	40	43	45	48	50;
]


z_2 =[
   36	36	36	36	36	36	36	36	36	36	36;
   36	36	36	36	36	36	36	36	36	36	36;
   36	36	36	36	36	36	36	36	36	36	36;
   36	36	36	36	36	36	36	36	36	36	36;
   36	36	36	36	36	36	36	36	36	36	36;
   36	36	36	36	36	36	36	36	36	36	36 ;      
]


f = Figure(resolution=(1200, 800), fontsize=26)
axs =Axis3(f[1,1]; title = "Expected Load-Carrying Capability", 
            xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
            zlabel = "ELCC (MW)",
            azimuth = 4.5π/6,
            perspectiveness=0.0,
            elevation=π/8,
            zlabeloffset=90,
            xlabeloffset=60,
            ylabeloffset=60,
            xticks = WilkinsonTicks(6;  k_max = 6, k_min = 6),
            yticks = WilkinsonTicks(6; k_min = 5),
            zticks = WilkinsonTicks(6; k_min = 4),
            #aspect = (1,1,0.75)
            #aspect = :data
)

cmap = (:gray1, 0.2)
s = surface!(axs,(x) ,y , z_2 , color = z_2, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, z_2, shading=false, color = :black, linewidth=0.5, overdraw=true, transparency=false)

cmap = (:viridis, 1)
s = surface!(axs,(x) ,y , z_1 , color = z_1, colormap=cmap)
wireframe!(axs,(x), y, z_1, shading=false, color = :black, linewidth=0.5, overdraw=false, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])


#contourf!(axs, x, y, z_1; colormap=cmap,transformation=(:xy, zmin))
#rowgap!(f.layout, 25)
#Colorbar(f[2, 1], s, width=Relative(0.8), flipaxis = false, vertical = false)
Colorbar(f[2, 1], s, width=Relative(0.6), flipaxis = false, vertical = false)

save("figure_4b.png", f)