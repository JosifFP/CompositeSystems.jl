% TO BE COMPLETED , FOLLOW DATA% TO BE COMPLETED , FOLLOW DATA https://www.collectionscanada.gc.ca/obj/s4/f2/dsk3/SSU/TC-SSU-10022003214447.pdf

% RBTS Roy Billinton Test system Feeder Network case to test no explicit branch limits.
"The RBTS is a six-bus composite system developed at the University of Saskatechewan for educational purpose. 
It is sufficiently small to permit the conduct of a large number of reliability studies with reasonable solution
time but sufficiently detailed to reflect the actual complexities involved in practical reliability analysis and 
can be used to examine a newly developed technique or method"

% Total installed capacity = 240 MW
% System peak load = 185 MW

%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%bus_i	type Pd		 Qd		 Gs		 Bs		area	Vm		Va	baseKV	zone	Vmax		Vmin
mpc.bus = [
	1	 3	 0.0	 0.0	 0.0	 0.0	 1	    1.05	0.0	 230.0	 1	    1.05	    0.97;
	2	 2	 20.0	 4.0	 0.0	 0.0	 1	    1.05	0.0	 230.0	 2	    1.05	    0.97;
	3	 1	 85.0	 17.0	 0.0	 0.0	 1	    1.00	0.0	 230.0	 3	    1.05	    0.97;
	4	 1	 40.0	 8.0	 0.0	 0.0	 1	    1.00	0.0	 230.0	 4	    1.05	    0.97;
	5	 1	 20.0	 4.0	 0.0	 0.0	 1	    1.00	0.0	 230.0	 5	    1.05	    0.97;
	6	 1	 20.0	 4.0	 0.0	 0.0	 1	    1.00	0.0	 230.0	 6	    1.05	    0.97;
];


%% generator data
%	bus	Pg		Qg		Qmax	Qmin	Vg		mBase	status	Pmax	Pmin
mpc.gen = [
	1	40.0	0.0		17		-15		1.05	100		1		40		0;	
	1	40.0	0.0		17		-15		1.05	100		1		40		0;
	1	10.0	0.0		7		0		1.05	100		1		10		0;
	1	10.0	0.0		12		-7		1.05	100		1		20		0;
	2	5.0		0.0		5		0		1.05	100		1		5		0;
	2	5.0		0.0		5		0		1.05	100		1		5		0;
	2	30.0	0.0		17		-15		1.05	100		1		40		0;	
	2	20.0	0.0		12		-7		1.05	100		1		20		0;
	2	20.0	0.0		12		-7		1.05	100		1		20		0;
	2	20.0	0.0		12		-7		1.05	100		1		20		0;
	2	20.0	0.0		12		-7		1.05	100		1		20		0;
];


%% branch data
%	fbus tbus	r		x		b	 	rateA	 rateB	 rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	1	 3	 0.0342	 0.180	 0.0212	 	89.25	 98.18	 102.64	 0.0	 0.0	 1	 -60	 60;
	2	 4	 0.1140	 0.600	 0.0704	 	74.55	 82.00	 85.73	 0.0	 0.0	 1	 -60	 60;
	2	 1	 0.0912	 0.480	 0.0564	 	74.55	 82.00	 85.73	 0.0	 0.0	 1	 -60	 60;
	3	 4	 0.0228	 0.120	 0.0142	 	74.55	 82.00	 85.73	 0.0	 0.0	 1	 -60	 60;
	3	 5	 0.0228	 0.120	 0.0142	 	74.55	 82.00	 85.73	 0.0	 0.0	 1	 -60	 60;
	3	 1	 0.0342	 0.180	 0.0212	 	89.25	 98.18	 102.64	 0.0	 0.0	 1	 -60	 60;
	4	 2	 0.1140	 0.600	 0.0704	 	74.55	 82.00	 85.73	 0.0	 0.0	 1	 -60	 60;
	4	 5	 0.0228	 0.120	 0.0142	 	74.55	 82.00	 85.73	 0.0	 0.0	 1	 -60	 60;
	5	 6	 0.0228	 0.120	 0.0142	 	74.55	 82.00	 85.73	 0.0	 0.0	 1	 -60	 60;
];



%%-----  OPF Data  -----%%
%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0		0			2	12.00	93.7797;
	2	0		0			2	12.00	93.7797;
	2	0		0			2	12.50	71.2251;
	2	0		0			2	12.25	80.7217;
	2	0		0			2	0.50	1.4839;
	2	0		0			2	0.50	1.4839;
	2	0		0			2	0.50	11.8708;
	2	0		0			2	0.50	5.9354;
	2	0		0			2	0.50	5.9354;
	2	0		0			2	0.50	5.9354;
	2	0		0			2	0.50	5.9354;
];


"%% generator reliability data
%	bus	FOR		Failure_r	Repair_r	Scheduled_m
mpc.genrel = [
	1	0.030	6.0			194.0		2;	
	1	0.030	6.0			194.0		2;
	1	0.020	4.0			196.0		2;
	1	0.025	5.0			195.0		2;
	2	0.010	2.0			198.0		2;
	2	0.010	2.0			198.0		2;
	2	0.020	3.0			147.0		2;
	2	0.015	2.4			157.6		2;
	2	0.015	2.4			157.6		2;
	2	0.015	2.4			157.6		2;
	2	0.015	2.4			157.6		2;
];

%% branch reliability data
%	fbus tbus	FOR		Failure_r	Repair_r	Scheduled_m
mpc.branchrel = [
	1	 3	  	0.00171	 	1.5			10	 		0;
	2	 4	  	0.00568	 	5.0			10	 		0;
	2	 1	  	0.00455	 	4.0			10	 		0;
	4	 3	  	0.00114	 	1.0			10	 		0;
	3	 5	  	0.00114	 	1.0			10	 		0;
	1	 3	  	0.00171	 	1.5			10	 		0;
	2	 4	  	0.00568	 	5.0			10	 		0;
	4	 5	  	0.00114	 	1.0			10	 		0;
	5	 6	  	0.00114	 	1.0			10	 		0;
];"


"FOR: Forced Outage Rate"
"Failure_r [occ/year]"
"Failure_r [hrs/year]"