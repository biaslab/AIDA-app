model_context_change(index, ha_pairs) = ha_pairs[mod_index(index, ha_pairs)]["context"]
mod_index(index, pairs) = mod1(index, length(pairs))

function playsound(type, ha_pairs, agent)
    if type == "output"
        gains  = agent.current_gain
        speech = ha_pairs[mod_index(stipple_model.index[], ha_pairs)]["speech"]
        noise  = ha_pairs[mod_index(stipple_model.index[], ha_pairs)]["noise"]
        wavplay(gains[1]*speech + gains[2]*noise, FS)
    else
        wavplay(ha_pairs[mod_index(stipple_model.index[], ha_pairs)][type], FS)
    end
end

function switch_ha_pairs(synthetic=true)
    if synthetic
        inputs, outputs = map(x -> get_ha_files_synth(x), [INPUT_PATH, OUTPUT_PATH])
        ha_pairs = map_input_output(inputs, outputs)
    else
        inputs, outputs = map(x -> get_ha_files_real(x), [INPUT_PATH, OUTPUT_PATH])
        ha_pairs = map_input_output(inputs, outputs)
    end
    return ha_pairs
end