%% MATPOWER Case Format
function mpc = RTS

%%-----  Reliability Data  -----%%

%% generator reliability data
%	bus	pmax	state_model	λ_updn	μ_updn	λ_upde	μ_upde	pde
mpc.gen = [
	1	20		2	19.47	175.2	0	0	0
	1	20		2	19.47	175.2	0	0	0
	1	76		2	4.47	219.0	0	0	0
	1	76		2	4.47	219.0	0	0	0
	2	20		2	19.47	175.2	0	0	0
	2	20		2	19.47	175.2	0	0	0
	2	76		2	4.47	219.0	0	0	0
	2	76		2	4.47	219.0	0	0	0
	7	100.0	2	7.30	175.2	0	0	0
	7	100.0	2	7.30	175.2	0	0	0
	7	100.0	2	7.30	175.2	0	0	0
	13	197.0	2	9.22	175.2	0	0	0
	13	197.0	2	9.22	175.2	0	0	0
	13	197.0	2	9.22	175.2	0	0	0
	14	0.0	2	0.01	1.0	0	0	0
	15	12.0	2	2.98	146.0	0	0	0
	15	12.0	2	2.98	146.0	0	0	0
	15	12.0	2	2.98	146.0	0	0	0
	15	12.0	2	2.98	146.0	0	0	0
	15	12.0	2	2.98	146.0	0	0	0
	15	155.0	2	9.13	219.0	0	0	0
	16	155.0	2	9.13	219.0	0	0	0
	18	400.0	2	7.96	58.4	0	0	0
	21	400.0	2	7.96	58.4	0	0	0
	22	50.0	2	4.42	438.0	0	0	0
	22	50.0	2	4.42	438.0	0	0	0
	22	50.0	2	4.42	438.0	0	0	0
	22	50.0	2	4.42	438.0	0	0	0
	22	50.0	2	4.42	438.0	0	0	0
	22	50.0	2	4.42	438.0	0	0	0
	23	155.0	2	9.13	219.0	0	0	0
	23	155.0	2	9.13	219.0	0	0	0
	23	350.0	2	7.62	87.6	0	0	0
];

%% branch reliability data
%    f_bus	t_bus	λ_updn	μ_updn common_mode λ_common μ_common
mpc.branch = [
	1	2	0.24	546.0	0	0	0	
	1	3	0.51	876.0	0	0	0
	1	5	0.33	876.0	0	0	0
	2	4	0.39	876.0	0	0	0
	2	6	0.48	876.0	0	0	0
	3	9	0.38	876.0	0	0	0
	3	24	0.02	11.4	0	0	0
	4	9	0.36	876.0	0	0	0
	5	10	0.34	876.0	0	0	0
	6	10	0.33	249.6	0	0	0
	7	8	0.30	876.0	0	0	0
	8	9	0.44	876.0	0	0	0
	8	10	0.44	876.0	0	0	0
	9	11	0.02	11.4	0	0	0
	9	12	0.02	11.4	0	0	0
	10	11	0.02	11.4	0	0	0
	10	12	0.02	11.4	0	0	0
	11	13	0.40	796.4	0	0	0
	11	14	0.39	796.4	0	0	0
	12	13	0.40	796.4	0	0	0
	12	23	0.52	796.4	0	0	0
	13	23	0.49	796.4	0	0	0
	14	16	0.38	796.4	0	0	0
	15	16	0.33	796.4	0	0	0
	15	21	0.41	796.4	0	0	0
	15	21	0.41	796.4	0	0	0
	15	24	0.41	796.4	0	0	0
	16	17	0.35	796.4	0	0	0
	16	19	0.34	796.4	0	0	0
	17	18	0.32	796.4	0	0	0
	17	22	0.54	796.4	0	0	0
	18	21	0.35	796.4	0	0	0
	18	21	0.35	796.4	0	0	0
	19	20	0.38	796.4	0	0	0
	19	20	0.38	796.4	0	0	0
	20	23	0.34	796.4	0	0	0
	20	23	0.34	796.4	0	0	0
	21	22	0.45	796.4	0	0	0
];

%% load cost data
%  bus_i  cost
mpc.load = [
1	8981.5
2	7360.6
3	5899.0
4	9599.2
5	9232.3
6	6523.8
7	7029.1
8	7774.2
9	3662.3
10	5194.0
13	7281.3
14	4371.7
15	5974.4
16	7230.5
18	5614.9
19	4543.0
20	5683.6
];
