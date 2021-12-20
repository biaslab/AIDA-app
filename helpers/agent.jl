using Optim

N_STEPS = 20
DEFAULT_GAIN = [1.0 2.0]
DEFAULT_PARAMS = (0.5, 0.5)

# load helper functions
mutable struct ContextMemory
    name    :: String
    params  :: Tuple
    dataset :: Dict{String, Any}
end

mutable struct EFEAgent
    cmems        :: Vector{ContextMemory}
    current_gain :: Matrix{Float64}
    current_hm   :: Matrix{Float64}
    grid

    function EFEAgent(names::Vector{String}, nsteps::T) where T<:Int64
        params = DEFAULT_PARAMS
        cmems = Vector{ContextMemory}()
        for name in names
            push!(cmems, ContextMemory(name, params, Dict("X" => missing, "y" => [])))
        end
        grid = Iterators.product(LinRange(0, 2, nsteps), LinRange(0, 2, nsteps))
        new(cmems, reshape(DEFAULT_GAIN, (2, 1)), 1e2*ones(nsteps, nsteps), grid)
    end
end


function optimize_hyperparams!(agent::EFEAgent, context::String)
    id = findall(isequal(context), CONTEXTS)[1]
    grid, X, y, cur_X, params = agent.grid, agent.cmems[id].dataset["X"], agent.cmems[id].dataset["y"], agent.cmems[id].dataset["X"][:, end], collect(agent.cmems[id].params)
    # res = Optim.optimize(params -> AIDA.log_evidence(X, y, params), params, show_trace=true)
    res = Optim.optimize(params -> AIDA.log_evidence(X, y, params), [0.1,0.1],[1.,1],params,Fminbox(),
		                                    Optim.Options( iterations=1000, g_tol=1e-4))
    agent.cmems[id].params = tuple(res.minimizer...)
    # Compute the EFE grid (meh... TODO:)
    # agent.current_hm = AIDA.choose_point.(Ref(X), grid, Ref(y), params...)
    σ, l = params
    epi_grid, inst_grid = get_new_decomp(grid, X, y, σ, l)
    agent.current_hm = epi_grid + inst_grid
end

# Grid search over EFE values with inhibition of return, inspired by eye movements
function get_new_proposal(agent::EFEAgent, context::String)
    id = findall(isequal(context), CONTEXTS)[1]
    grid, X, y, params = agent.grid, agent.cmems[id].dataset["X"], agent.cmems[id].dataset["y"], collect(agent.cmems[id].params)
    if ismissing(X)
        ndims = size(agent.current_gain, 1)
        nsteps = size(agent.current_hm, 1)
        return reshape([1.0 2.0], (2, 1)), 1e2*ones(nsteps, nsteps)
    end
    cur_X = agent.cmems[id].dataset["X"][:, end]
    σ, l = params
    epi_grid, inst_grid = get_new_decomp(grid, X, y, σ, l)
    value_grid = epi_grid + inst_grid
    # Ensure that we propose a new trial and not the same one twice in a row
    value_grid[collect(grid) .== [(cur_X[1], cur_X[2])]] .= Inf

    # Find the minimum and try it out
    idx         = argmin(value_grid)
    proposal_X  = collect(grid)[idx]

    proposal_X, value_grid
end


function update_dataset!(agent::EFEAgent, context::String, input::Float64)
    id = findall(isequal(context), CONTEXTS)[1]
    if ismissing(agent.cmems[id].dataset["X"])
        agent.cmems[id].dataset["X"] = collect(agent.current_gain)
    else
        agent.cmems[id].dataset["X"] = hcat(agent.cmems[id].dataset["X"], collect(agent.current_gain))
    end
    agent.cmems[id].dataset["y"] = vcat(agent.cmems[id].dataset["y"], input)
end