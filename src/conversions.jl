# # Helper functions

Point2{T}(a::Vector{T}) where T = Point2(a[1], a[2])

"""
    toPointVecs(poly::Polygon)

Creates a vector of [`Point`](@ref)s from the given polygon.
Returns a `Vector{Vector{Point}}`, with one element.
"""
toPointVecs(poly::GeoInterface.Polygon) = [Point2.(cs) for cs in poly.coordinates]

"""
    toPointVecs(mp::MultiPolygon)

Creates a vector of vectors of [`Point`](@ref)s from the given MultiPolygon.
Returns a `Vector{Vector{Point}}`.

!!! warning
    There is no support for holes in this function at present; that will need to
    wait for GeometryBasics.jl to become complete, possibly replacing GeoInterface.
"""
toPointVecs(mp::GeoInterface.MultiPolygon) = map(x -> Point2.(x[1]), mp.coordinates)

"""
    nonzero(pt::GeometryTypes.Point{2, T}) where T

Returns `true` if both of the elements are nonzero, and `false` otherwise.
"""
nonzero(pt::GeometryTypes.Point{2, T}) where {T} = pt[1] != zero(T) && pt[2] != zero(T)

"""
    imprecise(arr)

Returns `true` if the polygon is invalid when converted to Float32,
and `false` otherwise.
"""
function imprecise(arr)
    dif = Point2{Float32}.(arr) |> diff
    return !any(nonzero.(dif))
end

function toMesh(mp::Vector{Vector{Vector{Point2{T}}}}) where T

    meshes = GLNormalMesh[]

    for pol in mp # we check for holes here
        triangle_faces = EarCut.triangulate(pol)

        v = map(x-> Point3{T}(x[1], x[2], 0), vcat(pol...))

        push!(meshes, GLNormalMesh(vertices=v, faces=triangle_faces))
    end

    length(mp) == 1 && return meshes[1]

    return merge(meshes)
end

function toMesh(mp::Vector{Vector{Point2{T}}}) where T

    meshes = GLNormalMesh[]

    for pol in mp # WARNING we don't check for holes here, should probably do that...
        triangle_faces = EarCut.triangulate([pol])

        v = map(x-> Point3{T}(x[1], x[2], 0), pol)

        push!(meshes, GLNormalMesh(vertices=v, faces=triangle_faces))
    end

    length(mp) == 1 && return meshes[1]

    return merge(meshes)
end

# # Argument conversions

# ## Polygons

convert_arguments(::AbstractPlotting.Poly, poly::GeoInterface.Polygon) = (toPointVecs(poly)[1],)

convert_arguments(::Poly, mp::GeoInterface.MultiPolygon) = (toPointVecs(mp),)

# Only converts polygons and multipolygons
function convert_arguments(::Type{<: Poly}, fc::GeoInterface.FeatureCollection{GeoInterface.Feature})
    features = fc.features

    cs = Vector{Point2f0}[]

    imp = false

    for feature in features
        for coord in toPointVecs(feature.geometry)
            if imprecise(coord) || length(coord) <= 4
                @warn(
                    """
                    Imprecise coordinates!  You may want to consider reprojecting to a different coordinate system.
                    """,
                    coord
                )
                imp = true
            else
                push!(cs, coord)
            end
        end

    end

    imp && @warn(
                """Coordinates have been removed, because they were
                too ambiguous.  Number of coordinates is now $(length(cs)).
                """
            )

    (cs,)

end

function AbstractPlotting.convert_arguments(::Type{<: Mesh}, fc::GeoInterface.FeatureCollection{GeoInterface.Feature})
    return (fc.features .|> GeoInterface.geometry .|> toPointVecs .|> toMesh,) # return a Vector of meshes
end


# function plot!(plot::Poly{<: Tuple{GeoInterface.FeatureCollection{GeoInterface.Feature}}})5ytgtcx89o9lo

function Proj4.transform(src, dest, pt::Point2{T}) where T
    if isnan(pt[1]) && isnan(pt[2])
        return Point2{T}(NaN)
    end
    return Point2{T}(transform(src, dest, Vector(pt)))
end
Base.Broadcast.broadcastable(p::Projection) = Ref(p)
