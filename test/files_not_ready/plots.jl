using GLMakie, ColorSchemes

y = [0,	25,	50,	75,	100, 125,	150,	175,	200,	225,	250,	275,	300]
x = [0,	25,	50,	75,	100, 125,	150,	175,	200]

z =[
1404.980103    1404.980103 1404.980103 1404.980103	1404.980103	1404.980103	1404.980103	1404.980103	1404.980103	1404.980103	1404.980103	1404.980103	1404.980103;
1404.980103	1361.23792	1325.38418	1296.18462	    1277.35545	1261.90584	1249.0229	1237.44567	1227.04338	1217.76585	1210.07883	1204.02397	1199.95832;
1404.980103	1361.23792	1323.23144	1290.49948	    1259.95943	1232.5271	1207.74093	1189.56512	1173.3522	1158.75798	1145.05265	1132.55542	1120.66759;
1404.980103	1361.23792	1323.23144	1289.62348	    1258.77224	1229.95725	1203.03495	1178.33531	1155.21264	1134.73358	1117.53197	1102.17789	1087.63765;
1404.980103	1361.23792	1323.23144	1289.62348	    1258.33536	1229.34924	1202.19533	1176.72966	1152.8801	1131.14771	1110.81109	1091.66355	1074.15376;
1404.980103	1361.23792	1323.23144	1289.62348	    1258.33536	1229.17159	1201.91394	1176.32439	1152.37163	1130.24411	1109.53045	1090.10296	1071.8499;
1404.980103	1361.23792	1323.23144	1289.62348	    1258.33536	1229.17159	1201.85563	1176.1927	1152.14319	1129.95124	1109.17714	1089.51559	1070.99075;
1404.980103	1361.23792	1323.23144	1289.62348	    1258.33536	1229.17159	1201.85563	1176.16925	1152.0932	1129.85886	1109.03707	1089.32767	1070.75047;
1404.980103	1361.23792	1323.23144	1289.62348	    1258.33536	1229.17159	1201.85563	1176.16925	1152.0932	1129.85308	1109.02764	1089.28074	1070.65522]

f = Figure(resolution=(1200, 800), fontsize=20)
axs =Axis3(f[1,1]; title = "ESS at bus 8", 
            xlabel = "Power Rating (MW)", ylabel = "Energy Rating (MWh)", 
            zlabel = "EENS (MWh/y)",
            azimuth = π/4,
            perspectiveness=0.0,
            elevation=π/6,
            zlabeloffset=75,
            xlabeloffset=50,
            ylabeloffset=50,
            xticks = WilkinsonTicks(6; k_min = 4),
            yticks = WilkinsonTicks(6; k_min = 4),
            zticks = WilkinsonTicks(6; k_min = 3),
            #aspect = (1,1,0.75)
            #aspect = :data
)

#cmap = (Reverse(:Spectral_11), 0.9)
cmap = (:viridis, 0.9)
s = surface!(axs,(x) ,y , z , color = z, colormap=cmap)
#contour3d!(axs, x, y, z .+ 0.02; levels=20, linewidth=2)
wireframe!(axs,(x), y, z, shading=false, color = :black, linewidth=0.7, overdraw=true, transparency=true)
xmin, ymin, zmin = minimum(axs.finallimits[])
xmax, ymax, zmax = maximum(axs.finallimits[])
#contour!(axs, x, y, z; colormap=:Spectral_11, levels=20,transformation=(:xy, zmax))
contourf!(axs, x, y, z; colormap=cmap,transformation=(:xy, zmin))
Colorbar(f[1, 2], s, width=15, ticksize=15, height=Relative(0.5), label = "EENS (MWh/y)", flipaxis = false)




surface(x, y, z, axis=(type=Axis3,), shading=true, colormap = :watermelon)
surface(x, y, z, axis=(type=Axis3,), shading=true, colormap = :sunset)
surface(x, y, z, axis=(type=Axis3,), shading=true, colormap = :seaborn_rocket_gradient)
wireframe(x, y, z, axis=(type=Axis3,), shading=true, color = :black, colormap = :viridis)
contour(z, alpha=0.5)