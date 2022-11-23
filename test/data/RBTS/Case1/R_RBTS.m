%% MATPOWER Case Format : Version 2
function mpc = RBTS
mpc.version = '2';

%%-----  Reliability Data  -----%%

%% generator reliability data
%	bus	pmax	λ	mttr
mpc.reliability_gen = [
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
%    f_bus	t_bus	λ	mttr    
mpc.reliability_branch = [
	1	3	1.5	10;								
	2	4	5.0	10;									
	2	1	4.0	10;									
	3	4	1.0	10;								
	3	5	1.0	10;								
	1	3	1.5	10;									
	2	4	5.0	10;								
	4	5	1.0 10;								
	5	6	1.0 10;
	5	6	1.0 10;							
];

%% load cost data
%  bus_i  c
mpc.load_cost = [		
	2	7410;		
	3	2690;		
	4	6780;			
	5	4820;		
	6	3630;			
];