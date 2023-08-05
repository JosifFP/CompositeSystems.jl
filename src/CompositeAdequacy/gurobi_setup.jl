@info "Creating a GRB_ENV const for CompositeSystems..."
# Gurobi package setup (see https://github.com/jump-dev/Gurobi.jl)
const GRB_ENV = Ref{Gurobi.Env}()
export GRB_ENV

""
function init_gurobi_env(nthreads::Int)
    GRB_ENV[] = Gurobi.Env()
    Gurobi.GRBsetintparam(GRB_ENV[], "OutputFlag", 0)
    Gurobi.GRBsetintparam(GRB_ENV[], "Presolve", 1)
    Gurobi.GRBsetintparam(GRB_ENV[], "NonConvex", 2)
    Gurobi.GRBsetintparam(GRB_ENV[], "Threads", nthreads)
    return
end

function end_gurobi_env()
    Base.finalize(GRB_ENV[])
    return
end

export init_gurobi_env, end_gurobi_env