function download_dep(orig, dest, hash)
    dest_file = joinpath("data", dest)
    if isfile(dest_file)
        dest_hash = open(dest_file, "r") do f
            bytes2hex(sha256(f))
        end
        if dest_hash == hash
            return nothing
        end
    end
    mkpath("data")
    download(orig, dest_file)
    return nothing
end

@testset "ccd2rgb" begin
    download_dep("http://chandra.harvard.edu/photo/2009/casa/fits/casa_0.5-1.5keV.fits", "casa_0.5-1.5keV.fits",
                "5794b9ebced6b991a3e53888d129a38fbf4309250112be530cb6442be812dea6")
    download_dep("http://chandra.harvard.edu/photo/2009/casa/fits/casa_1.5-3.0keV.fits", "casa_1.5-3.0keV.fits",
                "a48b2502ceb979dfad0d05fd5ec19bf3e197ff2d1d9c604c9340992d1bf7eec9")
    download_dep("http://chandra.harvard.edu/photo/2009/casa/fits/casa_4.0-6.0keV.fits", "casa_4.0-6.0keV.fits",
                "15e90a14515c121c2817e97b255c604ad019c9c2340fda4fb6c5c3da55e1b0c2")
    # download_dep("https://bintray.com/aquatiko/AstroImages.jl/download_file?file_path=ccd2rgb.jld","ccd2rgb.jld",
    #             "81d96742e13c07306cd8a1104ca9d6d1d67262a379e8e22a86ae14f392194a6a")
    download_dep("https://bintray.com/aquatiko/AstroImages.jl/download_file?file_path=ccd2rgb_rounded.jld","ccd2rgb_rounded.jld",
                "b938d19e0c52f53d9be15ae155c9f12422fa81f1e911111c7ee9a8684e554bd6")
        
    r = FITS(joinpath("data","casa_0.5-1.5keV.fits"))[1]
    b = FITS(joinpath("data","casa_1.5-3.0keV.fits"))[1]
    g = FITS(joinpath("data","casa_4.0-6.0keV.fits"))[1]
    linear_res = RGB.(ccd2rgb(r, b, g, shape_out = (1000,1000)))
    asinh_res = RGB.(ccd2rgb(r, b, g, shape_out = (1000,1000), stretch = asinh))
    
    linear_ans = load(joinpath("data","ccd2rgb_rounded.jld"), "linear")
    asinh_ans = load(joinpath("data","ccd2rgb_rounded.jld"), "asinh")

    function check_diff(arr1,arr2,rtol)
        count = 0
        for i in 1:size(arr1)[1]
            for j in 1:size(arr1)[2]
                if !isapprox(arr1[i,j],arr2[i,j],nans =  true, rtol = rtol)
                    @info i,j,arr1[i,j],arr2[i,j], abs(arr1[i,j]-arr2[i,j])/max(arr1[i,j],arr2[i,j])
                    count += 1
                end
            end
        end
        return iszero(count)
    end

    @test check_diff(red.(linear_res), red.(linear_ans),1e-7)
    @test isapprox(blue.(linear_res), blue.(linear_ans), nans = true, rtol = 1e-7)
    @test isapprox(green.(linear_res), green.(linear_ans), nans = true, rtol = 1e-7)

    @test isapprox(red.(asinh_res), red.(asinh_ans), nans = true, rtol = 1e-7)
    @test isapprox(blue.(asinh_res), blue.(asinh_ans), nans = true, rtol = 1e-7)
    @test isapprox(green.(asinh_res), green.(asinh_ans), nans = true, rtol = 1e-7)
end
