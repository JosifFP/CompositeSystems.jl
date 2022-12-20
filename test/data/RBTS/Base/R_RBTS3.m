%% MATPOWER Case Format : Version 2
function mpc = RBTS
mpc.version = '2';

%%-----  Reliability Data  -----%%

%% generator reliability data
%	bus	pmax	λ	mttr
mpc.gen = [
	1	40	6	45;
	1	40	6	45;
	1	10	4	45;
	1	20	5	45;
	2	5	2	45;
	2	5	2	45;
	2	40	3	60;
	2	20	2.4	55;
	2	20	2.4	55;
	2	20	2.4	55;
	2	20	2.4	55;
];

%% branch reliability data
%    f_bus	t_bus	λ	mttr common_mode common_λ common_mttr
mpc.branch = [
	1	3	1.5	10	1	0.15	16.0;	
	2	4	5.0	10	2	0.50	16.0;	
	2	1	4.0	10	0	0.00	0.00;			
	3	4	1.0	10	0	0.00	0.00;
	3	5	1.0	10	0	0.00	0.00;
	1	3	1.5	10	1	0.15	16.0;	
	2	4	5.0	10	2	0.50	16.0;
	4	5	1.0 10	0	0.00	0.00;
	5	6	1.0 10	0	0.00	0.00;
];

%% load cost data
%  bus_i  cost firm_load
mpc.load_cost = [		
	2	1000	1	
	3	1000	1		
	4	1000	1			
	5	1000	1		
	6	1000	1			
];