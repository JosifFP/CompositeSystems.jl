@info "Creating a GRB_ENV const for CompositeSystems..."
# Gurobi package setup (see https://github.com/jump-dev/Gurobi.jl)
const GRB_ENV = Ref{Gurobi.Env}()
export GRB_ENV

"""
    init_gurobi_env(nthreads::Int)

Initialize the Gurobi environment with the specified number of threads (`nthreads`).
Configures various Gurobi parameters like turning off output, enabling presolve, 
setting non-convexity handling, and specifying thread count.
"""
function init_gurobi_env(nthreads::Int)
    GRB_ENV[] = Gurobi.Env()
    Gurobi.GRBsetintparam(GRB_ENV[], "OutputFlag", 0)
    Gurobi.GRBsetintparam(GRB_ENV[], "Presolve", 1)
    Gurobi.GRBsetintparam(GRB_ENV[], "NonConvex", 2)
    Gurobi.GRBsetintparam(GRB_ENV[], "Threads", nthreads)
    return
end

"""
    end_gurobi_env()

Finalize the Gurobi environment to release resources and cleanup.
"""
function end_gurobi_env()
    Base.finalize(GRB_ENV[])
    return
end

export init_gurobi_env, end_gurobi_env