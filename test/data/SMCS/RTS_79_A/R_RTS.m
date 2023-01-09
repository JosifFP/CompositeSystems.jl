%% MATPOWER Case Format
function mpc = RTS

%%-----  Reliability Data  -----%%

%% generator reliability data
%	bus	pmax	state_model	λ_updn	μ_updn	λ_upde	μ_upde	pde
mpc.gen = [
	1	20		2	19.41	174.72	0	0	0
	1	20		2	19.41	174.72	0	0	0
	1	76		2	4.46	218.4	0	0	0
	1	76		2	4.46	218.4	0	0	0
	2	20		2	19.41	174.72	0	0	0
	2	20		2	19.41	174.72	0	0	0
	2	76		2	4.46	218.4	0	0	0
	2	76		2	4.46	218.4	0	0	0
	7	100.0	2	7.28	174.72	0	0	0
	7	100.0	2	7.28	174.72	0	0	0
	7	100.0	2	7.28	174.72	0	0	0
	13	197.0	2	9.19	174.72	0	0	0
	13	197.0	2	9.19	174.72	0	0	0
	13	197.0	2	9.19	174.72	0	0	0
	14	0		2	0		0		0	0	0
	15	12.0	2	2.97	145.6	0	0	0
	15	12.0	2	2.97	145.6	0	0	0
	15	12.0	2	2.97	145.6	0	0	0
	15	12.0	2	2.97	145.6	0	0	0
	15	12.0	2	2.97	145.6	0	0	0
	15	155.0	2	9.10	218.4	0	0	0
	16	155.0	2	9.10	218.4	0	0	0
	18	400.0	2	7.94	58.24	0	0	0
	21	400.0	2	7.94	58.24	0	0	0
	22	50.0	2	4.41	436.8	0	0	0
	22	50.0	2	4.41	436.8	0	0	0
	22	50.0	2	4.41	436.8	0	0	0
	22	50.0	2	4.41	436.8	0	0	0
	22	50.0	2	4.41	436.8	0	0	0
	22	50.0	2	4.41	436.8	0	0	0
	23	155.0	2	9.10	218.4	0	0	0
	23	155.0	2	9.10	218.4	0	0	0
	23	350.0	2	7.59	87.36	0	0	0
];

%% branch reliability data
%    f_bus	t_bus	λ_updn	μ_updn common_mode λ_common μ_common
mpc.branch = [
	1	2	0.24	546.0	0	0	0	
	1	3	0.51	873.6	0	0	0
	1	5	0.33	873.6	0	0	0
	2	4	0.39	873.6	0	0	0
	2	6	0.48	873.6	0	0	0
	3	9	0.38	873.6	0	0	0
	4	9	0.36	873.6	0	0	0
	5	10	0.34	873.6	0	0	0
	6	10	0.33	249.6	0	0	0
	7	8	0.30	873.6	0	0	0
	8	9	0.44	873.6	0	0	0
	8	10	0.44	873.6	0	0	0
	11	13	0.40	794.2	0	0	0
	11	14	0.39	794.2	0	0	0
	12	13	0.40	794.2	0	0	0
	12	23	0.52	794.2	0	0	0
	13	23	0.49	794.2	0	0	0
	14	16	0.38	794.2	0	0	0
	15	16	0.33	794.2	0	0	0
	15	21	0.41	794.2	0	0	0
	15	21	0.41	794.2	0	0	0
	15	24	0.41	794.2	0	0	0
	16	17	0.35	794.2	0	0	0
	16	19	0.34	794.2	0	0	0
	17	18	0.32	794.2	0	0	0
	17	22	0.54	794.2	0	0	0
	18	21	0.35	794.2	0	0	0
	18	21	0.35	794.2	0	0	0
	19	20	0.38	794.2	0	0	0
	19	20	0.38	794.2	0	0	0
	20	23	0.34	794.2	0	0	0
	20	23	0.34	794.2	0	0	0
	21	22	0.45	794.2	0	0	0
	3	24	0.02	11.4	0	0	0
	9	11	0.02	11.4	0	0	0
	9	12	0.02	11.4	0	0	0
	10	11	0.02	11.4	0	0	0
	10	12	0.02	11.4	0	0	0
];


%% load cost data
%  bus_i  cost firm_load
mpc.load = [
1	8981.5	1
2	7360.6	1
3	5899	1
4	9599.2	1
5	9232.3	1
6	6523.8	1
7	7029.1	1
8	7774.2	1
9	3662.3	1
10	5194	1
13	7281.3	1
14	4371.7	1
15	5974.4	1
16	7230.5	1
18	5614.9	1
19	4543	1
20	5683.6	1
];