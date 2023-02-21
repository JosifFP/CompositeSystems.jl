%% MATPOWER Case Format
function mpc = RBTS

%%-----  Reliability Data  -----%%

%% generator reliability data
%	bus	pmax	state_model	λ_updn	μ_updn	λ_upde	μ_upde pde
mpc.gen = [
	1	100	2	0.0		0.0	0	0	0
];

%% branch reliability data
%    f_bus	t_bus	λ_updn	μ_updn common_mode λ_common μ_common
mpc.branch = [
	1	3	0.0	0	0	0.00	0.00;
	1	2	0.0	0	0	0.00	0.00;	
	2	3	0.0	0	0	0.00	0.00;
];

%% load data
%  bus_i  cost
mpc.load = [		
	2	1000.0
	3	1.0
];