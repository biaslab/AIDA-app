using Stipple, StippleUI, StipplePlotly
using LaTeXStrings
using WAV
using JLD
using AIDA
using Colors
using Images
using Random
using Compat: @compat
using WAV
using Base64
include("helpers/audio.jl")

## Initialize agent
include("helpers/agent.jl")
ndims = 2
agent = EFEAgent(CONTEXTS, 20, ndims, 1)

## Initialize context inference
include("helpers/context.jl")
context_classifier = ContextClassifier([lar_inference, lar_inference], PRIORS_SYNTH, 2)

include("helpers/utils.jl")
include("helpers/routines.jl")

#== plot HA ==#
pl_input(index, ha_pairs) = PlotData(y = ha_pairs[index]["input"], plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER, name = "input")
pl_speech(index, ha_pairs) = PlotData(y = ha_pairs[index]["speech"], plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER, name = "speech")
pl_noise(index, ha_pairs) = PlotData(y = ha_pairs[index]["noise"], plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER, name = "noise")
function pl_output(index, ha_pairs, agent)
    gains = agent.current_gain
    speech = ha_pairs[index]["speech"]
    noise = ha_pairs[index]["noise"]
    PlotData(y = gains[1]*speech + gains[2]*noise, plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER, name = "output")
end

#== heatmap ==#
function pl_agent_hm(agent)
    PlotData(x=agent.grid.iterators[1], y=agent.grid.iterators[2], z=agent.current_hm, plot = StipplePlotly.Charts.PLOT_TYPE_HEATMAP, name="heatmap")
end

#== ==#
function pl_context_fe(classifier::ContextClassifier, segment, real_context)
    if real_context in REAL_C
        classifier.priors = PRIORS
        classifier.vmpits = 5
        fes = infer_context(classifier, segment)
        return [PlotData(y=fes[1], plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER, name="Babble"),
                PlotData(y=fes[2], plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER, name="Train")]
    else
        classifier.priors = PRIORS_SYNTH
        classifier.vmpits = 1
        fes = infer_context(classifier, segment)
        return [PlotData(y=first(fes[1]) * ones(5), plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER, name="SIN"),
                PlotData(y=first(fes[2]) * ones(5), plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER, name="DRILL")]
    end
end

function update_plots(i, ha_pairs, agent)
    [pl_input(i, ha_pairs), pl_speech(i, ha_pairs), pl_noise(i, ha_pairs), pl_output(i, ha_pairs, agent)]
end

function update_gains(i, context, response, agent, ha_pairs)
    update_dataset!(agent, context, response)
    new_X, new_grid = get_new_proposal(agent, context)
    agent.current_gain = reshape(collect(new_X), size(agent.current_gain))
    agent.current_hm = new_grid
    @show new_X
    update_plots(i, ha_pairs, agent)
end


# Create layout for plots
HA_layout = PlotLayout(plot_bgcolor = "white", yaxis = [PlotLayoutAxis(xy = "y", index = 1, ticks = "outside", showline = true, zeroline = false, title = "amplitude")])
HM_layout = PlotLayout(plot_bgcolor="white",
                       yaxis = [PlotLayoutAxis(xy = "y", index = 1, ticks = "outside", showline = true, zeroline = false, title = "noise gain")],
                       xaxis = [PlotLayoutAxis(xy = "x", index = 1, ticks = "outside", showline = true, zeroline = false, title = "speech gain")])
FE_layout = PlotLayout(plot_bgcolor="white",
                        yaxis = [PlotLayoutAxis(xy = "y", index = 1, ticks = "outside", showline = true, zeroline = false, title = "BFE [nats]")])


ha_pairs_init = switch_ha_pairs(true)

