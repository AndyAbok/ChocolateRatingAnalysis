using CSV
using DataFrames
using FloatingTableView
using Statistics
using Plots
using CairoMakie
using DecisionTree
using DataFrames:sort
using BenchmarkTools
using Random 

"""
Part One : Exploring the data
"""

##Consume in the data 
#@benchmark chocolateData = CSV.read("chocolate.csv", DataFrame) 
chocolateData =  CSV.File("chocolate.csv") |> DataFrame 
#@benchmark chocolateData = CSV.Rows("chocolate.csv") |> DataFrame 

# 1.)Getting the first 10 highly rated chocolate producing countries.

avgRatingForOriginCountries = 
    chocolateData |>
    chocolateData -> select(chocolateData,Not(:1))|>
    chocolateData -> combine(groupby(chocolateData,:country_of_bean_origin),:rating .=> [mean,length]) |>
    chocolateData -> filter(:rating_length => >(30),chocolateData) |>
    chocolateData -> sort(chocolateData,:rating_mean,rev = true) 

labels = string.(round.(first(avgRatingForOriginCountries[:,:2],10);digits=2))

Plots.plot(first(avgRatingForOriginCountries[:,:1],10),
     first(avgRatingForOriginCountries[:,:2],10),
     seriestype = :bar,
     orientation=:h,
     size = (1200, 1000),
     title  = "Average Rating of Cocoa Producing Countries",
     xlabel = "Avearge Ratings",
     ylabel = "Countries",
     xlim = (3.0,3.50),
     series_annotations = labels) 

companyByRating = 
    chocolateData |>
    chocolateData -> select(chocolateData,Not(:1))|>
    chocolateData -> combine(groupby(chocolateData,:company_manufacturer),:rating .=> [mean,length]) |>
    chocolateData -> filter(:rating_length => >(30),chocolateData) |>
    chocolateData -> sort(chocolateData,:rating_mean,rev = true) 

somaImporters = 
    chocolateData |>
    chocolateData -> select(chocolateData,Not(:1))|>
    chocolateData -> filter(:company_manufacturer => x -> x == companyByRating[1,1],chocolateData) |> 
    chocolateData -> combine(groupby(chocolateData,:country_of_bean_origin),:country_of_bean_origin .=> length .=> :noOfCompaniesExportingFrom) |> 
    chocolateData -> DataFrames.sort(chocolateData,:noOfCompaniesExportingFrom,rev = true)

labels = String.(somaImporters[:,:country_of_bean_origin])
valuesPerCo = somaImporters[:,:noOfCompaniesExportingFrom]

p = PyPlot.pie(valuesPerCo,
		labels=labels,
		shadow=true,
		startangle=90,
		autopct="%1.1f%%")		
title("Importaion Country Propotion")
figure("pyplot_piechart",figsize=(10,10))

#=
2.) Comparison of the number of Companies in a country that use locally produced cocoa beans to manufacture chocolate
    and the number of countries that import their cocoa beans for chocolate manufacturing.
=#
# a.) Number of companies that use thier countries cocoa beans to manufacture chocolate.

chocaWithOrigin_Country = 
    chocolateData |>
    chocolateData -> select(chocolateData,Not(:1))|>
    chocolateData -> filter([:country_of_bean_origin,:company_location] => (x,y) -> x == y,chocolateData) |> 
    chocolateData -> combine(groupby(chocolateData,:company_location),:company_manufacturer .=> length => :noOfCompanies,
                            [:company_location] .=> unique,renamecols = false)   |> 
    chocolateData -> sort(chocolateData,:noOfCompanies,rev = true)

# b.) Number of companies that import cocoa beans for chocoalte manufacturing.

chocaNotInCountry = 
    chocolateData |>
    chocolateData -> select(chocolateData,Not(:1))|>
    chocolateData -> filter([:country_of_bean_origin,:company_location] => (x,y) -> x != y,chocolateData) |> 
    chocolateData -> combine(groupby(chocolateData,:company_location),:company_manufacturer .=> length => :noOfexternalChocoCompany)|>
    chocolateData -> DataFrames.sort(chocolateData,:noOfexternalChocoCompany,rev = true) 

outAndInCountryData = outerjoin(chocaNotInCountry,chocaWithOrigin_Country,on = :company_location) |> x -> coalesce.(x, 0.0) 

