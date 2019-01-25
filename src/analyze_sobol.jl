using Statistics

include("utils.jl")

#=
Code adapted from: Herman, J. and Usher, W. (2017) SALib: An open-source Python 
library for sensitivity analysis. Journal of Open Source Software, 2(9)

References
----------
    [1] Sobol, I. M. (2001).  "Global sensitivity indices for nonlinear
        mathematical models and their Monte Carlo estimates."  Mathematics
        and Computers in Simulation, 55(1-3):271-280,
        doi:10.1016/S0378-4754(00)00270-6.
    [2] Saltelli, A. (2002).  "Making best use of model evaluations to
        compute sensitivity indices."  Computer Physics Communications,
        145(2):280-297, doi:10.1016/S0010-4655(02)00280-1.
    [3] Saltelli, A., P. Annoni, I. Azzini, F. Campolongo, M. Ratto, and
        S. Tarantola (2010).  "Variance based sensitivity analysis of model
        output.  Design and estimator for the total sensitivity index."
        Computer Physics Communications, 181(2):259-270,
        doi:10.1016/j.cpc.2009.09.018.
=#

"""
    analyze(data::SobolData, model_output::AbstractArray{<:Number, S})

Performs a Sobol Analysis on the `model_output` produced with the problem 
defined by the information in `data` and returns the a dictionary of results
with the sensitivity indicies for each of the parameters.
"""
function analyze(data::SobolData, model_output::AbstractArray{<:Number, S}) where S

    # define constants
    D = length(data.params) # number of uncertain parameters in problem
    N = data.N # number of samples

    # normalize model output
    model_output = (model_output .- mean(model_output)) ./ std(model_output)

    # separate the model_output into results from matrices "A". "B" and "AB" 
    A, B, AB = split_output(model_output, N, D)

    # compute indicies and produce results
    firstorder = Array{Float64}(undef, D)
    totalorder = Array{Float64}(undef, D)

    for i in 1:D
        firstorder[i] = first_order(A, AB[:, i], B)
        totalorder[i] = total_order(A, AB[:, i], B)
    end

    results = Dict(:firstorder => firstorder, :totalorder => totalorder)

    return results
end

"""
    first_order(A::AbstractArray{<:Number, N}, AB::AbstractArray{<:Number, N}, B::AbstractArray{<:Number, N})

Calculate the first order sensitivity indicies for model outputs given model outputs
separated out into `A`, `AB`, and `A` and normalize by the variance of `[A B]`. [Saltelli et al., 
2010 Table 2 eq (b)]
"""
function first_order(A::AbstractArray{<:Number, N}, AB::AbstractArray{<:Number, N}, B::AbstractArray{<:Number, N}) where N
    return (mean(B .* (AB .- A), dims = 1) / var(vcat(A, B), corrected = false))[1]
end

"""
    total_order(A::AbstractArray{<:Number, N}, AB::AbstractArray{<:Number, N}, B::AbstractArray{<:Number, N})

Calculate the total order sensitivity indicies for model outputs given model outputs
separated out into `A`, `AB`, and `A` and normalize by the variance of `[A B]`. [Saltelli et al., 
2010 Table 2 eq (f)].
"""
function total_order(A::AbstractArray{<:Number, N}, AB::AbstractArray{<:Number, N}, B::AbstractArray{<:Number, N}) where N
    return (0.5 * mean((A .- AB).^2, dims = 1) / var(vcat(A, B), corrected = false))[1]
end

"""
    split_output(model_output::AbstractArray{<:Number, S}, N, D)

Separate the `model_outputs` into matrices "A", "B", and "AB" for calculation of sensitvity 
indices and return those three matrices.
"""
function split_output(model_output::AbstractArray{<:Number, S}, N, D) where S
    stepsize = D + 2

    A = model_output[1:stepsize:end]
    B = model_output[stepsize:stepsize:end]
    
    AB = Array{Float64}(undef, N, D)
    for i in 1:D
        AB[:, i] = model_output[i+1:stepsize:end, :]
    end

    return A, B, AB
end