#== reactive model ==#
Base.@kwdef mutable struct Model <: ReactiveModel

    # percentage::R{Float64} = 100.0

    index::R{Integer} = 1

    context::R{String} = "sin"

    play_in::R{Bool}     = false
    play_speech::R{Bool} = false
    play_noise::R{Bool}  = false
    play_output::R{Bool} = false

    like::R{Bool}    = false
    dislike::R{Bool} = false

    reset_env::R{Bool} = false

    optimize::R{Bool} = false

    logourl::R{String}    = "img/logo.svg"
    headerurl::R{String}  = "img/sound-waves.png"
    dislikeurl::R{String} = "img/dislike.png"
    likeurl::R{String}    = "img/like.png"
    optimurl::R{String}   = "img/optim.png"
    
    btntoggle::R{String} = "synthetic"

    ha_pairs::R{Vector} = ha_pairs_init

    config::R{PlotConfig} = PlotConfig()

    ha_plotdata::R{Vector{PlotData}} = [pl_input(index, ha_pairs_init), pl_speech(index, ha_pairs_init), pl_noise(index, ha_pairs_init), pl_output(index, ha_pairs_init, agent)]
    ha_layout::R{PlotLayout} = HA_layout

    agent_plotdata::R{PlotData} = pl_agent_hm(agent)
    hm_layout::R{PlotLayout} = HM_layout

    classifier_plotdata::R{Vector{PlotData}} = pl_context_fe(context_classifier, ha_pairs_init[1]["input"][1:SEGLEN], "sin")
    fe_layout::R{PlotLayout} = FE_layout

    audio_base_input::R{String} = soundtostring(ha_pairs_init[1]["input"])
    audio_base_speech::R{String} = soundtostring(ha_pairs_init[1]["speech"])
    audio_base_noise::R{String} = soundtostring(ha_pairs_init[1]["noise"])
    audio_base_output::R{String} = soundtostring(agent.current_gain[1]*ha_pairs_init[1]["speech"] + agent.current_gain[2]*ha_pairs_init[1]["noise"])

end

# const stipple_model = Stipple.init(Model(), transport = Genie.WebThreads)
const stipple_model = Stipple.init(Model())

# update if the index changes
on(i -> (stipple_model.classifier_plotdata[], 
        stipple_model.ha_plotdata[],           
        stipple_model.context[], 
        stipple_model.audio_base_input[],
        stipple_model.audio_base_speech[],
        stipple_model.audio_base_noise[],
        stipple_model.audio_base_output[]) 
    = update_index_routine(stipple_model, mod_index(i, stipple_model.ha_pairs[]), agent), stipple_model.index)

# update if context changes
on(_ -> (stipple_model.ha_plotdata[], 
        stipple_model.agent_plotdata[], 
        stipple_model.classifier_plotdata[]) 
    = context_change_routine(stipple_model, agent), stipple_model.context)

# update if pairs change
on(pairs -> stipple_model.ha_plotdata[] 
    = update_plots(mod_index(stipple_model.index[], pairs), pairs, agent), stipple_model.ha_pairs)

# play sounds when button is pressed (server-side)
on(_ -> playsound("input", stipple_model.ha_pairs[], nothing), stipple_model.play_in)
on(_ -> playsound("speech", stipple_model.ha_pairs[], nothing), stipple_model.play_speech)
on(_ -> playsound("noise", stipple_model.ha_pairs[], nothing), stipple_model.play_noise)
on(_ -> playsound("output", stipple_model.ha_pairs[], agent), stipple_model.play_output)

# TODO: Plots should be updated according to the agent's beliefs about the context, not the actual context
on(_ -> stipple_model.ha_plotdata[] = update_gains(mod_index(stipple_model.index[], stipple_model.ha_pairs[]), stipple_model.context[], 1.0, agent, stipple_model.ha_pairs[]), stipple_model.like)
on(_ -> stipple_model.ha_plotdata[] = update_gains(mod_index(stipple_model.index[], stipple_model.ha_pairs[]), stipple_model.context[], 0.0, agent, stipple_model.ha_pairs[]), stipple_model.dislike)
on(_ -> stipple_model.agent_plotdata[] = pl_agent_hm(agent), stipple_model.like)
on(_ -> stipple_model.agent_plotdata[] = pl_agent_hm(agent), stipple_model.dislike)

# update on optimize
on(_ -> stipple_model.agent_plotdata[] 
    = optimize_routine(agent, stipple_model), stipple_model.optimize)

