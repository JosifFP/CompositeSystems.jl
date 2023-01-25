%% MATPOWER Case Format
function mpc = RBTS

%%-----  Reliability Data  -----%%

%% generator reliability data
%	bus	pmax	state_model	λ_updn	μ_updn	λ_upde	μ_upde pde
mpc.gen = [
	1	40	2	6.0		194.0	0	0	0
	1	40	2	6.0		194.0	0	0	0
	1	10	2	4.0		196.0	0	0	0
	1	20	2	5.0		195.0	0	0	0
	2	5	2	2.0		198.0	0	0	0
	2	5	2	2.0		198.0	0	0	0
	2	40	2	3.0		147.0	0	0	0
	2	20	2	2.4		157.6	0	0	0
	2	20	2	2.4		157.6	0	0	0
	2	20	2	2.4		157.6	0	0	0
	2	20	2	2.4		157.6	0	0	0
];

%% branch reliability data
%    f_bus	t_bus	λ_updn	μ_updn common_mode λ_common μ_common
mpc.branch = [
	1	3	1.5	876	0	0.00	0.00;
	2	4	5.0	876	0	0.00	0.00;	
	2	1	4.0	876	0	0.00	0.00;			
	3	4	1.0	876	0	0.00	0.00;
	3	5	1.0	876	0	0.00	0.00;
	1	3	1.5	876	0	0.00	0.00;
	2	4	5.0	876	0	0.00	0.00;
	4	5	1.0 876	0	0.00	0.00;
	5	6	1.0 876	0	0.00	0.00;
];

%% load data
%  bus_i  cost
mpc.load = [		
	2	7410
	3	2690
	4	6780	
	5	4820
	6	3630		
];