function reset_routine!(model, agent)
    model.context[] = "sin"
    model.ha_pairs[] = ha_pairs_init
    model.btntoggle[] = "synthetic"
    
    @show "check 1"
    setfield!(agent, :grid, Iterators.product(LinRange(0, 2, N_STEPS), LinRange(0, 2, N_STEPS)))
    setfield!(agent, :current_gain, reshape(DEFAULT_GAIN, (2, 1)))
    setfield!(agent, :current_hm, 1e2*ones(N_STEPS, N_STEPS))
    setfield!(agent, :cmems, [ContextMemory(name, DEFAULT_PARAMS, Dict("X" => missing, "y" => [])) for name in CONTEXTS])


    @show "check2"
    model.index[] = 1
    model.ha_plotdata[] = [pl_input(model.index[], ha_pairs_init), pl_speech(model.index[], ha_pairs_init), pl_noise(model.index[], ha_pairs_init), pl_output(model.index[], ha_pairs_init, agent)]
    model.agent_plotdata[] = pl_agent_hm(agent)

    # update audio
    speech = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["speech"]
    noise  = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["noise"]
    model.audio_base_input[] = soundtostring(model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["input"])
    model.audio_base_speech[] = soundtostring(speech)
    model.audio_base_noise[] = soundtostring(noise)
    gains  = agent.current_gain
    model.audio_base_output[] = soundtostring(gains[1]*speech + gains[2]*noise)

    model.classifier_plotdata[] = pl_context_fe(context_classifier, zeros(SEGLEN), "synthetic")
    @show "check3"
    return agent
end

function update_index_routine(model, index, agent)
    ha_plotdata = update_plots(mod_index(index, model.ha_pairs[]), model.ha_pairs[], agent)
    real_context = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["context"]

    segment = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["input"][1:SEGLEN]
    classifier_plotdata = pl_context_fe(context_classifier, segment, real_context)

    # fetch sounds as strings
    speech = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["speech"]
    noise  = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["noise"]
    audio_base_input = soundtostring(model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["input"])
    audio_base_speech = soundtostring(speech)
    audio_base_noise = soundtostring(noise)
    gains  = agent.current_gain
    audio_base_output = soundtostring(gains[1]*speech + gains[2]*noise)

    # hm_plotdata = pl_agent_hm(agent)
    @show "no change"
    return classifier_plotdata, ha_plotdata, audio_base_input, audio_base_speech, audio_base_noise, audio_base_output, real_context
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
    
    ha_pairs, context, hm_plotdata
end

function context_change_routine(model, agent)
    real_context = model.context[]
    @show real_context
    segment = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["input"][1:SEGLEN]
    fe_plotdata = pl_context_fe(context_classifier, segment, real_context)

    new_X, new_grid = get_new_proposal(agent, real_context)
    agent.current_gain = reshape(collect(new_X), size(agent.current_gain))
    agent.current_hm = new_grid
    @show "hi"
    @show agent.current_gain
    hm_plotdata = pl_agent_hm(agent)

    ha_plotdata = update_plots(mod_index(model.index[], model.ha_pairs[]), model.ha_pairs[], agent)

    # update audio
    speech = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["speech"]
    noise  = model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["noise"]
    audio_base_input = soundtostring(model.ha_pairs[][mod_index(model.index[], model.ha_pairs[])]["input"])
    audio_base_speech = soundtostring(speech)
    audio_base_noise = soundtostring(noise)
    gains  = agent.current_gain
    audio_base_output = soundtostring(gains[1]*speech + gains[2]*noise)

    ha_plotdata, hm_plotdata, fe_plotdata, audio_base_input, audio_base_speech, audio_base_noise, audio_base_output
end