xs = string.(first(outAndInCountryData[!,:company_location],10))
ys = 
    outAndInCountryData |>
    outAndInCountryData -> DataFrames.sort(outAndInCountryData,:noOfexternalChocoCompany,rev= true) |>
    outAndInCountryData -> first(outAndInCountryData,10) |> 
    outAndInCountryData ->  outAndInCountryData[:,:noOfexternalChocoCompany]

ysTwo,countries = 
    outAndInCountryData |>
    outAndInCountryData -> DataFrames.sort(outAndInCountryData,:noOfCompanies,rev= true) |>
    outAndInCountryData -> first(outAndInCountryData,10) |> 
    outAndInCountryData ->  (outAndInCountryData[:,:noOfCompanies],outAndInCountryData[:,:company_location])

Plots.plot(
    Plots.plot(xs,
        ys,
        seriestype = :bar,
        orientation=:h,         
        xlabel = "Countries",
        ylabel = "Number of companies",
        label="noOfImportersAndManufacture"),    

    Plots.plot(countries,
        ysTwo,
        seriestype = :bar,
        orientation=:h,
        #size = (600, 600),
        xlabel = "Countries",
        ylabel = "Number of companies",
        label="noOfProducersAndManufactures"),

    title  = "No of Companies that Produce & Manufacture  Chocoa and chocolate 
              against Those that Import and Manufacture in A Country",
    size = (1500, 700),
    layout = (1,2))


#3.) The first n companies that import their cocoa beans which countries do they mostly import from.
   
#a.) Highest expoters of cocoa beans 

highestExporterOfCocoa = 
    chocolateData |>
    chocolateData -> select(chocolateData,Not(:1))|>
    chocolateData -> filter([:country_of_bean_origin,:company_location] => (x,y) -> x != y,chocolateData) |> 
    chocolateData -> combine(groupby(chocolateData,:country_of_bean_origin),:country_of_bean_origin .=> length .=> :noOfExports) |> 
    chocolateData -> sort(chocolateData,:noOfExports,rev = true) |>
    chocolateData -> first(chocolateData,10)

let
    f = Makie.Figure()
    noOfexporters = highestExporterOfCocoa[:,:noOfExports]
    countriesExportingTo = String.(highestExporterOfCocoa[:,:country_of_bean_origin])

    ax = Axis(f[1, 1], xlabel = "No Of Company it Exports to")
    tightlimits!(ax, Left())
    hideydecorations!(ax)

    barplot!(noOfexporters, direction = :x)
    CairoMakie.text!(countriesExportingTo, position = Point.(noOfexporters, 1:10), align = (:right, :center),
        offset = (-20, 0), color = :white)
    f
end

#Where the various companies located in various countries import their cocoa beans. 
noOfImportCountries = 
    chocolateData |>
    chocolateData -> select(chocolateData,Not(:1))|>
    chocolateData -> filter([:country_of_bean_origin,:company_location] => (x,y) -> x != y,chocolateData) |> 
    chocolateData -> combine(groupby(chocolateData,[:company_location,:country_of_bean_origin]),:country_of_bean_origin .=> length .=> :noOfCompaniesExportingFromOrigin) |> 
    chocolateData -> DataFrames.sort(chocolateData,[:company_location,:noOfCompaniesExportingFromOrigin],rev = [true,true])

#=
Comments and memory analysis 
Data cleaning and sorting Separeate ingridients to individuals columns 
=#

newDf = 
    chocolateData |> 
    chocolateData -> select(chocolateData, all.(!ismissing, eachcol(chocolateData))) |>
    chocolateData -> filter(:ingredients => x -> x != "NA",chocolateData) 

ingridientsCleaning = DataFrame([(noOfIngridients = a,ingredients = b) for (a,b) in split.(newDf.ingredients, "-")])
ingridientsCleaning[!,:noOfIngridients] = parse.(Int64,ingridientsCleaning[:,:noOfIngridients])

cleanData = 
    ingridientsCleaning |>
    ingridientsCleaning -> DataFrames.transform(ingridientsCleaning, [:ingredients => ByRow(v -> occursin(x, v)) => x for x in ["B", "S", "C", "L","V","S*","Sa"]])|>
    ingridientsCleaning -> rename(ingridientsCleaning,[:B,:S,:C,:L,:V,Symbol("S*"),:Sa] .=> [:Beans,:Sugar,:CocoaButter,:Lecithin,:Vanilla,:Sweetener,:Salt]) |> 
    ingridientsCleaning -> hcat(newDf,ingridientsCleaning,makeunique=true) |>
    ingridientsCleaning -> select(ingridientsCleaning,Not([:Column1]))

