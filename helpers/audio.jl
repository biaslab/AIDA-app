# Meta for audio processing
INPUT_PATH = "public/sound/speech/"
OUTPUT_PATH = "public/sound/separated_jld/speech/"

INPUT_PATH_SIN = "public/sound/speech/sin"
OUTPUT_PATH_SIN = "public/sound/separated_jld/speech/"

SEGLEN = 80

SNR = "5dB"
REAL_C = ["babble", "train"]
SYNTH_C = ["sin", "drill"]
CONTEXTS = [REAL_C; SYNTH_C]
FS = 8000


## helper functions
function get_ha_files_real(PATH)
    files = map(x -> readdir(PATH * x * "/" * SNR * "/", join = true), filter(x -> x in REAL_C, CONTEXTS))
    files = collect(Iterators.flatten(files))
    type = files[1][end-2:end]
    shuffle(filter!(x -> contains(x, "."*type), files))
end

function get_ha_files_synth(PATH)
    files = map(x -> readdir(PATH * x * "/", join = true), filter(x -> x in SYNTH_C, CONTEXTS))
    files = collect(Iterators.flatten(files))
    type = files[1][end-2:end]
    filter!(x -> contains(x, "."*type), files)
end

function extract_index(output, contexts)
    for context in contexts
        if occursin(context, output)
            return context
        end
    end
    return error("invalid context file")
end

function map_input_output(inputs, outputs, contexts=CONTEXTS)
    pairs = []
    for input in inputs
        for output in outputs
            if split(split(input, "/")[end], ".")[1] == split(split(output, "/")[end], ".")[1]
                out_dict = JLD.load(output)
                push!(pairs, Dict("input" => signal_alignment(wavread(input)[1], FS),
                                  "speech" => get_signal(out_dict["rmz"], FS),
                                  "noise" => get_signal(out_dict["rmx"], FS), 
                                  "output" => get_signal(out_dict["rmz"], FS) + get_signal(out_dict["rmx"], FS),
                                  "context" => extract_index(output, contexts)))
                                  
            end
        end
    end
    return pairs
end