# update when switching between real and synthetic
on(i -> (stipple_model.context[], 
        stipple_model.ha_pairs[], 
        stipple_model.agent_plotdata[]) 
    = btntoggle_routine(stipple_model, i, agent), stipple_model.btntoggle)

# update upon reset
on(_ -> reset_routine!(stipple_model, agent), stipple_model.reset_env)

# creating Toggle
btn_opt(label::AbstractString, value::AbstractString) = "{label: '$label', value: '$value'}"
btn_opt(labels::Vector, values::Vector) = "[ $(join( btn_opt.(labels, values), ",\n  ")) ]"
btn_opt(values::Vector) = btn_opt(values, values)

#== ui ==#
# params = Dict("hi" => 1)
function ui(stipple_model)
    dashboard(
        vm(stipple_model), class = "container", [
            # heading("Active Inference Design Agent", text_align="center")
            row([img(src=stipple_model.headerurl[], style = "height: 60px; width: 70px")
                 h3("Active Inference Design Agent")])
            row([cell(class = "st-module", [
                h5("Environment") 
                cell([
                    quasar(:btn__toggle, "", 
                            @bind("btntoggle"),
                            toggle__color="orange",
                            :multiple,
                            options=@data(btn_opt(["Synthetic", "Real"], ["synthetic", "real"])))
                    btn("reset", @click("reset_env = !reset_env"), color = "red", type = "submit", wrap = StippleUI.NO_WRAPPER)
                    
                    ])
                ])
            ])
            # spinner("infinity", size="5em")
            row([cell(class = "st-module",[ 
                h5("Hearing Aid")
                cell([
                    StipplePlotly.plot(:ha_plotdata, layout = :ha_layout, config = :config)
                    Stipple.center(btn("Next", @click("index += 1"), color = "pink", type = "submit", wrap = StippleUI.NO_WRAPPER))
                    ]) 
                ])
            ])
            Stipple.center([btn("input ", @click("play_in = !play_in"), color = "blue", type = "submit", wrap = StippleUI.NO_WRAPPER)
                            btn("speech ", @click("play_speech = !play_speech"), color = "orange", type = "submit", wrap = StippleUI.NO_WRAPPER)
                            btn("noise ", @click("play_noise = !play_noise"), color = "green", type = "submit", wrap = StippleUI.NO_WRAPPER)
                            btn("output ", @click("play_output = !play_output"), color = "red", type = "submit", wrap = StippleUI.NO_WRAPPER)
            ])
            Stipple.center([
                cell([
                    """
                        <audio controls style="width: 200px; height: 60px;" :src="audio_base_input"></audio>
                        <audio controls style="width: 200px; height: 60px;" :src="audio_base_speech"></audio>
                        <audio controls style="width: 200px; height: 60px;" :src="audio_base_noise"></audio>
                        <audio controls style="width: 200px; height: 60px;" :src="audio_base_output"></audio>
                    """
                ], style = "height: 60px;")
            ], style = "height: 60px;")
            Stipple.center(cell(class = "st-module", [
                        btn("", @click("like = !like"), content = img(src = stipple_model.likeurl[], style = "height: 50; max-width: 50"), type = "submit", wrap = StippleUI.NO_WRAPPER)
                        btn("", @click("dislike = !dislike"), content = img(src = stipple_model.dislikeurl[], style = "height: 50; max-width: 50"), type = "submit", wrap = StippleUI.NO_WRAPPER)
                        btn("", @click("optimize = !optimize"), content = img(src = stipple_model.optimurl[], style = "height: 50; max-width: 50"), type = "submit", wrap = StippleUI.NO_WRAPPER)])
                        )
            row([
                    cell(class="st-module", [
                        h5("EFE Agent")
                        StipplePlotly.plot(:agent_plotdata, layout = :hm_layout, config = :config)
                    ])

                    cell(class="st-module", [
                        h5("Classifier")
                        StipplePlotly.plot(:classifier_plotdata, layout = :fe_layout, config = :config)
                    ])
            ])
            
            Stipple.center([img(src = stipple_model.logourl[], style = "height: 500px; max-width: 700px"),
            ])
        ])
end



#== server ==#
route("/") do
    ui(stipple_model) |> html
end

up(async = true)