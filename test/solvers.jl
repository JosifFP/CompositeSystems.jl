import Ipopt, Juniper, HiGHS
import JuMP: JuMP, optimizer_with_attributes
   

ipopt_optimizer_1 = JuMP.optimizer_with_attributes(
    Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0
)

ipopt_optimizer_2 = JuMP.optimizer_with_attributes(
    Ipopt.Optimizer, "print_level" => 0, "max_cpu_time" => 5.0,
)

ipopt_optimizer_3 = JuMP.optimizer_with_attributes(
    Ipopt.Optimizer, 
    "tol"=>1e-4,
    "max_cpu_time"=>5.0,
    "print_level"=>0
)

"Slower than ipopt_optimizer_3, with a smaller amount of memory allocations"
ipopt_optimizer_4 = JuMP.optimizer_with_attributes(
    Ipopt.Optimizer, 
    "tol"=>1e-4,
    "max_cpu_time"=>5.0,
    "print_level"=>0,
    "hessian_approximation"=> "limited-memory"
)

highs_optimizer_1 = JuMP.optimizer_with_attributes(
    HiGHS.Optimizer, "output_flag"=>false
)

juniper_optimizer_1 = optimizer_with_attributes(
    Juniper.Optimizer, "nl_solver"=>
    JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), 
    "log_levels"=>[], "processors"=>1
)

juniper_optimizer_2 = optimizer_with_attributes(
    Juniper.Optimizer, "nl_solver"=> ipopt_optimizer_3, 
    "atol"=>1e-4, "log_levels"=>[], "processors"=>1
)