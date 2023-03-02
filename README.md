# CompositeSystems.jl

CompositeSystems.jl is the first open-source Composite System Reliability (CSR) tool written in Julia. The methodology is based on sequential Monte Carlo sampling of generation and transmission component availability such as: generators, transmission lines, transformers, shunts, loads and storage systems. Remedial actions, energy storage dispatch and load curtailment are carried out by an efficient linear programming routine (DC Optimal Power Flow) based on JuMP modeling language and linear solver provided by the user. The program is demonstrated in case studies with 6-Bus Roy Billiton Test System (RBTS) and the 24-Bus IEEE RTS.

**Powered and inspired by PowerModels.jl and *NREL's* Probabilistic Resource Adequacy Suite ( *PRAS* )**

[![Coverage](https://codecov.io/gh/JosifFP/PRATS.jl/branch/master/graph/badge.svg)
](https://codecov.io/gh/JosifFP/PRATS.jl)
