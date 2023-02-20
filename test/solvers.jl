import Ipopt, Juniper, HiGHS, Gurobi
import JuMP: JuMP, optimizer_with_attributes
#const GRB_ENV = Gurobi.Env()

ipopt_optimizer_1 = JuMP.optimizer_with_attributes(
    Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0
)

ipopt_optimizer_2 = JuMP.optimizer_with_attributes(
    Ipopt.Optimizer, "print_level" => 0, "max_cpu_time" => 5.0,
)

ipopt_optimizer_3 = JuMP.optimizer_with_attributes(
    Ipopt.Optimizer, 
    "tol"=>1e-6,
    "max_cpu_time"=>5.0,
    "print_level"=>0
)

"Slower than ipopt_optimizer_3, with a smaller amount of memory allocations"
ipopt_optimizer_4 = JuMP.optimizer_with_attributes(
    Ipopt.Optimizer, 
    "tol"=>1e-6,
    "max_cpu_time"=>5.0,
    "print_level"=>0,
    "hessian_approximation"=> "limited-memory"
)

highs_optimizer_1 = JuMP.optimizer_with_attributes(
    HiGHS.Optimizer, "output_flag"=>false
)

juniper_optimizer_1 = optimizer_with_attributes(
    Juniper.Optimizer, "nl_solver"=> JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0), 
    "log_levels"=>[], 
    "processors"=>1
)

juniper_optimizer_2 = optimizer_with_attributes(
    Juniper.Optimizer, "nl_solver" => ipopt_optimizer_3, 
    "atol"=>1e-6, 
    "log_levels"=>[], 
    "processors"=>1
)

gurobi_optimizer_1 = JuMP.optimizer_with_attributes(
    Gurobi.Optimizer, "Presolve"=>0, 
    "OutputFlag"=>0, 
    "LogToConsole"=>0, 
    "NumericFocus"=>3
)

gurobi_optimizer_2 = JuMP.optimizer_with_attributes(
    Gurobi.Optimizer, "Presolve"=>0, 
    "OutputFlag"=>0, 
    "LogToConsole"=>0, 
    "NonConvex"=>2, 
    "Threads"=>8
)

gurobi_optimizer_3 = JuMP.optimizer_with_attributes(
    Gurobi.Optimizer, 
    "Presolve"=>1, 
    "PreCrush"=>1, 
    "OutputFlag"=>0, 
    "LogToConsole"=>0, 
    "NonConvex"=>2, 
    "NumericFocus"=>3, 
    "Threads"=>8
)

# GLPK_optimizer =
#     JuMP.optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => GLPK.GLP_MSG_OFF)
# scs_solver = JuMP.optimizer_with_attributes(
#     SCS.Optimizer,
#     "max_iters" => 100000,
#     "eps" => 1e-4,
#     "verbose" => 0,
# )