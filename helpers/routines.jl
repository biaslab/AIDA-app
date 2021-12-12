function reset_routine!(model, agent)
    @show "check1"
    model.context[] = "synthetic"
    model.ha_pairs[] = ha_pairs_init
    model.btntoggle[] = "synthetic"
    @show agent
    agent = EFEAgent(CONTEXTS, 20, ndims, 1)
    model.index[] = 1
    model.ha_plotdata[] = [pl_input(model.index[], ha_pairs_init), pl_speech(model.index[], ha_pairs_init), pl_noise(model.index[], ha_pairs_init), pl_output(model.index[], ha_pairs_init, agent)]

    model.agent_plotdata[] = pl_agent_hm(agent)

    model.classifier_plotdata[] = pl_context_fe(context_classifier, zeros(SEGLEN), "synthetic")
    @show "check2"
    @show agent
end

function update_index_routine(model, index, agent)
    ha_plotdata = update_plots(mod_index(index, model.ha_pairs[]), model.ha_pairs[], agent)
    real_context = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["context"]

    segment = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["input"][1:SEGLEN]
    classifier_plotdata = pl_context_fe(context_classifier, segment, real_context)

    hm_plotdata = pl_agent_hm(agent)
    @show real_context
    return classifier_plotdata, ha_plotdata, real_context, hm_plotdata
end

function optimize_routine(agent, model)
    optimize_hyperparams!(agent, model.context[])
    pl_agent_hm(agent)
end

function btntoggle_routine(model, toggle, agent)
    @show toggle
    ha_pairs = switch_ha_pairs(toggle == "synthetic" ? true : false)
    context = model_context_change(model.index[], ha_pairs)
    @show context
    new_X, new_grid = get_new_proposal(agent, context)
    agent.current_gain = reshape(collect(new_X), size(agent.current_gain))
    agent.current_hm = new_grid
    hm_plotdata = pl_agent_hm(agent)
    @show model.context[]
    context, ha_pairs, hm_plotdata
end

function context_change_routine(model, agent)
    real_context = model.context[]
    segment = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["input"][1:SEGLEN]
    fe_plotdata = pl_context_fe(context_classifier, segment, real_context)

    new_X, new_grid = get_new_proposal(agent, real_context)
    agent.current_gain = reshape(collect(new_X), size(agent.current_gain))
    agent.current_hm = new_grid
    hm_plotdata = pl_agent_hm(agent)

    ha_plotdata = update_plots(mod_index(model.index[], model.ha_pairs[]), model.ha_pairs[], agent)

    ha_plotdata, hm_plotdata, fe_plotdata
end