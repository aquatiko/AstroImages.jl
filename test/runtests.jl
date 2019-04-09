using AstroImages, FITSIO, Images, Random
using Test

import AstroImages: _float, render
@testset "default handler" begin
        fname4 = tempname() * ".fits"
        @testset "less dimensions than 2" begin
            data = rand(2)
            FITS(fname4, "w") do f4
                write(f4, data)
            end
            @test_throws ErrorException AstroImage(fname4)
        end

        @testset "no ImageHDU" begin
            f4 = FITS(fname4, "w")
            ## Binary table
            indata = Dict{String, Array}()
            i = length(indata) + 1
            indata["col$i"] = [randstring(10) for j=1:20]  # ASCIIString column
            i += 1
            indata["col$i"] = ones(Bool, 20)  # Bool column
            i += 1
            indata["col$i"] = reshape([1:40;], (2, 20))  # vector Int64 column
            i += 1
            indata["col$i"] = [randstring(5) for j=1:2, k=1:20]  # vector ASCIIString col
            indata["vcol"] = [randstring(j) for j=1:20]  # variable length column
            indata["VCOL"] = [collect(1.:j) for j=1.:20.] # variable length

            # test writing
            write(f4, indata; varcols=["vcol", "VCOL"])

            @test_throws MethodError AstroImage(f4)
        end
end


@testset "Conversion to float and fixed-point" begin
    @testset "Float" begin
        for T in (Float16, Float32, Float64)
            @test _float(T(-9.8)) === T(-9.8)
            @test _float(T(12.3)) === T(12.3)
        end
    end
    @testset "Integers" begin
        for (UIT, SIT) in ((UInt8,  Int8),
                           (UInt16, Int16),
                           (UInt32, Int32),
                           (UInt64, Int64))
            N = sizeof(UIT) * 8
            NT = Normed{UIT, N}
            maxint = UIT(big(2) ^ (N - 1))
            @test _float(typemin(UIT)) === _float(typemin(SIT)) === NT(0)
            @test _float(UIT(85)) === reinterpret(NT, UIT(85))
            @test _float(SIT(-85)) === _float(UIT(-85 + big(maxint)))
            @test _float(SIT(115)) === _float(UIT(115) + maxint)
            @test _float(typemax(UIT)) === _float(typemax(SIT)) === NT(1)
        end
    end
end

@testset "FITS and images" begin
    fname1 = tempname()* ".fits"
    try
        for T in [UInt8, Int8, UInt16, Int16, UInt32, Int32, Int64,
                  Float32, Float64]
            data = reshape(T[1:100;], 5, 20)
            FITS(fname1, "w") do f1
                write(f1, data)
            end
            @test load(fname1) == data
            @test load(fname1, (1, 1)) == (data, data)
            img = AstroImage(fname1)
            rendered_img = render(img)
            @test iszero(minimum(rendered_img))
            
            img = AstroImage(fname1, 1)
            rendered_img = render(img)
            @test iszero(minimum(rendered_img))
            
            img = AstroImage(Gray, fname1, 1)
            rendered_img = render(img)
            @test iszero(minimum(rendered_img))
        end
    finally
        rm(fname1, force=true)
    end
end

include("plots.jl")
