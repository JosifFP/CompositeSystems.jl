%% MATPOWER Case Format
function mpc = RBTS

%%-----  Reliability Data  -----%%

%% generator reliability data
%	bus	pmax	state_model	λ_updn	μ_updn	λ_upde	μ_upde pde
mpc.gen = [
	1	40	3	4.0		192.0	2	96	0.5
	1	40	3	4.0		192.0	2	96	0.5
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
	1	3	1.5	873.6	1	0.15	547.5	
	2	4	5.0	873.6	2	0.50	547.5	
	2	1	4.0	873.6	0	0.00	0.00;			
	3	4	1.0	873.6	0	0.00	0.00;
	3	5	1.0	873.6	0	0.00	0.00;
	1	3	1.5	873.6	1	0.15	547.5;
	2	4	5.0	873.6	2	0.50	547.5;
	4	5	1.0 873.6	0	0.00	0.00;
	5	6	1.0 873.6	0	0.00	0.00;
	5	6	1.0 873.6	0	0.00	0.00;
];

%% load data
%  bus_i  cost firm_load
mpc.load = [		
	2	9632.5	1
	3	4376.9	1
	4	8026.7	1		
	5	8632.3	1	
	6	5513.2	1		
];