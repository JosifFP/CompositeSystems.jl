%% MATPOWER Case Format : Version 2
function mpc = toysystem
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;
%% bus data
%    bus_i	type    Pd    Qd    Gs    Bs    area    Vm    Va    baseKV    zone    Vmax    Vmin
mpc.bus = [
	1	3	0.0		0.0		0.0	0.0	1	1.05	0.0	230.0	1	1.05	0.97;		
	2	1	10.0	0.0		0.0	0.0	1	1.05	0.0	230.0	2	1.05	0.97;		
	3	1	10.0	0.0		0.0	0.0	1	1.0		0.0	230.0	3	1.05	0.97;		
];

%% generator data
%    bus    Pg    	Qg    Qmax    Qmin    Vg    mBase    status    Pmax    Pmin    Pc1    Pc2    Qc1min    Qc1max    Qc2min    Qc2max    ramp_agc    ramp_10    ramp_30    ramp_q    apf
mpc.gen = [
	1		100.0	0.0		0.0	0.0	1.05	100.0	1	100.0	0.0;												
];

%% branch data
%    f_bus    t_bus    r    x    b    rateA    rateB    rateC    ratio    angle    status    angmin    angmax
mpc.branch = [
	1	3	0.0		0.5		10.0	10.0	10.0	0.00	0	0	1	-60	60
	1	2	0.0		0.1		10.0	10.0	10.0	0.00	0	0	1	-60	60
	2	3	0.0		0.4		10.0	10.0	10.0	0.00	0	0	1	-60	60
];

%%-----  OPF Data  -----%%
%% cost data
%    1    startup    shutdown    n    x1    y1    ...    xn    yn
%    2    startup    shutdown    n    c(n-1)    ...    c0
mpc.gencost = [
	2	0.0	0.0	2	12.0	93.7797
];