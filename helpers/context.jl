using AIDA

mutable struct ContextClassifier
    models 
    priors
    vmpits

    function ContextClassifier(models, priors, vmpits=25)
        new(models, priors, vmpits)
    end
end

infer_context(classifier, segment) =  model_selection(segment, classifier.models, classifier.priors, vmp_iter=classifier.vmpits, verbose=true)

# These priors are extracted from silent frames of BABBLE and TRAIN contexts respectively
# See AIDA repository
PRIORS = [Dict(:mθ => [1.0526046070458872, -0.4232782070078879], 
               :vθ => [0.0002274117502010668 -0.0001681986150731712; -0.0001681986150731712 0.00022744882724672668], 
               :aγ => 5144.5, :bγ => 1.5403421819348209, 
               :τ  => 1e12, :order=>2),
          Dict(:mθ => [0.497019359872337, -0.15475030421215585], 
               :vθ => [8.002457029876353e-5 -3.4446944242771045e-5; -3.4446944242771045e-5 8.003099010678723e-5], 
               :aγ => 7679.5, :bγ => 4.857063799328507, 
               :τ  => 1e12, :order=>2)]

# These priors are extracted from drill and sin waves
PRIORS_SYNTH = [Dict(:mθ => [1.2646338317976666, -0.7654157857726572], 
                     :vθ => [5.5386696689848445e-5 -3.967520511224343e-5; -3.967520511224343e-5 5.538346267442823e-5], 
                     :aγ => 4999.0001, :bγ => 3.963055225255385, 
                     :τ  => 1e12, :order=>2),
                Dict(:mθ => [1.254676463181625, -0.5728654597459446], 
                     :vθ => [9.394519867362753e-5 -7.494377148571183e-5; -7.494377148571183e-5 9.394812684081623e-5], 
                     :aγ => 4999.0001, :bγ => 3.5135063420433115, 
                     :τ  => 1e12, :order=>2)]