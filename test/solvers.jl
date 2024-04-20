ipopt_optimizer = JuMP.optimizer_with_attributes(
    Ipopt.Optimizer, 
    "tol" => 1e-6, 
    "print_level" => 0
)

juniper_optimizer = optimizer_with_attributes(
    Juniper.Optimizer, 
    "nl_solver"=> JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0), 
    "log_levels"=>[], 
    "processors"=>1
)

gurobi_optimizer = JuMP.optimizer_with_attributes(
    Gurobi.Optimizer, "Presolve"=>0, 
    "OutputFlag"=>0, 
    "LogToConsole"=>0, 
    "NonConvex"=>2, 
    "Threads"=>4
)

gurobi_optimizer_2 = JuMP.optimizer_with_attributes(
    Gurobi.Optimizer, 
    "Presolve"=>1, 
    "PreCrush"=>1, 
    "OutputFlag"=>0, 
    "LogToConsole"=>0, 
    "NonConvex"=>2, 
    "NumericFocus"=>3, 
    "Threads"=>4
)