"""
Part Two: Applying Machine Learning Model.
"""

#1.) Divide the data int training and test set. 
function splitdf(df, pct)
    @assert 0 <= pct <= 1
    ids = collect(axes(df, 1))
    shuffle!(ids)
    sel = ids .<= nrow(df) .* pct
    trainset =   [df, sel, :]
    testset =  [df, .!sel, :]
    return trainset[1],testset[1]
end

memoriesAnalyticsData[!,:noOfIngridients] = Float64.(memoriesAnalyticsData[:,:noOfIngridients])
memoriesAnalyticsData[!,:country_of_bean_origin] = string.(memoriesAnalyticsData[:,:country_of_bean_origin])
trainigSet,testingSet = splitdf(memoriesAnalyticsData,0.8)

features = Matrix(trainigSet[:,[:country_of_bean_origin,:noOfIngridients,:percentBand,:Beans,:Sugar,:CocoaButter,:Lecithin,:Vanilla,:Sweetener,:Salt]])
labels = trainigSet[:,:rating]

#=
Model Building
using 2 random features, 10 trees, 0.5 portion of samples per tree, and a maximum tree depth of 6
=#
chocoModel = build_forest(labels, features, 2, 10, 0.5, 6)

# testTheModel
apply_forest(chocoModel,["Tanzania",4,"50-60",true,true,true,false,false,false,false])

# run 3-fold cross validation for forests, using 2 random features per split
n_folds=10; n_subfeatures=2
accuracy = nfoldCV_forest(labels, features, n_folds, n_subfeatures)

####Run the tests 
testingFeatures = Matrix(testingSet[:,[:country_of_bean_origin,:noOfIngridients,:percentBand,:Beans,:Sugar,:CocoaButter,:Lecithin,:Vanilla,:Sweetener,:Salt]])
predicted = apply_forest(chocoModel,testingFeatures)
actual = testingSet[:,:rating]

comparisonDf = DataFrame(Predicted = predicted,Actual = actual)
sampleLen = 50
samples = comparisonDf[shuffle(1:nrow(comparisonDf))[1:sampleLen], :] 

Plots.plot(collect(1:sampleLen),
           samples[:,:Actual],
           seriestype  = :line,
           label = "Actual Ratings") 

Plots.plot!(collect(1:sampleLen),
           samples[:,:Predicted],
           seriestype  = :line,
           label = "Predicted Ratings") 

##Perfomance Evaluation 
accuracyCheck = 
    let
        function errorTerm(ŷ, y)
            return ŷ - y
        end

        mse(ŷ, y)  = errorTerm(ŷ, y) |> (x)->x.^2 |> mean
        rmse(ŷ, y) = errorTerm(ŷ, y) |> x -> x.^2 |> mean |> sqrt
        mae(ŷ, y)  = errorTerm(ŷ, y) |> x -> abs.(x) |> mean
        mdae(ŷ, y) = errorTerm(ŷ, y) |> x -> abs.(x) |> median
        maxae(ŷ, y) = errorTerm(ŷ, y) |> x -> abs.(x) |> maximum

        ŷ = comparisonDf[:,:Predicted]
        y = comparisonDf[:,:Actual]

        accuracyMetrics = 
            DataFrame(
                meanSquaredError = mse(ŷ, y), 
                RootMeanSquaredError = rmse(ŷ, y),
                MeanAbsoluteError = mae(ŷ, y),
                MaximumAbsoluteError = maxae(ŷ, y),
                MediumAbsoluteError = mdae(ŷ, y))

        print(stack(accuracyMetrics))
    end

println("The End.")


#= 
Conclusions 
71-73% cocoa is a safe bet
There is atleast 160 common tastes which is preferred for first tastes.
Sugar is the most common ingredient, followed by cocoa butter, lecithin and vanilla.
Beans are mostly originated in developing countries and is exported to developed countries.
Top tastes seems to be creamy, which is pretty popular as first taste, 
=#




