const EARTH_IMG = ImageMagick.load(joinpath(dirname(@__DIR__), "assets", "raster", "50-natural-earth-1-downsampled.png"))

const COASTLINES_LINEVEC = begin
    to_nansep_vec(coordinates.(geometry.(GeoJSON.read(Base.read(joinpath(dirname(@__DIR__), "assets", "vector", "110m_coastline.geojson"), String)).features))) do feature
        Point2f0.(feature)
    end
end
