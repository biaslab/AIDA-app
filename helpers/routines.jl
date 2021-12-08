function reset_routine(model, agent)
    @show "check1"
    model.context[] = "synthetic"
    model.ha_pairs[] = ha_pairs_init
    model.btntoggle[] = "synthetic"
    @show agent
    agent = EFEAgent(CONTEXTS, 20, ndims, 1)
    model.index[] = 1
    model.ha_plotdata[] = [pl_input(model.index[], ha_pairs_init), pl_speech(model.index[], ha_pairs_init), pl_noise(model.index[], ha_pairs_init), pl_output(model.index[], ha_pairs_init, agent)]

    model.agent_plotdata[] = pl_agent_hm(agent)

    model.classifier_plotdata[] = pl_context_fe(context_classifier, ha_pairs_init[1]["context"], "synthetic")
    @show "check2"
    agent, model
end

function context_classifier_routine(model)
    real_context = model.btntoggle[]
    segment = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["input"][1:SEGLEN]
    pl_context_fe(context_classifier, segment, real_context)
end

function update_index_routine(model, index, agent)
    classifier_plotdata = context_classifier_routine(model)
    ha_plotdata = update_plots(mod_index(index, model.ha_pairs[]), model.ha_pairs[], agent)
    real_context = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["context"]
    return classifier_plotdata, ha_plotdata, real_context
end

function optimize_routine(agent, model)
    optimize_hyperparams!(agent, model.context[])
    pl_agent_hm(agent)
end

function btntoggle_routine(model, toggle, agent)
    @show toggle
    ha_pairs = switch_ha_pairs(toggle == "synthetic" ? true : false)
    context = toggle == "synthetic" ? "synthetic" : model_context_change(model.index[], ha_pairs)
    @show context
    new_X, new_grid = get_new_proposal(agent, context)
    agent.current_gain = reshape(collect(new_X), size(agent.current_gain))
    agent.current_hm = new_grid
    hm_plotdata = pl_agent_hm(agent)
    @show model.context[]
    context, ha_pairs, hm_plotdata
end
