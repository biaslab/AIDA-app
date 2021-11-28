# load helper functions
include("../agent/utils.jl")

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

    function EFEAgent(names::Vector{String}, nsteps::T, ndims::T, npoints::T) where T<:Int64
        params = (0.2, 0.5)
        cmems = Vector{ContextMemory}()
        for name in names
            push!(cmems, ContextMemory(name, params, Dict("X" => missing, "y" => [])))
        end
        grid = Iterators.product(LinRange(0, 2, nsteps), LinRange(0, 2, nsteps))
        new(cmems, rand(ndims, npoints), 1e2*ones(nsteps, nsteps), grid)
    end
end


function optimize_hyperparams!(agent::EFEAgent, context::String)
    id = findall(isequal(context), CONTEXTS)[1]
    grid, X, y, cur_X, params = agent.grid, agent.cmems[id].dataset["X"], agent.cmems[id].dataset["y"], agent.cmems[id].dataset["X"][:, end], collect(agent.cmems[id].params)
    res = optimize(params -> log_evidence(X, y, params), params, show_trace=true)
    agent.cmems[id].params = tuple(res.minimizer...)

    # Compute the EFE grid (meh... TODO:)
    agent.current_hm = choose_point.(Ref(X), grid, Ref(y), params...)
end

# Grid search over EFE values with inhibition of return, inspired by eye movements
function get_new_proposal(agent::EFEAgent, context::String)
    id = findall(isequal(context), CONTEXTS)[1]
    grid, X, y, params = agent.grid, agent.cmems[id].dataset["X"], agent.cmems[id].dataset["y"], collect(agent.cmems[id].params)
    if ismissing(X)
        ndims = size(agent.current_gain, 1)
        nsteps = size(agent.current_hm, 1)
        return rand(ndims, 1), 1e2*ones(nsteps, nsteps)
    end
    cur_X = agent.cmems[id].dataset["X"][:, end]
    # Compute the EFE grid
    value_grid = choose_point.(Ref(X), grid, Ref(y), params...)
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

# n_dims = 2
# n_points = 1
# n_steps = 20

# agent = EFEAgent(CONTEXTS, n_steps, n_dims, n_points)
# update_dataset!(agent, "train", 0.0)
# new_x, _ = get_new_proposal(agent, "train")
# new_y = 0.0

# update_dataset!(agent, "train", new_x, new_y)