function addCommaSep(strInput::AbstractString)
    countComma = count(i-> (i == ','),strInput)
    output = 
        if countComma == 1 
            string(strInput,",", "NotApplicable", ',' ,"NotApplicable", ',' ,"NotApplicable") 
        elseif countComma == 2
            string(strInput,',', "NotApplicable", ',' ,"NotApplicable")  
        elseif  countComma == 3
            string(strInput,',' ,"NotApplicable") 
        elseif  countComma == 0
            string(strInput,',', "NotApplicable", ',' ,"NotApplicable", ',' ,"NotApplicable",',' ,"NotApplicable",',' ,"NotApplicable")
        else
            strInput 
        end
    return output
end

cleanData[!,:most_memorable_characteristics] = addCommaSep.(cleanData[:,:most_memorable_characteristics])
dataFrameWithMemories = DataFrame([(firstMemory = a,secondMemory = b,thirdMemory = c,fourthMemory = d) for (a,b,c,d) in split.(cleanData.most_memorable_characteristics, ",")])
memoriesAnalyticsData = hcat(cleanData,dataFrameWithMemories)

# 4.) Getting the first memory comments with the highest ratings.

ratingsSummarised = 
    memoriesAnalyticsData |> 
    memoriesAnalyticsData -> combine(groupby(memoriesAnalyticsData,[:firstMemory]),:rating .=> [mean,length]) 

commentsSamples = ratingsSummarised[shuffle(1:nrow(ratingsSummarised))[1:40], :] 

font(8)
Plots.plot(commentsSamples[:,:rating_mean],           
           seriestype  = :scatter,
           series_annotations = Plots.text.(commentsSamples[:,:firstMemory],:bottom,rotation= 35.0,family="serif"), 
           size = (1200, 800),
           title = "First Comment and ratings",
           xlabel = "Count",
           ylabel = "Average Rating")
        
#5.) Analysis to confirm an Hypothesis if the number of ingridients increases the ratings. 
analyzeNoOfIngreds = 
    cleanData |>
    #cleanDaata -> DataFrames.transform(cleanData,:noOfIngridients => ByRow(x -> Base.parse(Int64,x)),renamecols = false) |> 
    cleanData -> combine(groupby(cleanData,[:ingredients]),[:rating,:noOfIngridients] .=> mean)

xs = analyzeNoOfIngreds[:,:noOfIngridients_mean]
ys = analyzeNoOfIngreds[:,:rating_mean]
categories = string.(unique(xs))

let
    fig = Makie.Figure(resolution = (600, 400), font = "sans")
    ax = Axis(fig, xlabel = "", ylabel = "", xticks = ([1,2,3,4,5,6], categories))
    colors = ColorScheme(range(colorant"black", colorant"red", length=length(categories)))

    Makie.violin!(xs,ys; width = 0.80,show_median = true, mediancolor = :black)
    fig[1,1] = ax
    fig
end

#6.) Analysing the percentage of each ingredients used.

function getIstruePercentage(arr::AbstractArray)
    n = length(arr)
    getPositiveVals = filter(x -> x ==true,arr) |> length
    return (getPositiveVals/n) * 100.0
end 

percentageOfIngredientUsage = 
    cleanData |> 
    cleanData -> combine(cleanData,[:Beans,:Sugar,:CocoaButter,:Lecithin,:Vanilla,:Sweetener,:Salt] .=> getIstruePercentage,renamecols = false) |>
    cleanData -> stack(cleanData) |> 
    cleanData -> rename(cleanData,[:variable,:value] .=> [:ingredients,:PercentageOfUsage])

pieDataY = string.(percentageOfIngredientUsage[:,:ingredients])
pieDataX = Float64.(percentageOfIngredientUsage[:,:PercentageOfUsage])

Plots.bar(pieDataY,pieDataX,title = "Percentage of use of each ingredient")

#7.) Geting which mixture among the ingredients gives the highest ratings 

