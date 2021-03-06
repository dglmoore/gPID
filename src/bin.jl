using Discretizers, Statistics

struct ThresholdBinner{R <: Real} <: DiscretizationAlgorithm
    θ::R
end

function Discretizers.binedges(binner::ThresholdBinner, xs::AbstractArray{<:Real})
    a, b = extrema(xs)
    [a, binner.θ, b]
end

struct MeanBinner <: DiscretizationAlgorithm end

function Discretizers.binedges(binner::MeanBinner, xs::AbstractArray{<:Real})
    binedges(ThresholdBinner(mean(xs)), xs)
end

const EqualCountBinner = DiscretizeUniformCount
const EqualWidthBinner = DiscretizeUniformWidth
const BayesianBinner = DiscretizeBayesianBlocks

function bin!(df::DataFrame, cols::Symbol...; algo=EqualCountBinner(2), replace=false)
    namemap = Dict{Symbol,Symbol}()
    for c in cols
        c_binned = Symbol(string(c)*"_binned")
        df[!,c_binned] = bin(df[:,c], algo)
        namemap[c_binned] = c
    end
    if replace
        select!(df, Not(collect(cols)))
        rename!(df, namemap)
    end
    df
end

bin!(df::DataFrame; kwargs...) = bin!(df, Symbol.(names(df))...; kwargs...)

function bin(xs::AbstractArray{<:Real}, alg::DiscretizationAlgorithm)
    encode(LinearDiscretizer(sort(binedges(alg, xs))), xs)
end

bin(xs::AbstractArray{<:Integer}, alg::DiscretizationAlgorithm) = bin(Array{Float64}(xs), alg)

bin(xs::AbstractArray{Symbol}, args...) = encode(CategoricalDiscretizer(xs), xs)
bin(xs::AbstractArray{<:AbstractString}, args...) = encode(CategoricalDiscretizer(xs), xs)

bin(df::DataFrame, args...; kwargs...) = bin!(copy(df), args...; kwargs...)