ratingByIngredients = 
    cleanData |> 
    cleanData -> combine(groupby(cleanData,:ingredients_1),:rating  .=> mean,renamecols = false)

function getMeanRating(inputDF::AbstractDataFrame,colName::String)
     getPositiveVals = filter(colName => ==(true),inputDF)  
    return mean(getPositiveVals[:,:rating])
end 

outPutDF = 
    let 
        ingredients = ["Beans","Sugar","CocoaButter","Lecithin","Vanilla","Sweetener","Salt"]

        gdf = groupby(cleanData,:ingredients_1)
        n₁ = length(gdf)
        n₂ = length(ingredients)
        mixtureMatrix = zeros(n₁,n₂)

        for i = 1:n₁
            for j = 1:n₂
                mixtureMatrix[i,j] = getMeanRating(gdf[i],ingredients[j]) 
            end
        end

        ##Matrix to dataFrame
        mixtureDataFrame = DataFrame(mixtureMatrix,:auto)
        mixtureDataFrame .= ifelse.(isnan.(mixtureDataFrame), 0.0, mixtureDataFrame)
        rename!(mixtureDataFrame,names(mixtureDataFrame) .=> ingredients)
        colOne = select(combine(first, gdf), groupcols(gdf))
        hcat(colOne,mixtureDataFrame)
        
    end

let
    m = 21
    n = 7
    data = Matrix(outPutDF[:,Not([:ingredients_1])])
    yticks = names(outPutDF[:,Not([:ingredients_1])]) 
    xticks = String.(outPutDF[:,:ingredients_1])
    fig = Makie.Figure(resolution = (1200, 600), fontsize = 20)
    ax = Axis(fig)
    hmap =Makie.heatmap!(ax, data, colormap = :plasma)
    for i in 1:21, j in 1:7
        if data[i,j] < 3.0
            txtcolor = :white
        else
            txtcolor = :black
        end
        Makie.text!(ax, "$(round(data[i,j], digits = 2))", position = (i,j),
            color = txtcolor, align = (:center, :center))
    end

    cbar = Colorbar(fig, hmap, label = "values", width = 21,
                ticksize=21, tickalign = 1, height = Relative(3.55/4))
    ax.xticks = (1:m, xticks)
    ax.yticks = (1:n, yticks)
    ax.xticklabelrotation = π/3
    fig[1, 1] = ax
    fig[1, 2] = cbar
    colgap!(fig.layout, 7)
    fig
end

# 8.) Chocoa Percentage 
function removePercentSign(inputString::String)

    newValue = 
        if occursin("%",string(inputString))
        newString = chop(inputString)
        toNumeric = parse(Float64,newString)/100.0 
        else
            parse(Float64,inputString)/100.0
        end
    return newValue
end

memoriesAnalyticsData[!,:cocoa_percent] = map(removePercentSign ∘ string,memoriesAnalyticsData[:,:cocoa_percent])

function getPercentageBand(arrInput::AbstractVector{Float64}) 
    bandRange = collect(0.1:0.1:1.0)
    bandHolder = String[]
    for i in 1:length(arrInput) 
        idx = findfirst(x ->  floor(arrInput[i],digits=1) == x,bandRange)
        upperRange = string.(ceil(Int,(bandRange[idx]*100.0))) 
        lowerRange = string.(ceil(Int,(bandRange[idx] + 0.09) * 100.0))
        iterBand = string(upperRange,-,lowerRange)
        push!(bandHolder,iterBand)
    end
    return bandHolder
end

@benchmark getPercentageBandOne(memoriesAnalyticsData)
@benchmark memoriesAnalyticsData[!, :percentBand] = getPercentageBand(memoriesAnalyticsData[:,:cocoa_percent])

cocoaPercentage = 
    memoriesAnalyticsData |>
    memoriesAnalyticsData -> combine(groupby(memoriesAnalyticsData,:percentBand),:rating .=> [mean,length]) |>
    memoriesAnalyticsData -> sort(memoriesAnalyticsData,:rating_mean,rev = true)

xs = cocoaPercentage[:,:percentBand]
ys =  cocoaPercentage[:,:rating_mean]

barplot(ys, fillto = 0.5,
        axis = (ylabel ="Avearge Ratings",
           xticks = (1:7,xs), xticklabelrotation = pi/8),
           color = :red,strokecolor = :black, 
           strokewidth = 1)

